<?php

namespace Tests\Feature;

use App\Models\Player;
use App\Models\Team;
use App\Models\Tournament;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ApiMyTeamsTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_fetch_their_teams_with_points()
    {
        $user = User::factory()->create();
        $t = Tournament::create(['name' => 'My Teams Cup']);

        $team = Team::create(['name' => 'My Team', 'user_id' => $user->id, 'tournament_id' => $t->id, 'points' => 42]);

        $this->actingAs($user, 'sanctum');
        $resp = $this->getJson(route('api.me.teams'));

        $resp->assertStatus(200);
        $data = $resp->json('data');
        $this->assertCount(1, $data);
        $this->assertEquals(42, $data[0]['points']);
    }
}
