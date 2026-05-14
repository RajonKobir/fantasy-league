<?php

namespace Tests\Feature;

use App\Models\GameMatch;
use App\Models\Player;
use App\Models\Team;
use App\Models\Tournament;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class CreateTeamTest extends TestCase
{
    use RefreshDatabase;

    public function test_create_team_requires_exact_11_players()
    {
        $user = User::factory()->create();
        // create two teams required for a match
        $t1 = Team::create(['name' => 'Team A', 'user_id' => $user->id]);
        $t2 = Team::create(['name' => 'Team B', 'user_id' => $user->id]);

        $match = GameMatch::create(['team_a_id' => $t1->id, 'team_b_id' => $t2->id, 'start_time' => now(), 'venue_id' => null]);

        $players = [];
        for ($i = 0; $i < 10; $i++) {
            $players[] = Player::create(['name' => "Player $i", 'nationality' => 'Team A', 'role' => 'batsman']);
        }

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/teams', [
            'name' => 'Test Team',
            'game_match_id' => $match->id,
            'player_ids' => array_map(function ($p) {
                return $p->id;
            }, $players),
            'captain_id' => $players[0]->id,
            'vice_captain_id' => $players[1]->id,
        ]);

        $response->assertStatus(422);
    }

    public function test_captain_must_be_in_selected_players()
    {
        $user = User::factory()->create();
        $t1 = Team::create(['name' => 'Team A', 'user_id' => $user->id]);
        $t2 = Team::create(['name' => 'Team B', 'user_id' => $user->id]);

        $match = GameMatch::create(['team_a_id' => $t1->id, 'team_b_id' => $t2->id, 'start_time' => now()]);

        $players = [];
        for ($i = 0; $i < 11; $i++) {
            $players[] = Player::create(['name' => "Player $i", 'nationality' => 'Team A', 'role' => 'batsman']);
        }

        // Use a captain ID that is NOT in the players array
        $notInList = Player::create(['name' => 'Other', 'nationality' => 'Team B', 'role' => 'bowler']);

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/teams', [
            'name' => 'Test Team 2',
            'game_match_id' => $match->id,
            'player_ids' => array_map(fn ($p) => $p->id, $players),
            'captain_id' => $notInList->id,
            'vice_captain_id' => $players[1]->id,
        ]);

        $response->assertStatus(422);
    }

    public function test_valid_team_creation_creates_selections_and_flags()
    {
        $user = User::factory()->create();
        $t1 = Team::create(['name' => 'Team A', 'user_id' => $user->id]);
        $t2 = Team::create(['name' => 'Team B', 'user_id' => $user->id]);

        $match = GameMatch::create(['team_a_id' => $t1->id, 'team_b_id' => $t2->id, 'start_time' => now(), 'venue_id' => null]);

        $players = [];
        for ($i = 0; $i < 11; $i++) {
            $players[] = Player::create(['name' => "Player $i", 'nationality' => 'Team A', 'role' => 'batsman']);
        }

        $captainId = $players[0]->id;
        $viceCaptainId = $players[1]->id;

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/teams', [
            'name' => 'Valid Team',
            'game_match_id' => $match->id,
            'player_ids' => array_map(fn ($p) => $p->id, $players),
            'captain_id' => $captainId,
            'vice_captain_id' => $viceCaptainId,
        ]);

        if ($response->status() !== 201) {
            echo "DEBUG RESPONSE: " . print_r($response->json(), true) . "\n";
        }

        $response->assertStatus(201);
        $this->assertDatabaseHas('teams', ['name' => 'Valid Team']);
        $teamId = $response->json('data.id');
        $this->assertDatabaseHas('player_selections', ['team_id' => $teamId, 'player_id' => $captainId, 'captain' => 1]);
        $this->assertDatabaseHas('player_selections', ['team_id' => $teamId, 'player_id' => $viceCaptainId, 'vice_captain' => 1]);
        $this->assertEquals(11, DB::table('player_selections')->where('team_id', $teamId)->count());
    }

    public function test_team_creation_deducts_entry_fee()
    {
        $user = User::factory()->create();
        $user->wallet_balance = 100.00;
        $user->save();

        $t1 = Team::create(['name' => 'Team A', 'user_id' => $user->id]);
        $t2 = Team::create(['name' => 'Team B', 'user_id' => $user->id]);

        $match = GameMatch::create(['team_a_id' => $t1->id, 'team_b_id' => $t2->id, 'start_time' => now(), 'venue_id' => null]);

        $tournament = Tournament::create(['name' => 'Paid Cup', 'entry_fee' => 25.00]);

        $players = [];
        for ($i = 0; $i < 11; $i++) {
            $players[] = Player::create(['name' => "Player $i", 'nationality' => 'Team A', 'role' => 'batsman']);
        }

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/teams', [
            'name' => 'Paid Team',
            'game_match_id' => $match->id,
            'tournament_id' => $tournament->id,
            'player_ids' => array_map(fn ($p) => $p->id, $players),
            'captain_id' => $players[0]->id,
            'vice_captain_id' => $players[1]->id,
        ]);

        $response->assertStatus(201);
        $user->refresh();
        $this->assertEquals(75.00, (float) $user->wallet_balance);
        $this->assertDatabaseHas('transactions', ['user_id' => $user->id, 'type' => 'DEBIT', 'amount' => 25.00]);
    }

    public function test_team_creation_fails_on_insufficient_balance()
    {
        $user = User::factory()->create();
        $user->wallet_balance = 5.00;
        $user->save();

        $t1 = Team::create(['name' => 'Team A', 'user_id' => $user->id]);
        $t2 = Team::create(['name' => 'Team B', 'user_id' => $user->id]);

        $match = GameMatch::create(['team_a_id' => $t1->id, 'team_b_id' => $t2->id, 'start_time' => now(), 'venue_id' => null]);

        $tournament = Tournament::create(['name' => 'Expensive Cup', 'entry_fee' => 50.00]);

        $players = [];
        for ($i = 0; $i < 11; $i++) {
            $players[] = Player::create(['name' => "Player $i", 'nationality' => 'Team A', 'role' => 'batsman']);
        }

        $response = $this->actingAs($user, 'sanctum')->postJson('/api/teams', [
            'name' => 'Paid Team',
            'game_match_id' => $match->id,
            'tournament_id' => $tournament->id,
            'player_ids' => array_map(fn ($p) => $p->id, $players),
            'captain_id' => $players[0]->id,
            'vice_captain_id' => $players[1]->id,
        ]);

        $response->assertStatus(402)->assertJson(['success' => false]);
    }

    public function test_user_can_create_multiple_teams_for_same_tournament_and_wallet_is_deducted_for_each()
    {
        $user = User::factory()->create();
        $user->wallet_balance = 200.00;
        $user->save();

        $tournament = Tournament::create(['name' => 'Multi Team Cup', 'entry_fee' => 50.00]);

        $players = [];
        for ($i = 0; $i < 11; $i++) {
            $players[] = Player::create(['name' => "Player $i", 'nationality' => 'Team A', 'role' => 'batsman']);
        }

        // First team
        $response1 = $this->actingAs($user, 'sanctum')->postJson('/api/fantasy-teams', [
            'name' => 'First Team',
            'tournament_id' => $tournament->id,
            'player_ids' => array_map(fn ($p) => $p->id, $players),
            'captain_id' => $players[0]->id,
            'vice_captain_id' => $players[1]->id,
        ]);

        $response1->assertStatus(201);

        // Second team should also be allowed
        $response2 = $this->actingAs($user, 'sanctum')->postJson('/api/fantasy-teams', [
            'name' => 'Second Team',
            'tournament_id' => $tournament->id,
            'player_ids' => array_map(fn ($p) => $p->id, $players),
            'captain_id' => $players[0]->id,
            'vice_captain_id' => $players[1]->id,
        ]);

        $response2->assertStatus(201);

        $user->refresh();
        $this->assertEquals(100.00, (float) $user->wallet_balance);

        $this->assertDatabaseCount('fantasy_teams', 2);
        $this->assertDatabaseHas('transactions', ['user_id' => $user->id, 'type' => 'DEBIT', 'amount' => 50.00]);
    }
}
