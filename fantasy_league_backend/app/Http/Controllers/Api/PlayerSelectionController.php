<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Player;
use App\Models\PlayerSelection;
use App\Models\Team;
use Illuminate\Http\Request;

class PlayerSelectionController extends Controller
{
    /**
     * List all player selections for a team.
     */
    public function index(Team $team)
    {
        $selections = $team->playerSelections()->with('player')->get();

        return response()->json([
            'team' => $team->only(['id', 'name']),
            'selections' => $selections,
        ]);
    }

    /**
     * Add a player to a team.
     */
    public function store(Request $request, Team $team)
    {
        $request->validate([
            'player_id' => 'required|exists:players,id',
            'captain' => 'boolean',
            'vice_captain' => 'boolean',
        ]);

        // Prevent adding the same player twice
        if ($team->playerSelections()->where('player_id', $request->player_id)->exists()) {
            return response()->json(['message' => 'Player already selected'], 422);
        }

        $selection = $team->playerSelections()->create([
            'player_id' => $request->player_id,
            'captain' => $request->boolean('captain', false),
            'vice_captain' => $request->boolean('vice_captain', false),
        ]);

        return response()->json($selection, 201);
    }

    /**
     * Update a selection (captain/vice-captain).
     */
    public function update(Request $request, Team $team, PlayerSelection $selection)
    {
        $request->validate([
            'captain' => 'boolean',
            'vice_captain' => 'boolean',
        ]);

        // Ensure the selection belongs to the team
        if ($selection->team_id !== $team->id) {
            return response()->json(['message' => 'Invalid selection for this team'], 403);
        }

        $selection->update([
            'captain' => $request->boolean('captain', $selection->captain),
            'vice_captain' => $request->boolean('vice_captain', $selection->vice_captain),
        ]);

        return response()->json($selection);
    }

    /**
     * Remove a player from the team.
     */
    public function destroy(Team $team, PlayerSelection $selection)
    {
        // Ensure the selection belongs to the team
        if ($selection->team_id !== $team->id) {
            return response()->json(['message' => 'Invalid selection for this team'], 403);
        }

        $selection->delete();

        return response()->json(['message' => 'Player removed from team']);
    }
}
