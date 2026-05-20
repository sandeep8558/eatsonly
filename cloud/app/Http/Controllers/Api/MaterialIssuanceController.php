<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MaterialIssuance;
use App\Models\MaterialIssuanceItem;
use App\Models\StockLedgerEntry;
use App\Models\InventoryItem;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MaterialIssuanceController extends Controller
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

        $issuances = MaterialIssuance::where('restaurant_id', $request->restaurant_id)
            ->with(['items.inventoryItem', 'issuer', 'receiver'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $issuances
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'received_by' => 'required|uuid',
            'department' => 'required|string',
            'notes' => 'nullable|string',
            'items' => 'required|array|min:1',
            'items.*.inventory_item_id' => 'required|uuid',
            'items.*.quantity' => 'required|numeric|min:0.0001',
            'items.*.unit' => 'required|string',
        ]);
        $this->setTenant();

        $user = auth()->user();

        $issuance = DB::connection('tenant')->transaction(function () use ($request, $user) {
            // 1. Create main issuance log
            $issuance = MaterialIssuance::create([
                'restaurant_id' => $request->restaurant_id,
                'issued_by' => $user->id,
                'received_by' => $request->received_by,
                'department' => $request->department,
                'notes' => $request->notes,
            ]);

            // 2. Loop and issue individual items
            foreach ($request->items as $itemData) {
                $invItem = InventoryItem::findOrFail($itemData['inventory_item_id']);

                // Create issuance detail row
                MaterialIssuanceItem::create([
                    'material_issuance_id' => $issuance->id,
                    'inventory_item_id' => $itemData['inventory_item_id'],
                    'quantity' => $itemData['quantity'],
                    'unit' => $itemData['unit'],
                ]);

                // Create stock ledger outbound entry
                StockLedgerEntry::create([
                    'restaurant_id' => $request->restaurant_id,
                    'inventory_item_id' => $itemData['inventory_item_id'],
                    'transaction_type' => 'kitchen_issue',
                    'quantity' => -$itemData['quantity'],
                    'cost_per_unit' => $invItem->cost_per_unit ?? 0.0,
                    'unit' => $itemData['unit'],
                    'reference_id' => $issuance->id,
                ]);

                // Adjust central stock level
                $invItem->quantity -= $itemData['quantity'];
                $invItem->save();
            }

            return $issuance;
        });

        $loaded = MaterialIssuance::with(['items.inventoryItem', 'issuer', 'receiver'])->find($issuance->id);

        return response()->json([
            'status' => 'success',
            'message' => 'Material issuance logged and kitchen stock updated successfully',
            'data' => $loaded
        ]);
    }
}
