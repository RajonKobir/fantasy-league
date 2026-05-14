<?php

namespace Tests\Feature;

use App\Models\GameMatch;
use App\Models\MatchPlayerPoints;
use App\Models\Player;
use App\Models\Tournament;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminMatchPointsUpdateTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test that admin can save player points to match_player_points table
     */
    public function test_admin_can_save_player_points_to_match_player_points()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $tournament = Tournament::create(['name' => 'Test Tournament']);
        $p1 = Player::create(['name' => 'Player 1', 'nationality' => 'India', 'role' => 'batsman']);
        $p2 = Player::create(['name' => 'Player 2', 'nationality' => 'India', 'role' => 'bowler']);
        $p3 = Player::create(['name' => 'Player 3', 'nationality' => 'India', 'role' => 'all-rounder']);

        $gameMatch = GameMatch::create([
            'tournament_id' => $tournament->id,
            'team_a_id' => null,
            'team_b_id' => null,
            'start_time' => now(),
        ]);

        // Admin saves player points for the match
        $response = $this->post(route('admin.game-matches.points.update', $gameMatch->id), [
            'points' => [
                ['player_id' => $p1->id, 'points' => 15, 'note' => 'Great batting'],
                ['player_id' => $p2->id, 'points' => 10, 'note' => 'Good bowling'],
                ['player_id' => $p3->id, 'points' => 8],
            ],
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');

        // Verify all points saved to match_player_points table
        $this->assertDatabaseHas('match_player_points', [
            'game_match_id' => $gameMatch->id,
            'player_id' => $p1->id,
            'points' => 15,
            'note' => 'Great batting',
        ]);

        $this->assertDatabaseHas('match_player_points', [
            'game_match_id' => $gameMatch->id,
            'player_id' => $p2->id,
            'points' => 10,
            'note' => 'Good bowling',
        ]);

        $this->assertDatabaseHas('match_player_points', [
            'game_match_id' => $gameMatch->id,
            'player_id' => $p3->id,
            'points' => 8,
        ]);

        // Verify count of match player points
        $this->assertEquals(3, MatchPlayerPoints::where('game_match_id', $gameMatch->id)->count());
    }

    /**
     * Test that admin can update existing player points
     */
    public function test_admin_can_update_existing_player_points()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $tournament = Tournament::create(['name' => 'Test Tournament']);
        $p1 = Player::create(['name' => 'Player 1', 'nationality' => 'India', 'role' => 'batsman']);
        $p2 = Player::create(['name' => 'Player 2', 'nationality' => 'India', 'role' => 'bowler']);

        $gameMatch = GameMatch::create([
            'tournament_id' => $tournament->id,
            'team_a_id' => null,
            'team_b_id' => null,
            'start_time' => now(),
        ]);

        // Create initial points
        $this->post(route('admin.game-matches.points.update', $gameMatch->id), [
            'points' => [
                ['player_id' => $p1->id, 'points' => 10],
                ['player_id' => $p2->id, 'points' => 8],
            ],
        ]);

        // Verify initial data
        $this->assertDatabaseHas('match_player_points', [
            'game_match_id' => $gameMatch->id,
            'player_id' => $p1->id,
            'points' => 10,
        ]);

        // Admin updates player points
        $response = $this->post(route('admin.game-matches.points.update', $gameMatch->id), [
            'points' => [
                ['player_id' => $p1->id, 'points' => 20, 'note' => 'Updated: excellent performance'],
                ['player_id' => $p2->id, 'points' => 12, 'note' => 'Updated: improved bowling'],
            ],
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');

        // Verify updated data
        $this->assertDatabaseHas('match_player_points', [
            'game_match_id' => $gameMatch->id,
            'player_id' => $p1->id,
            'points' => 20,
            'note' => 'Updated: excellent performance',
        ]);

        $this->assertDatabaseHas('match_player_points', [
            'game_match_id' => $gameMatch->id,
            'player_id' => $p2->id,
            'points' => 12,
            'note' => 'Updated: improved bowling',
        ]);

        // Verify only 2 rows exist (not duplicates)
        $this->assertEquals(2, MatchPlayerPoints::where('game_match_id', $gameMatch->id)->count());
    }

    /**
     * Test that all existing rows are updated when admin changes points and clicks update
     */
    public function test_all_existing_rows_are_updated_when_admin_changes_points()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $tournament = Tournament::create(['name' => 'Test Tournament']);
        $players = collect();
        for ($i = 0; $i < 5; $i++) {
            $players->push(Player::create(['name' => "Player $i", 'nationality' => 'India', 'role' => 'batsman']));
        }

        $gameMatch = GameMatch::create([
            'tournament_id' => $tournament->id,
            'team_a_id' => null,
            'team_b_id' => null,
            'start_time' => now(),
        ]);

        // Initial save
        $initialPoints = $players->map(fn($p, $idx) => [
            'player_id' => $p->id,
            'points' => $idx + 5,
        ])->toArray();

        $this->post(route('admin.game-matches.points.update', $gameMatch->id), [
            'points' => $initialPoints,
        ]);

        // Verify initial count
        $this->assertEquals(5, MatchPlayerPoints::where('game_match_id', $gameMatch->id)->count());

        // Get initial IDs to verify they are updated, not replaced
        $initialIds = MatchPlayerPoints::where('game_match_id', $gameMatch->id)
            ->pluck('id')
            ->sort()
            ->values()
            ->toArray();

        // Update all points with new values
        $updatedPoints = $players->map(fn($p, $idx) => [
            'player_id' => $p->id,
            'points' => ($idx + 10) * 2,
        ])->toArray();

        $response = $this->post(route('admin.game-matches.points.update', $gameMatch->id), [
            'points' => $updatedPoints,
        ]);

        $response->assertRedirect();
        $response->assertSessionHas('success');

        // Verify all values updated
        foreach ($players as $idx => $player) {
            $this->assertDatabaseHas('match_player_points', [
                'game_match_id' => $gameMatch->id,
                'player_id' => $player->id,
                'points' => ($idx + 10) * 2,
            ]);
        }

        // Verify still 5 rows (not 10)
        $this->assertEquals(5, MatchPlayerPoints::where('game_match_id', $gameMatch->id)->count());

        // Verify the IDs are the same (rows were updated, not replaced)
        $updatedIds = MatchPlayerPoints::where('game_match_id', $gameMatch->id)
            ->pluck('id')
            ->sort()
            ->values()
            ->toArray();

        $this->assertEquals($initialIds, $updatedIds);
    }

    /**
     * Test default value of 0 for missing points
     */
    public function test_default_value_is_zero_for_player_points()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $tournament = Tournament::create(['name' => 'Test Tournament']);
        $player1 = Player::create(['name' => 'Player 1', 'nationality' => 'India', 'role' => 'batsman']);

        $gameMatch = GameMatch::create([
            'tournament_id' => $tournament->id,
            'team_a_id' => null,
            'team_b_id' => null,
            'start_time' => now(),
        ]);

        // Save with points = 0 explicitly
        $this->post(route('admin.game-matches.points.update', $gameMatch->id), [
            'points' => [
                ['player_id' => $player1->id, 'points' => 0],
            ],
        ]);

        // Verify stored as 0
        $this->assertDatabaseHas('match_player_points', [
            'game_match_id' => $gameMatch->id,
            'player_id' => $player1->id,
            'points' => 0,
        ]);
    }
}
