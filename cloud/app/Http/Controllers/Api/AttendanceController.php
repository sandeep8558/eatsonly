<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Restaurant;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class AttendanceController extends Controller
{
    protected $tenantService;

    public function __construct(TenantService $tenantService)
    {
        $this->tenantService = $tenantService;
    }

    private function setTenant()
    {
        $user = Auth::user();
        
        $restaurantId = request()->input('restaurant_id') 
            ?? request()->header('X-Restaurant-ID') 
            ?? request()->query('restaurant_id');

        if ($restaurantId && $restaurantId !== 'all') {
            $restaurant = Restaurant::find($restaurantId);
            if ($restaurant) {
                $dbName = 'resto_' . str_replace('-', '_', $restaurant->user_id);
                $this->tenantService->switchToTenant($dbName);
                return;
            }
        }

        // Fallback
        $link = DB::table('restaurant_user')->where('user_id', $user->id)->first();
        if (!$link) {
            $dbName = 'resto_' . str_replace('-', '_', $user->id);
        } else {
            $restaurant = Restaurant::find($link->restaurant_id);
            $dbName = 'resto_' . str_replace('-', '_', $restaurant->user_id);
        }
        $this->tenantService->switchToTenant($dbName);
    }

    public function clockIn(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required|exists:restaurants,id'
        ]);

        $user = Auth::user();
        $this->setTenant();

        // Check if already clocked in
        $active = DB::connection('tenant')->table('attendances')
            ->where('user_id', $user->id)
            ->whereNull('clock_out')
            ->first();

        if ($active) {
            return response()->json(['status' => 'error', 'message' => 'Already clocked in'], 422);
        }

        DB::connection('tenant')->table('attendances')->insert([
            'user_id' => $user->id,
            'restaurant_id' => $request->restaurant_id,
            'clock_in' => now(),
            'status' => 'present',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json(['status' => 'success', 'message' => 'Clocked in successfully']);
    }

    public function clockOut(Request $request)
    {
        $user = Auth::user();
        $this->setTenant();

        $active = DB::connection('tenant')->table('attendances')
            ->where('user_id', $user->id)
            ->whereNull('clock_out')
            ->orderBy('clock_in', 'desc')
            ->first();

        if (!$active) {
            return response()->json(['status' => 'error', 'message' => 'Not clocked in'], 422);
        }

        DB::connection('tenant')->table('attendances')
            ->where('id', $active->id)
            ->update([
                'clock_out' => now(),
                'updated_at' => now(),
            ]);

        return response()->json(['status' => 'success', 'message' => 'Clocked out successfully']);
    }

    public function getStatus(Request $request)
    {
        $user = Auth::user();
        $this->setTenant();

        $active = DB::connection('tenant')->table('attendances')
            ->where('user_id', $user->id)
            ->whereNull('clock_out')
            ->first();

        return response()->json([
            'status' => 'success',
            'is_clocked_in' => (bool)$active,
            'attendance' => $active
        ]);
    }

    public function getHistory(Request $request)
    {
        $user = Auth::user();
        $this->setTenant();

        $history = DB::connection('tenant')->table('attendances')
            ->where('user_id', $user->id)
            ->orderBy('clock_in', 'desc')
            ->limit(30)
            ->get();

        return response()->json(['status' => 'success', 'data' => $history]);
    }
}
