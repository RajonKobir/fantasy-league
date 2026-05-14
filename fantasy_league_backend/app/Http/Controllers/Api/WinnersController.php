<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Winner;

class WinnersController extends Controller
{
    /**
     * Get paginated winners for a specific tournament (only active winners)
     */
    public function getTournamentWinners($tournamentId)
    {
        $perPage = max(10, (int) request()->query('per_page', 25));
        $page = (int) request()->query('page', 1);

        $winner = Winner::where('tournament_id', $tournamentId)
            ->where('status', 'active')
            ->first();

        if (!$winner) {
            return response()->json([
                'success' => true,
                'data' => [],
                'current_page' => $page,
                'last_page' => 1,
                'total' => 0,
            ]);
        }

        // Format data to match the expected structure with rank
        $allData = [];
        foreach ($winner->fantasy_teams_ids as $index => $teamId) {
            $allData[] = [
                'rank' => $index + 1,
                'fantasy_team_name' => $winner->fantasy_teams_names[$index] ?? '',
                'user_name' => $winner->user_names[$index] ?? '',
                'total_points' => $winner->total_points[$index] ?? 0,
            ];
        }

        // Paginate manually
        $total = count($allData);
        $lastPage = ceil($total / $perPage);
        $offset = ($page - 1) * $perPage;
        $paginatedData = array_slice($allData, $offset, $perPage);

        return response()->json([
            'success' => true,
            'data' => $paginatedData,
            'current_page' => $page,
            'last_page' => $lastPage,
            'total' => $total,
        ]);
    }
}
