<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\KOT;
use App\Services\TenantService;
use App\Models\MenuItem;
use App\Models\RestaurantTable;
use App\Models\OrderPayment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
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

        // Self-healing tenant resolution via central registry if restaurantId is missing
        if (!$restaurantId) {
            $routeId = request()->route('id') ?? request()->route('order_id') ?? request()->input('order_id');
            if ($routeId) {
                $registry = \App\Models\CustomerOrderRegistry::where('tenant_order_id', $routeId)->first();
                if ($registry) {
                    $restaurantId = $registry->restaurant_id;
                }
            }
        }

        if ($restaurantId && $restaurantId !== 'all') {
            $restaurant = \App\Models\Restaurant::find($restaurantId);
            if ($restaurant) {
                $dbName = 'resto_' . str_replace('-', '_', $restaurant->user_id);
                $this->tenantService->switchToTenant($dbName);
                return;
            }
        }

        $this->tenantService->ensureTenantDatabase($user);
    }

    public function index(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required|string',
            'date' => 'nullable|date',
            'payment_method' => 'nullable|string',
            'order_type' => 'nullable|string',
            'per_page' => 'nullable|integer'
        ]);

        $user = Auth::user();

        // SCALABLE SOLUTION B: Query from Master Database Central Registry
        if ($request->restaurant_id === 'all' && $user && $user->isCustomer()) {
            $query = \App\Models\CustomerOrderRegistry::with('restaurant')->where('customer_id', $user->id)
                                                      ->whereNotIn('status', ['open', 'preparing', 'on the way', 'ready', 'cooking', 'placed', 'pending_payment'])
                                                      ->latest();

            if ($request->date) {
                $query->whereDate('created_at', $request->date);
            }

            if ($request->order_type) {
                $orderType = str_replace('_', '-', $request->order_type);
                $query->where('order_type', $orderType);
            }

            $perPage = $request->per_page ?? 5;
            $registries = $query->paginate($perPage);

            return response()->json([
                'status' => 'success',
                'data' => $registries,
                'summary' => [
                    'total_count' => $registries->total(),
                    'total_amount' => $query->sum('total')
                ]
            ]);
        }

        $this->setTenant();

        $query = Order::with(['items.menuItem.taxGroup.taxes', 'table', 'payments', 'deliveryStaff']);
                       
        if ($request->restaurant_id !== 'all') {
            $query->where('restaurant_id', $request->restaurant_id);
        }

        $isStaff = $user && DB::table('restaurant_user')
            ->where('user_id', $user->id)
            ->where('restaurant_id', $request->restaurant_id)
            ->exists();

        if ($user && $user->isCustomer() && !$user->isRestaurant() && !$user->isSuperAdmin() && !$isStaff) {
            $query->where('customer_id', $user->id);
        }

        $query->latest();

        if ($request->date) {
            $query->whereDate('created_at', $request->date);
        }

        if ($request->payment_method) {
            $query->where('payment_method', $request->payment_method);
        }

        if ($request->order_type) {
            $orderType = str_replace('_', '-', $request->order_type);
            $query->where('order_type', $orderType);
        }

        $query->where('status', '!=', 'pending_payment');

        $summaryQuery = clone $query;
        $totalAmount = $summaryQuery->sum('total');

        $perPage = $request->per_page ?? 5;
        $orders = $query->paginate($perPage);

        return response()->json([
            'status' => 'success', 
            'data' => $orders,
            'summary' => [
                'total_count' => $orders->total(),
                'total_amount' => $totalAmount
            ]
        ]);
    }

    public function getActiveOrders(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required|string'
        ]);

        $user = Auth::user();

        if ($request->restaurant_id === 'all' && $user && $user->isCustomer()) {
            $orders = \App\Models\CustomerOrderRegistry::with('restaurant')->where('customer_id', $user->id)
                                                       ->whereIn('status', ['open', 'preparing', 'on the way', 'ready', 'cooking', 'placed', 'pending_payment'])
                                                       ->latest()
                                                       ->get();

            return response()->json([
                'status' => 'success',
                'data' => $orders
            ]);
        }

        $this->setTenant();

        $query = Order::with(['items' => function($q) {
                        $q->with(['menuItem.taxGroup.taxes', 'children.menuItem']);
                    }, 'table', 'payments'])
                    ->whereIn('status', ['open', 'preparing', 'ready', 'cooking', 'placed']);

        if ($request->restaurant_id !== 'all') {
            $query->where('restaurant_id', $request->restaurant_id);
        }

        $isStaff = $user && DB::table('restaurant_user')
            ->where('user_id', $user->id)
            ->where('restaurant_id', $request->restaurant_id)
            ->exists();

        if ($user && $user->isCustomer() && !$user->isRestaurant() && !$user->isSuperAdmin() && !$isStaff) {
            $query->where('customer_id', $user->id);
        }

        $orders = $query->get();

        return response()->json([
            'status' => 'success',
            'data' => $orders
        ]);
    }

    public function getDashboardStats(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required|string',
            'date' => 'nullable|date'
        ]);

        $user = Auth::user();
        $this->setTenant();

        $query = Order::query();

        if ($request->restaurant_id !== 'all') {
            $query->where('restaurant_id', $request->restaurant_id);
        }
        
        $isStaff = $user && DB::table('restaurant_user')
            ->where('user_id', $user->id)
            ->where('restaurant_id', $request->restaurant_id)
            ->exists();

        if ($user && $user->isCustomer() && !$user->isRestaurant() && !$user->isSuperAdmin() && !$isStaff) {
            $query->where('customer_id', $user->id);
        }

        $date = $request->date ?? date('Y-m-d');
        $query->whereDate('created_at', $date);

        $orders = $query->get(['id', 'order_type', 'total', 'status']);

        $stats = [
            'total_sales' => $orders->where('status', 'completed')->sum('total'),
            'total_orders' => $orders->count(),
            'dine_in_orders' => $orders->where('order_type', 'dine-in')->count(),
            'takeaway_orders' => $orders->where('order_type', 'takeaway')->count(),
            'delivery_orders' => $orders->where('order_type', 'delivery')->count(),
        ];

        return response()->json([
            'status' => 'success',
            'data' => $stats
        ]);
    }

    public function sendKOT(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'table_id' => 'nullable|string',
            'order_id' => 'nullable|string',
            'order_type' => 'nullable|string',
            'customer_name' => 'nullable|string',
            'customer_phone' => 'nullable|string',
            'delivery_address' => 'nullable|string',
            'items' => 'required|array',
            'items.*.menu_item_id' => 'required|uuid',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.price' => 'required|numeric',
            'items.*.temp_id' => 'nullable|string',
            'items.*.parent_temp_id' => 'nullable|string',
            'items.*.combo_group_id' => 'nullable|uuid',
            'customer_id' => 'nullable|uuid',
            'source' => 'nullable|string|in:qr_self,pos_waiter,pos_counter,web_delivery,customer_app_delivery,customer_app_takeaway,customer_app_dinein',
        ]);

        $this->setTenant();
        
        DB::connection('tenant')->beginTransaction();
        try {
            $orderType = $request->order_type ?? 'dine-in';
            $orderType = str_replace('_', '-', $orderType);
            $orderType = strtolower($orderType);
            $order = null;

            if ($orderType === 'dine-in') {
                if ($request->table_id) {
                    $order = Order::where('table_id', $request->table_id)
                                  ->whereIn('status', ['open', 'preparing', 'ready', 'cooking', 'placed'])
                                  ->first();
                }
                if (!$order && $request->customer_id) {
                    $order = Order::where('customer_id', $request->customer_id)
                                  ->where('order_type', 'dine-in')
                                  ->whereIn('status', ['open', 'preparing', 'ready', 'cooking', 'placed'])
                                  ->first();
                }
            } else {
                if ($request->order_id) {
                    $order = Order::find($request->order_id);
                }
                
                $isCustomerApp = strpos($request->source ?? '', 'customer_app') !== false;
                if (!$order && $request->customer_id && !$isCustomerApp) {
                    $order = Order::where('customer_id', $request->customer_id)
                                  ->where('order_type', $orderType)
                                  ->whereIn('status', ['open', 'preparing', 'ready', 'cooking', 'placed'])
                                  ->first();
                }
            }

            if (!$order) {
                $status = 'open';
                if ($request->payment_method === 'ONLINE' || $request->payment_method === 'online') {
                    $status = 'pending_payment';
                }

                $order = Order::create([
                    'restaurant_id' => $request->restaurant_id,
                    'table_id' => $request->table_id,
                    'order_type' => $orderType,
                    'customer_id' => $request->customer_id,
                    'source' => $request->source ?? 'pos_waiter',
                    'customer_name' => $request->customer_name,
                    'customer_phone' => $request->customer_phone,
                    'delivery_address' => $request->delivery_address,
                    'user_id' => Auth::id(),
                    'status' => $status,
                    'subtotal' => 0,
                    'tax' => 0,
                    'total' => 0
                ]);
            } else {
                // If order exists, update customer info if provided
                if ($request->customer_id) $order->customer_id = $request->customer_id;
                if ($request->customer_name) $order->customer_name = $request->customer_name;
                if ($request->customer_phone) $order->customer_phone = $request->customer_phone;
                if ($request->delivery_address) $order->delivery_address = $request->delivery_address;
            }

            $subtotalAddition = 0;
            $tempToIdMap = [];
            $kotMap = []; // StationID -> KOT Object

            // Pass 1: Create Parent Items
            $subtotalAddition = 0;
            foreach ($request->items as $itemData) {
                if (isset($itemData['parent_temp_id']) && $itemData['parent_temp_id']) {
                    continue;
                }

                $menuItem = MenuItem::with(['category', 'taxGroup.taxes'])->find($itemData['menu_item_id']);
                $stationId = $menuItem->category->kds_station_id ?? null;
                $stationKey = $stationId ?: 'default';

                if ($order->status !== 'pending_payment' && !isset($kotMap[$stationKey])) {
                    $kotMap[$stationKey] = KOT::create([
                        'order_id' => $order->id,
                        'kds_station_id' => $stationId,
                        'restaurant_id' => $request->restaurant_id,
                        'status' => 'pending'
                    ]);
                }

                $orderItem = OrderItem::create([
                    'order_id' => $order->id,
                    'kot_id' => isset($kotMap[$stationKey]) ? $kotMap[$stationKey]->id : null,
                    'menu_item_id' => $itemData['menu_item_id'],
                    'quantity' => $itemData['quantity'],
                    'price' => $itemData['price'],
                    'status' => 'pending',
                    'notes' => $itemData['notes'] ?? null
                ]);

                if (isset($itemData['temp_id'])) {
                    $tempToIdMap[$itemData['temp_id']] = $orderItem->id;
                }

                $subtotalAddition += ($itemData['quantity'] * $itemData['price']);
            }

            // Pass 2: Create Child Items
            foreach ($request->items as $itemData) {
                if (!isset($itemData['parent_temp_id']) || !$itemData['parent_temp_id']) {
                    continue;
                }

                $menuItem = MenuItem::with(['category', 'taxGroup.taxes'])->find($itemData['menu_item_id']);
                $stationId = $menuItem->category->kds_station_id ?? null;
                $stationKey = $stationId ?: 'default';

                $parentId = $tempToIdMap[$itemData['parent_temp_id']] ?? null;

                if ($order->status !== 'pending_payment' && !isset($kotMap[$stationKey])) {
                    $kotMap[$stationKey] = KOT::create([
                        'order_id' => $order->id,
                        'kds_station_id' => $stationId,
                        'restaurant_id' => $request->restaurant_id,
                        'status' => 'pending'
                    ]);
                }

                OrderItem::create([
                    'order_id' => $order->id,
                    'parent_order_item_id' => $parentId,
                    'combo_group_id' => $itemData['combo_group_id'] ?? null,
                    'kot_id' => isset($kotMap[$stationKey]) ? $kotMap[$stationKey]->id : null,
                    'menu_item_id' => $itemData['menu_item_id'],
                    'quantity' => $itemData['quantity'],
                    'price' => $itemData['price'],
                    'status' => 'pending',
                    'notes' => $itemData['notes'] ?? null
                ]);

                $subtotalAddition += ($itemData['quantity'] * $itemData['price']);
            }

            // Recalculate whole order subtotal, taxes, charges and total
            $this->recalculateOrderTotals($order);

            DB::connection('tenant')->commit();

            // Load relationships for printing
            $kots = KOT::with(['items.menuItem', 'items.children.menuItem', 'kdsStation'])
                       ->whereIn('id', collect($kotMap)->pluck('id'))
                       ->get();

            return response()->json([
                'status' => 'success', 
                'data' => [
                    'order' => $order->load('table'),
                    'kots' => $kots
                ]
            ]);



        } catch (\Exception $e) {
            DB::connection('tenant')->rollBack();
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    public function removeItem(Request $request)
    {
        $request->validate([
            'order_item_id' => 'nullable',
            'order_id' => 'nullable|string',
            'table_id' => 'nullable|string',
            'menu_item_id' => 'nullable|string',
            'restaurant_id' => 'nullable|string',
        ]);

        $this->setTenant();
        
        DB::connection('tenant')->beginTransaction();
        try {
            $item = null;
            if ($request->filled('order_item_id')) {
                $item = OrderItem::find($request->order_item_id);
            } else {
                $order = null;
                if ($request->filled('order_id')) {
                    $order = Order::find($request->order_id);
                }
                
                if (!$order && $request->filled('table_id')) {
                    // Find active order on this table
                    $order = Order::where('table_id', $request->table_id)
                        ->whereIn('status', ['open', 'preparing', 'ready'])
                        ->first();
                }

                if ($order && $request->filled('menu_item_id')) {
                    // Find the latest order item for this menu item
                    $item = OrderItem::where('order_id', $order->id)
                        ->where('menu_item_id', $request->menu_item_id)
                        ->latest()
                        ->first();
                }
            }

            if (!$item) {
                return response()->json(['status' => 'error', 'message' => 'Order item not found.'], 404);
            }

            $order = Order::findOrFail($item->order_id);
            
            if ($item->quantity > 1) {
                // Decrement quantity by 1
                $item->quantity -= 1;
                $item->save();
            } else {
                // Delete the item completely
                OrderItem::where('parent_order_item_id', $item->id)->delete();
                $item->delete();
            }

            // Recalculate whole order subtotal, taxes, charges and total
            $this->recalculateOrderTotals($order);

            DB::connection('tenant')->commit();
            return response()->json(['status' => 'success']);
        } catch (\Exception $e) {
            DB::connection('tenant')->rollBack();
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    public function generateBill(Request $request, $id)
    {
        $request->validate([
            'payment_method' => 'nullable|string',
            'amount_paid' => 'nullable|numeric',
            'discount_amount' => 'nullable|numeric',
            'discount_percentage' => 'nullable|numeric',
            'discount_type' => 'nullable|string|in:fixed,percentage',
            'discount_reason' => 'nullable|string',
            'subtotal' => 'nullable|numeric',
            'tax' => 'nullable|numeric',
            'total' => 'nullable|numeric',
            'delivery_charge' => 'nullable|numeric',
            'packing_charge' => 'nullable|numeric',
            'service_charge' => 'nullable|numeric',
            'tip_amount' => 'nullable|numeric',
            'transaction_id' => 'nullable|string',
            'notes' => 'nullable|string',
        ]);

        $this->setTenant();
        
        DB::connection('tenant')->beginTransaction();
        try {
            $order = Order::findOrFail($id);
            
            // Apply discounts and totals if provided (usually on first payment/checkout)
            if ($request->has('discount_amount') && $request->discount_amount !== null) {
                $order->discount_amount = $request->discount_amount;
                $order->discount_percentage = $request->discount_percentage ?? 0;
                $order->discount_type = $request->discount_type;
                $order->discount_reason = $request->discount_reason;
            }
            
            if ($request->has('delivery_charge')) $order->delivery_charge = $request->delivery_charge;
            if ($request->has('packing_charge')) $order->packing_charge = $request->packing_charge;
            if ($request->has('service_charge')) $order->service_charge = $request->service_charge;
            
            if ($request->has('subtotal') && $request->subtotal !== null) {
                $order->subtotal = $request->subtotal;
                $order->tax = $request->tax;
                $order->total = $request->total;
            } else {
                $this->recalculateOrderTotals($order);
            }

            if ($request->has('tip_amount') && $request->tip_amount !== null) {
                $order->tip_amount += $request->tip_amount;
            }

            $order->save();

            // Record payment
            $paidAmount = $request->amount_paid ?? $order->total;
            OrderPayment::create([
                'order_id' => $order->id,
                'amount' => $paidAmount,
                'tip_amount' => $request->tip_amount ?? 0,
                'payment_method' => $request->payment_method ?? 'cash',
                'transaction_id' => $request->transaction_id ?? null,
                'notes' => $request->notes ?? null,
            ]);

            // Check if order is fully paid
            $totalPaid = OrderPayment::where('order_id', $order->id)->sum('amount');
            
            if ($totalPaid >= $order->total) {
                $orderType = strtolower($order->order_type);
                if (strpos($orderType, 'delivery') === false && strpos($orderType, 'takeaway') === false) {
                    $order->status = 'completed';
                } else if ($order->status === 'pending_payment') {
                    $order->status = 'preparing';
                }
                $order->payment_method = $request->payment_method ?? 'cash'; // Store last method
                $order->save();

                // Generate KOTs if they were skipped (for online payments)
                if ($order->status === 'preparing') {
                    $itemsWithoutKot = OrderItem::where('order_id', $order->id)
                                                ->whereNull('kot_id')
                                                ->get();

                    if ($itemsWithoutKot->isNotEmpty()) {
                        $kotMap = [];
                        foreach ($itemsWithoutKot as $item) {
                            $menuItem = MenuItem::with('category')->find($item->menu_item_id);
                            $stationId = $menuItem->category->kds_station_id ?? null;
                            $stationKey = $stationId ?: 'default';

                            if (!isset($kotMap[$stationKey])) {
                                $kotMap[$stationKey] = KOT::create([
                                    'order_id' => $order->id,
                                    'kds_station_id' => $stationId,
                                    'restaurant_id' => $order->restaurant_id,
                                    'status' => 'pending'
                                ]);
                            }

                            $item->update(['kot_id' => $kotMap[$stationKey]->id]);
                        }
                    }
                }

                // Trigger automatic recipe deductions
                app(\App\Services\InventoryDeductionService::class)->deductForOrder($order);

                // Free the table
                if ($order->table_id) {
                    RestaurantTable::where('id', $order->table_id)->update(['status' => 'available']);
                }
            }

            $this->syncOrderRegistry($order);

            DB::connection('tenant')->commit();
            
            // Refresh order to get the latest status and payments
            $order->refresh()->load('payments');
            
            return response()->json([
                'status' => 'success', 
                'message' => $order->status == 'completed' ? 'Order completed successfully' : 'Payment recorded successfully',
                'data' => $order
            ]);
        } catch (\Exception $e) {
            DB::connection('tenant')->rollBack();
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    public function reopen(Request $request, $id)
    {
        $this->setTenant();
        $order = Order::findOrFail($id);
        $order->status = 'open';
        $order->save();

        return response()->json(['status' => 'success', 'data' => $order]);
    }

    public function show($id)
    {
        $this->setTenant();
        $order = Order::with(['items.menuItem', 'table'])->findOrFail($id);
        return response()->json(['status' => 'success', 'data' => $order]);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:open,completed,cancelled'
        ]);

        $this->setTenant();
        $order = Order::findOrFail($id);
        $order->status = $request->status;
        $order->save();

        if ($order->status === 'completed') {
            app(\App\Services\InventoryDeductionService::class)->deductForOrder($order);
        }

        $this->syncOrderRegistry($order);

        return response()->json(['status' => 'success', 'data' => $order]);
    }

    public function destroy($id)
    {
        $this->setTenant();
        
        DB::connection('tenant')->beginTransaction();
        try {
            $order = Order::findOrFail($id);
            OrderItem::where('order_id', $id)->delete();
            KOT::where('order_id', $id)->delete();
            $order->delete();
            
            \App\Models\CustomerOrderRegistry::where('tenant_order_id', $id)->delete();
            
            DB::connection('tenant')->commit();
            return response()->json(['status' => 'success', 'message' => 'Order deleted successfully']);
        } catch (\Exception $e) {
            DB::connection('tenant')->rollBack();
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    public function transferTable(Request $request)
    {
        $request->validate([
            'order_id' => 'required|uuid',
            'target_table_id' => 'required|uuid',
        ]);

        $this->setTenant();
        
        DB::connection('tenant')->beginTransaction();
        try {
            $order = Order::findOrFail($request->order_id);
            $oldTableId = $order->table_id;
            $newTableId = $request->target_table_id;

            // Check if target table has an active order
            $existingOrder = Order::where('table_id', $newTableId)
                                  ->whereIn('status', ['open', 'preparing', 'ready'])
                                  ->first();
            
            if ($existingOrder) {
                return response()->json(['status' => 'error', 'message' => 'Target table already has an active order!'], 400);
            }

            // Move the order
            $order->table_id = $newTableId;
            $order->save();

            // Update table statuses
            if ($oldTableId) {
                RestaurantTable::where('id', $oldTableId)->update(['status' => 'available']);
            }
            RestaurantTable::where('id', $newTableId)->update(['status' => 'busy']);

            DB::connection('tenant')->commit();
            
            return response()->json([
                'status' => 'success', 
                'message' => 'Order transferred successfully',
                'data' => $order->load('table')
            ]);
        } catch (\Exception $e) {
            DB::connection('tenant')->rollBack();
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    public function mergeTable(Request $request)
    {
        $request->validate([
            'source_order_id' => 'required|uuid',
            'target_order_id' => 'required|uuid',
        ]);

        $this->setTenant();
        
        DB::connection('tenant')->beginTransaction();
        try {
            $sourceOrder = Order::findOrFail($request->source_order_id);
            $targetOrder = Order::findOrFail($request->target_order_id);
            $sourceTableId = $sourceOrder->table_id;

            // Move all items from source to target
            OrderItem::where('order_id', $sourceOrder->id)->update(['order_id' => $targetOrder->id]);
            
            // Move all KOTs from source to target
            KOT::where('order_id', $sourceOrder->id)->update(['order_id' => $targetOrder->id]);

            // Recalculate target order totals
            $targetOrder->subtotal += $sourceOrder->subtotal;
            $targetOrder->tax += $sourceOrder->tax;
            $targetOrder->total += $sourceOrder->total;
            $targetOrder->save();

            // Delete source order
            $sourceOrder->delete();

            // Update source table status
            if ($sourceTableId) {
                RestaurantTable::where('id', $sourceTableId)->update(['status' => 'available']);
            }

            DB::connection('tenant')->commit();
            
            return response()->json([
                'status' => 'success', 
                'message' => 'Orders merged successfully',
                'data' => $targetOrder->load(['items', 'table'])
            ]);
        } catch (\Exception $e) {
            DB::connection('tenant')->rollBack();
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 500);
        }
    }

    /**
     * Synchronizes a tenant database order structure into the central Master registry
     * to provide lightning fast, non-blocking O(1) global query capabilities.
     */
    private function syncOrderRegistry($order)
    {
        $order->syncToCentralRegistry();
    }

    private function recalculateOrderTotals(Order $order)
    {
        $allOrderItems = OrderItem::where('order_id', $order->id)->get();
        
        $totalSubtotal = 0;
        $totalTax = 0;
        $totalExclusiveTax = 0;
        
        foreach ($allOrderItems as $item) {
            $itemTotal = $item->quantity * $item->price;
            $totalSubtotal += $itemTotal;
            
            $menuItem = MenuItem::with('taxGroup.taxes')->find($item->menu_item_id);
            if ($menuItem && $menuItem->taxGroup) {
                $taxGroup = $menuItem->taxGroup;
                $totalTaxPercentage = collect($taxGroup->taxes)->sum('percentage');
                
                if ($taxGroup->is_inclusive) {
                    $totalTax += $itemTotal * ($totalTaxPercentage / (100 + $totalTaxPercentage));
                } else {
                    $itemTax = $itemTotal * ($totalTaxPercentage / 100);
                    $totalTax += $itemTax;
                    $totalExclusiveTax += $itemTax;
                }
            }
        }
        
        $orderType = strtolower(str_replace('_', '-', $order->order_type));
        
        $serviceChargePercent = 0;
        $packingCharge = 0;
        $deliveryCharge = 0;
        
        if ($orderType === 'dine-in') {
            $packingEnabled = (DB::connection('tenant')->table('settings')->where('key', 'dinein_packing_enabled')->value('value') ?? 'no') === 'yes';
            if ($packingEnabled) {
                $packingCharge = floatval(DB::connection('tenant')->table('settings')->where('key', 'dinein_packing_amount')->value('value') ?? 0);
            }
            
            $serviceEnabled = (DB::connection('tenant')->table('settings')->where('key', 'dinein_service_enabled')->value('value') ?? 'no') === 'yes';
            if ($serviceEnabled) {
                $serviceChargePercent = floatval(DB::connection('tenant')->table('settings')->where('key', 'dinein_service_amount')->value('value') ?? 0);
            }
        } elseif ($orderType === 'takeaway') {
            $packingEnabled = (DB::connection('tenant')->table('settings')->where('key', 'takeaway_packing_enabled')->value('value') ?? 'no') === 'yes';
            if ($packingEnabled) {
                $packingCharge = floatval(DB::connection('tenant')->table('settings')->where('key', 'takeaway_packing_amount')->value('value') ?? 0);
            }
            
            $serviceEnabled = (DB::connection('tenant')->table('settings')->where('key', 'takeaway_service_enabled')->value('value') ?? 'no') === 'yes';
            if ($serviceEnabled) {
                $serviceChargePercent = floatval(DB::connection('tenant')->table('settings')->where('key', 'takeaway_service_amount')->value('value') ?? 0);
            }
        } elseif ($orderType === 'delivery') {
            $deliveryEnabled = (DB::connection('tenant')->table('settings')->where('key', 'delivery_delivery_enabled')->value('value') ?? 'no') === 'yes';
            if ($deliveryEnabled) {
                $deliveryCharge = floatval(DB::connection('tenant')->table('settings')->where('key', 'delivery_delivery_amount')->value('value') ?? 0);
            }
            
            $packingEnabled = (DB::connection('tenant')->table('settings')->where('key', 'delivery_packing_enabled')->value('value') ?? 'no') === 'yes';
            if ($packingEnabled) {
                $packingCharge = floatval(DB::connection('tenant')->table('settings')->where('key', 'delivery_packing_amount')->value('value') ?? 0);
            }
            
            $serviceEnabled = (DB::connection('tenant')->table('settings')->where('key', 'delivery_service_enabled')->value('value') ?? 'no') === 'yes';
            if ($serviceEnabled) {
                $serviceChargePercent = floatval(DB::connection('tenant')->table('settings')->where('key', 'delivery_service_amount')->value('value') ?? 0);
            }
        }
        
        $serviceCharge = $totalSubtotal * ($serviceChargePercent / 100);
        
        $order->subtotal = $totalSubtotal;
        $order->tax = $totalTax;
        $order->delivery_charge = $deliveryCharge;
        $order->packing_charge = $packingCharge;
        $order->service_charge = $serviceCharge;
        
        $discountAmount = 0;
        if ($order->discount_type === 'percentage') {
            $discountAmount = $totalSubtotal * ($order->discount_percentage / 100);
            $order->discount_amount = $discountAmount;
        } else {
            $discountAmount = $order->discount_amount;
        }
        
        $order->total = max(0, $totalSubtotal + $totalExclusiveTax + $deliveryCharge + $packingCharge + $serviceCharge - $discountAmount);
        $order->save();
        
        $this->syncOrderRegistry($order);
    }

    public function initiateRazorpayPayment(Request $request, $id)
    {
        // Automatically resolve tenant database by looking up the order inside the central master database registry
        $registry = \App\Models\CustomerOrderRegistry::where('tenant_order_id', $id)->first();
        if ($registry) {
            $restaurant = \App\Models\Restaurant::find($registry->restaurant_id);
            if ($restaurant) {
                $dbName = 'resto_' . str_replace('-', '_', $restaurant->user_id);
                $this->tenantService->switchToTenant($dbName);
            } else {
                $this->setTenant();
            }
        } else {
            $this->setTenant();
        }

        $order = Order::findOrFail($id);

        $key = \App\Models\Setting::get('razorpay_key');
        $secret = \App\Models\Setting::get('razorpay_secret');

        if (!$key || !$secret) {
            return response()->json([
                'status' => 'error',
                'message' => 'Razorpay credentials are not configured in SaaS settings.'
            ], 400);
        }

        try {
            // Create a Razorpay Order (required for native Android/iOS SDK)
            $response = \Illuminate\Support\Facades\Http::withBasicAuth($key, $secret)
                ->post('https://api.razorpay.com/v1/orders', [
                    'amount'   => round($order->total * 100), // in paise
                    'currency' => 'INR',
                    'receipt'  => 'eo_' . substr($order->id, 0, 8),
                    'notes'    => ['tenant_order_id' => $order->id],
                ]);

            if ($response->successful()) {
                $rzpOrder = $response->json();
                return response()->json([
                    'status' => 'success',
                    'data'   => [
                        'razorpay_order_id' => $rzpOrder['id'],     // format: order_XXXXX
                        'razorpay_key'      => $key,
                        'amount'            => $rzpOrder['amount'],  // in paise
                    ]
                ]);
            } else {
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Razorpay API error: ' . ($response->json()['error']['description'] ?? $response->body())
                ], 400);
            }
        } catch (\Exception $e) {
            return response()->json([
                'status'  => 'error',
                'message' => 'Unable to connect to Razorpay: ' . $e->getMessage()
            ], 500);
        }
    }

    public function paymentCallback(Request $request)
    {
        $restaurantId = $request->input('restaurant_id');
        $orderId = $request->input('order_id');

        if (!$restaurantId || !$orderId) {
            return response('Missing parameters', 400);
        }

        // Locate restaurant and switch to tenant
        $restaurant = \App\Models\Restaurant::find($restaurantId);
        if (!$restaurant) {
            return response('Restaurant not found', 400);
        }

        $dbName = 'resto_' . str_replace('-', '_', $restaurant->user_id);
        $this->tenantService->switchToTenant($dbName);

        // Find the order
        $order = Order::find($orderId);
        if (!$order) {
            return response('Order not found', 400);
        }

        DB::connection('tenant')->beginTransaction();
        try {
            // Mark the order as paid/completed immediately when paid online!
            $order->status = 'preparing';
            $order->payment_method = 'ONLINE';
            $order->save();

            // Record transaction in order payments
            OrderPayment::create([
                'order_id' => $order->id,
                'amount' => $order->total,
                'tip_amount' => 0,
                'payment_method' => 'ONLINE',
                'transaction_id' => $request->input('razorpay_payment_id') ?? 'online_' . uniqid(),
                'notes' => 'Setted securely via Razorpay Payment Link',
            ]);

            $order->syncToCentralRegistry();

            DB::connection('tenant')->commit();
        } catch (\Exception $e) {
            DB::connection('tenant')->rollBack();
            return response('Callback processing error: ' . $e->getMessage(), 500);
        }

        // Return a beautiful HTML confirmation page
        return '
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Payment Successful - EatsOnly</title>
            <style>
                body {
                    background-color: #0F1115;
                    color: white;
                    font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                }
                .container {
                    text-align: center;
                    background: #16181D;
                    padding: 40px;
                    border-radius: 24px;
                    border: 1px solid #D4AF37;
                    max-width: 400px;
                    box-shadow: 0 10px 30px rgba(0,0,0,0.5);
                }
                .icon {
                    color: #D4AF37;
                    font-size: 64px;
                    margin-bottom: 20px;
                }
                h1 {
                    font-size: 24px;
                    margin-bottom: 10px;
                    font-weight: 800;
                }
                p {
                    color: #A0A5B1;
                    font-size: 14px;
                    line-height: 1.5;
                    margin-bottom: 30px;
                }
                .btn {
                    background: #D4AF37;
                    color: black;
                    border: none;
                    padding: 12px 24px;
                    font-size: 14px;
                    font-weight: bold;
                    border-radius: 12px;
                    cursor: pointer;
                    text-decoration: none;
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="icon">✓</div>
                <h1>Payment Successful!</h1>
                <p>Your transaction has been securely captured by Razorpay. You can now close this window and track your order in the EatsOnly application.</p>
                <button class="btn" onclick="window.close()">Close Window</button>
            </div>
        </body>
        </html>';
    }

    public function getDeliveryPartners(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required|string',
        ]);

        $deliveryStaff = DB::table('restaurant_role_user')
            ->join('roles', 'restaurant_role_user.role_id', '=', 'roles.id')
            ->join('users', 'restaurant_role_user.user_id', '=', 'users.id')
            ->where('restaurant_role_user.restaurant_id', $request->restaurant_id)
            ->where('roles.name', 'delivery_executive')
            ->select('users.id', 'users.name', 'users.email', 'users.mobile')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $deliveryStaff
        ]);
    }

    public function assignDeliveryPartner(Request $request, $id)
    {
        $request->validate([
            'restaurant_id' => 'required|string',
            'delivery_staff_id' => 'required|string',
        ]);

        $this->setTenant();

        $order = Order::find($id);
        if (!$order) {
            return response()->json([
                'status' => 'error',
                'message' => 'Order not found.'
            ], 404);
        }

        $order->update([
            'delivery_staff_id' => $request->delivery_staff_id,
            'delivery_status' => 'assigned',
        ]);

        $order->syncToCentralRegistry();

        return response()->json([
            'status' => 'success',
            'message' => 'Delivery partner assigned successfully.',
            'data' => $order
        ]);
    }
}
