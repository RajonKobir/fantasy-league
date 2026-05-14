<?php

namespace Tests\Feature;

use App\Models\MatchPlayerPoints;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPointsPaginationTest extends TestCase
{
    use RefreshDatabase;

    public function test_points_index_is_paginated()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $t = \App\Models\Tournament::create(['name' => 'Test Tournament', 'start_at' => now(), 'end_at' => now()->addDays(7)]);

        // create 30 players and points
        for ($i = 1; $i <= 30; $i++) {
            $p = \App\Models\Player::create(['name' => 'Player '.$i, 'nationality' => 'Team', 'role' => 'batsman']);
            $team = \App\Models\Team::create(['name' => 'Team'.$i, 'user_id' => $admin->id, 'tournament_id' => $t->id]);
            // create a dummy game match to attach match points (we'll keep tournament_id for filtering)
            $gameMatch = \App\Models\GameMatch::create(['tournament_id' => $t->id, 'team_a_id' => $team->id, 'team_b_id' => null, 'start_time' => now()]);
            \App\Models\MatchPlayerPoints::create(['game_match_id' => $gameMatch->id, 'tournament_id' => $t->id, 'player_id' => $p->id, 'points' => $i]);
        }

        // first page is ordered by points desc — should contain Player 30 and Player 6 (top 25)
        $res1 = $this->get('/admin/points');
        $res1->assertStatus(200);
        $res1->assertSee('Player 30');
        $res1->assertSee('Player 6');
        $res1->assertDontSee('Player 5');

        // second page should contain Player 5 down to Player 1
        $res2 = $this->get('/admin/points?page=2');
        $res2->assertStatus(200);
        $res2->assertSee('Player 5');
        $res2->assertSee('Player 1');
        $res2->assertDontSee('Player 6');
    }
}
