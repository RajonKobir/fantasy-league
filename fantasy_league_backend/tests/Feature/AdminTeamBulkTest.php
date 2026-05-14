<?php

namespace Tests\Feature;

use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminTeamBulkTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_bulk_delete_teams()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $t1 = Team::create(['name' => 'Del One', 'user_id' => $admin->id]);
        $t2 = Team::create(['name' => 'Del Two', 'user_id' => $admin->id]);

        $res = $this->post('/admin/teams/bulk', ['ids' => [$t1->id, $t2->id], 'action' => 'delete']);
        $res->assertRedirect();

        $this->assertDatabaseMissing('teams', ['id' => $t1->id]);
        $this->assertDatabaseMissing('teams', ['id' => $t2->id]);
    }

    public function test_admin_can_change_owner_of_teams()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $owner = User::factory()->create();
        $this->actingAs($admin);

        $t1 = Team::create(['name' => 'Own One', 'user_id' => $admin->id]);
        $t2 = Team::create(['name' => 'Own Two', 'user_id' => $admin->id]);

        $res = $this->post('/admin/teams/bulk', ['ids' => [$t1->id, $t2->id], 'action' => 'change_owner', 'user_id' => $owner->id]);
        $res->assertRedirect();

        $this->assertDatabaseHas('teams', ['id' => $t1->id, 'user_id' => $owner->id]);
        $this->assertDatabaseHas('teams', ['id' => $t2->id, 'user_id' => $owner->id]);

    }

    public function test_admin_can_assign_teams_to_tournament()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $t1 = Team::create(['name' => 'T1', 'user_id' => $admin->id]);
        $t2 = Team::create(['name' => 'T2', 'user_id' => $admin->id]);

        $tourn = \App\Models\Tournament::create(['name' => 'Summer']);

        $res = $this->post('/admin/teams/bulk', ['ids' => [$t1->id, $t2->id], 'action' => 'assign_tournament', 'tournament_id' => $tourn->id]);
        $res->assertRedirect();

        $this->assertDatabaseHas('teams', ['id' => $t1->id, 'tournament_id' => $tourn->id]);
        $this->assertDatabaseHas('teams', ['id' => $t2->id, 'tournament_id' => $tourn->id]);
    }
}
