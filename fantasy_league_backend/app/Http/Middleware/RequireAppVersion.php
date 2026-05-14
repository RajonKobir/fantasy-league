<?php

namespace App\Http\Middleware;

use App\Models\AppSetting;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RequireAppVersion
{
    /**
     * Handle an incoming request.
     * Returns HTTP 426 with a standard JSON payload when the client app version
     * is missing or lower than the minimum allowed version.
     */
    public function handle(Request $request, Closure $next)
    {
        // Allow the client to read the config without being blocked (discovery endpoint)
        if ($request->is('api/config')) {
            return $next($request);
        }

        // Read min version/force setting from AppSetting or env fallback
        $settings = AppSetting::all()->pluck('value', 'key')->toArray();

        $minVersion = $settings['min_app_version'] ?? env('MIN_APP_VERSION', null);
        $forceUpdate = $settings['force_update'] ?? env('FORCE_UPDATE', '0');
        $updateUrl = $settings['update_url'] ?? env('UPDATE_URL', '');

        if (!$minVersion) {
            // No min version configured -> allow all clients
            return $next($request);
        }

        $clientVersion = $request->header('X-App-Version');

        if (!$clientVersion || version_compare($clientVersion, $minVersion, '<')) {
            $payload = [
                'success' => false,
                'code' => 'update_required',
                'data' => [
                    'min_version' => (string) $minVersion,
                    'force_update' => (bool) intval($forceUpdate),
                    'update_url' => (string) $updateUrl,
                ],
                'message' => 'A newer app version is required. Please update your app.',
            ];

            return response()->json($payload, Response::HTTP_UPGRADE_REQUIRED);
        }

        return $next($request);
    }
}
