<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class RegistrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_with_valid_credentials()
    {
        $response = $this->postJson('/api/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(201);
        $response->assertJsonStructure(['message']);

        $this->assertDatabaseHas('users', [
            'email' => 'john@example.com',
            'name' => 'John Doe',
        ]);

        // Email should not be verified yet
        $user = User::where('email', 'john@example.com')->first();
        $this->assertNull($user->email_verified_at);
    }

    public function test_registration_fails_with_duplicate_email()
    {
        User::create([
            'name' => 'Existing User',
            'email' => 'existing@example.com',
            'password' => bcrypt('password123'),
            'email_verified_at' => now(), // Mark as verified
        ]);

        $response = $this->postJson('/api/register', [
            'name' => 'John Doe',
            'email' => 'existing@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(422);
        $response->assertJson(['message' => 'Email already registered. Please log in or use another email.']);
    }

    public function test_registration_recreates_unverified_user()
    {
        $user1 = User::create([
            'name' => 'First Registration',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
        ]);

        // Register again with same email (should delete old unverified user and create new one)
        $response = $this->postJson('/api/register', [
            'name' => 'Second Registration',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertStatus(201);

        // Old user should be deleted
        $this->assertNull(User::find($user1->id));

        // New user should exist with new name
        $newUser = User::where('email', 'john@example.com')->first();
        $this->assertNotNull($newUser);
        $this->assertEquals('Second Registration', $newUser->name);
        $this->assertNull($newUser->email_verified_at);
    }

    public function test_registration_fails_with_short_password()
    {
        $response = $this->postJson('/api/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'short',
            'password_confirmation' => 'short',
        ]);

        $response->assertStatus(422);
    }

    public function test_registration_fails_with_mismatched_passwords()
    {
        $response = $this->postJson('/api/register', [
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password456',
        ]);

        $response->assertStatus(422);
    }

    public function test_user_can_verify_email_with_valid_token()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
        ]);

        $verificationCode = hash('sha256', $user->getKey() . $user->email);

        $response = $this->postJson('/api/verify-email', [
            'email' => 'john@example.com',
            'token' => $verificationCode,
        ]);

        $response->assertStatus(200);

        $user->refresh();
        $this->assertNotNull($user->email_verified_at);
    }

    public function test_email_verification_fails_with_invalid_token()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
        ]);

        $response = $this->postJson('/api/verify-email', [
            'email' => 'john@example.com',
            'token' => 'invalid-token',
        ]);

        $response->assertStatus(401);
    }

    public function test_verified_email_cannot_be_verified_again()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'email_verified_at' => now(),
        ]);

        $verificationCode = hash('sha256', $user->getKey() . $user->email);

        $response = $this->postJson('/api/verify-email', [
            'email' => 'john@example.com',
            'token' => $verificationCode,
        ]);

        $response->assertStatus(200);
        $response->assertJson(['message' => 'Email already verified']);
    }

    public function test_resend_verification_email()
    {
        $user = User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
        ]);

        $response = $this->postJson('/api/resend-verification-email', [
            'email' => 'john@example.com',
        ]);

        $response->assertStatus(200);
        $response->assertJson(['message' => 'Verification email sent']);
    }

    public function test_user_cannot_login_with_unverified_email()
    {
        User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'john@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(403);
        $response->assertJson(['message' => 'Email address not verified']);
    }

    public function test_user_can_login_with_verified_email()
    {
        User::create([
            'name' => 'John Doe',
            'email' => 'john@example.com',
            'password' => bcrypt('password123'),
            'email_verified_at' => now(),
        ]);

        $response = $this->postJson('/api/login', [
            'email' => 'john@example.com',
            'password' => 'password123',
        ]);

        $response->assertStatus(200);
        $response->assertJsonStructure(['user', 'token']);
    }
}
