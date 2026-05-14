<?php

namespace Tests\Feature;

use App\Models\Player;
use App\Models\Team;
use App\Models\Tournament;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminSearchPaginationTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_search_users()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $matching = User::factory()->create(['name' => 'Alice Wonderland', 'email' => 'alice@example.com']);
        $other = User::factory()->create(['name' => 'Bob Builder', 'email' => 'bob@example.com']);

        $res = $this->get('/admin/users?q=Alice');
        $res->assertStatus(200);
        $res->assertSee('Alice Wonderland');
        $res->assertDontSee('Bob Builder');
    }

    public function test_admin_can_search_teams_by_name_or_owner()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $owner = User::factory()->create(['name' => 'Owner Name']);
        $this->actingAs($admin);

        $teamA = Team::create(['name' => 'Blue Rockets', 'user_id' => $owner->id]);
        $teamB = Team::create(['name' => 'Red Rockets', 'user_id' => $admin->id]);

        $res = $this->get('/admin/teams?q=Blue');
        $res->assertStatus(200);
        $res->assertSee('Blue Rockets');
        $res->assertDontSee('Red Rockets');

        $res2 = $this->get('/admin/teams?q=Owner');
        $res2->assertStatus(200);
        $res2->assertSee('Blue Rockets');
    }

    public function test_admin_can_search_players_by_name_or_team()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $p1 = Player::create(['name' => 'John Doe', 'nationality' => 'Alpha', 'role' => 'batsman']);
        $p2 = Player::create(['name' => 'Jane Roe', 'nationality' => 'Beta', 'role' => 'bowler']);

        $res = $this->get('/admin/players?q=Alpha');
        $res->assertStatus(200);
        $res->assertSee('John Doe');
        $res->assertDontSee('Jane Roe');
    }

    public function test_admin_can_search_tournaments()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $t1 = Tournament::create(['name' => 'Winter Cup']);
        $t2 = Tournament::create(['name' => 'Summer Bash']);

        $res = $this->get('/admin/tournaments?q=Winter');
        $res->assertStatus(200);
        $res->assertSee('Winter Cup');
        $res->assertDontSee('Summer Bash');
    }

    public function test_api_can_search_players()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin, 'sanctum');

        $p1 = Player::create(['name' => 'Alpha One', 'nationality' => 'Alpha', 'role' => 'batsman']);
        $p2 = Player::create(['name' => 'Beta Two', 'nationality' => 'Beta', 'role' => 'bowler']);

        $res = $this->getJson('/api/players?q=Alpha');
        $res->assertStatus(200)->assertJson(['success' => true]);
        $data = $res->json('data.data');
        $this->assertCount(1, $data);
        $this->assertEquals('Alpha One', $data[0]['name']);
    }

    public function test_api_can_search_teams()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $owner = User::factory()->create(['name' => 'Team Owner']);
        $this->actingAs($admin, 'sanctum');

        $teamA = Team::create(['name' => 'Blue Rockets', 'user_id' => $owner->id]);
        $teamB = Team::create(['name' => 'Red Rockets', 'user_id' => $admin->id]);

        $res = $this->getJson('/api/teams?q=Blue');
        $res->assertStatus(200)->assertJson(['success' => true]);
        $data = $res->json('data.data');
        $this->assertCount(1, $data);
        $this->assertEquals('Blue Rockets', $data[0]['name']);
    }

    public function test_api_can_search_tournaments()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin, 'sanctum');

        $t1 = Tournament::create(['name' => 'Winter Cup']);
        $t2 = Tournament::create(['name' => 'Summer Bash']);

        $res = $this->getJson('/api/tournaments?q=Winter');
        $res->assertStatus(200)->assertJson(['success' => true]);
        $data = $res->json('data.data');
        $this->assertCount(1, $data);
        $this->assertEquals('Winter Cup', $data[0]['name']);
    }
}
