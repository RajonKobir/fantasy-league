<?php

namespace Tests\Feature;

use App\Models\Team;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminTeamExportTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_export_selected_teams_as_csv()
    {
        $admin = User::factory()->create(['is_admin' => true]);
        $this->actingAs($admin);

        $t1 = Team::create(['name' => 'X Team', 'user_id' => $admin->id]);
        $t2 = Team::create(['name' => 'Y Team', 'user_id' => $admin->id]);

        $res = $this->post('/admin/teams/export', ['ids' => [$t1->id, $t2->id]]);
        $res->assertStatus(200);
        // Accept text/csv with optional charset (servers often add charset)
        $this->assertStringContainsString('text/csv', $res->headers->get('content-type'));
        $content = $res->getContent();
        // debug dump to file to inspect streaming output in CI/console
        @file_put_contents(storage_path('logs/teams_export_test_content.txt'), $content);
        $this->assertStringContainsString('id,name,owner_name,tournament_id', $content);
        $this->assertStringContainsString('X Team', $content);
        $this->assertStringContainsString('Y Team', $content);
    }
}
