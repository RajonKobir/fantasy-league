<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use Illuminate\Http\Request;

class ConfigController extends Controller
{
    // Public: return a curated set of settings that the frontend can read.
    // Falls back to environment values when not present in DB.
    public function index()
    {
        $settings = AppSetting::all()->pluck('value', 'key')->toArray();

        // Which keys we allow the mobile client to read
        $allowedKeys = [
            'min_app_version',
            'force_update',
            'update_url',
            'theme_color',
            'font_family',
        ];

        // Merge in env fallbacks for some values
        $fallbacks = [
            'min_app_version' => env('MIN_APP_VERSION', null),
            'force_update' => env('FORCE_UPDATE', '0'),
            'update_url' => env('UPDATE_URL', ''),
            'theme_color' => env('THEME_COLOR', '#3b82f6'),
            'font_family' => env('FONT_FAMILY', 'system-ui'),
        ];

        $settings = array_merge($fallbacks, $settings);
        $settings = array_intersect_key($settings, array_flip($allowedKeys));

        return response()->json(['success' => true, 'data' => $settings]);
    }

    // Authenticated: update multiple keys (expects JSON object of key => value pairs)
    public function update(Request $request)
    {
        // Authenticated endpoint. Admin-level checks should be enforced at the controller middleware or caller.
        $payload = $request->all();

        foreach ($payload as $key => $value) {
            if (preg_match('/^[a-zA-Z0-9_\.\-]+$/', $key)) {
                AppSetting::updateOrCreate(['key' => $key], ['value' => $value]);
            }
        }

        return response()->json(['success' => true, 'message' => 'Settings updated']);
    }

    // Delete a single config key (admin only)
    public function destroy($key)
    {
        if (preg_match('/^[a-zA-Z0-9_\.\-]+$/', $key)) {
            AppSetting::where('key', $key)->delete();
        }

        return response()->json(['success' => true, 'message' => 'Setting deleted']);
    }
}
