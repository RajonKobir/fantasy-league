<?php

namespace Tests\Feature;

use App\Models\Player;
use App\Models\Tournament;
use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminTournamentTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_set_player_points()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $t = Tournament::create(['name' => 'Points Cup']);
        $p1 = Player::create(['name' => 'P1', 'nationality' => 'X', 'role' => 'batsman']);
        $p2 = Player::create(['name' => 'P2', 'nationality' => 'Y', 'role' => 'bowler']);

        // create a game match and set match-specific points
        $gameMatch = \App\Models\GameMatch::create(['tournament_id' => $t->id, 'team_a_id' => null, 'team_b_id' => null, 'start_time' => now()]);

        $resp = $this->post(route('admin.game-matches.points.update', $gameMatch->id), [
            'points' => [
                ['player_id' => $p1->id, 'points' => 12],
                ['player_id' => $p2->id, 'points' => 5],
            ],
        ]);

        $resp->assertRedirect();

        $this->assertDatabaseHas('match_player_points', ['game_match_id' => $gameMatch->id, 'player_id' => $p1->id, 'points' => 12]);
        $this->assertDatabaseHas('match_player_points', ['game_match_id' => $gameMatch->id, 'player_id' => $p2->id, 'points' => 5]);

        // Also ensure cached team points are recalculated (teams use sum of match player points)
        $team = Team::create(['name' => 'Scoring Team', 'user_id' => $admin->id, 'tournament_id' => $t->id]);
        \App\Models\PlayerSelection::create(['team_id' => $team->id, 'player_id' => $p1->id]);
        \App\Models\PlayerSelection::create(['team_id' => $team->id, 'player_id' => $p2->id]);

        // Trigger recalculation manually (points were saved earlier but selections were created after);
        // dispatch sync recalculation now to include selections
        \App\Jobs\RecalculateTournamentScores::dispatchSync($t->id);

        $this->assertDatabaseHas('teams', ['id' => $team->id, 'points' => 17]);
    }
}
