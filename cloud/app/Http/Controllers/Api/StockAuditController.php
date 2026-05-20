<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\StockAudit;
use App\Models\StockAuditItem;
use App\Models\InventoryItem;
use App\Models\StockLedgerEntry;
use App\Services\TenantService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class StockAuditController extends Controller
{
    protected $tenantService;

    public function __construct(TenantService $tenantService)
    {
        $this->tenantService = $tenantService;
    }

    public function index(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required|integer',
        ]);

        $dbName = $this->tenantService->ensureTenantDatabase($request->user());
        $this->tenantService->switchToTenant($dbName);

        $audits = StockAudit::where('restaurant_id', $request->restaurant_id)
            ->with(['items.inventoryItem', 'auditor'])
            ->orderBy('audit_date', 'desc')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $audits
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required|integer',
            'audit_date' => 'required|date',
            'items' => 'required|array|min:1',
            'items.*.inventory_item_id' => 'required|uuid',
            'items.*.physical_qty' => 'required|numeric',
        ]);

        $dbName = $this->tenantService->ensureTenantDatabase($request->user());
        $this->tenantService->switchToTenant($dbName);

        DB::connection('tenant')->beginTransaction();

        try {
            $audit = StockAudit::create([
                'restaurant_id' => $request->restaurant_id,
                'audited_by' => $request->user()->id,
                'audit_date' => $request->audit_date,
                'status' => 'submitted', // Auto-submit for now
            ]);

            foreach ($request->items as $itemData) {
                $inventoryItem = InventoryItem::where('id', $itemData['inventory_item_id'])
                    ->where('restaurant_id', $request->restaurant_id)
                    ->lockForUpdate()
                    ->first();

                if (!$inventoryItem) {
                    throw new \Exception("Inventory item not found.");
                }

                $theoreticalQty = $inventoryItem->quantity;
                $physicalQty = $itemData['physical_qty'];
                $variance = $physicalQty - $theoreticalQty;
                $costVariance = $variance * $inventoryItem->cost_per_unit;

                StockAuditItem::create([
                    'stock_audit_id' => $audit->id,
                    'inventory_item_id' => $inventoryItem->id,
                    'theoretical_qty' => $theoreticalQty,
                    'physical_qty' => $physicalQty,
                    'variance' => $variance,
                    'cost_variance' => $costVariance,
                ]);

                if ($variance != 0) {
                    $inventoryItem->quantity = $physicalQty;
                    $inventoryItem->save();

                    StockLedgerEntry::create([
                        'id' => (string) Str::uuid(),
                        'restaurant_id' => $request->restaurant_id,
                        'inventory_item_id' => $inventoryItem->id,
                        'transaction_type' => 'audit_adjustment',
                        'quantity' => $variance,
                        'cost_per_unit' => $inventoryItem->cost_per_unit,
                        'unit' => $inventoryItem->unit,
                        'reference_id' => $audit->id,
                    ]);
                }
            }

            DB::connection('tenant')->commit();

            return response()->json([
                'success' => true,
                'message' => 'Stock audit recorded successfully.',
                'data' => $audit->load(['items.inventoryItem', 'auditor'])
            ]);

        } catch (\Exception $e) {
            DB::connection('tenant')->rollBack();
            return response()->json([
                'success' => false,
                'message' => 'Failed to record audit: ' . $e->getMessage()
            ], 500);
        }
    }
}
