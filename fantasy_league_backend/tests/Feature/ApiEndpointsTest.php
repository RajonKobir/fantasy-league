<?php

namespace Tests\Feature;

use App\Models\Player;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ApiEndpointsTest extends TestCase
{
    use RefreshDatabase;

    public function test_transactions_and_notifications()
    {
        // Seed minimal data
        $this->seed();

        $user = User::first();
        $this->assertNotNull($user);

        Sanctum::actingAs($user);

        // Create a player without image to ensure API returns local placeholder
        Player::create(['name' => 'NoImagePlayer', 'nationality' => 'Unknown', 'role' => 'batsman']);

        // Wallet endpoint should return balance and transactions
        $res = $this->getJson('/api/wallet');
        $res->assertStatus(200)->assertJsonStructure(['success', 'message', 'data' => ['wallet_balance', 'transactions']]);

        // Admin credit should increase wallet balance
        $before = $this->getJson('/api/wallet')->json('data.wallet_balance');

        // Players endpoint should include image_url (use placeholder if missing)
        $playersPayload = $this->getJson('/api/players')->json('data');
        // Support paginated or non-paginated responses
        $players = is_array($playersPayload) && array_key_exists('data', $playersPayload) ? $playersPayload['data'] : $playersPayload;
        $this->assertNotEmpty($players);
        $this->assertArrayHasKey('image_url', $players[0]);
        $this->assertNotEmpty($players[0]['image_url']);

        // Tournaments list should include logo_url (if any exist)
        $tournamentsPayload = $this->getJson('/api/tournaments')->json('data');
        $tournaments = is_array($tournamentsPayload) && array_key_exists('data', $tournamentsPayload) ? $tournamentsPayload['data'] : $tournamentsPayload;
        if (! empty($tournaments)) {
            $this->assertArrayHasKey('logo_url', $tournaments[0]);
            $this->assertNotEmpty($tournaments[0]['logo_url']);
        }

        // Teams endpoint should include logo_url
        $teamsPayload = $this->getJson('/api/teams')->json('data');
        $teams = is_array($teamsPayload) && array_key_exists('data', $teamsPayload) ? $teamsPayload['data'] : $teamsPayload;
        $this->assertIsArray($teams);
        if (! empty($teams)) {
            $this->assertArrayHasKey('logo_url', $teams[0]);
            $this->assertNotEmpty($teams[0]['logo_url']);
        }

        $creditAmount = 50.00;
        $res = $this->postJson("/api/admin/users/{$user->id}/wallet/credit", ['amount' => $creditAmount, 'remark' => 'Test credit']);
        $res->assertStatus(200)->assertJson(['success' => 1]);
        // Ensure the credit endpoint returns the updated wallet balance
        $res->assertJsonStructure(['data' => ['user_id', 'amount', 'wallet_balance']]);
        $this->assertEquals(number_format($creditAmount, 2, '.', ''), $res->json('data.wallet_balance'));

        $after = $this->getJson('/api/wallet')->json('data.wallet_balance');
        $this->assertEquals(number_format((float) $before + $creditAmount, 2, '.', ''), $after);

        $res = $this->getJson('/api/transactions');
        $res->assertStatus(200)->assertJsonStructure(['success', 'message', 'data' => ['transaction']]);

        $res = $this->getJson('/api/notifications');
        $res->assertStatus(200)->assertJsonStructure(['success', 'message', 'data' => ['notification_data']]);
    }
}
