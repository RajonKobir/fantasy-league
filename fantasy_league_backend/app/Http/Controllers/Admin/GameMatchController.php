<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\GameMatch;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use Inertia\Inertia;

class GameMatchController extends Controller
{
    public function index(Request $request)
    {
        $q = trim($request->get('q', ''));

        $query = GameMatch::with(['teamA', 'teamB', 'tournament'])->orderBy('id', 'desc');

        if (!empty($q)) {
            $query->where(function ($builder) use ($q) {
                $builder->whereHas('teamA', fn ($qb) => $qb->where('name', 'like', "%{$q}%"))
                    ->orWhereHas('teamB', fn ($qb) => $qb->where('name', 'like', "%{$q}%"))
                    ->orWhereHas('tournament', fn ($qb) => $qb->where('name', 'like', "%{$q}%"))
                    ->orWhere('status', 'like', "%{$q}%");
            });
        }

        $matches = $query->paginate(15)->appends($request->only('q'));

        // Transform to include team names expected by the front-end
        $matches->getCollection()->transform(function ($m) {
            return [
                'id' => $m->id,
                'team_a' => $m->teamA->name ?? '',
                'team_b' => $m->teamB->name ?? '',
                'tournament' => [
                    'name' => $m->tournament->name ?? 'N/A',
                ],
                'scheduled_at' => $m->start_time,
                'status' => $m->status,
            ];
        });

        return Inertia::render('Admin/GameMatches/Index', ['gameMatches' => $matches, 'filters' => ['q' => $q]]);
    }

    public function create()
    {
        $teams = \App\Models\Team::all()->map(fn ($t) => ['id' => $t->id, 'label' => $t->name])->values();
        $tournaments = \App\Models\Tournament::all()->map(fn ($t) => ['id' => $t->id, 'label' => $t->name])->values();
        $cities = \App\Models\City::orderBy('name')->limit(200)->get()->map(fn($c) => ['id' => $c->id, 'label' => $c->name . ($c->country ? ' (' . $c->country->name . ')' : '')]);

        return Inertia::render('Admin/GameMatches/Create', [
            'teams' => $teams,
            'tournaments' => $tournaments,
            'cities' => $cities,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'team_a_id' => 'nullable|integer|exists:teams,id',
            'team_b_id' => 'nullable|integer|exists:teams,id|different:team_a_id',
            'team_a' => 'nullable|string|max:255',
            'team_b' => 'nullable|string|max:255',
            'tournament_id' => 'nullable|integer|exists:tournaments,id',
            'start_time' => 'required|date',
            'status' => 'required|in:upcoming,live,completed',
            'venue_id' => 'nullable|integer|exists:cities,id',
        ]);

        // If names were provided instead of ids, create/find teams
        if (empty($validated['team_a_id']) && !empty($validated['team_a'])) {
            $teamA = \App\Models\Team::firstOrCreate(['name' => trim($validated['team_a'])], ['user_id' => Auth::id() ?? null]);
            $validated['team_a_id'] = $teamA->id;
        }
        if (empty($validated['team_b_id']) && !empty($validated['team_b'])) {
            $teamB = \App\Models\Team::firstOrCreate(['name' => trim($validated['team_b'])], ['user_id' => Auth::id() ?? null]);
            $validated['team_b_id'] = $teamB->id;
        }

        // Validate required team ids now
        $request->merge($validated);
        $request->validate([
            'team_a_id' => 'required|integer|exists:teams,id',
            'team_b_id' => 'required|integer|exists:teams,id|different:team_a_id',
        ]);

        DB::beginTransaction();
        try {
            $match = GameMatch::create([
                'team_a_id' => $validated['team_a_id'],
                'team_b_id' => $validated['team_b_id'],
                'tournament_id' => $validated['tournament_id'] ?? null,
                'start_time' => $validated['start_time'],
                'status' => $validated['status'],
                'venue_id' => $validated['venue_id'] ?? null,
            ]);

            // Auto-create match_player_points entries for all players in both teams
            $this->createPlayerPointsForMatch($match);

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }

        return redirect()
            ->route('admin.game-matches.index')
            ->with('success', 'Game Match created successfully! Player points entries initialized.');
    }

    /**
     * Auto-create match_player_points entries for all players in both teams
     */
    private function createPlayerPointsForMatch(GameMatch $match)
    {
        $playerSelections = \App\Models\PlayerSelection::where('game_match_id', $match->id)->get();

        foreach ($playerSelections as $selection) {
            \App\Models\MatchPlayerPoints::firstOrCreate(
                [
                    'game_match_id' => $match->id,
                    'player_id' => $selection->player_id,
                ],
                [
                    'tournament_id' => $match->tournament_id,
                    'points' => 0,
                    'note' => null,
                ]
            );
        }
    }

    public function edit(GameMatch $gameMatch)
    {
        // Load relationships and format data for the edit form
        $gameMatch->load(['teamA', 'teamB']);

        $teams = \App\Models\Team::all()->map(fn ($t) => ['id' => $t->id, 'label' => $t->name])->values();
        $tournaments = \App\Models\Tournament::all()->map(fn ($t) => ['id' => $t->id, 'label' => $t->name])->values();
        $cities = \App\Models\City::orderBy('name')->limit(200)->get()->map(fn($c) => ['id' => $c->id, 'label' => $c->name . ($c->country ? ' (' . $c->country->name . ')' : '')]);

        // Return formatted data instead of model with relationships
        return Inertia::render('Admin/GameMatches/Edit', [
            'gameMatch' => [
                'id' => $gameMatch->id,
                'team_a_id' => $gameMatch->team_a_id,
                'team_b_id' => $gameMatch->team_b_id,
                'tournament_id' => $gameMatch->tournament_id,
                'start_time' => $gameMatch->start_time,
                'status' => $gameMatch->status,
                'venue_id' => $gameMatch->venue_id,
            ],
            'teams' => $teams,
            'tournaments' => $tournaments,
            'cities' => $cities,
        ]);
    }

    public function update(Request $request, GameMatch $gameMatch)
    {
        $validated = $request->validate([
            'team_a_id' => 'nullable|integer|exists:teams,id',
            'team_b_id' => 'nullable|integer|exists:teams,id|different:team_a_id',
            'team_a' => 'nullable|string|max:255',
            'team_b' => 'nullable|string|max:255',
            'tournament_id' => 'nullable|integer|exists:tournaments,id',
            'start_time' => 'required|date',
            'status' => 'required|in:upcoming,live,completed',
            'venue_id' => 'nullable|integer|exists:cities,id',
        ]);

        // If names were provided instead of ids, create/find teams
        if (empty($validated['team_a_id']) && !empty($validated['team_a'])) {
            $teamA = \App\Models\Team::firstOrCreate(['name' => trim($validated['team_a'])], ['user_id' => Auth::id() ?? null]);
            $validated['team_a_id'] = $teamA->id;
        }
        if (empty($validated['team_b_id']) && !empty($validated['team_b'])) {
            $teamB = \App\Models\Team::firstOrCreate(['name' => trim($validated['team_b'])], ['user_id' => Auth::id() ?? null]);
            $validated['team_b_id'] = $teamB->id;
        }

        // Validate required team ids now
        $request->merge($validated);
        $request->validate([
            'team_a_id' => 'required|integer|exists:teams,id',
            'team_b_id' => 'required|integer|exists:teams,id|different:team_a_id',
        ]);

        DB::beginTransaction();
        try {
            $gameMatch->update([
                'team_a_id' => $validated['team_a_id'],
                'team_b_id' => $validated['team_b_id'],
                'tournament_id' => $validated['tournament_id'] ?? null,
                'start_time' => $validated['start_time'],
                'status' => $validated['status'],
                'venue_id' => $validated['venue_id'] ?? null,
            ]);

            DB::commit();
        } catch (\Throwable $e) {
            DB::rollBack();
            throw $e;
        }

        return redirect()
            ->route('admin.game-matches.index')
            ->with('success', 'Game Match updated successfully!');
    }

    public function destroy(GameMatch $gameMatch)
    {
        $gameMatch->delete();

        return redirect()
            ->route('admin.game-matches.index')
            ->with('success', 'Game Match deleted successfully!');
    }
}
