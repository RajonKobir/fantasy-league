<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FantasyTeam;
use App\Models\MatchPlayerPoints;
use App\Models\Tournament;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Auth;

class CronController extends Controller
{
    /**
     * Show the stream status page (opens in new tab)
     */
    public function showStreamPage(Request $request)
    {
        // Only allow authenticated admins to open the stream page
        if (!Auth::check() || !Auth::user()->is_admin) {
            abort(403);
        }

        $tournamentId = $request->query('tournament_id');
        return response()->view('admin.cron_stream', ['tournament_id' => $tournamentId]);
    }

    /**
     * Stream progress updates as Server-Sent Events (SSE)
     *
     * Algorithm:
     * 1. Check if any live tournaments exist (status = 'running' or 'active')
     * 2. For each live tournament (or specified tournament):
     *    a. Get all match_player_points for that tournament
     *    b. Calculate each player's total points
     *    c. For each fantasy team in that tournament:
     *       - Sum base points from all players
     *       - Apply captain multiplier: add (captain_points * (multiplier - 1))
     *       - Apply vice-captain multiplier: add (vc_points * (multiplier - 1))
     *       - Update fantasy_team.total_points
     * 3. Move to next tournament (non-breaking, error-tolerant)
     *
     * Uses each tournament's own captain_multiplier and vice_captain_multiplier values.
     * Can be run manually (with visual progress) or as a server cron job (background).
     */
    public function streamUpdateFantasyTeamPoints(Request $request)
    {
        // Only authenticated admins may run the long-running update
        if (!Auth::check() || !Auth::user()->is_admin) {
            abort(403);
        }

        $filterTournamentId = $request->query('tournament_id');
        $batchSize = (int) $request->query('batch', 1000);

        $headers = [
            'Content-Type' => 'text/event-stream',
            'Cache-Control' => 'no-cache, no-transform',
            'X-Accel-Buffering' => 'no',
        ];

        return response()->stream(function () use ($filterTournamentId, $batchSize) {
            $totalUpdated = 0;
            $totalErrors = 0;

            try {
                // Step 1: Check if any live tournaments exist
                $tournamentsQuery = Tournament::whereIn('status', ['running', 'active']);

                if ($filterTournamentId) {
                    $tournamentsQuery->where('id', $filterTournamentId);
                }

                $liveTournaments = $tournamentsQuery->get();

                if ($liveTournaments->isEmpty()) {
                    echo "data: " . json_encode(['status' => 'info', 'message' => 'No live tournaments found']) . "\n\n";
                    ob_flush(); flush();
                    echo "data: " . json_encode(['status' => 'done', 'updated' => 0, 'errors' => 0, 'total' => 0]) . "\n\n";
                    ob_flush(); flush();
                    return;
                }

                echo "data: " . json_encode(['status' => 'info', 'message' => "Found {$liveTournaments->count()} live tournament(s)"]) . "\n\n";
                ob_flush(); flush();

                // Step 2: Process each live tournament
                foreach ($liveTournaments as $tournament) {
                    try {
                        echo "data: " . json_encode(['status' => 'tournament_start', 'tournament_id' => $tournament->id, 'tournament_name' => $tournament->name]) . "\n\n";
                        ob_flush(); flush();

                        $captainMultiplier = (float) ($tournament->captain_multiplier ?? 2.0);
                        $viceCaptainMultiplier = (float) ($tournament->vice_captain_multiplier ?? 1.5);

                        // Step 2a: Load all match_player_points for this tournament
                        $playerPointsMap = MatchPlayerPoints::where('tournament_id', $tournament->id)
                            ->selectRaw('player_id, SUM(points) as total_points')
                            ->groupBy('player_id')
                            ->pluck('total_points', 'player_id')
                            ->toArray();

                        echo "data: " . json_encode(['status' => 'info', 'message' => "Loaded points for {$tournament->id} players"]) . "\n\n";
                        ob_flush(); flush();

                        // Step 2c: Get all fantasy teams for this tournament and update in batches
                        $fantasyTeamsQuery = FantasyTeam::where('tournament_id', $tournament->id);
                        $teamsCount = $fantasyTeamsQuery->count();

                        $fantasyTeamsQuery->chunk($batchSize, function ($teams) use ($playerPointsMap, $captainMultiplier, $viceCaptainMultiplier, $tournament, &$totalUpdated, &$totalErrors) {
                            foreach ($teams as $team) {
                                try {
                                    // Calculate base points from all selected players
                                    $totalPoints = 0;
                                    $playerIds = $team->player_ids ?? [];

                                    foreach ($playerIds as $playerId) {
                                        $totalPoints += (int) ($playerPointsMap[$playerId] ?? 0);
                                    }

                                    // Apply captain multiplier (bonus = base * (multiplier - 1))
                                    if ($team->captain_id) {
                                        $captainBasePoints = (int) ($playerPointsMap[$team->captain_id] ?? 0);
                                        $totalPoints += (int) ($captainBasePoints * ($captainMultiplier - 1));
                                    }

                                    // Apply vice-captain multiplier (bonus = base * (multiplier - 1))
                                    if ($team->vice_captain_id) {
                                        $vcBasePoints = (int) ($playerPointsMap[$team->vice_captain_id] ?? 0);
                                        $totalPoints += (int) ($vcBasePoints * ($viceCaptainMultiplier - 1));
                                    }

                                    // Update only if changed
                                    if ((int) $team->total_points !== (int) $totalPoints) {
                                        $team->update(['total_points' => (int) $totalPoints]);
                                        $totalUpdated++;
                                    }
                                } catch (\Exception $e) {
                                    $totalErrors++;
                                    echo "data: " . json_encode(['status' => 'error', 'message' => "Error updating fantasy team {$team->id}: {$e->getMessage()}"]) . "\n\n";
                                    ob_flush(); flush();
                                }
                            }
                        });

                        echo "data: " . json_encode(['status' => 'tournament_done', 'tournament_id' => $tournament->id, 'updated' => $totalUpdated]) . "\n\n";
                        ob_flush(); flush();

                    } catch (\Exception $e) {
                        $totalErrors++;
                        echo "data: " . json_encode(['status' => 'error', 'message' => "Error processing tournament {$tournament->id}: {$e->getMessage()}"]) . "\n\n";
                        ob_flush(); flush();
                    }
                }

                // Final summary
                echo "data: " . json_encode(['status' => 'done', 'updated' => $totalUpdated, 'errors' => $totalErrors, 'total' => $totalUpdated + $totalErrors]) . "\n\n";
                ob_flush(); flush();

            } catch (\Exception $e) {
                echo "data: " . json_encode(['status' => 'error', 'message' => "Critical error: {$e->getMessage()}"]) . "\n\n";
                ob_flush(); flush();
                echo "data: " . json_encode(['status' => 'done', 'updated' => 0, 'errors' => 1, 'total' => 1]) . "\n\n";
                ob_flush(); flush();
            }
        }, 200, $headers);
    }
}
