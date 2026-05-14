<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPanelMenuTest extends TestCase
{
    use RefreshDatabase;

    protected $adminPaths = [
        '/admin/dashboard',
        '/admin/users',
        '/admin/players',
        '/admin/teams',
        '/admin/tournaments',
        '/admin/game-matches',
        '/admin/settings',
    ];

    public function test_admin_can_access_all_menu_pages()
    {
        $admin = User::factory()->create(['is_admin' => true, 'email_verified_at' => now()]);
        $this->actingAs($admin);

        foreach ($this->adminPaths as $path) {
            $res = $this->get($path);
            $res->assertStatus(200, "Failed asserting admin can access {$path}");
        }
    }

    public function test_non_admin_cannot_access_menu_pages()
    {
        $user = User::factory()->create(['is_admin' => false, 'email_verified_at' => now()]);
        $this->actingAs($user);

        foreach ($this->adminPaths as $path) {
            $res = $this->get($path);
            $res->assertStatus(403, "Failed asserting non-admin is blocked from {$path}");
        }
    }

    public function test_logout_route_logs_out()
    {
        $admin = User::factory()->create(['is_admin' => true, 'email_verified_at' => now()]);
        $this->actingAs($admin);

        $res = $this->post('/logout');
        $res->assertStatus(302);
    }
}
