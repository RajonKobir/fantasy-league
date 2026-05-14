<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\MatchPlayerPoints;
use Illuminate\Http\Request;
use Inertia\Inertia;

class PointController extends Controller
{
    public function index(Request $request)
    {
        $q = trim((string) $request->get('q', ''));
        $perPage = (int) $request->get('per_page', 15);
        $allowed = [10, 15, 25, 50];
        if (!in_array($perPage, $allowed)) $perPage = 15;

        $query = MatchPlayerPoints::with(['tournament','player','gameMatch.teamA','gameMatch.teamB'])
            ->orderByDesc('points');

        if (!empty($q)) {
            $query->where(function ($builder) use ($q) {
                $builder->whereHas('player', fn($qb) => $qb->where('name', 'like', "%{$q}%"))
                    ->orWhereHas('tournament', fn($qb) => $qb->where('name', 'like', "%{$q}%"))
                    ->orWhereHas('gameMatch', fn($qb) => $qb->whereHas('teamA', fn($b) => $b->where('name', 'like', "%{$q}%"))->orWhereHas('teamB', fn($b) => $b->where('name', 'like', "%{$q}%")))
                    ->orWhere('points', 'like', "%{$q}%")
                    ->orWhere('note', 'like', "%{$q}%");
            });
        }

        if ($request->has('tournament_id')) {
            $query->where('tournament_id', $request->input('tournament_id'));
        }
        if ($request->has('game_match_id')) {
            $query->where('game_match_id', $request->input('game_match_id'));
        }

        $points = $query->paginate($perPage)->withQueryString();

        return Inertia::render('Admin/Points/Index', [
            'points' => $points,
            'filters' => ['q' => $q, 'per_page' => $perPage],
        ]);
    }

    public function create()
    {
        $tournaments = \App\Models\Tournament::orderBy('start_at')->get();
        $players = \App\Models\Player::orderBy('name')->get();
        $teams = \App\Models\Team::orderBy('name')->get();
        $gameMatches = \App\Models\GameMatch::orderBy('start_time')->get();

        return Inertia::render('Admin/Points/Create', compact('tournaments', 'players', 'teams', 'gameMatches'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'game_match_id' => 'required|exists:game_matches,id',
            'tournament_id' => 'nullable|exists:tournaments,id',
            'player_id' => 'required|exists:players,id',
            'points' => 'required|integer|min:0',
            'note' => 'nullable|string',
        ]);

        MatchPlayerPoints::updateOrCreate([
            'game_match_id' => $data['game_match_id'],
            'player_id' => $data['player_id'],
        ], [
            'points' => $data['points'],
            'note' => $data['note'] ?? null,
            'tournament_id' => $data['tournament_id'] ?? null,
        ]);

        return redirect()->route('admin.points.index')->with('success', 'Point created.');
    }

    public function edit(MatchPlayerPoints $point)
    {
        $point->load(['player','tournament','gameMatch']);

        $tournaments = \App\Models\Tournament::orderBy('start_at')->get();
        $players = \App\Models\Player::orderBy('name')->get();
        $teams = \App\Models\Team::orderBy('name')->get();
        $gameMatches = \App\Models\GameMatch::orderBy('start_time')->get();

        return Inertia::render('Admin/Points/Edit', compact('point', 'tournaments', 'players', 'teams', 'gameMatches'));
    }

    public function update(Request $request, MatchPlayerPoints $point)
    {
        $data = $request->validate([
            'game_match_id' => 'sometimes|required|exists:game_matches,id',
            'tournament_id' => 'sometimes|required|exists:tournaments,id',
            'player_id' => 'sometimes|required|exists:players,id',
            'points' => 'required|integer|min:0',
            'note' => 'nullable|string',
        ]);

        $point->update($data);

        return redirect()->route('admin.points.index')->with('success', 'Point updated.');
    }

    public function destroy(MatchPlayerPoints $point)
    {
        $point->delete();

        return redirect()->route('admin.points.index')->with('success', 'Point deleted.');
    }
}
