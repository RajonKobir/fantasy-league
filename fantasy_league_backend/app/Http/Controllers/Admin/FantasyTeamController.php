<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\FantasyTeam;
use Illuminate\Http\Request;
use Inertia\Inertia;

class FantasyTeamController extends Controller
{
    public function index(Request $request)
    {
        $filters = $request->only(['q', 'per_page']);
        $perPage = (int) ($request->query('per_page', 25));

        $teams = FantasyTeam::with(['user', 'tournament'])
            ->when($request->query('q'), function ($query, $q) {
                $query->where('name', 'like', "%{$q}%")
                    ->orWhereHas('user', function ($q2) use ($q) {
                        $q2->where('name', 'like', "%{$q}%")->orWhere('email', 'like', "%{$q}%");
                    })
                    ->orWhereHas('tournament', function ($q3) use ($q) {
                        $q3->where('name', 'like', "%{$q}%");
                    });
            })
            ->orderByDesc('id')
            ->paginate($perPage)
            ->withQueryString();

        return Inertia::render('Admin/FantasyTeams/Index', compact('teams', 'filters'));
    }

    public function create()
    {
        $tournaments = \App\Models\Tournament::orderBy('start_at')->get();

        // Get players who participated in tournaments (have match_player_points records)
        $players = \App\Models\Player::whereIn('id', function ($query) {
            $query->selectRaw('DISTINCT player_id')
                ->from('match_player_points');
        })
        ->orderBy('name')
        ->get();

        // (no extra merging here for create)

        $users = \App\Models\User::where('is_admin', 0)->orderBy('name')->get(['id', 'name', 'email']);

        return Inertia::render('Admin/FantasyTeams/Create', compact('tournaments', 'players', 'users'));
    }

    public function store(Request $request)
    {
        $tournament = \App\Models\Tournament::find($request->tournament_id);
        $requiredPlayers = $tournament?->required_players ?? 11;

        $data = $request->validate([
            'tournament_id' => 'required|exists:tournaments,id',
            'user_id' => 'required|exists:users,id',
            'player_ids' => "required|array|size:{$requiredPlayers}",
            'player_ids.*' => 'distinct|exists:players,id',
            'name' => 'nullable|string',
            'captain_id' => 'nullable|exists:players,id',
            'vice_captain_id' => 'nullable|exists:players,id',
            'status' => 'nullable|in:pending,approved,rejected',
        ]);

        // Set default status if not provided
        if (!isset($data['status'])) {
            $data['status'] = 'pending';
        }

        // Ensure captain and vice are within player_ids
        if (! in_array($data['captain_id'], $data['player_ids'] ?? [])) {
            return back()->withErrors(['captain_id' => 'Captain must be one of the selected players.'])->withInput();
        }
        if (! in_array($data['vice_captain_id'], $data['player_ids'] ?? [])) {
            return back()->withErrors(['vice_captain_id' => 'Vice-Captain must be one of the selected players.'])->withInput();
        }

        FantasyTeam::create($data);

        return redirect()->route('admin.fantasy-teams.index')->with('success', 'Fantasy team created.');
    }

    public function edit(FantasyTeam $fantasyTeam)
    {
        $tournaments = \App\Models\Tournament::orderBy('start_at')->get();

        // Get players who participated in tournaments (have match_player_points records)
        $players = \App\Models\Player::whereIn('id', function ($query) {
            $query->selectRaw('DISTINCT player_id')
                ->from('match_player_points');
        })
        ->orderBy('name')
        ->get();

        // Ensure any players already present in the fantasy team are included
        // (some players may not have match_player_points records but are part of teams)
        $teamPlayerIds = $fantasyTeam->player_ids ?? [];
        if (!empty($teamPlayerIds)) {
            $existingIds = $players->pluck('id')->all();
            $missing = array_values(array_diff($teamPlayerIds, $existingIds));
            if (!empty($missing)) {
                $extra = \App\Models\Player::whereIn('id', $missing)->orderBy('name')->get();
                // Merge and keep unique by id
                $players = $players->merge($extra)->unique('id')->sortBy('name')->values();
            }
        }

        $users = \App\Models\User::where('is_admin', 0)->orderBy('name')->get(['id', 'name', 'email']);

        return Inertia::render('Admin/FantasyTeams/Edit', compact('fantasyTeam', 'tournaments', 'players', 'users'));
    }

    public function update(Request $request, FantasyTeam $fantasyTeam)
    {
        $tournament = \App\Models\Tournament::find($request->tournament_id);
        $requiredPlayers = $tournament?->required_players ?? 11;

        $data = $request->validate([
            'tournament_id' => 'required|exists:tournaments,id',
            'user_id' => 'required|exists:users,id',
            'player_ids' => "required|array|size:{$requiredPlayers}",
            'player_ids.*' => 'distinct|exists:players,id',
            'name' => 'nullable|string',
            'captain_id' => 'nullable|exists:players,id',
            'vice_captain_id' => 'nullable|exists:players,id',
            'status' => 'nullable|in:pending,approved,rejected',
        ]);

        if (! in_array($data['captain_id'], $data['player_ids'] ?? [])) {
            return back()->withErrors(['captain_id' => 'Captain must be one of the selected players.'])->withInput();
        }
        if (! in_array($data['vice_captain_id'], $data['player_ids'] ?? [])) {
            return back()->withErrors(['vice_captain_id' => 'Vice-Captain must be one of the selected players.'])->withInput();
        }

        $fantasyTeam->update($data);

        return redirect()->route('admin.fantasy-teams.index')->with('success', 'Fantasy team updated.');
    }

    public function destroy(FantasyTeam $fantasyTeam)
    {
        $fantasyTeam->delete();

        return redirect()->route('admin.fantasy-teams.index')->with('success', 'Fantasy team deleted.');
    }
}
