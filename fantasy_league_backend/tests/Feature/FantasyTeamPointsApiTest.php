<?php

namespace Tests\Feature;

use App\Models\FantasyTeam;
use App\Models\MatchPlayerPoints;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class FantasyTeamPointsApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_fetch_points_for_their_fantasy_team()
    {
        $user = User::factory()->create();
        $this->actingAs($user, 'sanctum');

        $t = \App\Models\Tournament::create(['name' => 'Test Tournament', 'start_at' => now(), 'end_at' => now()->addDays(7)]);
        $players = collect();
        for ($i = 0; $i < 11; $i++) {
            $players->push(\App\Models\Player::create(['name' => 'Player '.$i, 'nationality' => 'India', 'role' => 'batsman']));
        }

        $team = FantasyTeam::create([
            'tournament_id' => $t->id,
            'user_id' => $user->id,
            'player_ids' => $players->pluck('id')->toArray(),
            'name' => 'My Team'
        ]);

        // create points for those players (via a game match)
        $gameMatch = \App\Models\GameMatch::create(['tournament_id' => $t->id, 'team_a_id' => null, 'team_b_id' => null, 'start_time' => now()]);
        foreach ($players as $pl) {
            MatchPlayerPoints::create([
                'game_match_id' => $gameMatch->id,
                'tournament_id' => $t->id,
                'player_id' => $pl->id,
                'points' => rand(1, 100),
            ]);
        }

        $res = $this->getJson('/api/me/fantasy-team/points?');
        $res->assertStatus(200);

        $data = $res->json();
        $this->assertArrayHasKey('team', $data);
        $this->assertArrayHasKey('points', $data);
        $this->assertCount(11, $data['points']);
    }

    public function test_user_cannot_fetch_other_users_fantasy_team_points()
    {
        $user = User::factory()->create();
        $other = User::factory()->create();

        $t = \App\Models\Tournament::create(['name' => 'Test Tournament', 'start_at' => now(), 'end_at' => now()->addDays(7)]);
        $players = collect();
        for ($i = 0; $i < 11; $i++) {
            $players->push(\App\Models\Player::create(['name' => 'Player '.$i, 'nationality' => 'India', 'role' => 'batsman']));
        }

        FantasyTeam::create([
            'tournament_id' => $t->id,
            'user_id' => $other->id,
            'player_ids' => $players->pluck('id')->toArray(),
            'name' => 'Other Team'
        ]);

        $this->actingAs($user, 'sanctum');
        $res = $this->getJson('/api/me/fantasy-team/points');
        $res->assertStatus(404);
    }
}
