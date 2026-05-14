<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Tournament;
use App\Models\FantasyTeam;
use App\Models\Winner;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class WinnersController extends Controller
{
    /**
     * Display all winners with CRUD functionality
     */
    public function index(Request $request)
    {
        $filters = $request->only(['q', 'per_page', 'status']);
        $perPage = (int) ($request->query('per_page', 15));

        $winners = Winner::with('tournament')
            ->when($request->query('q'), function ($query, $q) {
                $query->where(function ($q2) use ($q) {
                    $q2->where('tournament_name', 'like', "%{$q}%")
                        ->orWhereJsonContains('user_names', $q);
                });
            })
            ->when($request->query('status'), function ($query, $status) {
                $query->where('status', $status);
            })
            ->latest()
            ->paginate($perPage)
            ->withQueryString();

        return Inertia::render('Admin/Winners/Index', compact('winners', 'filters'));
    }

    /**
     * Show winners management page (fetch and save)
     */
    public function manage()
    {
        $tournaments = Tournament::all();
        $winners = Winner::with('tournament')->get();

        return Inertia::render('Admin/Winners/Manage', [
            'tournaments' => $tournaments,
            'winners' => $winners,
        ]);
    }

    /**
     * Get top N users by fantasy team points for a tournament
     */
    public function getTopUsers(Request $request)
    {
        $request->validate([
            'tournament_id' => 'required|exists:tournaments,id',
            'limit' => 'required|integer|min:1|max:100',
        ]);

        $tournamentId = $request->input('tournament_id');
        $limit = $request->input('limit');

        // Get top fantasy teams by total_points
        $topTeams = FantasyTeam::where('tournament_id', $tournamentId)
            ->orderByDesc('total_points')
            ->limit($limit)
            ->with(['user', 'tournament'])
            ->get();

        return response()->json([
            'success' => true,
            'data' => $topTeams->map(function ($team, $index) {
                return [
                    'rank' => $index + 1,
                    'fantasy_team_id' => $team->id,
                    'fantasy_team_name' => $team->name,
                    'user_id' => $team->user_id,
                    'user_name' => $team->user->name,
                    'user_email' => $team->user->email,
                    'total_points' => $team->total_points,
                    'tournament_id' => $team->tournament_id,
                ];
            }),
        ]);
    }

    /**
     * Save winners to the winners table (one row per tournament)
     */
    public function saveWinners(Request $request)
    {
        $request->validate([
            'tournament_id' => 'required|exists:tournaments,id',
            'winners' => 'required|array|min:1',
            'winners.*.fantasy_team_id' => 'required|integer',
            'winners.*.user_id' => 'required|integer',
            'winners.*.fantasy_team_name' => 'required|string',
            'winners.*.user_name' => 'required|string',
            'winners.*.user_email' => 'required|email',
            'winners.*.total_points' => 'required|integer',
        ]);

        $tournamentId = $request->input('tournament_id');
        $winnersData = $request->input('winners');
        $tournament = Tournament::find($tournamentId);

        try {
            DB::transaction(function () use ($tournamentId, $winnersData, $tournament) {
                // Extract arrays from winners data
                $fantasyTeamIds = array_column($winnersData, 'fantasy_team_id');
                $fantasyTeamNames = array_column($winnersData, 'fantasy_team_name');
                $userIds = array_column($winnersData, 'user_id');
                $userNames = array_column($winnersData, 'user_name');
                $totalPoints = array_column($winnersData, 'total_points');

                // Update or create a single row for this tournament with status = 'active'
                Winner::updateOrCreate(
                    ['tournament_id' => $tournamentId],
                    [
                        'tournament_name' => $tournament->name,
                        'fantasy_teams_ids' => $fantasyTeamIds,
                        'fantasy_teams_names' => $fantasyTeamNames,
                        'user_ids' => $userIds,
                        'user_names' => $userNames,
                        'total_points' => $totalPoints,
                        'status' => 'active',
                    ]
                );
            });

            return response()->json([
                'success' => true,
                'message' => 'Winners saved successfully!',
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'success' => false,
                'message' => 'Error saving winners: ' . $e->getMessage(),
            ], 500);
        }
    }

    /**
     * Show edit form for a winner
     */
    public function edit(Winner $winner)
    {
        return Inertia::render('Admin/Winners/Edit', compact('winner'));
    }

    /**
     * Update winner record (primarily for status toggle)
     */
    public function update(Request $request, Winner $winner)
    {
        $request->validate([
            'status' => 'required|in:active,inactive,cancel,hold,archived',
        ]);

        try {
            $winner->update([
                'status' => $request->input('status'),
            ]);

            return redirect()->route('admin.winners.index')->with('success', 'Winner status updated successfully!');
        } catch (\Exception $e) {
            return back()->with('error', 'Failed to update winner: ' . $e->getMessage());
        }
    }

    /**
     * Delete a winner record
     */
    public function destroy(Winner $winner)
    {
        try {
            $winner->delete();
            return redirect()->route('admin.winners.index')->with('success', 'Winner record deleted successfully!');
        } catch (\Exception $e) {
            return back()->with('error', 'Failed to delete winner: ' . $e->getMessage());
        }
    }

    /**
     * Get winners for a specific tournament
     */
    public function getTournamentWinners($tournamentId)
    {
        $winner = Winner::where('tournament_id', $tournamentId)->first();

        if (!$winner) {
            return response()->json([
                'success' => true,
                'data' => [],
            ]);
        }

        // Format data to match the expected structure
        $data = [];
        foreach ($winner->fantasy_teams_ids as $index => $teamId) {
            $data[] = [
                'rank' => $index + 1,
                'fantasy_team_id' => $teamId,
                'fantasy_team_name' => $winner->fantasy_teams_names[$index] ?? '',
                'user_id' => $winner->user_ids[$index] ?? null,
                'user_name' => $winner->user_names[$index] ?? '',
                'total_points' => $winner->total_points[$index] ?? 0,
            ];
        }

        return response()->json([
            'success' => true,
            'data' => $data,
        ]);
    }
}

