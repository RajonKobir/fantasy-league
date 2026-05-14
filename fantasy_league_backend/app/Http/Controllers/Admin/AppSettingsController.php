<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\AppSetting;
use Illuminate\Http\Request;
use Inertia\Inertia;

class AppSettingsController extends Controller
{
    public function index()
    {
        // Return all keys so admin can edit any of them
        $settings = AppSetting::all()->pluck('value', 'key')->toArray();

        // Merge in env fallbacks for commonly expected keys
        $fallbacks = [
            'theme_color' => env('THEME_COLOR', '#3b82f6'),
        ];

        $settings = array_merge($fallbacks, $settings);

        return Inertia::render('Admin/Settings', ['settings' => $settings]);
    }

    public function update(Request $request)
    {
        // Update existing settings from the settings[] array
        $settings = $request->input('settings', []);
        foreach ($settings as $key => $value) {
            // only allow safe key names
            if (preg_match('/^[a-zA-Z0-9_\.\-]+$/', $key)) {
                AppSetting::updateOrCreate(['key' => $key], ['value' => $value]);
            }
        }

        // Add new key if present
        $newKey = $request->input('new_key');
        $newValue = $request->input('new_value');
        if ($newKey && preg_match('/^[a-zA-Z0-9_\.\-]+$/', $newKey)) {
            AppSetting::updateOrCreate(['key' => $newKey], ['value' => $newValue]);
        }

        return redirect()->route('admin.settings.index')->with('success', 'Settings updated');
    }

    public function destroy(Request $request)
    {
        $key = $request->input('key');
        if ($key && preg_match('/^[a-zA-Z0-9_\.\-]+$/', $key)) {
            AppSetting::where('key', $key)->delete();
        }

        return redirect()->route('admin.settings.index')->with('success', 'Setting deleted');
    }
}
