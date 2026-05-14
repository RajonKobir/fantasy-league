<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;
use App\Models\User;
use App\Models\Player;

class ApiImageUploadTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_create_player_via_api_with_capitalized_role_and_image()
    {
        Storage::fake('public');

        $admin = User::factory()->create(['is_admin' => 1]);

        $file = UploadedFile::fake()->image('player.jpg');

        $resp = $this->actingAs($admin, 'sanctum')
            ->post(route('api.players.store'), ['name' => 'API Player', 'role' => 'Batsman', 'nationality' => 'T1', 'image' => $file]);

        $resp->assertStatus(201);

        $this->assertTrue(Storage::disk('public')->exists('players/'.$file->hashName()));
        $this->assertDatabaseHas('players', ['name' => 'API Player', 'role' => 'batsman']);
        $player = Player::where('name', 'API Player')->first();
        $this->assertNotEmpty($player->image_url);
    }

    public function test_invalid_role_removes_uploaded_file_on_api_create()
    {
        Storage::fake('public');

        $admin = User::factory()->create(['is_admin' => 1]);

        $file = UploadedFile::fake()->image('player2.jpg');

        $resp = $this->actingAs($admin, 'sanctum')
            ->post(route('api.players.store'), ['name' => 'Bad API Player', 'role' => 'InvalidRole', 'nationality' => 'T1', 'image' => $file]);

        $resp->assertStatus(422);

        $this->assertFalse(Storage::disk('public')->exists('players/'.$file->hashName()));
        $this->assertDatabaseMissing('players', ['name' => 'Bad API Player']);
    }
}
