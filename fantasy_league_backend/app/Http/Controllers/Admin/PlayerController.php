<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Player;
use App\Models\PlayerRole;
use App\Models\Team;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class PlayerController extends Controller
{
    /**
     * Display a paginated listing of players.
     */
    public function index(Request $request)
    {
        $filters = $request->only(['q', 'per_page']);
        $perPage = (int) ($request->query('per_page', 25));

        $players = Player::with('playerRole')->when($request->query('q'), function ($query, $q) {
            $query->where(function ($q2) use ($q) {
                $q2->where('name', 'like', "%{$q}%")->orWhere('nationality', 'like', "%{$q}%");
            });
        })->latest()->paginate($perPage)->withQueryString();

        return Inertia::render('Admin/Players/Index', [
            'players' => $players,
            'filters' => $filters,
        ]);
    }

    /**
     * Show the form for creating a new player.
     */
    public function create()
    {
        return Inertia::render('Admin/Players/Create', [
            'roles' => PlayerRole::all(),
            'countries' => \App\Models\Country::select('id','name')->orderBy('name')->get(),
        ]);
    }

    /**
     * Store a newly created player.
     */
    public function store(Request $request)
    {
        // Accept legacy `team` param for backwards compatibility: map to `nationality`
        if ($request->has('team') && ! $request->has('nationality')) {
            $request->merge(['nationality' => $request->input('team')]);
        }

        // Basic validation (role can be passed either as `player_role_id` or a string `role`)
        $request->validate([
            'name' => 'required|string|max:255',
            'player_role_id' => 'nullable|exists:player_roles,id',
            'role' => 'nullable|string',
            'nationality' => 'nullable|string|max:255|required_without:country_id',
            'country_id' => 'nullable|integer|exists:countries,id',
            'image' => 'nullable|image|max:3072',
        ]);

        $hasPlayerRoleId = $request->filled('player_role_id');
        $hasRoleString = $request->filled('role');

        // If neither provided, require player_role_id (keeps backwards compatibility)
        if (! $hasPlayerRoleId && ! $hasRoleString) {
            return back()->withErrors(['player_role_id' => 'The player role id field is required.']);
        }

        // Normalize and validate string role if provided
        if ($hasRoleString) {
            $roleStr = strtolower($request->input('role'));
            $allowedRoles = ['batsman','bowler','all-rounder','wicket-keeper'];
            if (! in_array($roleStr, $allowedRoles)) {
                // remove uploaded file if present
                if ($request->hasFile('image')) {
                    $tmp = $request->file('image')->store('players/tmp', 'public');
                    if (Storage::disk('public')->exists($tmp)) {
                        Storage::disk('public')->delete($tmp);
                    }
                }
                return back()->withErrors(['role' => 'Invalid role']);
            }
        }

        DB::beginTransaction();
        try {
            $data = $request->only(['name', 'player_role_id', 'nationality', 'country_id']);

            if ($hasRoleString) {
                $data['role'] = strtolower($request->input('role'));
            }

            // If country_id provided but nationality not set, resolve to country's name
            if (empty($data['nationality']) && ! empty($data['country_id'])) {
                $country = \App\Models\Country::find($data['country_id']);
                if ($country) {
                    $data['nationality'] = $country->name;
                }
            }

            $player = Player::create($data);

            if ($request->hasFile('image')) {
                // For create, store in root 'players' folder (legacy tests expect this)
                $path = $request->file('image')->store('players', 'public');
                $player->update(['image_url' => Storage::url($path)]);
            }

            DB::commit();
        } catch (\Throwable $e) {
            if (isset($path)) {
                Storage::disk('public')->delete($path);
            }
            DB::rollBack();
            throw $e;
        }

        return to_route('admin.players.index')
            ->with('success', '✅ Player created successfully!');
    }

    /**
     * Show the form for editing the specified player.
     */
    public function edit(Player $player)
    {
        return Inertia::render('Admin/Players/Edit', [
            'player' => $player,
            'roles' => PlayerRole::all(),
            'countries' => \App\Models\Country::select('id','name')->orderBy('name')->get(),
        ]);
    }

    /**
     * Update the specified player.
     */
    public function update(Request $request, Player $player)
    {
        // Accept legacy `team` param for backwards compatibility: map to `nationality`
        if ($request->has('team') && ! $request->has('nationality')) {
            $request->merge(['nationality' => $request->input('team')]);
        }

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'player_role_id' => 'sometimes|integer|exists:player_roles,id',
            'role' => 'sometimes|string',
            'nationality' => 'sometimes|nullable|string|max:255',
            'country_id' => 'sometimes|integer|exists:countries,id',
            'image' => 'nullable|image|max:3072',
            'remove_image' => 'nullable|boolean',
        ]);

        // prepare old path for potential cleanup after successful update
        $oldPath = null;
        if ($player->image_url) {
            $oldPath = str_replace('/storage/', '', $player->image_url);
        }

        DB::beginTransaction();
        try {
            if ($request->boolean('remove_image')) {
                $validated['image_url'] = null;
            }

            if ($request->hasFile('image')) {
                // For updates, store under player's directory
                $path = $request->file('image')->store("players/{$player->id}", 'public');
                $validated['image_url'] = Storage::url($path);
            }

            // Normalize role if provided as string
            if ($request->filled('role')) {
                $roleStr = strtolower($request->input('role'));
                $allowedRoles = ['batsman','bowler','all-rounder','wicket-keeper'];
                if (! in_array($roleStr, $allowedRoles)) {
                    if (isset($path)) {
                        Storage::disk('public')->delete($path);
                    }
                    DB::rollBack();
                    return back()->withErrors(['role' => 'Invalid role']);
                }
                $validated['role'] = $roleStr;
            }

            // If country_id provided but nationality not set, set nationality to country's name
            if (empty($validated['nationality']) && ! empty($validated['country_id'])) {
                $country = \App\Models\Country::find($validated['country_id']);
                if ($country) {
                    $validated['nationality'] = $country->name;
                }
            }

            $player->update($validated);

            DB::commit();

            // post-success cleanup: remove old file if replaced or removed
            if (isset($path) && $oldPath) {
                if (Storage::disk('public')->exists($oldPath)) {
                    Storage::disk('public')->delete($oldPath);
                }
            }

            if ($request->boolean('remove_image') && $oldPath) {
                if (Storage::disk('public')->exists($oldPath)) {
                    Storage::disk('public')->delete($oldPath);
                }
            }
        } catch (\Throwable $e) {
            if (isset($path)) {
                Storage::disk('public')->delete($path);
            }
            DB::rollBack();
            throw $e;
        }

        return to_route('admin.players.index')
            ->with('success', '✏️ Player updated successfully!');
    }

    /**
     * Remove the specified player.
     */
    public function destroy(Player $player)
    {
        if ($player->image_url) {
            $oldPath = str_replace('/storage/', '', $player->image_url);
            if (Storage::disk('public')->exists($oldPath)) {
                Storage::disk('public')->delete($oldPath);
            }
        }

        $player->delete();

        return to_route('admin.players.index')
            ->with('success', '🗑️ Player deleted successfully!');
    }
}
