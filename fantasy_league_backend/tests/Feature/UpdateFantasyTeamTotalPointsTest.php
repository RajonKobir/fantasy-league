<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use App\Models\Tournament;
use App\Models\Player;
use App\Models\MatchPlayerPoints;
use App\Models\FantasyTeam;
use App\Models\GameMatch;
use App\Models\User;

class UpdateFantasyTeamTotalPointsTest extends TestCase
{
    use RefreshDatabase;

    public function test_multipliers_are_stored_and_applied_during_update()
    {
        // Create tournament with explicit multipliers
        $tournament = Tournament::create([
            'name' => 'Multiplier Cup',
            'start_at' => now(),
            'end_at' => now()->addDays(7),
            'entry_fee' => 0,
            'required_players' => 11,
            'captain_multiplier' => 3.0,
            'vice_captain_multiplier' => 2.0,
            'status' => 'running',
        ]);

        // Create two players (ensure required fields)
        $p1 = Player::create(['name' => 'Player 1', 'role' => 'batsman', 'nationality' => 'X']);
        $p2 = Player::create(['name' => 'Player 2', 'role' => 'bowler', 'nationality' => 'Y']);

        // Create a match in this tournament
        $match = GameMatch::create([
            'tournament_id' => $tournament->id,
            'start_time' => now(),
            'status' => 'completed',
        ]);

        // Give points: p1=10, p2=5
        MatchPlayerPoints::create([
            'game_match_id' => $match->id,
            'tournament_id' => $tournament->id,
            'player_id' => $p1->id,
            'points' => 10,
        ]);

        MatchPlayerPoints::create([
            'game_match_id' => $match->id,
            'tournament_id' => $tournament->id,
            'player_id' => $p2->id,
            'points' => 5,
        ]);

        // Create a user and a fantasy team with captain p1 and vice p2
        $user = User::factory()->create();

        $team = FantasyTeam::create([
            'tournament_id' => $tournament->id,
            'user_id' => $user->id,
            'player_ids' => [$p1->id, $p2->id],
            'name' => 'Test Team',
            'captain_id' => $p1->id,
            'vice_captain_id' => $p2->id,
            'total_points' => 0,
            'status' => 'approved',
        ]);

        // Confirm multipliers are persisted in DB
        $this->assertDatabaseHas('tournaments', [
            'id' => $tournament->id,
            'captain_multiplier' => 3.0,
            'vice_captain_multiplier' => 2.0,
        ]);

        // Run the artisan command for this tournament
        $this->artisan('fantasy-teams:update-total-points', ['--tournament_id' => $tournament->id, '--batch' => 100])
            ->assertExitCode(0);

        // Refresh team and assert points calculation:
        // base = 10 + 5 = 15
        // captain bonus = 10 * (3.0 - 1) = 20
        // vice bonus = 5 * (2.0 - 1) = 5
        // total = 15 + 20 + 5 = 40

        $team->refresh();
        $this->assertEquals(40, $team->total_points, 'Expected total_points to include captain/vice multipliers');
    }
}
