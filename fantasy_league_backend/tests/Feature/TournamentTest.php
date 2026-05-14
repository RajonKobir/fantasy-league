<?php

namespace Tests\Feature;

use App\Models\Player;
use App\Models\Team;
use App\Models\Tournament;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TournamentTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_and_get_tournament()
    {
        $admin = User::factory()->create();
        // mark as admin via simple property — assume EnsureUserIsAdmin checks is_admin
        $admin->is_admin = 1;
        $admin->save();

        $payload = ['name' => 'Test Tour', 'description' => 'Desc', 'entry_fee' => 50.00];
        $resp = $this->actingAs($admin, 'sanctum')->postJson('/api/tournaments', $payload);
        $resp->assertStatus(201)->assertJson(['success' => true]);

        $id = $resp->json('data.id');
        $this->assertEquals(50.00, floatval($resp->json('data.entry_fee')));
        $show = $this->getJson('/api/tournaments/'.$id);
        $show->assertStatus(200)->assertJson(['success' => true]);
    }

    public function test_tournament_teams_and_players_listed()
    {
        $user = User::factory()->create();
        $t = Tournament::create(['name' => 'Cup']);
        $team = Team::create(['name' => 'T1', 'user_id' => $user->id, 'tournament_id' => $t->id]);

        $players = [];
        for ($i = 0; $i < 11; $i++) {
            $players[] = Player::create(['name' => 'P'.$i, 'nationality' => 'T1', 'role' => 'batsman']);
        }

        // add selections for the team
        foreach ($players as $idx => $p) {
            \App\Models\PlayerSelection::create(['team_id' => $team->id, 'player_id' => $p->id, 'captain' => $idx === 0, 'vice_captain' => $idx === 1]);
        }

        $resp = $this->getJson('/api/tournaments/'.$t->id.'/teams');
        $resp->assertStatus(200)->assertJson(['success' => true]);
        $data = $resp->json('data');
        $this->assertNotEmpty($data);
        $this->assertEquals($team->id, $data[0]['id']);
        $this->assertArrayHasKey('selections', $data[0]);
    }
}
