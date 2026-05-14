<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminMenuTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_menu_contains_tournaments_and_matches_links()
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin);
        $res = $this->get('/admin/dashboard');

        $res->assertStatus(200);
        // Inertia renders the menu client-side; assert that Ziggy route for tournaments and matches exists
        $res->assertSee('admin.tournaments.index');
        $res->assertSee('admin.game-matches.index');
        $res->assertSee('admin.fantasy-teams.index');
        $res->assertSee('admin.points.index');
    }

    public function test_admin_can_access_team_create_and_matches_index()
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin);

        // Team create page should be accessible now that full CRUD routes are registered
        $this->get('/admin/teams/create')->assertStatus(200);

        // Matches index should be accessible via the correct path
        $this->get('/admin/game-matches')->assertStatus(200);

        // Points index should be accessible
        $this->get('/admin/points')->assertStatus(200);
    }
}
