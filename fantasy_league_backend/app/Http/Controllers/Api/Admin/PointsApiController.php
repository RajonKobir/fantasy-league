<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\MatchPlayerPoints;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Artisan;

class PointsApiController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = MatchPlayerPoints::with(['player', 'gameMatch', 'tournament']);

        // allow filtering by tournament or game_match
        if ($request->has('tournament_id')) {
            $query->where('tournament_id', $request->input('tournament_id'));
        }
        if ($request->has('game_match_id')) {
            $query->where('game_match_id', $request->input('game_match_id'));
        }

        return response()->json($query->paginate(25));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'game_match_id' => 'required|exists:game_matches,id',
            'tournament_id' => 'nullable|exists:tournaments,id',
            'player_id' => 'required|exists:players,id',
            'points' => 'required|integer|min:0',
            'note' => 'nullable|string',
        ]);

        // Create or update a match-specific points record
        $point = MatchPlayerPoints::updateOrCreate([
            'game_match_id' => $data['game_match_id'],
            'player_id' => $data['player_id'],
        ], [
            'points' => $data['points'],
            'note' => $data['note'] ?? null,
            'tournament_id' => $data['tournament_id'] ?? null,
        ]);

        return response()->json($point, 201);
    }

    public function update(Request $request, MatchPlayerPoints $point): JsonResponse
    {
        $data = $request->validate([
            'points' => 'required|integer|min:0',
            'note' => 'nullable|string',
        ]);

        $point->update($data);

        return response()->json($point);
    }

    public function destroy(MatchPlayerPoints $point): JsonResponse
    {
        $point->delete();

        return response()->json(null, 204);
    }

    /**
     * Manually trigger fantasy team total points update cron job
     */
    public function triggerCronJob(Request $request): JsonResponse
    {
        try {
            $tournamentId = $request->input('tournament_id');

            // Build artisan command with options
            $command = 'fantasy-teams:update-total-points';
            if ($tournamentId) {
                $command .= ' --tournament_id=' . $tournamentId;
            }

            // Execute the command synchronously
            Artisan::call($command);

            $output = Artisan::output();

            return response()->json([
                'success' => true,
                'message' => '✅ Fantasy team points calculated successfully!',
                'output' => $output,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => '❌ Error running cron job: ' . $e->getMessage(),
                'error' => $e->getMessage(),
            ], 500);
        }
    }
}
