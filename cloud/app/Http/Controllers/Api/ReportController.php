<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    protected $tenantService;

    public function __construct(TenantService $tenantService)
    {
        $this->tenantService = $tenantService;
    }

    public function getTipReport(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'waiter_id' => 'nullable|uuid'
        ]);

        $user = Auth::user();
        $this->tenantService->ensureTenantDatabase($user);

        $startDate = $request->start_date ?? now()->startOfMonth()->format('Y-m-d');
        $endDate = $request->end_date ?? now()->format('Y-m-d');

        $query = Order::on('tenant')
            ->where('tip_amount', '>', 0)
            ->whereBetween('created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59']);

        if ($request->waiter_id) {
            $query->where('user_id', $request->waiter_id);
        }

        $totalTips = (float) $query->sum('tip_amount');
        $totalOrdersWithTips = $query->count();

        // Group by waiter
        $tipsByWaiter = Order::on('tenant')
            ->select('user_id', DB::raw('SUM(tip_amount) as total_tips'), DB::raw('COUNT(*) as order_count'))
            ->where('tip_amount', '>', 0)
            ->whereBetween('created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59'])
            ->groupBy('user_id')
            ->get();

        $waiterIds = $tipsByWaiter->pluck('user_id')->filter()->toArray();
        $waiterNames = User::whereIn('id', $waiterIds)->pluck('name', 'id');

        $tipsByWaiter = $tipsByWaiter->map(function ($item) use ($waiterNames) {
            return [
                'user_id' => $item->user_id,
                'waiter_name' => $waiterNames[$item->user_id] ?? 'Unknown',
                'total_tips' => (float) $item->total_tips,
                'order_count' => (int) $item->order_count,
            ];
        });

        // Group by date
        $tipsByDate = Order::on('tenant')
            ->select(DB::raw('DATE(created_at) as date'), DB::raw('SUM(tip_amount) as total_tips'))
            ->where('tip_amount', '>', 0)
            ->whereBetween('created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59'])
            ->groupBy('date')
            ->orderBy('date', 'desc')
            ->get()
            ->map(fn($item) => [
                'date' => $item->date,
                'total_tips' => (float) $item->total_tips
            ]);

        return response()->json([
            'status' => 'success',
            'data' => [
                'summary' => [
                    'total_tips' => $totalTips,
                    'order_count' => $totalOrdersWithTips,
                    'average_tip' => $totalOrdersWithTips > 0 ? $totalTips / $totalOrdersWithTips : 0,
                ],
                'by_waiter' => $tipsByWaiter,
                'by_date' => $tipsByDate,
            ]
        ]);
    }

    public function getSalesReport(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'range' => 'nullable|string' // 'Today', 'Weekly', 'Monthly'
        ]);

        $user = Auth::user();
        $this->tenantService->ensureTenantDatabase($user);

        $restaurantId = $request->restaurant_id;
        $range = $request->range ?? 'Today';

        // Set date range and previous periods for trend calculations
        if ($range === 'Weekly') {
            $startDate = now()->subDays(6)->format('Y-m-d');
            $endDate = now()->format('Y-m-d');
            
            $prevStartDate = now()->subDays(13)->format('Y-m-d');
            $prevEndDate = now()->subDays(7)->format('Y-m-d');
        } elseif ($range === 'Monthly') {
            $startDate = now()->subDays(29)->format('Y-m-d');
            $endDate = now()->format('Y-m-d');
            
            $prevStartDate = now()->subDays(59)->format('Y-m-d');
            $prevEndDate = now()->subDays(30)->format('Y-m-d');
        } else { // Today
            $startDate = now()->format('Y-m-d');
            $endDate = now()->format('Y-m-d');
            
            $prevStartDate = now()->subDay()->format('Y-m-d');
            $prevEndDate = now()->subDay()->format('Y-m-d');
        }

        // --- Core Totals ---
        $currentOrdersQuery = Order::on('tenant')
            ->where('restaurant_id', $restaurantId)
            ->where('status', '!=', 'cancelled');

        $totalRevenue = (float) (clone $currentOrdersQuery)
            ->whereBetween('created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59'])
            ->sum('total');

        $totalOrders = (clone $currentOrdersQuery)
            ->whereBetween('created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59'])
            ->count();

        $avgOrderValue = $totalOrders > 0 ? $totalRevenue / $totalOrders : 0;

        // --- Previous Period Totals for Trends ---
        $prevOrdersQuery = Order::on('tenant')
            ->where('restaurant_id', $restaurantId)
            ->where('status', '!=', 'cancelled');

        $prevRevenue = (float) (clone $prevOrdersQuery)
            ->whereBetween('created_at', [$prevStartDate . ' 00:00:00', $prevEndDate . ' 23:59:59'])
            ->sum('total');

        $prevOrders = (clone $prevOrdersQuery)
            ->whereBetween('created_at', [$prevStartDate . ' 00:00:00', $prevEndDate . ' 23:59:59'])
            ->count();

        $prevAvgOrderValue = $prevOrders > 0 ? $prevRevenue / $prevOrders : 0;

        // Calculate changes
        $revenueChange = $prevRevenue > 0 ? (($totalRevenue - $prevRevenue) / $prevRevenue) * 100 : 0;
        $ordersChange = $prevOrders > 0 ? (($totalOrders - $prevOrders) / $prevOrders) * 100 : 0;
        $aovChange = $prevAvgOrderValue > 0 ? (($avgOrderValue - $prevAvgOrderValue) / $prevAvgOrderValue) * 100 : 0;

        // --- Sales Trend by Date or Hour ---
        if ($range === 'Today') {
            // Group by hour
            $trendData = Order::on('tenant')
                ->select(DB::raw('HOUR(created_at) as label'), DB::raw('SUM(total) as value'))
                ->where('restaurant_id', $restaurantId)
                ->where('status', '!=', 'cancelled')
                ->whereBetween('created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59'])
                ->groupBy('label')
                ->orderBy('label')
                ->get()
                ->map(fn($item) => [
                    'label' => sprintf('%02d:00', $item->label),
                    'value' => (float) $item->value
                ]);
        } else {
            // Group by date
            $trendData = Order::on('tenant')
                ->select(DB::raw('DATE(created_at) as label'), DB::raw('SUM(total) as value'))
                ->where('restaurant_id', $restaurantId)
                ->where('status', '!=', 'cancelled')
                ->whereBetween('created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59'])
                ->groupBy('label')
                ->orderBy('label')
                ->get()
                ->map(fn($item) => [
                    'label' => date('d M', strtotime($item->label)),
                    'value' => (float) $item->value
                ]);
        }

        // --- Order Type Breakdown ---
        $orderTypes = Order::on('tenant')
            ->select('order_type', DB::raw('SUM(total) as total'))
            ->where('restaurant_id', $restaurantId)
            ->where('status', '!=', 'cancelled')
            ->whereBetween('created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59'])
            ->groupBy('order_type')
            ->get()
            ->map(fn($item) => [
                'type' => $item->order_type ?: 'Dine-In',
                'total' => (float) $item->total
            ]);

        // --- Payment Mode Splits ---
        $paymentSplits = Order::on('tenant')
            ->select('payment_method', DB::raw('SUM(total) as total'))
            ->where('restaurant_id', $restaurantId)
            ->where('status', '!=', 'cancelled')
            ->whereBetween('created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59'])
            ->groupBy('payment_method')
            ->get()
            ->map(fn($item) => [
                'method' => $item->payment_method ?: 'Cash',
                'total' => (float) $item->total
            ]);

        // --- Category Distribution ---
        $categoryDistribution = DB::connection('tenant')->table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->join('menu_items', 'order_items.menu_item_id', '=', 'menu_items.id')
            ->join('menu_categories', 'menu_items.menu_category_id', '=', 'menu_categories.id')
            ->select('menu_categories.name as category', DB::raw('SUM(order_items.quantity * order_items.price) as total'))
            ->where('orders.restaurant_id', $restaurantId)
            ->where('orders.status', '!=', 'cancelled')
            ->whereBetween('orders.created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59'])
            ->groupBy('menu_categories.id', 'menu_categories.name')
            ->get()
            ->map(fn($item) => [
                'category' => $item->category,
                'total' => (float) $item->total
            ]);

        // --- Recent Transactions ---
        $recentTransactions = Order::on('tenant')
            ->where('restaurant_id', $restaurantId)
            ->where('status', '!=', 'cancelled')
            ->orderBy('created_at', 'desc')
            ->limit(10)
            ->get()
            ->map(fn($item) => [
                'id' => $item->id,
                'customer' => $item->customer_name ?: 'Guest Customer',
                'type' => $item->order_type ?: 'Dine-In',
                'payment' => $item->payment_method ?: 'Cash',
                'total' => (float) $item->total,
                'time' => $item->created_at->diffForHumans()
            ]);

        return response()->json([
            'status' => 'success',
            'data' => [
                'summary' => [
                    'revenue' => $totalRevenue,
                    'revenue_change' => $revenueChange,
                    'orders' => $totalOrders,
                    'orders_change' => $ordersChange,
                    'avg_order_value' => $avgOrderValue,
                    'avg_order_value_change' => $aovChange,
                ],
                'trend' => $trendData,
                'order_types' => $orderTypes,
                'payments' => $paymentSplits,
                'categories' => $categoryDistribution,
                'recent' => $recentTransactions,
            ]
        ]);
    }

    private function getConversionFactor($fromUnit, $toUnit)
    {
        $from = strtolower($fromUnit ?? '');
        $to = strtolower($toUnit ?? '');
        if ($from === $to) return 1.0;
        
        if ($from === 'kg' && $to === 'g') return 1000.0;
        if ($from === 'g' && $to === 'kg') return 0.001;
        if (($from === 'l' || $from === 'ltr') && $to === 'ml') return 1000.0;
        if ($from === 'ml' && ($to === 'l' || $to === 'ltr')) return 0.001;
        
        return 1.0;
    }

    public function getLeakageReport(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'range' => 'nullable|string' // 'Today', 'Weekly', 'Monthly'
        ]);

        $user = Auth::user();
        $this->tenantService->ensureTenantDatabase($user);

        $restaurantId = $request->restaurant_id;
        $range = $request->range ?? 'Today';

        if ($range === 'Weekly') {
            $startDate = now()->subDays(6)->format('Y-m-d');
            $endDate = now()->format('Y-m-d');
        } elseif ($range === 'Monthly') {
            $startDate = now()->subDays(29)->format('Y-m-d');
            $endDate = now()->format('Y-m-d');
        } else { // Today
            $startDate = now()->format('Y-m-d');
            $endDate = now()->format('Y-m-d');
        }

        // 1. Fetch Wastage Entries with inventory item cost
        $wastageEntries = \App\Models\WastageEntry::on('tenant')
            ->with('inventoryItem')
            ->where('restaurant_id', $restaurantId)
            ->whereBetween('created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59'])
            ->get();

        $totalWastageCost = 0.0;
        $wastageByReason = [
            'Spoiled/Expired' => 0.0,
            'Kitchen/Cooking Error' => 0.0,
            'Spill/Damage' => 0.0,
            'Other' => 0.0
        ];
        $itemWastageTotals = [];

        foreach ($wastageEntries as $entry) {
            $item = $entry->inventoryItem;
            if (!$item) continue;

            $qty = (float) $entry->quantity;
            $costPerUnit = (float) $item->cost_per_unit;
            
            // Apply unit conversion factor
            $factor = $this->getConversionFactor($entry->unit, $item->unit);
            $cost = $qty * $factor * $costPerUnit;

            $totalWastageCost += $cost;

            // Map reason
            $reason = trim($entry->reason);
            if (stripos($reason, 'spoilt') !== false || stripos($reason, 'expired') !== false || stripos($reason, 'spoilage') !== false || stripos($reason, 'expiry') !== false) {
                $wastageByReason['Spoiled/Expired'] += $cost;
            } elseif (stripos($reason, 'burnt') !== false || stripos($reason, 'cooking') !== false || stripos($reason, 'error') !== false || stripos($reason, 'kitchen') !== false) {
                $wastageByReason['Kitchen/Cooking Error'] += $cost;
            } elseif (stripos($reason, 'spill') !== false || stripos($reason, 'damage') !== false || stripos($reason, 'dropped') !== false) {
                $wastageByReason['Spill/Damage'] += $cost;
            } else {
                $wastageByReason['Other'] += $cost;
            }

            // Group by item for top wasted
            if (!isset($itemWastageTotals[$item->name])) {
                $itemWastageTotals[$item->name] = [
                    'name' => $item->name,
                    'qty' => 0.0,
                    'unit' => $item->unit,
                    'cost' => 0.0
                ];
            }
            $itemWastageTotals[$item->name]['qty'] += ($qty * $factor);
            $itemWastageTotals[$item->name]['cost'] += $cost;
        }

        // 2. Fetch Audit Cost Variances
        $auditItems = \App\Models\StockAuditItem::on('tenant')
            ->whereHas('audit', function($query) use ($restaurantId, $startDate, $endDate) {
                $query->where('restaurant_id', $restaurantId)
                    ->whereBetween('created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59']);
            })
            ->with('inventoryItem')
            ->get();

        $totalAuditLoss = 0.0;
        foreach ($auditItems as $auditItem) {
            $costVar = (float) $auditItem->cost_variance;
            // Negative cost_variance represents physical stock less than expected (theft/loss)
            if ($costVar < 0) {
                $totalAuditLoss += abs($costVar);
            }
        }

        // Sort item wastage and take top 5
        usort($itemWastageTotals, fn($a, $b) => $b['cost'] <=> $a['cost']);
        $topWastedItems = array_slice($itemWastageTotals, 0, 5);

        // Trend over time
        $trendData = [];
        if ($range === 'Today') {
            for ($i = 0; $i < 24; $i += 4) {
                $hourLabel = sprintf('%02d:00', $i);
                $costSum = 0.0;
                foreach ($wastageEntries as $entry) {
                    $entryHour = (int) $entry->created_at->format('H');
                    if ($entryHour >= $i && $entryHour < $i + 4) {
                        $item = $entry->inventoryItem;
                        if ($item) {
                            $costSum += ((float)$entry->quantity * $this->getConversionFactor($entry->unit, $item->unit) * (float)$item->cost_per_unit);
                        }
                    }
                }
                $trendData[] = [
                    'label' => $hourLabel,
                    'wastage' => $costSum,
                    'audit' => 0.0
                ];
            }
        } else {
            $daysCount = $range === 'Weekly' ? 7 : 30;
            for ($i = $daysCount - 1; $i >= 0; $i--) {
                $dateStr = now()->subDays($i)->format('Y-m-d');
                $label = now()->subDays($i)->format('d M');

                $wastageCostSum = 0.0;
                foreach ($wastageEntries as $entry) {
                    if ($entry->created_at->format('Y-m-d') === $dateStr) {
                        $item = $entry->inventoryItem;
                        if ($item) {
                            $wastageCostSum += ((float)$entry->quantity * $this->getConversionFactor($entry->unit, $item->unit) * (float)$item->cost_per_unit);
                        }
                    }
                }

                $auditCostSum = 0.0;
                foreach ($auditItems as $auditItem) {
                    if ($auditItem->created_at->format('Y-m-d') === $dateStr && (float)$auditItem->cost_variance < 0) {
                        $auditCostSum += abs((float)$auditItem->cost_variance);
                    }
                }

                $trendData[] = [
                    'label' => $label,
                    'wastage' => $wastageCostSum,
                    'audit' => $auditCostSum
                ];
            }
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'summary' => [
                    'total_wastage_cost' => $totalWastageCost,
                    'total_audit_loss' => $totalAuditLoss,
                    'total_financial_loss' => $totalWastageCost + $totalAuditLoss,
                ],
                'by_reason' => array_map(fn($key, $val) => ['reason' => $key, 'cost' => $val], array_keys($wastageByReason), $wastageByReason),
                'top_wasted' => $topWastedItems,
                'trend' => $trendData
            ]
        ]);
    }

    public function getMenuEngineeringReport(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'range' => 'nullable|string' // 'Today', 'Weekly', 'Monthly'
        ]);

        $user = Auth::user();
        $this->tenantService->ensureTenantDatabase($user);

        $restaurantId = $request->restaurant_id;
        $range = $request->range ?? 'Today';

        if ($range === 'Weekly') {
            $startDate = now()->subDays(6)->format('Y-m-d');
            $endDate = now()->format('Y-m-d');
        } elseif ($range === 'Monthly') {
            $startDate = now()->subDays(29)->format('Y-m-d');
            $endDate = now()->format('Y-m-d');
        } else { // Today
            $startDate = now()->format('Y-m-d');
            $endDate = now()->format('Y-m-d');
        }

        // Fetch all order items sold during this period
        $soldItems = DB::connection('tenant')->table('order_items')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->join('menu_items', 'order_items.menu_item_id', '=', 'menu_items.id')
            ->select('menu_items.id', 'menu_items.name', 'menu_items.price', DB::raw('SUM(order_items.quantity) as qty_sold'))
            ->where('orders.restaurant_id', $restaurantId)
            ->where('orders.status', '!=', 'cancelled')
            ->whereBetween('orders.created_at', [$startDate . ' 00:00:00', $endDate . ' 23:59:59'])
            ->groupBy('menu_items.id', 'menu_items.name', 'menu_items.price')
            ->get();

        if ($soldItems->isEmpty()) {
            return response()->json([
                'status' => 'success',
                'data' => [
                    'matrix' => [],
                    'averages' => ['volume' => 0, 'margin' => 0]
                ]
            ]);
        }

        // Load all recipes and raw cost per units
        $recipes = \App\Models\Recipe::on('tenant')->with('inventoryItem')->get()->groupBy('menu_item_id');

        $itemsWithMetrics = [];
        $totalVolume = 0;
        $totalMargin = 0.0;

        foreach ($soldItems as $sold) {
            $menuItemId = $sold->id;
            $price = (float) $sold->price;
            $qty = (int) $sold->qty_sold;

            // Compute Recipe Cost
            $recipeCost = 0.0;
            if (isset($recipes[$menuItemId])) {
                foreach ($recipes[$menuItemId] as $recipe) {
                    $item = $recipe->inventoryItem;
                    if ($item) {
                        $qtyNeeded = (float) $recipe->quantity_needed;
                        $costPerUnit = (float) $item->cost_per_unit;
                        $factor = $this->getConversionFactor($recipe->consumption_unit, $item->unit);
                        $recipeCost += ($qtyNeeded * $factor * $costPerUnit);
                    }
                }
            } else {
                // Fallback: 30% of price is cost
                $recipeCost = $price * 0.30;
            }

            $grossMargin = $price - $recipeCost;

            $itemsWithMetrics[] = [
                'id' => $menuItemId,
                'name' => $sold->name,
                'price' => $price,
                'volume' => $qty,
                'margin' => $grossMargin,
                'recipe_cost' => $recipeCost
            ];

            $totalVolume += $qty;
            $totalMargin += $grossMargin;
        }

        $count = count($itemsWithMetrics);
        $avgVolume = $totalVolume / $count;
        $avgMargin = $totalMargin / $count;

        // Classify into Quadrants
        $matrix = [];
        foreach ($itemsWithMetrics as $item) {
            $vol = $item['volume'];
            $marg = $item['margin'];

            if ($vol >= $avgVolume) {
                $quadrant = $marg >= $avgMargin ? 'Stars' : 'Plowhorses';
            } else {
                $quadrant = $marg >= $avgMargin ? 'Puzzles' : 'Dogs';
            }

            $item['quadrant'] = $quadrant;
            $matrix[] = $item;
        }

        return response()->json([
            'status' => 'success',
            'data' => [
                'matrix' => $matrix,
                'averages' => [
                    'volume' => round($avgVolume, 1),
                    'margin' => round($avgMargin, 2)
                ]
            ]
        ]);
    }

    public function downloadReport(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'type' => 'required|string|in:sales,purchases,wastage',
            'start_date' => 'nullable|date_format:Y-m-d',
            'end_date' => 'nullable|date_format:Y-m-d',
            'month' => 'nullable|date_format:Y-m',
            'token' => 'nullable|string'
        ]);

        $user = Auth::user();

        // 1. Authenticate via query token (for direct browser downloads)
        if (!$user && $request->filled('token')) {
            $tokenModel = \Laravel\Sanctum\PersonalAccessToken::findToken($request->token);
            if ($tokenModel) {
                $user = $tokenModel->tokenable;
                Auth::login($user);
            }
        }

        // 2. Authenticate via standard bearer headers if available
        if (!$user && $request->bearerToken()) {
            $tokenModel = \Laravel\Sanctum\PersonalAccessToken::findToken($request->bearerToken());
            if ($tokenModel) {
                $user = $tokenModel->tokenable;
                Auth::login($user);
            }
        }

        if (!$user) {
            abort(401, 'Unauthorized');
        }

        $this->tenantService->ensureTenantDatabase($user);

        $restaurantId = $request->restaurant_id;
        $type = $request->type;

        // Resolve date ranges
        if ($request->filled('month')) {
            $month = $request->month;
            $startDate = "{$month}-01 00:00:00";
            $endDate = date('Y-m-t', strtotime($startDate)) . " 23:59:59";
        } elseif ($request->filled('start_date') && $request->filled('end_date')) {
            $startDate = $request->start_date . " 00:00:00";
            $endDate = $request->end_date . " 23:59:59";
        } else {
            // Default to current month
            $startDate = date('Y-m-01 00:00:00');
            $endDate = date('Y-m-t 23:59:59');
        }

        // Support returning JSON instead of CSV for native printing (e.g. PDF generation)
        if ($request->query('format') === 'json') {
            $data = [];
            if ($type === 'sales') {
                $orders = \App\Models\Order::on('tenant')
                    ->where('restaurant_id', $restaurantId)
                    ->whereBetween('created_at', [$startDate, $endDate])
                    ->orderBy('created_at', 'asc')
                    ->get();

                foreach ($orders as $order) {
                    $tax = (float) $order->tax;
                    $cgst = round($tax / 2, 2);
                    $sgst = round($tax / 2, 2);
                    $data[] = [
                        'id' => $order->id,
                        'date' => $order->created_at->format('Y-m-d H:i:s'),
                        'customer_name' => $order->customer_name ?: 'Guest Customer',
                        'customer_phone' => $order->customer_phone ?: 'N/A',
                        'order_type' => $order->order_type ?: 'Dine-In',
                        'status' => strtoupper($order->status),
                        'payment_method' => $order->payment_method ?: 'N/A',
                        'subtotal' => (float)$order->subtotal,
                        'discount_amount' => (float)$order->discount_amount,
                        'cgst' => $cgst,
                        'sgst' => $sgst,
                        'tip_amount' => (float)$order->tip_amount,
                        'total' => (float)$order->total
                    ];
                }
            } elseif ($type === 'purchases') {
                $purchases = \App\Models\PurchaseOrder::on('tenant')
                    ->with('supplier')
                    ->where('restaurant_id', $restaurantId)
                    ->whereBetween('order_date', [date('Y-m-d', strtotime($startDate)), date('Y-m-d', strtotime($endDate))])
                    ->orderBy('order_date', 'asc')
                    ->get();

                foreach ($purchases as $po) {
                    $data[] = [
                        'po_number' => $po->po_number,
                        'order_date' => $po->order_date,
                        'supplier_name' => $po->supplier ? $po->supplier->name : 'N/A',
                        'supplier_email' => $po->supplier ? $po->supplier->email : 'N/A',
                        'supplier_phone' => $po->supplier ? $po->supplier->phone : 'N/A',
                        'status' => strtoupper($po->status),
                        'total_amount' => (float)$po->total_amount
                    ];
                }
            } else {
                $wastages = \App\Models\WastageEntry::on('tenant')
                    ->with('inventoryItem')
                    ->where('restaurant_id', $restaurantId)
                    ->whereBetween('created_at', [$startDate, $endDate])
                    ->orderBy('created_at', 'asc')
                    ->get();

                foreach ($wastages as $entry) {
                    $item = $entry->inventoryItem;
                    if (!$item) continue;

                    $qty = (float) $entry->quantity;
                    $costPerUnit = (float) $item->cost_per_unit;
                    $factor = $this->getConversionFactor($entry->unit, $item->unit);
                    $loss = $qty * $factor * $costPerUnit;

                    $data[] = [
                        'id' => $entry->id,
                        'date' => $entry->created_at->format('Y-m-d H:i:s'),
                        'item_name' => $item->name,
                        'sku' => $item->sku ?: 'N/A',
                        'quantity' => $qty,
                        'unit' => $entry->unit,
                        'cost_per_unit' => $costPerUnit,
                        'financial_loss' => $loss,
                        'reason' => $entry->reason,
                        'notes' => $entry->notes ?: 'N/A'
                    ];
                }
            }

            return response()->json([
                'status' => 'success',
                'data' => $data
            ]);
        }

        $headers = [
            'Content-type' => 'text/csv',
            'Content-Disposition' => "attachment; filename={$type}_report_" . date('Ymd_His') . ".csv",
            'Pragma' => 'no-cache',
            'Cache-Control' => 'must-revalidate, post-check=0, pre-check=0',
            'Expires' => '0'
        ];

        $callback = function() use ($restaurantId, $type, $startDate, $endDate) {
            $file = fopen('php://output', 'w');

            if ($type === 'sales') {
                fputcsv($file, [
                    'Order/Invoice ID', 'Date & Time', 'Customer Name', 'Phone', 
                    'Order Type', 'Status', 'Payment Method', 'Subtotal (₹)', 
                    'Discount (₹)', 'CGST (2.5% - ₹)', 'SGST (2.5% - ₹)', 'Tip (₹)', 'Total Amount (₹)'
                ]);

                $orders = \App\Models\Order::on('tenant')
                    ->where('restaurant_id', $restaurantId)
                    ->whereBetween('created_at', [$startDate, $endDate])
                    ->orderBy('created_at', 'asc')
                    ->get();

                foreach ($orders as $order) {
                    $tax = (float) $order->tax;
                    $cgst = round($tax / 2, 2);
                    $sgst = round($tax / 2, 2);

                    fputcsv($file, [
                        $order->id,
                        $order->created_at->format('Y-m-d H:i:s'),
                        $order->customer_name ?: 'Guest Customer',
                        $order->customer_phone ?: 'N/A',
                        $order->order_type ?: 'Dine-In',
                        strtoupper($order->status),
                        $order->payment_method ?: 'N/A',
                        number_format($order->subtotal, 2, '.', ''),
                        number_format($order->discount_amount, 2, '.', ''),
                        number_format($cgst, 2, '.', ''),
                        number_format($sgst, 2, '.', ''),
                        number_format($order->tip_amount, 2, '.', ''),
                        number_format($order->total, 2, '.', '')
                    ]);
                }

            } elseif ($type === 'purchases') {
                fputcsv($file, [
                    'PO Number', 'Order Date', 'Supplier Name', 'Supplier Email', 
                    'Supplier Phone', 'Status', 'Total Amount (₹)'
                ]);

                $purchases = \App\Models\PurchaseOrder::on('tenant')
                    ->with('supplier')
                    ->where('restaurant_id', $restaurantId)
                    ->whereBetween('order_date', [date('Y-m-d', strtotime($startDate)), date('Y-m-d', strtotime($endDate))])
                    ->orderBy('order_date', 'asc')
                    ->get();

                foreach ($purchases as $po) {
                    fputcsv($file, [
                        $po->po_number,
                        $po->order_date,
                        $po->supplier ? $po->supplier->name : 'N/A',
                        $po->supplier ? $po->supplier->email : 'N/A',
                        $po->supplier ? $po->supplier->phone : 'N/A',
                        strtoupper($po->status),
                        number_format($po->total_amount, 2, '.', '')
                    ]);
                }

            } else {
                fputcsv($file, [
                    'Wastage ID', 'Logged At', 'Item Name', 'SKU', 
                    'Quantity', 'Unit', 'Cost Per Unit (₹)', 'Est. Financial Loss (₹)', 'Reason', 'Notes'
                ]);

                $wastages = \App\Models\WastageEntry::on('tenant')
                    ->with('inventoryItem')
                    ->where('restaurant_id', $restaurantId)
                    ->whereBetween('created_at', [$startDate, $endDate])
                    ->orderBy('created_at', 'asc')
                    ->get();

                foreach ($wastages as $entry) {
                    $item = $entry->inventoryItem;
                    if (!$item) continue;

                    $qty = (float) $entry->quantity;
                    $costPerUnit = (float) $item->cost_per_unit;
                    $factor = $this->getConversionFactor($entry->unit, $item->unit);
                    $loss = $qty * $factor * $costPerUnit;

                    fputcsv($file, [
                        $entry->id,
                        $entry->created_at->format('Y-m-d H:i:s'),
                        $item->name,
                        $item->sku ?: 'N/A',
                        number_format($qty, 2, '.', ''),
                        $entry->unit,
                        number_format($costPerUnit, 2, '.', ''),
                        number_format($loss, 2, '.', ''),
                        $entry->reason,
                        $entry->notes ?: 'N/A'
                    ]);
                }
            }

            fclose($file);
        };

        return response()->stream($callback, 200, $headers);
    }
}
