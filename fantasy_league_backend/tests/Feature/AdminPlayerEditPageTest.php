<?php

namespace Tests\Feature;

use App\Models\Player;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPlayerEditPageTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_view_player_edit_page()
    {
        $admin = User::factory()->create(['is_admin' => true, 'email_verified_at' => now()]);
        $this->actingAs($admin);

        $p = \App\Models\Player::create(['name' => 'Joe', 'nationality' => 'India', 'role' => 'batsman']);

        $res = $this->get('/admin/players/' . $p->id . '/edit');
        $res->assertStatus(200);
        $res->assertSee('Admin\\/Players\\/Edit');
        $res->assertSee('"id":'.$p->id);
    }

    public function test_non_admin_cannot_access_player_edit()
    {
        $user = User::factory()->create(['is_admin' => false, 'email_verified_at' => now()]);
        $this->actingAs($user);

        $p = \App\Models\Player::create(['name' => 'Other', 'nationality' => 'India', 'role' => 'batsman']);

        $res = $this->get('/admin/players/' . $p->id . '/edit');
        $res->assertStatus(403);
    }
}
