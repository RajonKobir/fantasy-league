<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;
use App\Models\User;
use App\Models\Player;
use App\Models\Team;
use App\Models\Tournament;

class AdminImageUploadTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_upload_player_image_on_update()
    {
        Storage::fake('public');

        $admin = User::factory()->create(['is_admin' => 1]);
        $player = Player::create(['name' => 'P1', 'role' => 'batsman', 'nationality' => 'T1']);

        $file = UploadedFile::fake()->image('player.jpg');

        $this->actingAs($admin)
            ->put(route('admin.players.update', $player->id), ['image' => $file, 'name' => 'P1'])
            ->assertRedirect(route('admin.players.index'));

        // assert saved under players/{id} folder
        $this->assertTrue(Storage::disk('public')->exists("players/{$player->id}/{$file->hashName()}"));
    }

    public function test_admin_can_upload_team_logo_on_update()
    {
        Storage::fake('public');

        $admin = User::factory()->create(['is_admin' => 1]);
        $team = Team::create(['name' => 'Team X', 'user_id' => $admin->id]);

        $file = UploadedFile::fake()->image('team.png');

        $this->actingAs($admin)
            ->put(route('admin.teams.update', $team->id), ['logo' => $file, 'name' => 'Team X'])
            ->assertRedirect(route('admin.teams.index'));

        $this->assertTrue(Storage::disk('public')->exists("teams/{$team->id}/{$file->hashName()}"));
    }

    public function test_admin_can_upload_tournament_logo_on_update()
    {
        Storage::fake('public');

        $admin = User::factory()->create(['is_admin' => 1]);
        $t = Tournament::create(['name' => 'T1']);

        $file = UploadedFile::fake()->image('tourn.jpg');

        $this->actingAs($admin)
            ->put(route('admin.tournaments.update', $t->id), ['logo' => $file, 'name' => 'T1'])
            ->assertRedirect(route('admin.tournaments.index'));

        $this->assertTrue(Storage::disk('public')->exists("tournaments/{$t->id}/{$file->hashName()}"));
    }

    public function test_admin_can_upload_user_avatar_on_update()
    {
        Storage::fake('public');

        $admin = User::factory()->create(['is_admin' => 1]);
        $user = User::factory()->create();

        $file = UploadedFile::fake()->image('avatar.jpg');

        $this->actingAs($admin)
            ->put(route('admin.users.update', $user->id), ['avatar' => $file, 'name' => $user->name, 'email' => $user->email])
            ->assertRedirect(route('admin.users.index'));

        $this->assertTrue(Storage::disk('public')->exists('avatars/'.$user->id.'/'.$file->hashName()));
    }

    public function test_admin_can_create_player_with_capitalized_role_and_image()
    {
        Storage::fake('public');

        $admin = User::factory()->create(['is_admin' => 1]);

        $file = UploadedFile::fake()->image('player.jpg');

        $this->actingAs($admin)
            ->post(route('admin.players.store'), ['name' => 'Test Player', 'role' => 'Batsman', 'nationality' => 'T1', 'image' => $file])
            ->assertRedirect(route('admin.players.index'));

        $this->assertTrue(Storage::disk('public')->exists('players/'.$file->hashName()));
        $this->assertDatabaseHas('players', ['name' => 'Test Player', 'role' => 'batsman']);
        $player = Player::where('name', 'Test Player')->first();
        $this->assertNotEmpty($player->image_url);
    }

    public function test_invalid_role_removes_uploaded_file_on_create()
    {
        Storage::fake('public');

        $admin = User::factory()->create(['is_admin' => 1]);

        $file = UploadedFile::fake()->image('player2.jpg');

        $this->actingAs($admin)
            ->post(route('admin.players.store'), ['name' => 'Bad Player', 'role' => 'InvalidRole', 'nationality' => 'T1', 'image' => $file])
            ->assertSessionHasErrors('role');

        $this->assertFalse(Storage::disk('public')->exists('players/'.$file->hashName()));
        $this->assertDatabaseMissing('players', ['name' => 'Bad Player']);
    }

    public function test_remove_avatar_not_deleted_on_validation_error()
    {
        Storage::fake('public');

        $admin = User::factory()->create(['is_admin' => 1]);

        // seed an existing avatar
        $user = User::factory()->create(['avatar_url' => '/storage/avatars/old.png']);
        Storage::disk('public')->put('avatars/old.png', 'dummy');

        // attempt to remove avatar but fail validation (invalid email)
        $this->actingAs($admin)
            ->put(route('admin.users.update', $user->id), ['remove_avatar' => '1', 'email' => 'not-an-email'])
            ->assertSessionHasErrors('email');

        // old file should still exist and DB should be unchanged
        $this->assertTrue(Storage::disk('public')->exists('avatars/old.png'));
        $user->refresh();
        $this->assertNotNull($user->avatar_url);
    }

    public function test_uploaded_avatar_is_deleted_on_validation_error()
    {
        Storage::fake('public');

        $admin = User::factory()->create(['is_admin' => 1]);

        // seed an existing avatar
        $user = User::factory()->create(['avatar_url' => '/storage/avatars/old.png']);
        Storage::disk('public')->put('avatars/old.png', 'dummy');

        $file = UploadedFile::fake()->image('new_avatar.jpg');

        // attempt update with new avatar but fail validation
        $this->actingAs($admin)
            ->put(route('admin.users.update', $user->id), ['avatar' => $file, 'email' => 'not-an-email'])
            ->assertSessionHasErrors('email');

        // new upload should be deleted, old file still exists
        $this->assertFalse(Storage::disk('public')->exists('avatars/'.$user->id.'/'.$file->hashName()));
        $this->assertTrue(Storage::disk('public')->exists('avatars/old.png'));
        $user->refresh();
        $this->assertNotNull($user->avatar_url);
    }

    public function test_admin_can_update_profile_avatar_and_shared_auth_user_is_refreshed()
    {
        Storage::fake('public');

        $admin = User::factory()->create(['is_admin' => 1]);

        $file = UploadedFile::fake()->image('admin_avatar.jpg');

        $response = $this->actingAs($admin)
            ->post(route('admin.profile.update'), ['avatar_url' => $file, 'name' => $admin->name, 'email' => $admin->email]);

        // should redirect to profile.show so shared auth props are refreshed
        $response->assertRedirect(route('admin.profile.show'));

        // expect file saved under avatars/{id} and DB updated
        $this->assertTrue(Storage::disk('public')->exists('avatars/'.$admin->id.'/'.$file->hashName()));
        $this->assertNotNull($admin->refresh()->avatar_url);
        $this->assertStringContainsString('avatars/'.$admin->id.'/', $admin->avatar_url);
    }
}
