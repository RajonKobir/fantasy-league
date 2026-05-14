<?php

namespace Tests\Feature;

use App\Models\GameMatch;
use App\Models\Player;
use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TeamE2ETest extends TestCase
{
    use RefreshDatabase;

    public function test_create_team_and_then_list_and_show()
    {
        $user = User::factory()->create();
        $t1 = Team::create(['name' => 'Team A', 'user_id' => $user->id]);
        $t2 = Team::create(['name' => 'Team B', 'user_id' => $user->id]);

        $match = GameMatch::create(['team_a_id' => $t1->id, 'team_b_id' => $t2->id, 'start_time' => now(), 'venue_id' => null]);

        $players = [];
        for ($i = 0; $i < 11; $i++) {
            $players[] = Player::create(['name' => "Player $i", 'nationality' => 'Team A', 'role' => 'batsman']);
        }

        $payload = [
            'name' => 'E2E Test Team',
            'game_match_id' => $match->id,
            'player_ids' => array_map(fn ($p) => $p->id, $players),
            'captain_id' => $players[0]->id,
            'vice_captain_id' => $players[1]->id,
        ];

        // create team via API
        $createResp = $this->actingAs($user, 'sanctum')->postJson('/api/teams', $payload);
        $createResp->assertStatus(201)->assertJson(['success' => true]);

        $teamId = $createResp->json('data.id');

        // list teams for match
        $listResp = $this->actingAs($user, 'sanctum')->getJson('/api/teams?match_id='.$match->id);
        $listResp->assertStatus(200)->assertJsonStructure(['success', 'data']);
        $this->assertNotEmpty($listResp->json('data'));

        // show team detail
        $showResp = $this->actingAs($user, 'sanctum')->getJson('/api/teams/'.$teamId);
        $showResp->assertStatus(200)->assertJsonStructure(['success', 'data']);
        $data = $showResp->json('data');
        // verify captain and vice flags in selections
        $this->assertTrue(collect($data['selections'])->firstWhere('captain', 1) !== null);
        $this->assertTrue(collect($data['selections'])->firstWhere('vice_captain', 1) !== null);
    }
}
