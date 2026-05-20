<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\StockLedgerEntry;
use App\Services\TenantService;
use Illuminate\Http\Request;

class StockLedgerController extends Controller
{
    protected $tenantService;

    public function __construct(TenantService $tenantService)
    {
        $this->tenantService = $tenantService;
    }

    private function setTenant()
    {
        $user = auth()->user();
        $restaurantId = request()->input('restaurant_id') 
            ?? request()->header('X-Restaurant-ID') 
            ?? request()->query('restaurant_id');

        if ($restaurantId && $restaurantId !== 'all') {
            $restaurant = \App\Models\Restaurant::find($restaurantId);
            if ($restaurant) {
                $dbName = 'resto_' . str_replace('-', '_', $restaurant->user_id);
                $this->tenantService->switchToTenant($dbName);
                $this->tenantService->syncSchema($restaurant->user);
                return;
            }
        }

        $this->tenantService->ensureTenantDatabase($user);
    }

    public function index(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
        ]);
        $this->setTenant();

        $entries = StockLedgerEntry::where('restaurant_id', $request->restaurant_id)
            ->with('inventoryItem')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $entries
        ]);
    }
}
