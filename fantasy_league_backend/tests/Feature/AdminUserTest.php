<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdminUserTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Storage::fake('public');
    }

    public function test_admin_can_list_update_and_delete_user()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin, 'sanctum');

        $user = User::factory()->create(['name' => 'Regular', 'email' => 'regular@example.com']);

        // list
        $list = $this->getJson('/api/admin/users');
        $list->assertStatus(200)->assertJson(['success' => true]);

        // search via API
        $search = $this->getJson('/api/admin/users?q=Regular');
        $search->assertStatus(200)->assertJson(['success' => true]);
        $data = $search->json('data.data');
        $this->assertCount(1, $data);
        $this->assertEquals('regular@example.com', $data[0]['email']);

        // update with avatar and admin flag (API)
        $file = UploadedFile::fake()->image('avatar.jpg');
        $update = $this->putJson('/api/admin/users/'.$user->id, [
            'name' => 'Regular Updated',
            'is_admin' => true,
            'avatar' => $file,
        ]);
        $update->assertStatus(200)->assertJson(['success' => true]);

        $user->refresh();
        $this->assertEquals('Regular Updated', $user->name);
        $this->assertTrue((bool) $user->is_admin);
        $this->assertStringContainsString('/storage/avatars/', $user->avatar_url);

        // web/admin update: sending null password should NOT nullify existing password
        $existingHash = $user->password;
        $res = $this->actingAs($admin)->put('/admin/users/'.$user->id, ['name' => 'Regular Updated Again', 'password' => null]);
        $res->assertStatus(302); // redirect back to users list
        $user->refresh();
        $this->assertEquals($existingHash, $user->password);

        // delete
        $del = $this->deleteJson('/api/admin/users/'.$user->id);
        $del->assertStatus(200)->assertJson(['success' => true]);
        $this->assertDatabaseMissing('users', ['id' => $user->id]);
    }
}
