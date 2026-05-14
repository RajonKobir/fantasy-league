<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\GameMatch;
use App\Models\Team;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class TeamController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->only(['q', 'per_page', 'sort_by', 'sort_dir']);
        $perPage = (int) ($request->query('per_page', 15));
        $sortBy = $request->query('sort_by', 'created_at');
        $sortDir = strtolower($request->query('sort_dir', 'desc')) === 'asc' ? 'asc' : 'desc';

        $query = Team::with(['user', 'matchesAsTeamA', 'matchesAsTeamB']);

        if ($request->query('q')) {
            $q = $request->query('q');
            $query->where(function ($qr) use ($q) {
                $qr->where('name', 'like', "%{$q}%")
                    ->orWhereHas('user', function ($q2) use ($q) {
                        $q2->where('name', 'like', "%{$q}%");
                    });
            });
        }

        if ($sortBy === 'owner') {
            $query->leftJoin('users', 'teams.user_id', '=', 'users.id')
                ->orderBy('users.name', $sortDir)
                ->select('teams.*');
        } else {
            // allow sort by name or created_at
            $allowed = ['name', 'created_at'];
            $sortByAllowed = in_array($sortBy, $allowed) ? $sortBy : 'created_at';
            $query->orderBy($sortByAllowed, $sortDir);
        }

        $teams = $query->paginate($perPage)->withQueryString();
        // Ensure logo_url is always present and absolute
        $teams->getCollection()->transform(function ($team) {
            $team->logo_url = $team->logo_url ? asset($team->logo_url) : null;
            return $team;
        });

        $users = User::select(['id', 'name'])->orderBy('name')->get();
        $tournaments = \App\Models\Tournament::select(['id', 'name'])->orderBy('name')->get();

        return Inertia::render('Admin/Teams/Index', compact('teams', 'filters', 'users', 'tournaments'));
    }

    // Bulk actions for teams
    public function bulk(Request $request)
    {
        $request->validate([
            'ids' => 'required|array|min:1',
            'action' => 'required|string|in:delete,change_owner,assign_tournament',
            'user_id' => 'nullable|exists:users,id',
            'tournament_id' => 'nullable|exists:tournaments,id',
        ]);

        $ids = $request->input('ids');
        $action = $request->input('action');

        if ($action === 'delete') {
            $teams = Team::whereIn('id', $ids)->get();
            foreach ($teams as $team) {
                $team->selections()->delete();
                $team->delete();
            }

            return redirect()->back()->with('success', 'Selected teams deleted');
        }

        if ($action === 'change_owner') {
            $userId = $request->input('user_id');
            Team::whereIn('id', $ids)->update(['user_id' => $userId]);

            return redirect()->back()->with('success', 'Selected teams updated');
        }

        if ($action === 'assign_tournament') {
            $tournamentId = $request->input('tournament_id');
            Team::whereIn('id', $ids)->update(['tournament_id' => $tournamentId]);

            return redirect()->back()->with('success', 'Selected teams assigned to tournament');
        }

        return redirect()->back()->with('error', 'Invalid action');
    }

    // Export selected teams as CSV
    public function export(Request $request)
    {
        $request->validate([
            'ids' => 'required|array|min:1',
        ]);

        $ids = $request->input('ids');
        $teams = Team::whereIn('id', $ids)->with('user')->get();

        // Build CSV in-memory so it's easily testable and still returns a CSV response
        $handle = fopen('php://temp', 'r+');
        // header row
        fputcsv($handle, ['id', 'name', 'owner_name', 'tournament_id']);
        foreach ($teams as $t) {
            fputcsv($handle, [$t->id, $t->name, optional($t->user)->name, $t->tournament_id]);
        }
        rewind($handle);
        $csv = stream_get_contents($handle);
        fclose($handle);

        $filename = 'teams_export_'.now()->format('Ymd_His').'.csv';

        return response($csv, 200, [
            'Content-Type' => 'text/csv',
            'Content-Disposition' => 'attachment; filename="'.$filename.'"',
        ]);
    }

    public function create()
    {
        $users = User::select(['id', 'name'])->get();

        return Inertia::render('Admin/Teams/Create', compact('users'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'user_id' => 'nullable|exists:users,id',
            'logo' => 'nullable|image|max:4096',
        ]);

        DB::beginTransaction();
        try {
            if ($request->hasFile('logo')) {
                $path = $request->file('logo')->store('teams/tmp', 'public');
                $validated['logo_url'] = Storage::url($path);
            }
            $team = Team::create($validated);

            // Move logo to permanent location if uploaded
            if (isset($path)) {
                $newPath = "teams/{$team->id}/" . basename($path);
                Storage::disk('public')->move($path, $newPath);
                $team->logo_url = Storage::url($newPath);
                $team->save();
            }
            DB::commit();
        } catch (\Throwable $e) {
            if (isset($path)) {
                Storage::disk('public')->delete($path);
            }
            DB::rollBack();
            throw $e;
        }

        return redirect()
            ->route('admin.teams.index')
            ->with('success', 'Team created successfully!');
    }

    public function edit(Team $team)
    {
        $users = User::select(['id', 'name'])->get();

        return Inertia::render('Admin/Teams/Edit', compact('team', 'users'));
    }

    public function update(Request $request, Team $team)
    {
        // Log incoming request metadata to help diagnose upload/update failures


        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'user_id' => 'nullable|exists:users,id',
            'logo' => 'nullable|image|mimes:jpg,jpeg,png,gif|max:4096',
            'remove_logo' => 'nullable|boolean',
        ]);

        $oldPath = null;
        $tmpPath = null;
        $newLogoPath = null;
        if ($team->logo_url) {
            $oldPath = str_replace('/storage/', '', $team->logo_url);
        }

        DB::beginTransaction();
        try {
            $newLogoUploaded = false;

            if ($request->boolean('remove_logo')) {
                $validated['logo_url'] = null;

            }

            if ($request->hasFile('logo')) {
                $tmpPath = $request->file('logo')->store('teams/tmp', 'public');

                $newLogoPath = "teams/{$team->id}/" . basename($tmpPath);
                $moveResult = Storage::disk('public')->move($tmpPath, $newLogoPath);

                $validated['logo_url'] = Storage::url($newLogoPath);
                $newLogoUploaded = true;
            }

            $team->update($validated);


            DB::commit();


            // Only delete old file if a new logo was uploaded
            if ($newLogoUploaded && $oldPath) {
                if (Storage::disk('public')->exists($oldPath)) {
                    Storage::disk('public')->delete($oldPath);

                }
            }
            // If remove_logo is set and no new logo uploaded, delete old file
            if ($request->boolean('remove_logo') && !$newLogoUploaded && $oldPath) {
                if (Storage::disk('public')->exists($oldPath)) {
                    Storage::disk('public')->delete($oldPath);

                }
            }
        } catch (\Throwable $e) {
            if (!empty($tmpPath) && Storage::disk('public')->exists($tmpPath)) {
                Storage::disk('public')->delete($tmpPath);
            }
            if (!empty($newLogoPath) && Storage::disk('public')->exists($newLogoPath)) {
                Storage::disk('public')->delete($newLogoPath);
            }
            DB::rollBack();

            throw $e;
        }

        return redirect()
            ->route('admin.teams.index')
            ->with('success', 'Team updated successfully!');
    }

    public function destroy(Team $team)
    {
        if ($team->logo_url) {
            $oldPath = str_replace('/storage/', '', $team->logo_url);
            if (Storage::disk('public')->exists($oldPath)) {
                Storage::disk('public')->delete($oldPath);
            }
        }

        $team->delete();

        return redirect()
            ->route('admin.teams.index')
            ->with('success', 'Team deleted successfully!');
    }
}
