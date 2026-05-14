<?php

namespace Tests\Feature;

use App\Models\MatchPlayerPoints;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPointsWebCrudTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_edit_and_delete_point()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $t = \App\Models\Tournament::create(['name' => 'Test Tournament', 'start_at' => now(), 'end_at' => now()->addDays(7)]);
        $p = \App\Models\Player::create(['name' => 'Player 1', 'nationality' => 'India', 'role' => 'batsman']);
        $team = \App\Models\Team::create(['name' => 'TestTeam', 'user_id' => $admin->id, 'tournament_id' => $t->id]);

        // create a dummy game match to attach match points
        $gameMatch = \App\Models\GameMatch::create(['tournament_id' => $t->id, 'team_a_id' => $team->id, 'team_b_id' => null, 'start_time' => now()]);

        $res = $this->post('/admin/points', [
            'game_match_id' => $gameMatch->id,
            'tournament_id' => $t->id,
            'player_id' => $p->id,
            'points' => 50,
            'note' => 'Good match',
        ]);

        $res->assertRedirect('/admin/points');
        $this->assertDatabaseHas('match_player_points', ['player_id' => $p->id, 'points' => 50, 'game_match_id' => $gameMatch->id]);

        $point = MatchPlayerPoints::first();

        $res2 = $this->put('/admin/points/' . $point->id, [
            'points' => 60,
            'note' => 'Updated',
        ]);

        $res2->assertRedirect('/admin/points');
        $this->assertDatabaseHas('match_player_points', ['id' => $point->id, 'points' => 60, 'note' => 'Updated']);

        $res3 = $this->delete('/admin/points/' . $point->id);
        $res3->assertRedirect('/admin/points');
        $this->assertDatabaseMissing('match_player_points', ['id' => $point->id]);
    }

    public function test_validation_errors_on_create()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $res = $this->post('/admin/points', [
            // missing required fields
        ]);

        $res->assertStatus(302);
        $res->assertSessionHasErrors(['game_match_id', 'player_id', 'points']);
    }
}
