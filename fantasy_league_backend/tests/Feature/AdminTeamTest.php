<?php

namespace Tests\Feature;

use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdminTeamTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_admin_can_update_team_logo_and_delete()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin, 'sanctum');

        $user = User::factory()->create();
        $team = Team::create(['name' => 'Alpha Team', 'user_id' => $user->id]);

        $file = UploadedFile::fake()->image('logo.png');

        $response = $this->putJson('/api/teams/'.$team->id, [
            'name' => 'Alpha Renamed',
            'logo' => $file,
        ]);

        $response->assertStatus(200)->assertJson(['success' => true]);

        $team->refresh();
        $this->assertEquals('Alpha Renamed', $team->name);
        $this->assertStringContainsString('/storage/teams/', $team->logo_url);
        $this->assertTrue(Storage::disk('public')->exists(str_replace('/storage/', '', $team->logo_url)));

        // delete
        $del = $this->deleteJson('/api/teams/'.$team->id);
        $del->assertStatus(200)->assertJson(['success' => true]);
        $this->assertDatabaseMissing('teams', ['id' => $team->id]);
    }
}
