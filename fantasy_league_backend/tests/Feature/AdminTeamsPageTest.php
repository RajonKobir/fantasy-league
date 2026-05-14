<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminTeamsPageTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_view_teams_page()
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin);
        $res = $this->get('/admin/teams');

        $res->assertStatus(200);
        $res->assertSee('Teams');
    }

    public function test_guest_is_redirected_to_login()
    {
        $res = $this->get('/admin/teams');

        $res->assertStatus(302);
        $res->assertRedirect('/login');
    }
}
