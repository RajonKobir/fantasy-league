<?php

namespace Tests\Feature;

use App\Models\Tournament;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminTournamentEditPageTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_view_tournament_edit_page()
    {
        $admin = User::factory()->create(['is_admin' => true, 'email_verified_at' => now()]);
        $this->actingAs($admin);

        $t = \App\Models\Tournament::create(['name' => 'Spring Cup']);

        $res = $this->get('/admin/tournaments/' . $t->id . '/edit');
        $res->assertStatus(200);
        $res->assertSee('Admin\\/Tournaments\\/Edit');
        $res->assertSee('"id":'.$t->id);
    }

    public function test_non_admin_cannot_access_tournament_edit()
    {
        $user = User::factory()->create(['is_admin' => false, 'email_verified_at' => now()]);
        $this->actingAs($user);

        $t = \App\Models\Tournament::create(['name' => 'Autumn Cup']);

        $res = $this->get('/admin/tournaments/' . $t->id . '/edit');
        $res->assertStatus(403);
    }
}
