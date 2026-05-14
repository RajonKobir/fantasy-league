<?php

namespace Tests\Feature;

use App\Models\FantasyTeam;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminFantasyTeamsCrudTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_and_edit_fantasy_team()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $t = \App\Models\Tournament::create(['name' => 'Test Tournament', 'start_at' => now(), 'end_at' => now()->addDays(7)]);
        $user = User::factory()->create();

        $players = [];
        for ($i=0;$i<11;$i++) {
            $p = \App\Models\Player::create(['name' => 'P'.$i, 'nationality' => 'India', 'role' => 'batsman']);
            $players[] = $p->id;
        }

        $res = $this->post('/admin/fantasy-teams', [
            'tournament_id' => $t->id,
            'user_id' => $user->id,
            'player_ids' => $players,
            'name' => 'Admins Team',
            'captain_id' => $players[0],
            'vice_captain_id' => $players[1],
        ]);

        $res->assertRedirect('/admin/fantasy-teams');
        $this->assertDatabaseHas('fantasy_teams', ['user_id' => $user->id, 'name' => 'Admins Team']);

        $team = FantasyTeam::first();
        $res2 = $this->put('/admin/fantasy-teams/' . $team->id, [
            'tournament_id' => $t->id,
            'user_id' => $user->id,
            'player_ids' => $players,
            'name' => 'Updated Team',
            'captain_id' => $players[2],
            'vice_captain_id' => $players[3],
        ]);

        $res2->assertRedirect('/admin/fantasy-teams');
        $this->assertDatabaseHas('fantasy_teams', ['id' => $team->id, 'name' => 'Updated Team', 'captain_id' => $players[2]]);
    }

    public function test_validation_errors_when_not_enough_players()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $t = \App\Models\Tournament::create(['name' => 'Test Tournament', 'start_at' => now(), 'end_at' => now()->addDays(7)]);
        $user = User::factory()->create();

        $players = [];
        for ($i=0;$i<5;$i++) {
            $p = \App\Models\Player::create(['name' => 'P'.$i, 'nationality' => 'India', 'role' => 'batsman']);
            $players[] = $p->id;
        }

        $res = $this->post('/admin/fantasy-teams', [
            'tournament_id' => $t->id,
            'user_id' => $user->id,
            'player_ids' => $players,
            'name' => 'Short Team',
            'captain_id' => $players[0],
            'vice_captain_id' => $players[1],
        ]);

        $res->assertStatus(302);
        $res->assertSessionHasErrors(['player_ids']);
    }
}
