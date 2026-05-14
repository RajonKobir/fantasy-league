<?php

namespace Tests\Feature;

use App\Models\Player;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdminPlayerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_admin_can_create_player_with_image()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin, 'sanctum');

        $file = UploadedFile::fake()->image('player.jpg');

        $response = $this->postJson('/api/players', [
            'name' => 'Test Player',
            'role' => 'batsman',
            'nationality' => 'Team A',
            'image' => $file,
        ]);

        $response->assertStatus(201)->assertJson(['success' => true]);

        $player = Player::first();
        $this->assertNotNull($player);
        $this->assertStringContainsString('/storage/players/', $player->image_url);

        // ensure file stored
        $this->assertTrue(Storage::disk('public')->exists(str_replace('/storage/', '', $player->image_url)));
    }

    public function test_admin_can_create_player_with_country_id()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin, 'sanctum');

        $country = \App\Models\Country::create(['name' => 'Narnia']);

        $response = $this->postJson('/api/players', [
            'name' => 'Country Player',
            'role' => 'batsman',
            'country_id' => $country->id,
        ]);

        $response->assertStatus(201)->assertJson(['success' => true]);

        $player = Player::where('name', 'Country Player')->first();
        $this->assertNotNull($player);
        $this->assertEquals('Narnia', $player->nationality);
        $this->assertEquals($country->id, $player->country_id);
    }

    public function test_admin_can_update_and_delete_player()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin, 'sanctum');

        $player = Player::create(['name' => 'Old Player', 'nationality' => 'Team X', 'role' => 'batsman']);

        $file = UploadedFile::fake()->image('new.jpg');

        $update = $this->putJson('/api/players/'.$player->id, [
            'name' => 'Updated Name',
            'image' => $file,
        ]);

        $update->assertStatus(200)->assertJson(['success' => true]);

        $player->refresh();
        $this->assertEquals('Updated Name', $player->name);
        $this->assertStringContainsString('/storage/players/', $player->image_url);

        // delete
        $delete = $this->deleteJson('/api/players/'.$player->id);
        $delete->assertStatus(200)->assertJson(['success' => true]);

        $this->assertDatabaseMissing('players', ['id' => $player->id]);
    }
}
