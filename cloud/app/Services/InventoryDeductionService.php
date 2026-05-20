<?php

namespace App\Services;

use App\Models\Order;
use App\Models\Recipe;
use App\Models\InventoryItem;
use App\Models\StockLedgerEntry;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class InventoryDeductionService
{
    /**
     * Deduct raw materials based on the recipes of the order's items.
     * Ensure this runs inside a tenant connection.
     */
    public function deductForOrder(Order $order)
    {
        // Prevent double deductions: Only deduct if the order wasn't previously deducted.
        // We can check if a stock ledger entry exists for this order.
        $alreadyDeducted = StockLedgerEntry::where('reference_id', $order->id)
            ->where('transaction_type', 'sales_consumption')
            ->exists();

        if ($alreadyDeducted) {
            return;
        }

        $orderItems = $order->items()->with('menuItem')->get();

        foreach ($orderItems as $item) {
            $recipes = Recipe::where('menu_item_id', $item->menu_item_id)->get();

            foreach ($recipes as $recipe) {
                $rawItem = InventoryItem::find($recipe->inventory_item_id);
                if (!$rawItem) continue;

                $totalConsumed = $recipe->quantity_needed * $item->quantity;

                // Simple decrement of main quantity
                $rawItem->quantity -= $totalConsumed;
                $rawItem->save();

                // Auto-PO Drafting if below threshold
                if ($rawItem->quantity < $rawItem->min_threshold) {
                    $this->draftPurchaseOrder($rawItem);
                }

                // Log the ledger entry for sales consumption
                StockLedgerEntry::create([
                    'id' => (string) Str::uuid(),
                    'restaurant_id' => $order->restaurant_id,
                    'inventory_item_id' => $rawItem->id,
                    'transaction_type' => 'sales_consumption',
                    'quantity' => -$totalConsumed,
                    'cost_per_unit' => $rawItem->cost_per_unit,
                    'unit' => $recipe->consumption_unit,
                    'reference_id' => $order->id, // Use order ID to prevent duplicates
                ]);
            }
        }
    }

    private function draftPurchaseOrder(InventoryItem $item)
    {
        // Check if there is already a pending PO for this item
        $existingPO = DB::connection('tenant')->table('purchase_order_items')
            ->join('purchase_orders', 'purchase_orders.id', '=', 'purchase_order_items.purchase_order_id')
            ->where('purchase_order_items.inventory_item_id', $item->id)
            ->where('purchase_orders.status', 'pending')
            ->exists();

        if ($existingPO) {
            return; // Already ordered
        }

        // Find a supplier for this item (or just use the first available, or generic)
        $supplier = DB::connection('tenant')->table('suppliers')->first();
        if (!$supplier) return; // Cannot draft without a supplier

        // Let's create a new PO, or append to an existing open generic PO for this supplier
        $po = DB::connection('tenant')->table('purchase_orders')
            ->where('supplier_id', $supplier->id)
            ->where('status', 'pending')
            ->first();

        $poId = $po ? $po->id : (string) Str::uuid();

        if (!$po) {
            DB::connection('tenant')->table('purchase_orders')->insert([
                'id' => $poId,
                'restaurant_id' => $item->restaurant_id,
                'supplier_id' => $supplier->id,
                'po_number' => 'PO-AUTO-' . strtoupper(Str::random(6)),
                'status' => 'pending',
                'total_amount' => 0,
                'order_date' => now(),
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        // Draft qty = threshold * 2 or some default logic
        $draftQty = $item->min_threshold > 0 ? $item->min_threshold * 2 : 10;
        $unitPrice = $item->cost_per_unit;

        DB::connection('tenant')->table('purchase_order_items')->insert([
            'id' => (string) Str::uuid(),
            'purchase_order_id' => $poId,
            'inventory_item_id' => $item->id,
            'quantity' => $draftQty,
            'unit_price' => $unitPrice,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // Update PO total
        DB::connection('tenant')->table('purchase_orders')
            ->where('id', $poId)
            ->increment('total_amount', $draftQty * $unitPrice);
    }
}
