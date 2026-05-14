<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\User;
use App\Models\Player;
use App\Models\Tournament;
use App\Models\Team;
use App\Models\GameMatch;

class AdminEditPagesTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_view_and_update_player_edit()
    {
        $admin = User::factory()->create(['is_admin' => 1]);
        $player = Player::create(['name' => 'Old Name', 'role' => 'batsman', 'nationality' => 'Old Team']);

        $this->actingAs($admin)
            ->get(route('admin.players.edit', $player->id))
            ->assertStatus(200);

        $payload = ['name' => 'New Name', 'role' => 'bowler', 'nationality' => 'New Team'];

        $this->actingAs($admin)
            ->put(route('admin.players.update', $player->id), $payload)
            ->assertRedirect(route('admin.players.index'));

        $this->assertDatabaseHas('players', ['id' => $player->id, 'name' => 'New Name', 'role' => 'bowler', 'nationality' => 'New Team']);
    }

    public function test_admin_can_view_and_update_tournament_edit()
    {
        $admin = User::factory()->create(['is_admin' => 1]);
        $tournament = Tournament::create(['name' => 'Old Tour', 'description' => 'desc']);
        $team = Team::create(['name' => 'Team A', 'user_id' => $admin->id]);

        $this->actingAs($admin)
            ->get(route('admin.tournaments.edit', $tournament->id))
            ->assertStatus(200);

        $payload = ['name' => 'New Tour', 'entry_fee' => 12.5];

        $this->actingAs($admin)
            ->put(route('admin.tournaments.update', $tournament->id), $payload)
            ->assertRedirect(route('admin.tournaments.index'));

        $this->assertDatabaseHas('tournaments', ['id' => $tournament->id, 'name' => 'New Tour', 'entry_fee' => 12.5]);
    }

    public function test_admin_can_view_and_update_game_match_edit()
    {
        $admin = User::factory()->create(['is_admin' => 1]);

        $t1 = Team::create(['name' => 'T1', 'user_id' => $admin->id]);
        $t2 = Team::create(['name' => 'T2', 'user_id' => $admin->id]);

        $match = GameMatch::create(['team_a_id' => $t1->id, 'team_b_id' => $t2->id, 'start_time' => now(), 'status' => 'upcoming', 'venue_id' => null]);

        $this->actingAs($admin)
            ->get(route('admin.game-matches.edit', $match->id))
            ->assertStatus(200);

        $payload = ['team_a' => 'Updated A', 'team_b' => 'Updated B', 'start_time' => now()->addDay()->format('Y-m-d H:i:s'), 'status' => 'live'];

        $this->actingAs($admin)
            ->put(route('admin.game-matches.update', $match->id), $payload)
            ->assertRedirect(route('admin.game-matches.index'));

        $match->refresh();
        $this->assertEquals('live', $match->status);
        $this->assertNotNull($match->teamA);
        $this->assertNotNull($match->teamB);
        $this->assertEquals('Updated A', $match->teamA->name);
        $this->assertEquals('Updated B', $match->teamB->name);
    }
}
