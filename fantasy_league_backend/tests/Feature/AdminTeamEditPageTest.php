<?php

namespace Tests\Feature;

use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminTeamEditPageTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_view_team_edit_page()
    {
        $admin = User::factory()->create(['is_admin' => true, 'email_verified_at' => now()]);
        $this->actingAs($admin);

        $owner = User::factory()->create(['email_verified_at' => now()]);
        $team = \App\Models\Team::create(['name' => 'Alpha', 'user_id' => $owner->id]);

        $res = $this->get('/admin/teams/' . $team->id . '/edit');
        $res->assertStatus(200);
        $res->assertSee('Admin\\/Teams\\/Edit');
        $res->assertSee('"id":'.$team->id);
    }

    public function test_non_admin_cannot_access_team_edit()
    {
        $user = User::factory()->create(['is_admin' => false, 'email_verified_at' => now()]);
        $this->actingAs($user);

        $owner = User::factory()->create(['email_verified_at' => now()]);
        $team = \App\Models\Team::create(['name' => 'Beta', 'user_id' => $owner->id]);

        $res = $this->get('/admin/teams/' . $team->id . '/edit');
        $res->assertStatus(403);
    }
}
