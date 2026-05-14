<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminWalletLogsTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_fetch_wallet_logs_for_user()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $user = User::factory()->create(['wallet_balance' => 20.00]);

        Sanctum::actingAs($admin);

        // create a couple of logs via the adjust endpoint
        $this->postJson("/api/admin/users/{$user->id}/wallet/adjust", ['action' => 'credit', 'amount' => 10.5]);
        $this->postJson("/api/admin/users/{$user->id}/wallet/adjust", ['action' => 'debit', 'amount' => 5, 'force' => true]);

        $res = $this->getJson("/api/admin/users/{$user->id}/wallet/logs?per_page=1&page=1");
        $res->assertStatus(200)->assertJson(['success' => 1]);
        $payload = $res->json('data');
        $meta = $res->json('meta');

        $this->assertIsArray($payload);
        $this->assertArrayHasKey('current_page', $meta);
        $this->assertArrayHasKey('last_page', $meta);
        $this->assertArrayHasKey('total', $meta);

        // now test search by action
        $search = $this->getJson("/api/admin/users/{$user->id}/wallet/logs?q=credit");
        $search->assertStatus(200)->assertJson(['success' => 1]);
        $sdata = $search->json('data');
        $this->assertNotEmpty($sdata);
        $this->assertContains('credit', array_column($sdata, 'action'));

        // ensure recent actions include our credit/debit
        $all = $this->getJson("/api/admin/users/{$user->id}/wallet/logs")->json('data');
        $actions = array_column($all, 'action');
        $this->assertContains('credit', $actions);
        $this->assertContains('debit', $actions);
    }
}
