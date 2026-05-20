<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use App\Models\Restaurant;
use App\Models\User;
use App\Models\CustomerOrderRegistry;
use Illuminate\Support\Facades\DB;
use App\Services\TenantService;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('orders:sync', function (TenantService $tenantService) {
    $this->info("Starting global order synchronization to central registry...");

    // Get all customers to randomly distribute guest orders for demonstration/seeding purposes
    $customers = User::all()->filter(function($u) {
        return $u->isCustomer();
    })->values();

    if ($customers->isEmpty()) {
        $this->error("No customer users found in master database! Please seed users first.");
        return;
    }

    $restaurants = Restaurant::all();
    $totalSynced = 0;

    foreach ($restaurants as $restaurant) {
        $dbName = 'resto_' . str_replace('-', '_', $restaurant->user_id);
        $this->comment("Syncing orders for: {$restaurant->name} (Database: {$dbName})");

        try {
            $tenantService->switchToTenant($dbName);

            $orders = DB::connection('tenant')->table('orders')->get();
            
            foreach ($orders as $order) {
                // If customer_id is missing, assign one for display purposes
                $customerId = $order->customer_id;
                if (!$customerId) {
                    // Grab a customer user (e.g. Royce Rathod)
                    $customer = $customers->first();
                    $customerId = $customer->id;
                    
                    // Update the tenant order with this customer_id so they match!
                    DB::connection('tenant')->table('orders')
                        ->where('id', $order->id)
                        ->update(['customer_id' => $customerId]);
                }

                // Fetch items for this order from tenant DB
                $items = DB::connection('tenant')->table('order_items')
                    ->leftJoin('menu_items', 'order_items.menu_item_id', '=', 'menu_items.id')
                    ->where('order_items.order_id', $order->id)
                    ->whereNull('order_items.parent_order_item_id')
                    ->select('order_items.quantity', 'menu_items.name')
                    ->get();

                $summaryParts = [];
                foreach ($items as $item) {
                    $itemName = $item->name ?? 'Item';
                    $summaryParts[] = "{$item->quantity}x {$itemName}";
                }
                $itemsSummary = implode(', ', $summaryParts);

                // Upsert into central registry
                CustomerOrderRegistry::updateOrCreate(
                    [
                        'restaurant_id' => $restaurant->id,
                        'tenant_order_id' => $order->id,
                    ],
                    [
                        'customer_id' => $customerId,
                        'restaurant_name' => $restaurant->name,
                        'restaurant_logo' => $restaurant->logo,
                        'items_summary' => $itemsSummary ?: 'Standard Items',
                        'status' => $order->status,
                        'total' => $order->total,
                        'order_type' => $order->order_type,
                        'created_at' => $order->created_at,
                        'updated_at' => $order->updated_at,
                    ]
                );

                $totalSynced++;
            }
        } catch (\Exception $e) {
            $this->error("Failed to sync orders for restaurant {$restaurant->name}: " . $e->getMessage());
        }
    }

    $this->info("Successfully synchronized {$totalSynced} orders into the central Master Registry!");
})->purpose('Synchronizes all isolated tenant database orders into the central Master registry');
