<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Tournament;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TournamentController extends Controller
{
    // GET /api/tournaments
    public function index(Request $request): JsonResponse
    {
        $perPage = max(10, (int) $request->query('per_page', 25));

        $tournaments = Tournament::withCount('teams')
            ->when($request->query('q'), function ($query, $q) {
                $query->where('name', 'like', "%{$q}%");
            })->paginate($perPage);

        $tournaments->getCollection()->transform(function ($t) {
            $arr = $t->toArray();
            $arr['logo_url'] = $arr['logo_url'] ?? config('app.placeholder_image');

            return $arr;
        });

        return response()->json(['success' => true, 'data' => $tournaments]);
    }

    // GET /api/tournaments/{tournament}
    public function show(Tournament $tournament): JsonResponse
    {
        $tournament->load(['teams.selections.player']);

        $arr = $tournament->toArray();
        $arr['logo_url'] = $arr['logo_url'] ?? config('app.placeholder_image');

        // ensure teams and players have fallback images
        if (! empty($arr['teams']) && is_array($arr['teams'])) {
            foreach ($arr['teams'] as &$team) {
                $team['logo_url'] = $team['logo_url'] ?? config('app.placeholder_image');
                if (! empty($team['selections']) && is_array($team['selections'])) {
                    foreach ($team['selections'] as &$sel) {
                        if (isset($sel['player']) && is_array($sel['player'])) {
                            $sel['player']['image_url'] = $sel['player']['image_url'] ?? config('app.placeholder_image');
                        }
                    }
                }
            }
        }

        return response()->json(['success' => true, 'data' => $arr]);
    }

    // GET /api/tournaments/{tournament}/leaderboard - Fantasy team rankings by total_points
    public function leaderboard(Tournament $tournament): JsonResponse
    {
        // ✅ Optimized: Uses cached total_points from fantasy_teams table
        // ✅ Index on (tournament_id, total_points) makes this fast with millions of records
        // ✅ Eager loads users (no N+1 queries)
        // ✅ Limits to top 100 to avoid huge JSON responses

        // Default to top 5 when not specified, cap at 100 when provided
        $perPage = min((int)request('per_page', 5), 100);  // Default 5, cap at 100 for performance

        // Leaderboard: prefer fantasy teams if available, otherwise fallback to game teams
        $fantasyExists = \App\Models\FantasyTeam::where('tournament_id', $tournament->id)->exists();

        if ($fantasyExists) {
            $leaderboard = \App\Models\FantasyTeam::query()
                ->where('tournament_id', $tournament->id)
                ->select('fantasy_teams.id', 'fantasy_teams.name', 'fantasy_teams.user_id', 'fantasy_teams.total_points')
                ->with('user:id,name')
                ->orderByDesc('total_points')
                ->paginate($perPage);

            $items = $leaderboard->items();
            $formatItems = array_map(function ($team) {
                return [
                    'team_id' => $team->id,
                    'team_name' => $team->name,
                    'user_name' => $team->user?->name,
                    'total_points' => (int)$team->total_points,
                ];
            }, $items);
            $total = $leaderboard->total();
            $currentPage = $leaderboard->currentPage();
        } else {
            $teams = \App\Models\Team::where('tournament_id', $tournament->id)
                ->select('teams.id', 'teams.name', 'teams.user_id', 'teams.points')
                ->with('user:id,name')
                ->orderByDesc('points')
                ->paginate($perPage);

            $items = $teams->items();
            $formatItems = array_map(function ($team) {
                return [
                    'team_id' => $team->id,
                    'team_name' => $team->name,
                    'user_name' => $team->user?->name,
                    'total_points' => (int)$team->points,
                ];
            }, $items);
            $total = $teams->total();
            $currentPage = $teams->currentPage();
        }

        // Format response with rank
        $result = collect();
        $startRank = ($currentPage - 1) * $perPage + 1;

        foreach ($formatItems as $index => $team) {
            $result->push(array_merge(['rank' => $startRank + $index], $team));
        }

        // pick paginator depending on source
        $paginator = $fantasyExists ? $leaderboard : $teams;

        return response()->json([
            'success' => true,
            'data' => $result,
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'last_page' => $paginator->lastPage(),
                'total' => $paginator->total(),
                'per_page' => $paginator->perPage(),
            ],
        ]);
    }

    // GET /api/tournaments/{tournament}/teams
    public function teams(Tournament $tournament): JsonResponse
    {
        // ✅ Optimized: Pagination to handle lacs of teams
        // ✅ Only loads necessary fields, selections loaded on-demand

        $perPage = min((int)request('per_page', 20), 50);  // Cap at 50 for performance

        // Include teams that are either attached via the pivot table `tournament_team` or have a direct `tournament_id` for backwards compatibility
        $teamsQuery = \App\Models\Team::where(function ($q) use ($tournament) {
                $q->where('tournament_id', $tournament->id)
                  ->orWhereHas('tournaments', fn($q2) => $q2->where('tournaments.id', $tournament->id));
            })
            ->select('teams.id', 'teams.name', 'teams.user_id', 'teams.tournament_id', 'teams.created_at')
            ->with(['user:id,name', 'selections']);

        $teams = $teamsQuery->paginate($perPage);

        // Convert selections to a simple array shape for API consumers
        $items = collect($teams->items())->map(function ($team) {
            $t = $team->toArray();
            $t['selections'] = collect($team->selections)->map(function ($s) {
                return [
                    'player_id' => $s['player_id'],
                    'captain' => (int)$s['captain'],
                    'vice_captain' => (int)$s['vice_captain'],
                ];
            })->toArray();
            return $t;
        })->toArray();

        return response()->json([
            'success' => true,
            'data' => $teams->items(),
            'pagination' => [
                'current_page' => $teams->currentPage(),
                'last_page' => $teams->lastPage(),
                'total' => $teams->total(),
                'per_page' => $teams->perPage(),
            ],
        ]);
    }

    // Admin-only: POST /api/tournaments
    public function store(Request $request): JsonResponse
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'logo_url' => 'nullable|url',
            'description' => 'nullable|string',
            'start_at' => 'nullable|date',
            'end_at' => 'nullable|date',
            'entry_fee' => 'nullable|numeric|min:0',
            'required_players' => 'nullable|integer|min:1|max:100',
            'status' => 'nullable|in:upcoming,running,active,stopped,canceled',
        ]);

        $t = Tournament::create($request->only(['name', 'logo_url', 'description', 'start_at', 'end_at', 'entry_fee', 'required_players', 'captain_multiplier', 'vice_captain_multiplier', 'status']));

        return response()->json(['success' => true, 'data' => $t], 201);
    }

    // Admin-only: PUT /api/tournaments/{tournament}
    public function update(Request $request, Tournament $tournament): JsonResponse
    {
        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'logo_url' => 'nullable|url',
            'description' => 'nullable|string',
            'start_at' => 'nullable|date',
            'end_at' => 'nullable|date',
            'entry_fee' => 'nullable|numeric|min:0',
            'required_players' => 'nullable|integer|min:1|max:100',
            'status' => 'nullable|in:upcoming,running,active,stopped,canceled',
        ]);

        $tournament->update($request->only(['name', 'logo_url', 'description', 'start_at', 'end_at', 'entry_fee', 'required_players', 'captain_multiplier', 'vice_captain_multiplier', 'status']));

        return response()->json(['success' => true, 'data' => $tournament]);
    }

    // Admin-only: DELETE /api/tournaments/{tournament}
    public function destroy(Tournament $tournament): JsonResponse
    {
        $tournament->delete();

        return response()->json(['success' => true, 'message' => 'Tournament deleted']);
    }
}
