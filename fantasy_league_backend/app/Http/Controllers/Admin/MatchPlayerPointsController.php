<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\GameMatch;
use App\Models\MatchPlayerPoints;
use App\Models\Player;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class MatchPlayerPointsController extends Controller
{
    /**
     * Show all players and their points for a specific match
     */
    public function show(GameMatch $gameMatch)
    {
        $gameMatch->load(['teamA', 'teamB']);

        // Get all players from both teams (use assignedPlayers many-to-many)
        $teamAPlayers = $gameMatch->teamA ? $gameMatch->teamA->assignedPlayers()->get() : collect();
        $teamBPlayers = $gameMatch->teamB ? $gameMatch->teamB->assignedPlayers()->get() : collect();

        // Get existing points for this match
        $matchPoints = MatchPlayerPoints::where('game_match_id', $gameMatch->id)
            ->with('player')
            ->get()
            ->keyBy('player_id');

        // Format match data for Vue component
        $matchData = [
            'id' => $gameMatch->id,
            'team_a' => $gameMatch->teamA->name,
            'team_b' => $gameMatch->teamB->name,
            'start_time' => $gameMatch->start_time,
            'status' => $gameMatch->status,
            'tournament_id' => $gameMatch->tournament_id,
        ];

        return Inertia::render('Admin/GameMatches/MatchPoints', [
            'match' => $matchData,
            'teamAPlayers' => $teamAPlayers,
            'teamBPlayers' => $teamBPlayers,
            'matchPoints' => $matchPoints,
        ]);
    }

    /**
     * Update or create match player points
     */
    public function update(Request $request, GameMatch $gameMatch)
    {
        $validated = $request->validate([
            'points' => 'required|array',
            'points.*.player_id' => 'required|exists:players,id',
            'points.*.points' => 'required|integer|min:0|max:1000',
            'points.*.note' => 'nullable|string|max:500',
        ]);

        DB::beginTransaction();
        try {
            foreach ($validated['points'] as $pointData) {
                $playerId = $pointData['player_id'];
                $points = $pointData['points'];
                $note = $pointData['note'] ?? null;

                MatchPlayerPoints::updateOrCreate(
                    [
                        'game_match_id' => $gameMatch->id,
                        'player_id' => $playerId,
                    ],
                    [
                        'points' => $points,
                        'note' => $note,
                        'tournament_id' => $gameMatch->tournament_id,  // Include tournament_id
                    ]
                );
            }

            DB::commit();

            // Recalculate cached tournament team scores immediately for visibility in admin UI
            if ($gameMatch->tournament_id) {
                \App\Jobs\RecalculateTournamentScores::dispatchSync($gameMatch->tournament_id);
            }

            return back()->with('success', '✅ Match player points updated successfully!');
        } catch (\Throwable $e) {
            DB::rollBack();
            return back()->withErrors(['error' => 'Failed to update match points: ' . $e->getMessage()]);
        }
    }

    /**
     * Delete a match player point entry
     */
    public function destroy(GameMatch $gameMatch, Player $player)
    {
        try {
            MatchPlayerPoints::where('game_match_id', $gameMatch->id)
                ->where('player_id', $player->id)
                ->delete();

            // Recalculate cached tournament team scores
            if ($gameMatch->tournament_id) {
                \App\Jobs\RecalculateTournamentScores::dispatchSync($gameMatch->tournament_id);
            }

            return back()->with('success', '✅ Match player points deleted successfully!');
        } catch (\Throwable $e) {
            return back()->withErrors(['error' => 'Failed to delete match points: ' . $e->getMessage()]);
        }
    }
}
