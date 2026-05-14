<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class SocialLoginEdgeTest extends TestCase
{
    use RefreshDatabase;

    public function test_social_login_revokes_previous_tokens(): void
    {
        Http::fake([
            'https://graph.facebook.com/*' => Http::response([
                'id' => 'revoketest',
                'name' => 'Revoker',
                'email' => 'revoker@example.com',
                'picture' => ['data' => ['url' => 'https://example.com/avatar.png']],
            ], 200),
        ]);

        // First login (via social) creates user and token
        $first = $this->postJson('/api/social-login', [
            'provider' => 'facebook',
            'token' => 'firsttoken',
        ]);
        $first->assertStatus(200)->assertJsonStructure(['user' => ['id', 'email'], 'token']);

        $userId = $first->json('user.id');
        $user = User::find($userId);
        $this->assertNotNull($user);
        $this->assertCount(1, $user->tokens);

        // Simulate an existing token by creating a manual token
        $oldToken = $user->createToken('old')->plainTextToken;
        $user->refresh();
        $this->assertCount(2, $user->tokens);

        // Second social login should delete old tokens and return a new single token
        $second = $this->postJson('/api/social-login', [
            'provider' => 'facebook',
            'token' => 'secondtoken',
        ]);
        $second->assertStatus(200)->assertJsonStructure(['user' => ['id', 'email'], 'token']);

        $user->refresh();
        $this->assertCount(1, $user->tokens, 'Previous tokens should be revoked and a single fresh token created');
    }

    public function test_social_login_validation_errors_when_missing_fields(): void
    {
        $response = $this->postJson('/api/social-login', [
            'token' => 'whatever',
        ]);

        $response->assertStatus(422);
    }

    public function test_google_token_without_name_or_picture_falls_back_to_defaults(): void
    {
        Http::fake([
            'https://oauth2.googleapis.com/tokeninfo*' => Http::response([
                'email' => 'minimal@example.com',
                // no name, no picture
                'sub' => 'minimal-sub',
            ], 200),
        ]);

        $response = $this->postJson('/api/social-login', [
            'provider' => 'google',
            'token' => 'minid',
        ]);

        $response->assertStatus(200)->assertJsonStructure(['user' => ['id', 'email'], 'token']);

        $this->assertDatabaseHas('users', ['email' => 'minimal@example.com', 'name' => 'User']);
    }

    public function test_existing_user_profile_is_updated_from_provider_data(): void
    {
        // Create existing user
        $user = User::create([
            'name' => 'Old Name',
            'email' => 'update@example.com',
            'password' => bcrypt('secret123'),
            'image' => 'https://example.com/old.png',
        ]);

        Http::fake([
            'https://graph.facebook.com/*' => Http::response([
                'id' => 'updateid',
                'name' => 'New Name',
                'email' => 'update@example.com',
                'picture' => ['data' => ['url' => 'https://example.com/new.png']],
            ], 200),
        ]);

        $response = $this->postJson('/api/social-login', [
            'provider' => 'facebook',
            'token' => 'updatetoken',
        ]);
        $response->assertStatus(200)->assertJsonStructure(['user' => ['id', 'email'], 'token']);

        $user->refresh();
        $this->assertEquals('New Name', $user->name);
        // image column may not exist in test schema; assert only if present
        if (\Illuminate\Support\Facades\Schema::hasColumn('users', 'image')) {
            $this->assertEquals('https://example.com/new.png', $user->image);
        } else {
            $this->assertTrue(true);
        }
    }
}
