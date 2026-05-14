<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminUserEditPageTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_view_user_edit_page()
    {
        $admin = User::factory()->create(['is_admin' => true, 'email_verified_at' => now()]);
        $this->actingAs($admin);

        $user = User::factory()->create(['name' => 'Regular', 'email' => 'regular@example.com']);

        $res = $this->get('/admin/users/' . $user->id . '/edit');
        $res->assertStatus(200);

        // The server response includes Inertia's initial page JSON with the Edit component
        $res->assertSee('Admin\\/Users\\/Edit');
        // The initial page JSON should include the user payload (id)
        $res->assertSee('"id":'.$user->id);
    }

    public function test_non_admin_cannot_access_user_edit()
    {
        $regular = User::factory()->create(['is_admin' => false, 'email_verified_at' => now()]);
        $this->actingAs($regular);

        $user = User::factory()->create();

        $res = $this->get('/admin/users/' . $user->id . '/edit');
        $res->assertStatus(403);
    }
}
