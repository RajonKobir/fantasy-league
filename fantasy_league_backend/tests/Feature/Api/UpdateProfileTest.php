<?php

namespace Tests\Feature\Api;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UpdateProfileTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_update_name()
    {
        $user = User::factory()->create(['name' => 'John Doe', 'email_verified_at' => now()]);
        $this->actingAs($user, 'sanctum');

        $response = $this->putJson('/api/users/me', [
            'name' => 'Jane Doe',
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('data.name', 'Jane Doe');
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Jane Doe',
        ]);
    }

    public function test_user_can_update_email()
    {
        $user = User::factory()->create(['email' => 'old@example.com', 'email_verified_at' => now()]);
        $this->actingAs($user, 'sanctum');

        $response = $this->putJson('/api/users/me', [
            'email' => 'new@example.com',
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('data.email', 'new@example.com');
        $response->assertJsonPath('email_changed', true);
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'email' => 'new@example.com',
            'email_verified_at' => null, // Should be unverified after email change
        ]);
    }

    public function test_user_cannot_use_existing_email()
    {
        $user1 = User::factory()->create(['email' => 'user1@example.com', 'email_verified_at' => now()]);
        $user2 = User::factory()->create(['email' => 'user2@example.com', 'email_verified_at' => now()]);
        $this->actingAs($user1, 'sanctum');

        $response = $this->putJson('/api/users/me', [
            'email' => 'user2@example.com', // Try to use user2's email
        ]);

        $response->assertStatus(422);
    }

    public function test_user_can_update_name_and_email()
    {
        $user = User::factory()->create(['name' => 'Old Name', 'email' => 'old@example.com', 'email_verified_at' => now()]);
        $this->actingAs($user, 'sanctum');

        $response = $this->putJson('/api/users/me', [
            'name' => 'New Name',
            'email' => 'new@example.com',
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('data.name', 'New Name');
        $response->assertJsonPath('data.email', 'new@example.com');
        $response->assertJsonPath('email_changed', true);
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'New Name',
            'email' => 'new@example.com',
        ]);
    }

    public function test_unauthenticated_user_cannot_update_profile()
    {
        $response = $this->putJson('/api/users/me', [
            'name' => 'Hacker',
        ]);

        $response->assertStatus(401);
    }

    public function test_user_can_update_with_same_email()
    {
        $user = User::factory()->create(['email' => 'same@example.com', 'email_verified_at' => now()]);
        $this->actingAs($user, 'sanctum');

        $response = $this->putJson('/api/users/me', [
            'name' => 'New Name',
            'email' => 'same@example.com', // Same email
        ]);

        $response->assertStatus(200);
        $response->assertJsonPath('email_changed', false);
        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'email_verified_at' => $user->email_verified_at, // Should remain verified
        ]);
    }
}
