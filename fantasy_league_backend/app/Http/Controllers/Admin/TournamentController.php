<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Player;
use App\Models\Team;
use App\Models\Tournament;
use App\Models\MatchPlayerPoints;
use App\Models\GameMatch;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class TournamentController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->only(['q', 'per_page']);
        $perPage = (int) ($request->query('per_page', 15));

        $tournaments = Tournament::when($request->query('q'), function ($query, $q) {
            $query->where('name', 'like', "%{$q}%");
        })->latest()->paginate($perPage)->withQueryString();

        return Inertia::render('Admin/Tournaments/Index', compact('tournaments', 'filters'));
    }

    public function create()
    {
        return Inertia::render('Admin/Tournaments/Create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'description' => 'nullable|string',
            'start_at' => 'nullable|date_format:Y-m-d\TH:i',
            'end_at' => 'nullable|date_format:Y-m-d\TH:i|after_or_equal:start_at',
            'entry_fee' => 'nullable|numeric|min:0',
            'required_players' => 'nullable|integer|min:1|max:100',
            'captain_multiplier' => 'nullable|numeric|min:1',
            'vice_captain_multiplier' => 'nullable|numeric|min:1',
            'status' => 'nullable|in:upcoming,running,active,stopped,canceled',
            'logo' => 'nullable|image|max:4096',
        ], [
            'entry_fee.required' => 'Entry fee is required.',
            'entry_fee.numeric' => 'Entry fee must be a valid number.',
            'entry_fee.min' => 'Entry fee must be at least 0.',
            'name.required' => 'Tournament name is required.',
            'required_players.required' => 'Number of required players is required.',
            'required_players.min' => 'Required players must be at least 1.',
            'required_players.max' => 'Required players cannot exceed 100.',
        ]);

        // set defaults
        $validated['entry_fee'] = $validated['entry_fee'] ?? 0;
        $validated['required_players'] = $validated['required_players'] ?? 11;
        $validated['captain_multiplier'] = $validated['captain_multiplier'] ?? 2.0;
        $validated['vice_captain_multiplier'] = $validated['vice_captain_multiplier'] ?? 1.5;

        DB::beginTransaction();
        try {
            $tournament = Tournament::create($validated);

            if ($request->hasFile('logo')) {
                $path = $request->file('logo')->store("tournaments/{$tournament->id}", 'public');
                $tournament->update(['logo_url' => Storage::url($path)]);
            }

            DB::commit();
        } catch (\Throwable $e) {
            if (isset($path)) {
                Storage::disk('public')->delete($path);
            }
            DB::rollBack();
            throw $e;
        }

        return to_route('admin.tournaments.index')->with('success', 'Tournament created');
    }

    public function edit(Tournament $tournament)
    {
        // Get all teams with assigned status for this tournament
        $tournamentTeamIds = $tournament->teams()->pluck('teams.id')->toArray();
        $teams = Team::all()->map(function($team) use ($tournamentTeamIds) {
            $team->is_assigned = in_array($team->id, $tournamentTeamIds);
            return $team;
        });

        return Inertia::render('Admin/Tournaments/Edit', compact('tournament', 'teams'));
    }

    public function update(Request $request, Tournament $tournament)
    {
        $validated = $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'start_at' => 'nullable|date_format:Y-m-d\TH:i',
            'end_at' => 'nullable|date_format:Y-m-d\TH:i|after_or_equal:start_at',
            'entry_fee' => 'sometimes|required|numeric|min:0',
            'required_players' => 'sometimes|required|integer|min:1|max:100',
            'captain_multiplier' => 'nullable|numeric|min:1',
            'vice_captain_multiplier' => 'nullable|numeric|min:1',
            'status' => 'nullable|in:upcoming,running,active,stopped,canceled',
            'logo' => 'nullable|image|max:4096',
            'remove_logo' => 'nullable|boolean',
        ], [
            'entry_fee.required' => 'Entry fee is required.',
            'entry_fee.numeric' => 'Entry fee must be a valid number.',
            'entry_fee.min' => 'Entry fee must be at least 0.',
            'name.required' => 'Tournament name is required.',
            'required_players.required' => 'Number of required players is required.',
            'required_players.min' => 'Required players must be at least 1.',
            'required_players.max' => 'Required players cannot exceed 100.',
        ]);

        // Ensure entry_fee is not null
        $validated['entry_fee'] = $validated['entry_fee'] ?? 0;

        $oldPath = null;
        if ($tournament->logo_url) {
            $oldPath = str_replace('/storage/', '', $tournament->logo_url);
        }

        DB::beginTransaction();
        try {
            if ($request->boolean('remove_logo')) {
                $validated['logo_url'] = null;
            }

            if ($request->hasFile('logo')) {
                $path = $request->file('logo')->store("tournaments/{$tournament->id}", 'public');
                $validated['logo_url'] = Storage::url($path);
            }

            $tournament->update($validated);

            DB::commit();

            // cleanup old file after successful update
            if (isset($path) && $oldPath) {
                if (Storage::disk('public')->exists($oldPath)) {
                    Storage::disk('public')->delete($oldPath);
                }
            }

            if ($request->boolean('remove_logo') && $oldPath) {
                if (Storage::disk('public')->exists($oldPath)) {
                    Storage::disk('public')->delete($oldPath);
                }
            }

            // Return JSON response for AJAX requests
            if ($request->wantsJson()) {
                return response()->json(['success' => true, 'tournament' => $tournament->fresh()]);
            }
        } catch (\Throwable $e) {
            if (isset($path)) {
                Storage::disk('public')->delete($path);
            }
            DB::rollBack();

            if ($request->wantsJson()) {
                return response()->json(['success' => false, 'message' => 'Failed to update tournament'], 500);
            }
            throw $e;
        }

        return to_route('admin.tournaments.index')->with('success', 'Tournament updated');
    }

    public function destroy(Tournament $tournament)
    {
        if ($tournament->logo_url) {
            $oldPath = str_replace('/storage/', '', $tournament->logo_url);
            if (Storage::disk('public')->exists($oldPath)) {
                Storage::disk('public')->delete($oldPath);
            }
        }
        $tournament->delete();

        return to_route('admin.tournaments.index')->with('success', 'Tournament deleted');
    }

    // assign team to tournament
    public function assignTeam(Request $request, Tournament $tournament)
    {
        $request->validate(['team_id' => 'required|exists:teams,id']);
        $team = Team::findOrFail($request->team_id);

        DB::beginTransaction();
        try {
            // Attach team to tournament (pivot table)
            $tournament->teams()->attach($team->id);

            // Tournament-level player records were removed. Historically we created per-tournament player rows here;
            // points are now stored per-match in `match_player_points` and aggregated when recalculating team scores.
            // No action required here.

            DB::commit();

            // Compute number of players associated with the team for the success message
            $playerIds = \App\Models\PlayerSelection::where('team_id', $team->id)
                ->pluck('player_id')
                ->unique()
                ->toArray();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }

        return back()->with('success', 'Team assigned with ' . count($playerIds) . ' players');
    }

    public function removeTeam(Tournament $tournament, Team $team)
    {
        DB::beginTransaction();
        try {
            // Get all players associated with this team
            $playerIds = \App\Models\PlayerSelection::where('team_id', $team->id)
                ->pluck('player_id')
                ->unique()
                ->toArray();

            // Tournament-level player records were removed; nothing to delete here.

            // Detach team from tournament (pivot table)
            $tournament->teams()->detach($team->id);

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }

        return back()->with('success', 'Team removed');
    }

    // bulk update player points for a tournament
    public function updatePlayerPoints(Request $request, Tournament $tournament)
    {
        $request->validate(['points' => 'required|array']);
        $points = $request->points; // associative array player_id => points

        // Create or find a synthetic "tournament summary" game match to store tournament-level points
        $summaryMatch = GameMatch::firstOrCreate(
            ['tournament_id' => $tournament->id, 'team_a_id' => null, 'team_b_id' => null],
            ['start_time' => now()]
        );

        foreach ($points as $playerId => $value) {
            $player = Player::find($playerId);
            if (! $player) {
                continue;
            }

            // store as a match-specific point on the synthetic match (keeps storage in `match_player_points`)
            MatchPlayerPoints::updateOrCreate(
                ['game_match_id' => $summaryMatch->id, 'player_id' => $player->id],
                ['points' => intval($value), 'tournament_id' => $tournament->id, 'note' => 'Tournament-level admin points']
            );
        }

        // Recalculate cached team scores for this tournament (synchronous to make immediate results visible to admin)
        \App\Jobs\RecalculateTournamentScores::dispatchSync($tournament->id);

        return back()->with('success', 'Points updated');
    }
}
