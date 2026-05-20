<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PurchaseOrder;
use App\Models\PurchaseOrderItem;
use App\Models\InventoryItem;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PurchaseController extends Controller
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
        $request->validate(['restaurant_id' => 'required']);
        $this->setTenant();

        $query = PurchaseOrder::where('restaurant_id', $request->restaurant_id)
            ->with(['supplier', 'items.inventoryItem']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('start_date') && $request->filled('end_date')) {
            $query->whereBetween('order_date', [$request->start_date, $request->end_date]);
        }

        $purchases = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $purchases
        ]);
    }

    public function store(Request $request)
    {
        $this->setTenant();

        $request->validate([
            'restaurant_id' => 'required',
            'supplier_id' => 'required|exists:tenant.suppliers,id',
            'status' => 'required|in:pending,paid,cancelled',
            'order_date' => 'nullable|date',
            'items' => 'required|array|min:1',
            'items.*.inventory_item_id' => 'required|exists:tenant.inventory_items,id',
            'items.*.quantity' => 'required|numeric|gt:0',
            'items.*.unit_price' => 'required|numeric|min:0',
        ]);

        $po = null;

        // Perform the purchase logging and stock auto-increment safely inside a transaction
        DB::connection('tenant')->transaction(function () use ($request, &$po) {
            // 1. Generate unique PO Number
            $latestPo = PurchaseOrder::where('restaurant_id', $request->restaurant_id)
                ->orderBy('created_at', 'desc')
                ->first();

            $nextNumber = 1;
            if ($latestPo && preg_match('/#PO-(\d+)/', $latestPo->po_number, $matches)) {
                $nextNumber = intval($matches[1]) + 1;
            }
            $poNumber = '#PO-' . str_pad($nextNumber, 4, '0', STR_PAD_LEFT);

            // 2. Calculate sum total
            $totalAmount = 0.00;
            foreach ($request->items as $item) {
                $totalAmount += ($item['quantity'] * $item['unit_price']);
            }

            // 3. Create Purchase Order
            $po = PurchaseOrder::create([
                'restaurant_id' => $request->restaurant_id,
                'supplier_id' => $request->supplier_id,
                'po_number' => $poNumber,
                'status' => $request->status,
                'total_amount' => $totalAmount,
                'order_date' => $request->input('order_date') ?? now(),
            ]);

            // 4. Create Line Items & Sync Stock levels
            foreach ($request->items as $itemData) {
                PurchaseOrderItem::create([
                    'purchase_order_id' => $po->id,
                    'inventory_item_id' => $itemData['inventory_item_id'],
                    'quantity' => $itemData['quantity'],
                    'unit_price' => $itemData['unit_price'],
                ]);

                // Auto-increment inventory stock level if order status is 'paid' or 'pending' (restocked)
                if ($request->status !== 'cancelled') {
                    $item = InventoryItem::find($itemData['inventory_item_id']);
                    if ($item) {
                        $item->quantity += $itemData['quantity'];
                        $item->cost_per_unit = $itemData['unit_price']; // update last cost rate
                        $item->save();
                    }
                }
            }
        });

        // Eager load relationships for complete return payload
        $po->load(['supplier', 'items.inventoryItem']);

        return response()->json([
            'status' => 'success',
            'data' => $po
        ]);
    }

    public function update(Request $request, $id)
    {
        $this->setTenant();

        $request->validate([
            'supplier_id' => 'required|exists:tenant.suppliers,id',
            'status' => 'required|in:pending,paid,cancelled',
            'order_date' => 'nullable|date',
            'items' => 'required|array|min:1',
            'items.*.inventory_item_id' => 'required|exists:tenant.inventory_items,id',
            'items.*.quantity' => 'required|numeric|gt:0',
            'items.*.unit_price' => 'required|numeric|min:0',
        ]);

        $po = PurchaseOrder::findOrFail($id);

        DB::connection('tenant')->transaction(function () use ($request, $po) {
            // Revert original stock increments if the old status was not cancelled
            if ($po->status !== 'cancelled') {
                foreach ($po->items as $oldItem) {
                    $invItem = InventoryItem::find($oldItem->inventory_item_id);
                    if ($invItem) {
                        $invItem->quantity -= $oldItem->quantity;
                        $invItem->save();
                    }
                }
            }

            // Delete old items
            $po->items()->delete();

            // Calculate new sum total
            $totalAmount = 0.00;
            foreach ($request->items as $item) {
                $totalAmount += ($item['quantity'] * $item['unit_price']);
            }

            // Update Purchase Order details
            $po->update([
                'supplier_id' => $request->supplier_id,
                'status' => $request->status,
                'total_amount' => $totalAmount,
                'order_date' => $request->input('order_date') ?? $po->order_date,
            ]);

            // Save new items and apply new stock increments
            foreach ($request->items as $itemData) {
                PurchaseOrderItem::create([
                    'purchase_order_id' => $po->id,
                    'inventory_item_id' => $itemData['inventory_item_id'],
                    'quantity' => $itemData['quantity'],
                    'unit_price' => $itemData['unit_price'],
                ]);

                if ($request->status !== 'cancelled') {
                    $invItem = InventoryItem::find($itemData['inventory_item_id']);
                    if ($invItem) {
                        $invItem->quantity += $itemData['quantity'];
                        $invItem->cost_per_unit = $itemData['unit_price'];
                        $invItem->save();
                    }
                }
            }
        });

        $po->load(['supplier', 'items.inventoryItem']);

        return response()->json([
            'status' => 'success',
            'data' => $po
        ]);
    }

    public function destroy($id)
    {
        $this->setTenant();

        $po = PurchaseOrder::findOrFail($id);

        DB::connection('tenant')->transaction(function () use ($po) {
            // Revert original stock increments if the status was not cancelled
            if ($po->status !== 'cancelled') {
                foreach ($po->items as $item) {
                    $invItem = InventoryItem::find($item->inventory_item_id);
                    if ($invItem) {
                        $invItem->quantity -= $item->quantity;
                        $invItem->save();
                    }
                }
            }

            // Cascade delete purchase items
            $po->items()->delete();
            $po->delete();
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Purchase order deleted successfully.'
        ]);
    }
}
