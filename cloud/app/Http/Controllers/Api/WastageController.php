<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WastageEntry;
use App\Models\StockLedgerEntry;
use App\Models\InventoryItem;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class WastageController extends Controller
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

        $entries = WastageEntry::where('restaurant_id', $request->restaurant_id)
            ->with(['inventoryItem', 'user'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $entries
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'inventory_item_id' => 'required|uuid',
            'quantity' => 'required|numeric|min:0.0001',
            'unit' => 'required|string',
            'reason' => 'required|string',
            'notes' => 'nullable|string',
        ]);
        $this->setTenant();

        $user = auth()->user();

        $entry = DB::connection('tenant')->transaction(function () use ($request, $user) {
            $item = InventoryItem::findOrFail($request->inventory_item_id);

            // 1. Create Wastage entry
            $wastage = WastageEntry::create([
                'restaurant_id' => $request->restaurant_id,
                'inventory_item_id' => $request->inventory_item_id,
                'quantity' => $request->quantity,
                'unit' => $request->unit,
                'reason' => $request->reason,
                'logged_by' => $user->id,
                'notes' => $request->notes,
            ]);

            // 2. Log in Stock Ledger as negative movement
            StockLedgerEntry::create([
                'restaurant_id' => $request->restaurant_id,
                'inventory_item_id' => $request->inventory_item_id,
                'transaction_type' => 'wastage',
                'quantity' => -$request->quantity,
                'cost_per_unit' => $item->cost_per_unit ?? 0.0,
                'unit' => $request->unit,
                'reference_id' => $wastage->id,
            ]);

            // 3. Decrement central inventory item quantity
            $item->quantity -= $request->quantity;
            $item->save();

            return $wastage;
        });

        $loaded = WastageEntry::with(['inventoryItem', 'user'])->find($entry->id);

        return response()->json([
            'status' => 'success',
            'message' => 'Wastage logged successfully',
            'data' => $loaded
        ]);
    }
}
