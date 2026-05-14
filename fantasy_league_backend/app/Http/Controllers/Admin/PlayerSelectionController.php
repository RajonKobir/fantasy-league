<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Player;
use App\Models\PlayerSelection;
use App\Models\Team;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class PlayerSelectionController extends Controller
{
    public function index()
    {
        $selections = PlayerSelection::with(['player', 'team'])->orderBy('id', 'desc')->get();

        return Inertia::render('Admin/PlayerSelections/Index', compact('selections'));
    }

    // Edit selections for a specific team
    public function editTeam(\App\Models\Team $team)
    {
        $players = Player::orderBy('name')->get();
        $selections = $team->selections()->with('player')->get();

        return Inertia::render('Admin/PlayerSelections/TeamEdit', compact('team', 'players', 'selections'));
    }

    public function create()
    {
        $teams = Team::orderBy('name')->get();
        $players = Player::orderBy('name')->get();

        return Inertia::render('Admin/PlayerSelections/Create', compact('teams', 'players'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'team_id' => 'required|exists:teams,id',
            'player_id' => 'required|exists:players,id',
            'captain' => 'boolean',
            'vice_captain' => 'boolean',
        ]);

        // Prevent making the same player both captain and vice-captain
        if (! empty($validated['captain']) && ! empty($validated['vice_captain'])) {
            return back()->with('error', 'A player cannot be both Captain and Vice-Captain.');
        }

        // Ensure only 1 captain and 1 vice-captain per team
        if (! empty($validated['captain']) && PlayerSelection::where('team_id', $validated['team_id'])->where('captain', true)->exists()) {
            return back()->with('error', 'Team already has a Captain.');
        }
        if (! empty($validated['vice_captain']) && PlayerSelection::where('team_id', $validated['team_id'])->where('vice_captain', true)->exists()) {
            return back()->with('error', 'Team already has a Vice-Captain.');
        }

        // Don't allow more than 11 players
        $team = Team::find($validated['team_id']);
        if ($team && $team->selections()->count() >= 11) {
            return back()->with('error', 'Team already has 11 players selected. Remove a player before adding another.');
        }

        PlayerSelection::create($validated);

        return redirect()
            ->route('admin.player-selections.index')
            ->with('success', 'Player selection added successfully!');
    }

    public function edit(PlayerSelection $playerSelection)
    {
        $teams = Team::orderBy('name')->get();
        $players = Player::orderBy('name')->get();

        return Inertia::render('Admin/PlayerSelections/Edit', compact('playerSelection', 'teams', 'players'));
    }

    public function update(Request $request, PlayerSelection $playerSelection)
    {
        $validated = $request->validate([
            'team_id' => 'required|exists:teams,id',
            'player_id' => 'required|exists:players,id',
            'captain' => 'boolean',
            'vice_captain' => 'boolean',
        ]);

        // Ensure only 1 captain and 1 vice-captain per team
        if ($validated['captain'] && PlayerSelection::where('team_id', $validated['team_id'])->where('captain', true)->where('id', '!=', $playerSelection->id)->exists()) {
            return back()->with('error', 'Team already has a Captain.');
        }
        if ($validated['vice_captain'] && PlayerSelection::where('team_id', $validated['team_id'])->where('vice_captain', true)->where('id', '!=', $playerSelection->id)->exists()) {
            return back()->with('error', 'Team already has a Vice-Captain.');
        }

        $playerSelection->update($validated);

        return redirect()
            ->route('admin.player-selections.index')
            ->with('success', 'Player selection updated successfully!');
    }

    // Update all selections for a team in bulk (replace existing selections)
    public function updateTeam(Request $request, \App\Models\Team $team)
    {
        $validated = $request->validate([
            'player_ids' => 'required|array|min:1|distinct',
            'player_ids.*' => 'exists:players,id',
            'captain_id' => 'required|exists:players,id',
            'vice_captain_id' => 'required|exists:players,id',
        ]);

        $playerIds = array_map('intval', $validated['player_ids']);
        $captainId = (int) $validated['captain_id'];
        $viceCaptainId = (int) $validated['vice_captain_id'];

        if (! in_array($captainId, $playerIds, true) || ! in_array($viceCaptainId, $playerIds, true)) {
            return redirect()->back()->with('error', 'Captain and Vice-Captain must be among the selected players.');
        }
        if ($captainId === $viceCaptainId) {
            return redirect()->back()->with('error', 'Captain and Vice-Captain must be different players.');
        }

        // Replace selections atomically
        DB::transaction(function () use ($team, $playerIds, $captainId, $viceCaptainId) {
            $team->selections()->delete();
            foreach ($playerIds as $pid) {
                PlayerSelection::create([
                    'team_id' => $team->id,
                    'player_id' => $pid,
                    'captain' => $pid == $captainId,
                    'vice_captain' => $pid == $viceCaptainId,
                ]);
            }
        });

        // If the team belongs to a tournament, recalculate cached team scores synchronously
        if ($team->tournament_id) {
            \App\Jobs\RecalculateTournamentScores::dispatchSync($team->tournament_id);
        }

        return redirect()->route('admin.teams.index')->with('success', 'Team selections updated successfully!');
    }

    public function destroy(PlayerSelection $playerSelection)
    {
        $playerSelection->delete();

        return redirect()
            ->route('admin.player-selections.index')
            ->with('success', 'Player selection deleted successfully!');
    }
}
