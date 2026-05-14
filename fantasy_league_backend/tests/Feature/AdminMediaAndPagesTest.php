<?php

namespace Tests\Feature;

use App\Models\Player;
use App\Models\Team;
use App\Models\Tournament;
use App\Models\MatchPlayerPoints;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdminMediaAndPagesTest extends TestCase
{
    use RefreshDatabase;

    public function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_player_create_and_edit_pages_and_image_upload()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        // pages
        $this->get('/admin/players/create')->assertStatus(200);

        $player = Player::create(['name' => 'P1', 'nationality' => 'T', 'role' => 'batsman']);
        $this->get('/admin/players/'.$player->id.'/edit')->assertStatus(200);

        // upload via web form
        $file = UploadedFile::fake()->image('avatar.jpg');
        $res = $this->post('/admin/players', [
            'name' => 'New Player',
            'role' => 'batsman',
            'nationality' => 'Team A',
            'image' => $file,
        ]);

        $res->assertRedirect('/admin/players');

        $p = Player::where('name', 'New Player')->first();
        $this->assertNotNull($p);
        $this->assertStringContainsString('/storage/players/', $p->image_url);
        $this->assertTrue(Storage::disk('public')->exists(str_replace('/storage/', '', $p->image_url)));
    }

    public function test_team_and_tournament_create_pages_and_logo_upload()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $this->get('/admin/teams/create')->assertStatus(200);
        $this->get('/admin/tournaments/create')->assertStatus(200);

        $file = UploadedFile::fake()->image('logo.png');

        $res = $this->post('/admin/teams', [
            'name' => 'New Team',
            'user_id' => $admin->id,
            'logo' => $file,
        ]);
        $res->assertRedirect('/admin/teams');

        $team = Team::where('name', 'New Team')->first();
        $this->assertNotNull($team);
        $this->assertStringContainsString('/storage/teams/', $team->logo_url);
        $this->assertTrue(Storage::disk('public')->exists(str_replace('/storage/', '', $team->logo_url)));

        $file2 = UploadedFile::fake()->image('tournament.png');
        $res2 = $this->post('/admin/tournaments', [
            'name' => 'New Tournament',
            'logo' => $file2,
        ]);
        $res2->assertRedirect('/admin/tournaments');

        $t = Tournament::where('name', 'New Tournament')->first();
        $this->assertNotNull($t);
        $this->assertStringContainsString('/storage/tournaments/', $t->logo_url);
        $this->assertTrue(Storage::disk('public')->exists(str_replace('/storage/', '', $t->logo_url)));
    }

    public function test_points_create_and_edit_pages_are_accessible()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $this->get('/admin/points/create')->assertStatus(200);

        // create required models for point edit
        $t = Tournament::create(['name' => 'T1', 'start_at' => now(), 'end_at' => now()->addDay()]);
        $p = Player::create(['name' => 'P1', 'nationality' => 'T', 'role' => 'batsman']);
        $gameMatch = \App\Models\GameMatch::create(['tournament_id' => $t->id, 'team_a_id' => null, 'team_b_id' => null, 'start_time' => now()]);
        $point = MatchPlayerPoints::create(['game_match_id' => $gameMatch->id, 'tournament_id' => $t->id, 'player_id' => $p->id, 'points' => 5]);

        $this->get('/admin/points/'.$point->id.'/edit')->assertStatus(200);
    }

    public function test_can_remove_uploaded_images_from_edit_pages()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        // PLAYER
        $file = UploadedFile::fake()->image('player.jpg');
        $this->post('/admin/players', [
            'name' => 'RemP',
            'role' => 'batsman',
            'nationality' => 'T',
            'image' => $file,
        ]);
        $player = Player::where('name', 'RemP')->first();
        $this->assertNotNull($player->image_url);

        $this->put('/admin/players/'.$player->id, ['remove_image' => '1']);
        $player->refresh();
        $this->assertNull($player->image_url);

        // TEAM
        $file2 = UploadedFile::fake()->image('team.png');
        $this->post('/admin/teams', [
            'name' => 'RemTeam',
            'user_id' => $admin->id,
            'logo' => $file2,
        ]);
        $team = Team::where('name', 'RemTeam')->first();
        $this->assertNotNull($team->logo_url);

        $this->put('/admin/teams/'.$team->id, ['remove_logo' => '1']);
        $team->refresh();
        $this->assertNull($team->logo_url);

        // TOURNAMENT
        $file3 = UploadedFile::fake()->image('t.png');
        $this->post('/admin/tournaments', ['name' => 'RemT', 'logo' => $file3]);
        $t = Tournament::where('name', 'RemT')->first();
        $this->assertNotNull($t->logo_url);

        $this->put('/admin/tournaments/'.$t->id, ['remove_logo' => '1']);
        $t->refresh();
        $this->assertNull($t->logo_url);

        // USER avatar
        $file4 = UploadedFile::fake()->image('u.png');
        $user = User::create(['name' => 'Temp User', 'email' => 'temp@example.com', 'password' => bcrypt('secret')]);
        // upload avatar
        $this->put('/admin/users/'.$user->id, ['avatar' => $file4]);
        $user->refresh();
        $this->assertNotNull($user->avatar_url);

        $this->put('/admin/users/'.$user->id, ['remove_avatar' => '1']);
        $user->refresh();
        $this->assertNull($user->avatar_url);
    }
}
