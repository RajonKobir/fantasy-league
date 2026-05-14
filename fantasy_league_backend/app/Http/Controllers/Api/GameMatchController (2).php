<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GameMatch;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class GameMatchController extends Controller
{
    // GET /api/game-matches
    public function index(): JsonResponse
    {
        $matches = GameMatch::query()
            ->get(['id', 'team_a_id', 'team_b_id', 'tournament_id', 'start_time', 'status', 'venue_id']);

        $data = $matches->map(function ($match) {
            return [
                'id' => $match->id,
                'team_a_id' => $match->team_a_id,
                'team_b_id' => $match->team_b_id,
                'tournament_id' => $match->tournament_id,
                'start_time' => $match->start_time,
                'status' => $match->status,
                'venue_id' => $match->venue_id,
                'venue_name' => $match->venue ? $match->venue->name : null,
                'team_a_name' => $match->teamA ? $match->teamA->name : null,
                'team_b_name' => $match->teamB ? $match->teamB->name : null,
                'tournament_name' => $match->tournament ? $match->tournament->name : null,
            ];
        });

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    // GET /api/game-matches/{gameMatch}
    public function show(GameMatch $gameMatch): JsonResponse
    {
        $gameMatch->loadMissing(['teamA', 'teamB', 'players']);

        $data = $gameMatch->only(['id', 'team_a_id', 'team_b_id', 'tournament_id', 'start_time', 'status', 'venue_id']) + $gameMatch->toArray();

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }

    // GET /api/game-matches/{gameMatch}/players
    public function players(GameMatch $gameMatch): JsonResponse
    {
        $players = $gameMatch->players;

        return response()->json([
            'success' => true,
            'data' => $players,
        ]);
    }

    // GET /api/game-matches/{gameMatch}/squads
    public function squads(GameMatch $gameMatch): JsonResponse
    {
        $gameMatch->loadMissing(['teamA', 'teamB', 'players', 'venue']);

        $selections = DB::table('player_selections')
            ->where('game_match_id', $gameMatch->id)
            ->get();

        $teamAPlayers = $selections->where('team_id', $gameMatch->team_a_id)->pluck('player');
        $teamBPlayers = $selections->where('team_id', $gameMatch->team_b_id)->pluck('player');

        return response()->json([
            'success' => true,
            'data' => [
                'squad' => [
                    ['team' => ['id' => $gameMatch->team_a_id, 'name' => $gameMatch->teamA ? $gameMatch->teamA->name : null], 'players' => $teamAPlayers],
                    ['team' => ['id' => $gameMatch->team_b_id, 'name' => $gameMatch->teamB ? $gameMatch->teamB->name : null], 'players' => $teamBPlayers],
                ],
                'venue' => $gameMatch->venue ? ['id' => $gameMatch->venue->id, 'name' => $gameMatch->venue->name] : null,
            ],
        ]);
    }
}
