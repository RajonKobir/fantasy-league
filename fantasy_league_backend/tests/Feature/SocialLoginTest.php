<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class SocialLoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_facebook_social_login_creates_user_and_returns_token(): void
    {
        Http::fake([
            'https://graph.facebook.com/*' => Http::response([
                'id' => '12345',
                'name' => 'Test User',
                'email' => 'test@example.com',
                'picture' => ['data' => ['url' => 'https://example.com/avatar.png']],
            ], 200),
        ]);

        $response = $this->postJson('/api/social-login', [
            'provider' => 'facebook',
            'token' => 'validtoken',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure(['user' => ['id', 'email'], 'token']);

        $this->assertDatabaseHas('users', ['email' => 'test@example.com', 'name' => 'Test User']);
    }

    public function test_google_social_login_creates_user_and_returns_token(): void
    {
        Http::fake([
            'https://oauth2.googleapis.com/tokeninfo*' => Http::response([
                'email' => 'google@example.com',
                'name' => 'Google User',
                'picture' => 'https://example.com/gavatar.png',
                'sub' => 'google-sub-1',
            ], 200),
        ]);

        $response = $this->postJson('/api/social-login', [
            'provider' => 'google',
            'token' => 'valididtoken',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure(['user' => ['id', 'email'], 'token']);

        $this->assertDatabaseHas('users', ['email' => 'google@example.com', 'name' => 'Google User']);
    }

    public function test_invalid_facebook_token_returns_401(): void
    {
        Http::fake([
            'https://graph.facebook.com/*' => Http::response(['error' => 'Invalid token'], 401),
        ]);

        $response = $this->postJson('/api/social-login', [
            'provider' => 'facebook',
            'token' => 'badtoken',
        ]);

        $response->assertStatus(401);
    }

    public function test_social_login_creates_user_without_email(): void
    {
        Http::fake([
            'https://graph.facebook.com/*' => Http::response([
                'id' => 'noemailid',
                'name' => 'No Email',
                'picture' => ['data' => ['url' => 'https://example.com/a.png']],
            ], 200),
        ]);

        $response = $this->postJson('/api/social-login', [
            'provider' => 'facebook',
            'token' => 'validnoemail',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure(['user' => ['id', 'email'], 'token']);

        $json = $response->json();
        $this->assertStringContainsString('facebook_noemailid@noemail.local', $json['user']['email']);
    }
}
