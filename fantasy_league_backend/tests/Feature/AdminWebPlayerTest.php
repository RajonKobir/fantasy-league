<?php

namespace Tests\Feature;

use App\Models\Player;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdminWebPlayerTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_admin_can_create_player_with_image_via_web()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $file = UploadedFile::fake()->image('player_web.jpg');

        $response = $this->post(route('admin.players.store'), [
            'name' => 'Web Player',
            'role' => 'batsman',
            'nationality' => 'Team Web',
            'image' => $file,
        ]);

        $response->assertRedirect(route('admin.players.index'));

        $player = Player::first();
        $this->assertNotNull($player);
        $this->assertStringContainsString('/storage/players/', $player->image_url);
        Storage::disk('public')->assertExists(str_replace('/storage/', '', $player->image_url));
    }
}
