<?php

namespace Tests\Feature;

use App\Models\MatchPlayerPoints;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPointsApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_update_and_delete_point()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin, 'sanctum');

        $t = \App\Models\Tournament::create(['name' => 'Test Tournament', 'start_at' => now(), 'end_at' => now()->addDays(7)]);
        $p = \App\Models\Player::create(['name' => 'Test Player', 'nationality' => 'India', 'role' => 'batsman']);

        // create a game match to attach match points
        $gameMatch = \App\Models\GameMatch::create(['tournament_id' => $t->id, 'team_a_id' => null, 'team_b_id' => null, 'start_time' => now()]);

        $res = $this->postJson('/api/admin/points', [
            'game_match_id' => $gameMatch->id,
            'tournament_id' => $t->id,
            'player_id' => $p->id,
            'points' => 10,
        ]);

        $res->assertStatus(201);
        $this->assertDatabaseHas('match_player_points', ['player_id' => $p->id, 'points' => 10, 'game_match_id' => $gameMatch->id]);

        $pointId = $res->json('id');

        $res2 = $this->putJson('/api/admin/points/'.$pointId, ['points' => 20]);
        $res2->assertStatus(200);
        $this->assertDatabaseHas('match_player_points', ['id' => $pointId, 'points' => 20]);

        $res3 = $this->deleteJson('/api/admin/points/'.$pointId);
        $res3->assertStatus(204);
        $this->assertDatabaseMissing('match_player_points', ['id' => $pointId]);
    }

    public function test_non_admin_cannot_access_points_api()
    {
        $user = User::factory()->create(['is_admin' => false]);
        $this->actingAs($user, 'sanctum');

        $res = $this->getJson('/api/admin/points');
        $res->assertStatus(403);
    }
}
