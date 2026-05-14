<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminFantasyTeamsPageTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_view_fantasy_teams_page()
    {
        $admin = User::factory()->create(['is_admin' => true, 'email_verified_at' => now()]);
        $this->actingAs($admin);

        $res = $this->get('/admin/fantasy-teams');
        $res->assertStatus(200);
        $res->assertSee('Admin\/FantasyTeams\/Index');
    }

    public function test_non_admin_cannot_view_fantasy_teams_page()
    {
        $user = User::factory()->create(['is_admin' => false, 'email_verified_at' => now()]);
        $this->actingAs($user);

        $res = $this->get('/admin/fantasy-teams');
        $res->assertStatus(403);
    }
}
