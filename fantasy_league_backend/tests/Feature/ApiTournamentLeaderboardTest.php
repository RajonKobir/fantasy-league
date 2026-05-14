<?php

namespace Tests\Feature;

use App\Jobs\RecalculateTournamentScores;
use App\Models\Player;
use App\Models\Team;
use App\Models\Tournament;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ApiTournamentLeaderboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_leaderboard_returns_top_5_users_by_points()
    {
        $t = Tournament::create(['name' => 'Leaderboard Cup']);

        // create 6 users with teams
        $users = User::factory()->count(6)->create();
        $players = collect();

        // create players and set points
        for ($i = 1; $i <= 6; $i++) {
            $players->push(Player::create(['name' => 'P'.$i, 'nationality' => 'T', 'role' => 'all-rounder']));
        }

        foreach ($users as $index => $u) {
            $team = Team::create(['name' => 'Team'.$index, 'user_id' => $u->id, 'tournament_id' => $t->id, 'points' => 0]);
            // each team has single player
            \App\Models\PlayerSelection::create(['team_id' => $team->id, 'player_id' => $players[$index]->id, 'captain' => 1]);
        }

        // Set points: make users 0..5 have increasing points so top is user with highest index
        $pointMap = [];
        foreach ($players as $i => $p) {
            $pointMap[$p->id] = ($i + 1) * 10; // 10,20,...60
        }

        // set points and recalc
        // use admin to post
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin, 'sanctum')->post(route('admin.tournaments.playerPoints', $t->id), ['points' => $pointMap]);

        // call leaderboard
        $resp = $this->getJson(route('api.tournaments.leaderboard', $t->id));

        $resp->assertStatus(200);
        $data = $resp->json('data');

        // Should have top 5 entries (descending by total_points)
        $this->assertCount(5, $data);
        $this->assertEquals(60 * 2, $data[0]['total_points']); // top user had 60 and as captain doubled to 120
        $this->assertEquals(50 * 2, $data[1]['total_points']);
    }
}
