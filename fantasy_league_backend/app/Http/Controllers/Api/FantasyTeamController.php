<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\FantasyTeam;
use App\Models\Player;
use App\Models\GameMatch;
use App\Models\Tournament;
use App\Models\Transaction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class FantasyTeamController extends Controller
{
    // GET /api/fantasy-teams
    public function index(Request $request): JsonResponse
    {
        $perPage = max(10, (int) $request->query('per_page', 25));

        $teams = FantasyTeam::where('user_id', $request->user()->id)
            ->with([
                'tournament:id,name,status,refund_percentage,entry_fee',
                'captain:id,name,image_url',
                'viceCaptain:id,name,image_url',
                'cancelRequest' => function ($query) {
                    $query->select('id', 'fantasy_team_id', 'status', 'refund_percentage_at_request', 'refund_amount', 'approved_at');
                }
            ])
            ->when($request->query('q'), function ($query, $q) {
                $query->where('name', 'like', "%{$q}%");
            })
            ->when($request->query('tournament_id'), function ($query, $id) {
                $query->where('tournament_id', $id);
            })
            ->paginate($perPage, ['id', 'tournament_id', 'user_id', 'name', 'captain_id', 'vice_captain_id', 'total_points', 'status', 'player_ids', 'created_at']);

        // Add players for each team (fetch by player_ids)
        foreach ($teams->items() as $team) {
            if (!empty($team->player_ids) && is_array($team->player_ids)) {
                $players = Player::whereIn('id', $team->player_ids)
                    ->get(['id', 'name', 'role', 'image_url']);
                $team->players = $players;
            } else {
                $team->players = [];
            }
        }

        return response()->json([
            'success' => true,
            'data' => $teams,
        ]);
    }

    // GET /api/fantasy-teams/{fantasy_team}
    /**
     * @return JsonResponse
     */
    public function show(FantasyTeam $fantasyTeam): JsonResponse
    {
        // Verify user owns this fantasy team
        if ((int) $fantasyTeam->user_id !== (int) Auth::id()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to view this team'
            ], 403);
        }

        $fantasyTeam->load([
            'tournament:id,name,status,refund_percentage,entry_fee',
            'user:id,name',
            'captain:id,name,image_url',
            'viceCaptain:id,name,image_url',
        ]);

        $players = Player::whereIn('id', $fantasyTeam->player_ids ?? [])
            ->get(['id', 'name', 'role', 'image_url']);

        $data = $fantasyTeam->toArray();
        $data['players'] = $players;

        // Ensure total_points is always included in response
        $data['total_points'] = (int) $fantasyTeam->total_points;

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    // POST /api/fantasy-teams
    public function store(Request $request): JsonResponse
    {
        // First validate basic structure (capture validation failures so we can log them clearly)
        try {
            $request->validate([
                'tournament_id' => 'nullable|exists:tournaments,id',
                'game_match_id' => 'nullable|exists:game_matches,id', // Legacy: accepts a game match id
                'name' => 'required|string|max:255',
                'player_ids' => 'required|array|distinct',
                'player_ids.*' => 'required|exists:players,id',
                'captain_id' => 'required|exists:players,id',
                'vice_captain_id' => 'required|exists:players,id',
            ]);
        } catch (\Illuminate\Validation\ValidationException $ve) {

            return response()->json([
                'success' => false,
                'message' => 'Validation failed',
                'errors' => $ve->errors(),
            ], 422);
        }

        // Determine which tournament ID to use (new or legacy game_match_id -> tournament mapping)
        $tournamentId = $request->tournament_id ?? null;
        if (!$tournamentId && $request->filled('game_match_id')) {
            $gameMatch = GameMatch::find($request->game_match_id);
            if (!$gameMatch) {
                return response()->json([
                    'success' => false,
                    'message' => 'Invalid game match id'
                ], 422);
            }
            // If the match has a linked tournament, use it. Otherwise allow match-only creation and fall back
            // to default tournament rules (handled later).
            if ($gameMatch->tournament_id) {
                $tournamentId = $gameMatch->tournament_id;
            }
        }

        if (!$tournamentId && !$request->filled('game_match_id')) {
            return response()->json([
                'success' => false,
                'message' => 'Tournament ID is required'
            ], 422);
        }

        $playerIds = array_map('intval', (array) $request->player_ids);
        $captainId = intval($request->captain_id);
        $viceCaptainId = intval($request->vice_captain_id);

        // Get tournament and validate required player count
        $tournament = $tournamentId ? Tournament::find($tournamentId) : null;
        // If no tournament was provided but a game_match_id exists, allow creation using default tournament rules (legacy behavior)
        if (!$tournament && $request->filled('game_match_id')) {
            // Create a minimal tournament for this match so fantasy_teams can reference it.
            $tournament = Tournament::create([
                'name' => 'Match ' . $request->game_match_id . ' Tournament',
                'required_players' => 11,
                'entry_fee' => 0,
                'start_at' => now(),
                'end_at' => now()->addDay(),
            ]);
            // Ensure we set the tournament id to be used when creating the fantasy team
            $tournamentId = $tournament->id;

            // Optionally link the game match back to this tournament if it exists and isn't already linked
            $gameMatch = GameMatch::find($request->game_match_id);
            if ($gameMatch && !$gameMatch->tournament_id) {
                $gameMatch->tournament_id = $tournament->id;
                $gameMatch->save();
            }
        }

        if (!$tournament) {
            return response()->json([
                'success' => false,
                'message' => 'Tournament not found'
            ], 404);
        }

        if (count($playerIds) !== $tournament->required_players) {
            return response()->json([
                'success' => false,
                'message' => "This tournament requires exactly {$tournament->required_players} players. You provided " . count($playerIds)
            ], 422);
        }

        // Validation: captain & vice must be in player_ids and be different
        if (!in_array($captainId, $playerIds, true) || !in_array($viceCaptainId, $playerIds, true)) {
            return response()->json([
                'success' => false,
                'message' => 'Captain and Vice-Captain must be selected from team players'
            ], 422);
        }

        if ($captainId === $viceCaptainId) {
            return response()->json([
                'success' => false,
                'message' => 'Captain and Vice-Captain must be different players'
            ], 422);
        }

        // Wrap DB work in try/catch to return friendly error messages on failure
        try {
            $fantasyTeam = DB::transaction(function () use ($request, $playerIds, $captainId, $viceCaptainId, $tournament, $tournamentId) {
                // Charge entry fee if tournament requires it
                if ($tournament->entry_fee > 0) {
                    $user = $request->user();
                    if (($user->wallet_balance ?? 0) < $tournament->entry_fee) {
                        return response()->json([
                            'success' => false,
                            'message' => 'Insufficient wallet balance'
                        ], 402);
                    }

                    // Deduct entry fee
                    $user->wallet_balance = ($user->wallet_balance ?? 0) - $tournament->entry_fee;
                    $user->save();

                    // Record transaction
                    Transaction::create([
                        'user_id' => $user->id,
                        'transaction_id' => 'TRX' . strtoupper(Str::random(8)),
                        'type' => 'DEBIT',
                        'remark' => 'Entry fee for tournament ' . ($tournament->name ?? $tournament->id),
                        'amount' => $tournament->entry_fee,
                        'team_name' => $request->name,
                        'status_process' => '1',
                        'status_credit' => '1',
                        'time' => now(),
                    ]);
                }

                // Backwards-compatible behavior: if called via legacy /api/teams, create a normal Team and player_selections
                if ($request->getPathInfo() === '/api/teams' || $request->is('api/teams')) {
                    $team = \App\Models\Team::create([
                        'name' => $request->name,
                        'user_id' => $request->user()->id,
                    ]);

                    foreach ($playerIds as $pid) {
                        DB::table('player_selections')->insert([
                            'team_id' => $team->id,
                            'player_id' => $pid,
                            'captain' => ($pid === $captainId) ? 1 : 0,
                            'vice_captain' => ($pid === $viceCaptainId) ? 1 : 0,
                            'created_at' => now(),
                            'updated_at' => now(),
                        ]);
                    }

                    return $team->fresh();
                }

                // Create fantasy team for newer endpoints
                $fantasyTeam = FantasyTeam::create([
                    'tournament_id' => $tournamentId,
                    'user_id' => $request->user()->id,
                    'name' => $request->name,
                    'player_ids' => $playerIds,
                    'captain_id' => $captainId,
                    'vice_captain_id' => $viceCaptainId,
                    'total_points' => 0,
                    'status' => 'pending',
                ]);

                return $fantasyTeam->load(['tournament:id,name', 'captain:id,name', 'viceCaptain:id,name']);
            });
        } catch (\Illuminate\Database\QueryException $qe) {
            // Database error while creating fantasy team

            return response()->json([
                'success' => false,
                'message' => 'Failed to create fantasy team. Please try again or contact support.'
            ], 500);
        } catch (\Exception $ex) {
            // Unexpected error while creating fantasy team
            return response()->json([
                'success' => false,
                'message' => 'Failed to create fantasy team. Please try again.'
            ], 500);
        }

        // If entry fee was not sufficient, return the error response
        if ($fantasyTeam instanceof \Illuminate\Http\JsonResponse) {
            return $fantasyTeam;
        }

        return response()->json([
            'success' => true,
            'message' => 'Fantasy team created successfully',
            'data' => $fantasyTeam,
        ], 201);
    }

    // PUT /api/fantasy-teams/{fantasy_team}
    /**
     * @return JsonResponse
     */
    public function update(Request $request, FantasyTeam $fantasyTeam): JsonResponse
    {
        // Verify user owns this fantasy team
        if ((int) $fantasyTeam->user_id !== (int) Auth::id()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to update this team'
            ], 403);
        }

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'player_ids' => 'sometimes|required|array|distinct',
            'player_ids.*' => 'required|exists:players,id',
            'captain_id' => 'sometimes|required|exists:players,id',
            'vice_captain_id' => 'sometimes|required|exists:players,id',
        ]);

        $playerIds = array_map('intval', (array) $request->get('player_ids', $fantasyTeam->player_ids));
        $captainId = intval($request->get('captain_id', $fantasyTeam->captain_id));
        $viceCaptainId = intval($request->get('vice_captain_id', $fantasyTeam->vice_captain_id));

        // Get tournament for validation
        $tournament = $fantasyTeam->tournament;

        // Validate captain and vice-captain are different (independent of player_ids changes)
        if ($request->filled('captain_id') || $request->filled('vice_captain_id')) {
            if ($captainId === $viceCaptainId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Captain and Vice-Captain must be different players'
                ], 422);
            }
        }

        // Validation if player_ids were provided
        if ($request->filled('player_ids')) {
            if (count($playerIds) !== $tournament->required_players) {
                return response()->json([
                    'success' => false,
                    'message' => "This tournament requires exactly {$tournament->required_players} players. You provided " . count($playerIds)
                ], 422);
            }
            if (!in_array($captainId, $playerIds, true) || !in_array($viceCaptainId, $playerIds, true)) {
                return response()->json([
                    'success' => false,
                    'message' => 'Captain and Vice-Captain must be selected from team players'
                ], 422);
            }

            if ($captainId === $viceCaptainId) {
                return response()->json([
                    'success' => false,
                    'message' => 'Captain and Vice-Captain must be different players'
                ], 422);
            }
        }

        $fantasyTeam->update(array_filter([
            'name' => $request->get('name'),
            'player_ids' => $request->filled('player_ids') ? $playerIds : null,
            'captain_id' => $request->filled('captain_id') ? $captainId : null,
            'vice_captain_id' => $request->filled('vice_captain_id') ? $viceCaptainId : null,
        ], function ($value) {
            return $value !== null;
        }));

        return response()->json([
            'success' => true,
            'message' => 'Fantasy team updated successfully',
            'data' => $fantasyTeam->load(['tournament:id,name', 'captain:id,name', 'viceCaptain:id,name']),
        ]);
    }

    // DELETE /api/fantasy-teams/{fantasy_team}
    /**
     * @return JsonResponse
     */
    public function destroy(FantasyTeam $fantasyTeam): JsonResponse
    {
        // Verify user owns this fantasy team
        if ((int) $fantasyTeam->user_id !== (int) Auth::id()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized to delete this team'
            ], 403);
        }

        $fantasyTeam->delete();

        return response()->json([
            'success' => true,
            'message' => 'Fantasy team deleted successfully'
        ]);
    }

    // GET /api/fantasy-teams/{fantasy_team}/points (legacy endpoint)
    public function myTeamPoints(Request $request): JsonResponse
    {
        $user = $request->user();

        $query = FantasyTeam::where('user_id', $user->id);
        if ($request->has('tournament_id')) {
            $query->where('tournament_id', $request->input('tournament_id'));
        }

        $team = $query->first();

        if (!$team) {
            return response()->json(['success' => false, 'message' => 'Fantasy team not found'], 404);
        }

        $playerIds = $team->player_ids ?? [];

        // Load player points for this tournament
        $points = Player::with(['matchPoints' => function ($q) use ($team) {
            $q->where('tournament_id', $team->tournament_id);
        }])
            ->whereIn('id', $playerIds)
            ->get();

        return response()->json([
            'team' => $team,
            'points' => $points,
        ]);
    }
}
