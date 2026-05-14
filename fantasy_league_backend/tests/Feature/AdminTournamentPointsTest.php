<?php

namespace Tests\Feature;

use App\Jobs\RecalculateTournamentScores;
use App\Models\Player;
use App\Models\Team;
use App\Models\Tournament;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminTournamentPointsTest extends TestCase
{
    use RefreshDatabase;

    public function test_captain_and_vice_are_doubled_in_team_score()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $t = Tournament::create(['name' => 'Double Cup']);
        $p1 = Player::create(['name' => 'Captain P', 'nationality' => 'A', 'role' => 'batsman']);
        $p2 = Player::create(['name' => 'Vice P', 'nationality' => 'B', 'role' => 'bowler']);
        $p3 = Player::create(['name' => 'Other P', 'nationality' => 'C', 'role' => 'batsman']);

        $team = Team::create(['name' => 'Duo Team', 'user_id' => $admin->id, 'tournament_id' => $t->id]);

        // create selections with captain and vice flags
        \App\Models\PlayerSelection::create(['team_id' => $team->id, 'player_id' => $p1->id, 'captain' => 1, 'vice_captain' => 0]);
        \App\Models\PlayerSelection::create(['team_id' => $team->id, 'player_id' => $p2->id, 'captain' => 0, 'vice_captain' => 1]);
        \App\Models\PlayerSelection::create(['team_id' => $team->id, 'player_id' => $p3->id, 'captain' => 0, 'vice_captain' => 0]);

        // set points and dispatch recalculation
        $this->actingAs($admin, 'sanctum')->post(route('admin.tournaments.playerPoints', $t->id), [
            'points' => [$p1->id => 10, $p2->id => 5, $p3->id => 3],
        ]);

        // After recalculation: p1 -> 10*2, p2 -> 5*2, p3 -> 3
        $this->assertDatabaseHas('teams', ['id' => $team->id, 'points' => 10*2 + 5*2 + 3]);
    }
}
