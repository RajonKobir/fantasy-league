<?php

namespace Tests\Feature;

use App\Models\Player;
use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminTeamSelectionsTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_set_team_selections_and_captains()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $team = Team::create(['name' => 'Admin Team', 'user_id' => $admin->id]);

        // create 11 players
        $players = [];
        $roles = ['batsman','bowler','all-rounder','wicket-keeper'];
        for ($i = 1; $i <= 11; $i++) {
            $players[] = Player::create([
                'name' => 'Player '.$i,
                'nationality' => 'Testers',
                'role' => $roles[$i % count($roles)],
            ]);
        }
        $playerIds = array_map(fn($p) => $p->id, $players);

        $captain = $players[0];
        $vice = $players[1];

        $this->actingAs($admin);

        $resp = $this->post(route('admin.teams.selections.update', $team->id), [
            'player_ids' => $playerIds,
            'captain_id' => $captain->id,
            'vice_captain_id' => $vice->id,
        ]);

        $resp->assertRedirect(route('admin.teams.index'));

        $team->refresh();
        $this->assertCount(11, $team->selections);
        $this->assertTrue($team->selections()->where('captain', true)->exists());
        $this->assertTrue($team->selections()->where('vice_captain', true)->exists());

        $this->assertEquals($captain->id, $team->selections()->where('captain', true)->first()->player_id);
        $this->assertEquals($vice->id, $team->selections()->where('vice_captain', true)->first()->player_id);
    }

    public function test_updating_selections_triggers_recalculation_of_team_points()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $t = \App\Models\Tournament::create(['name' => 'Recalc Cup']);

        // create 11 players
        $players = [];
        $roles = ['batsman','bowler','all-rounder','wicket-keeper'];
        for ($i = 1; $i <= 11; $i++) {
            $players[] = Player::create([
                'name' => 'Player '.$i,
                'nationality' => 'Testers',
                'role' => $roles[$i % count($roles)],
            ]);
        }
        $playerIds = array_map(fn($p) => $p->id, $players);

        $captain = $players[0];
        $vice = $players[1];

        // set player points for tournament (by creating match points)
        $gameMatch = \App\Models\GameMatch::create(['tournament_id' => $t->id, 'team_a_id' => null, 'team_b_id' => null, 'start_time' => now()]);
        \App\Models\MatchPlayerPoints::create(['game_match_id' => $gameMatch->id, 'tournament_id' => $t->id, 'player_id' => $captain->id, 'points' => 10]);
        \App\Models\MatchPlayerPoints::create(['game_match_id' => $gameMatch->id, 'tournament_id' => $t->id, 'player_id' => $vice->id, 'points' => 5]);
        \App\Models\MatchPlayerPoints::create(['game_match_id' => $gameMatch->id, 'tournament_id' => $t->id, 'player_id' => $players[2]->id, 'points' => 3]);

        $team = Team::create(['name' => 'Duo Team', 'user_id' => $admin->id, 'tournament_id' => $t->id]);

        $resp = $this->post(route('admin.teams.selections.update', $team->id), [
            'player_ids' => $playerIds,
            'captain_id' => $captain->id,
            'vice_captain_id' => $vice->id,
        ]);

        $resp->assertRedirect(route('admin.teams.index'));

        $team->refresh();

        // expected score: captain (10*2) + vice (5*2) + player 3 (3) + others (0)
        $expected = 10*2 + 5*2 + 3;

        $this->assertEquals($expected, $team->points);
    }

    public function test_rejects_wrong_number_of_players()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $team = Team::create(['name' => 'Small Team', 'user_id' => $admin->id]);

        // create only 10 players
        $players = [];
        for ($i = 1; $i <= 10; $i++) {
            $players[] = Player::create(['name' => 'P'.$i, 'nationality' => 'X', 'role' => 'batsman']);
        }
        $playerIds = array_map(fn($p) => $p->id, $players);

        $this->actingAs($admin);
        $resp = $this->post(route('admin.teams.selections.update', $team->id), [
            'player_ids' => $playerIds,
            'captain_id' => $playerIds[0],
            'vice_captain_id' => $playerIds[1],
        ]);

        $resp->assertSessionHasErrors('player_ids');
        $this->assertEquals(0, $team->selections()->count());
    }

    public function test_rejects_captain_not_in_selection()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $team = Team::create(['name' => 'Team Z', 'user_id' => $admin->id]);

        // create 11 players
        $players = [];
        for ($i = 1; $i <= 11; $i++) {
            $players[] = Player::create(['name' => 'P'.$i, 'nationality' => 'X', 'role' => 'batsman']);
        }
        $playerIds = array_map(fn($p) => $p->id, $players);

        $this->actingAs($admin);
        // set captain to a player not included (id + 100)
        $resp = $this->post(route('admin.teams.selections.update', $team->id), [
            'player_ids' => $playerIds,
            'captain_id' => $playerIds[0] + 100,
            'vice_captain_id' => $playerIds[1],
        ]);

        $resp->assertSessionHasErrors('captain_id');
        $this->assertEquals(0, $team->selections()->count());
    }

    public function test_rejects_duplicate_captain_and_vice()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $team = Team::create(['name' => 'Team Y', 'user_id' => $admin->id]);

        $players = [];
        for ($i = 1; $i <= 11; $i++) {
            $players[] = Player::create(['name' => 'P'.$i, 'nationality' => 'X', 'role' => 'batsman']);
        }
        $playerIds = array_map(fn($p) => $p->id, $players);

        $this->actingAs($admin);
        $resp = $this->post(route('admin.teams.selections.update', $team->id), [
            'player_ids' => $playerIds,
            'captain_id' => $playerIds[0],
            'vice_captain_id' => $playerIds[0],
        ]);

        $resp->assertSessionHas('error');
        $this->assertEquals(0, $team->selections()->count());
    }
}

