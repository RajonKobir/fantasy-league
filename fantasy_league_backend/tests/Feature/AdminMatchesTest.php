<?php

namespace Tests\Feature;

use App\Models\GameMatch;
use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminMatchesTest extends TestCase
{
    use RefreshDatabase;

    public function test_guest_is_redirected_from_matches_index()
    {
        $res = $this->get('/admin/game-matches');

        $res->assertRedirect('/login');
    }

    public function test_admin_can_view_matches_index_and_create_page()
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin);

        $this->get('/admin/game-matches')->assertStatus(200);
        $this->get('/admin/game-matches/create')->assertStatus(200);
    }

    public function test_admin_can_create_match()
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin);

        $payload = [
            'team_a' => 'Alpha XI',
            'team_b' => 'Bravo XI',
            'start_time' => now()->addDay()->toDateTimeString(),
            'status' => 'upcoming',
        ];

        $res = $this->post('/admin/game-matches', $payload);

        $res->assertRedirect('/admin/game-matches');

        $this->assertDatabaseHas('game_matches', [
            'status' => 'upcoming',
        ]);

        // Ensure teams were created
        $this->assertDatabaseHas('teams', ['name' => 'Alpha XI']);
        $this->assertDatabaseHas('teams', ['name' => 'Bravo XI']);
    }

    public function test_admin_can_edit_and_update_match()
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin);

        // create teams and match
        $teamA = Team::create(['name' => 'Alpha XI', 'user_id' => $admin->id]);
        $teamB = Team::create(['name' => 'Bravo XI', 'user_id' => $admin->id]);

        $match = GameMatch::create([
            'team_a_id' => $teamA->id,
            'team_b_id' => $teamB->id,
            'start_time' => now()->toDateTimeString(),
            'status' => 'upcoming',
            'venue_id' => null,
        ]);

        $this->get('/admin/game-matches/'.$match->id.'/edit')->assertStatus(200);

        $update = [
            'team_a' => 'Alpha XI Updated',
            'team_b' => 'Bravo XI',
            'start_time' => now()->addHours(2)->toDateTimeString(),
            'status' => 'live',
        ];

        $res = $this->put('/admin/game-matches/'.$match->id, $update);
        $res->assertRedirect('/admin/game-matches');

        $this->assertDatabaseHas('game_matches', ['id' => $match->id, 'status' => 'live']);
        $this->assertDatabaseHas('teams', ['name' => 'Alpha XI Updated']);
    }

    public function test_admin_can_delete_match()
    {
        $admin = User::factory()->create(['is_admin' => true]);

        $this->actingAs($admin);

        $teamA = Team::create(['name' => 'Alpha XI', 'user_id' => $admin->id]);
        $teamB = Team::create(['name' => 'Bravo XI', 'user_id' => $admin->id]);

        $match = GameMatch::create([
            'team_a_id' => $teamA->id,
            'team_b_id' => $teamB->id,
            'start_time' => now()->toDateTimeString(),
            'status' => 'upcoming',
        ]);

        $res = $this->delete('/admin/game-matches/'.$match->id);
        $res->assertRedirect('/admin/game-matches');

        $this->assertDatabaseMissing('game_matches', ['id' => $match->id]);
    }
}
