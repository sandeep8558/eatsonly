<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SettingController extends Controller
{
    protected $tenantService;

    public function __construct(TenantService $tenantService)
    {
        $this->tenantService = $tenantService;
    }

    public function index(Request $request)
    {
        $user = $request->user();
        $this->tenantService->ensureTenantDatabase($user);

        $tenantDb = config('database.connections.tenant.database');

        $formatted = [];
        if (empty($tenantDb)) {
            // No tenant database active (e.g. for customers). Fetch settings from the central 'settings' table.
            $settings = \App\Models\Setting::all();
            foreach ($settings as $setting) {
                $formatted[$setting->key] = $setting->value;
            }
        } else {
            // Fetch settings from the tenant database
            $settings = DB::connection('tenant')->table('settings')->get();
            foreach ($settings as $setting) {
                $formatted[$setting->key] = $setting->value;
            }

            // Merge central google_maps_api_key if not overridden by the tenant
            if (!isset($formatted['google_maps_api_key'])) {
                $formatted['google_maps_api_key'] = \App\Models\Setting::get('google_maps_api_key');
            }
        }

        return response()->json([
            'success' => true,
            'settings' => $formatted
        ]);
    }

    public function update(Request $request)
    {
        $request->validate([
            'settings' => 'required|array'
        ]);

        $user = $request->user();

        // Only SaaS admins or Restaurant admins are authorized to update settings
        if (!$user->isSuperAdmin() && !$user->isRestaurant()) {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized action'
            ], 403);
        }

        $this->tenantService->ensureTenantDatabase($user);
        $tenantDb = config('database.connections.tenant.database');

        if (empty($tenantDb)) {
            return response()->json([
                'success' => false,
                'message' => 'No active tenant database found'
            ], 400);
        }

        foreach ($request->settings as $key => $value) {
            DB::connection('tenant')->table('settings')->updateOrInsert(
                ['key' => $key],
                [
                    'value' => $value,
                    'updated_at' => now()
                ]
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Settings updated successfully'
        ]);
    }
}
