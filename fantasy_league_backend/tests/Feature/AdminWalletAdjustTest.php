<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminWalletAdjustTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_debit_and_credit_and_set_wallet()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $user = User::factory()->create(['wallet_balance' => 100.00]);

        Sanctum::actingAs($admin);

        // credit
        $res = $this->postJson("/api/admin/users/{$user->id}/wallet/adjust", ['action' => 'credit', 'amount' => 25.5]);
        $res->assertStatus(200)->assertJson(['success' => 1]);
        $this->assertEquals('125.50', $res->json('data.wallet_balance'));
        $this->assertDatabaseHas('admin_wallet_logs', ['admin_id' => $admin->id, 'user_id' => $user->id, 'action' => 'credit']);

        // debit (insufficient should fail)
        $res = $this->postJson("/api/admin/users/{$user->id}/wallet/adjust", ['action' => 'debit', 'amount' => 200]);
        $res->assertStatus(422)->assertJson(['success' => 0]);

        // debit with force
        $res = $this->postJson("/api/admin/users/{$user->id}/wallet/adjust", ['action' => 'debit', 'amount' => 50, 'force' => true]);
        $res->assertStatus(200)->assertJson(['success' => 1]);
        $this->assertDatabaseHas('admin_wallet_logs', ['admin_id' => $admin->id, 'user_id' => $user->id, 'action' => 'debit']);

        // set balance
        $res = $this->postJson("/api/admin/users/{$user->id}/wallet/adjust", ['action' => 'set', 'amount' => 999.99]);
        $res->assertStatus(200)->assertJson(['success' => 1]);
        $this->assertEquals('999.99', $res->json('data.wallet_balance'));
        $this->assertDatabaseHas('admin_wallet_logs', ['admin_id' => $admin->id, 'user_id' => $user->id, 'action' => 'set']);
    }
}
