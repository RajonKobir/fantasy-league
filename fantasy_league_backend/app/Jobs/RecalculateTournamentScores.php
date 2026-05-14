<?php

namespace App\Jobs;

use App\Models\Team;
use App\Models\MatchPlayerPoints;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;


class RecalculateTournamentScores implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $tournamentId;

    public function __construct(int $tournamentId)
    {
        $this->tournamentId = $tournamentId;
    }

    public function handle(): void
    {
        // load player points for tournament once
        // Sum match points per player for the tournament (aggregate across matches)
        $points = MatchPlayerPoints::where('tournament_id', $this->tournamentId)
            ->selectRaw('player_id, SUM(points) as points')
            ->groupBy('player_id')
            ->pluck('points', 'player_id')
            ->toArray();

        // iterate teams in tournament
        $teams = Team::where('tournament_id', $this->tournamentId)->with('selections')->get();

        foreach ($teams as $team) {
            $score = 0;
            foreach ($team->selections as $sel) {
                $pid = $sel->player_id;
                $base = intval($points[$pid] ?? 0);
                // Captain or vice-captain doubles the player's points. If both flags are set, still treat as doubled.
                $mult = ($sel->captain || $sel->vice_captain) ? 2 : 1;
                $score += $base * $mult;
            }
            $team->points = $score;
            $team->save();

        }
    }
}
