<?php

namespace Tests\Feature;

use App\Models\AppSetting;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class RequireAppVersionTest extends TestCase
{
    use RefreshDatabase;

    public function test_requests_are_allowed_when_no_min_version_is_set()
    {
        // No settings seeded -> any request should work
        $response = $this->getJson('/api/tournaments');
        $response->assertStatus(200);
    }

    public function test_requests_are_blocked_when_version_missing_or_too_old()
    {
        // Set a min version
        AppSetting::updateOrCreate(['key' => 'min_app_version'], ['value' => '2.0.0']);

        // Missing header -> blocked
        $this->getJson('/api/tournaments')->assertStatus(426)->assertJson(['code' => 'update_required']);

        // Too old header -> blocked
        $this->getJson('/api/tournaments', ['X-App-Version' => '1.0.0'])->assertStatus(426)->assertJson(['code' => 'update_required']);
    }

    public function test_requests_are_allowed_when_version_is_new_enough()
    {
        AppSetting::updateOrCreate(['key' => 'min_app_version'], ['value' => '1.2.0']);

        $this->getJson('/api/tournaments', ['X-App-Version' => '1.2.0'])->assertStatus(200);
        $this->getJson('/api/tournaments', ['X-App-Version' => '1.2.1'])->assertStatus(200);
    }

    public function test_config_endpoint_is_public_even_when_min_version_is_set()
    {
        AppSetting::updateOrCreate(['key' => 'min_app_version'], ['value' => '9.9.9']);

        $this->getJson('/api/config')->assertStatus(200)->assertJson(['success' => true]);
    }
}
