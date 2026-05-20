<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AggregatorCredential;
use App\Models\AggregatorMapping;
use App\Models\AggregatorOrder;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Restaurant;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Webpatser\Uuid\Uuid;

class AggregatorWebhookController extends Controller
{
    protected $tenantService;

    public function __construct(TenantService $tenantService)
    {
        $this->tenantService = $tenantService;
    }

    /**
     * POST /api/webhooks/zomato/order
     */
    public function handleZomatoOrder(Request $request)
    {
        Log::info('Incoming Zomato Webhook Payload:', $request->all());

        // 1. Retrieve the Merchant/Outlet identifier from the payload
        $merchantId = $request->input('merchant_id') ?? $request->input('outlet_id');
        if (!$merchantId) {
            return response()->json(['status' => 'error', 'message' => 'Missing merchant_id in payload.'], 400);
        }

        // 2. Fetch Zomato master credentials to resolve Restaurant ID
        $credential = AggregatorCredential::where('aggregator', 'zomato')
            ->where('merchant_id', $merchantId)
            ->where('is_active', true)
            ->first();

        if (!$credential) {
            Log::warning("Zomato Webhook failed: No active credentials for Merchant ID: {$merchantId}");
            return response()->json(['status' => 'error', 'message' => 'Merchant not registered or inactive.'], 404);
        }

        return $this->processAggregatorOrder('zomato', $credential, $request->all());
    }

    /**
     * POST /api/webhooks/swiggy/order
     */
    public function handleSwiggyOrder(Request $request)
    {
        Log::info('Incoming Swiggy Webhook Payload:', $request->all());

        // 1. Retrieve the Outlet identifier from the payload
        $outletId = $request->input('outlet_id') ?? $request->input('merchant_id');
        if (!$outletId) {
            return response()->json(['status' => 'error', 'message' => 'Missing outlet_id in payload.'], 400);
        }

        // 2. Fetch Swiggy master credentials to resolve Restaurant ID
        $credential = AggregatorCredential::where('aggregator', 'swiggy')
            ->where('merchant_id', $outletId)
            ->where('is_active', true)
            ->first();

        if (!$credential) {
            Log::warning("Swiggy Webhook failed: No active credentials for Outlet ID: {$outletId}");
            return response()->json(['status' => 'error', 'message' => 'Outlet not registered or inactive.'], 404);
        }

        return $this->processAggregatorOrder('swiggy', $credential, $request->all());
    }

    /**
     * Core translation and injection engine
     */
    private function processAggregatorOrder(string $aggregator, AggregatorCredential $credential, array $payload)
    {
        // 1. Resolve master Restaurant details
        $restaurant = Restaurant::find($credential->restaurant_id);
        if (!$restaurant) {
            return response()->json(['status' => 'error', 'message' => 'Linked master restaurant not found.'], 404);
        }

        // 2. Dynamically switch connection to tenant database
        $dbName = 'resto_' . str_replace('-', '_', $restaurant->user_id);
        $this->tenantService->switchToTenant($dbName);

        DB::connection('tenant')->beginTransaction();
        try {
            $customerName = $payload['customer']['name'] ?? ucfirst($aggregator) . " Customer";
            $customerPhone = $payload['customer']['phone'] ?? "N/A";
            $deliveryAddress = $payload['delivery']['address_text'] ?? "Delivered by " . ucfirst($aggregator);
            $subtotal = $payload['pricing']['subtotal'] ?? ($payload['pricing']['total'] ?? 0);
            $tax = $payload['pricing']['tax'] ?? 0;
            $total = $payload['pricing']['grand_total'] ?? ($payload['pricing']['total'] ?? 0);
            $externalOrderId = $payload['order_id'] ?? $payload['id'] ?? 'EXT_' . rand(1000, 9999);

            // 3. Inject standard EatsOnly Order
            $order = Order::create([
                'restaurant_id' => $restaurant->id,
                'order_type' => 'delivery',
                'source' => $aggregator,
                'customer_name' => $customerName,
                'customer_phone' => $customerPhone,
                'delivery_address' => $deliveryAddress,
                'subtotal' => $subtotal,
                'tax' => $tax,
                'total' => $total,
                'status' => 'open', // POS user accepts order
            ]);

            // 4. Log the original details in aggregator_orders log
            AggregatorOrder::create([
                'order_id' => $order->id,
                'aggregator' => $aggregator,
                'external_order_id' => $externalOrderId,
                'rider_name' => $payload['rider']['name'] ?? null,
                'rider_phone' => $payload['rider']['phone'] ?? null,
                'raw_payload' => $payload,
            ]);

            // 5. Translate external items to local EatsOnly Menu Items
            $items = $payload['items'] ?? [];
            foreach ($items as $item) {
                $externalItemId = $item['id'] ?? $item['menu_item_id'] ?? null;
                if (!$externalItemId) continue;

                $mapping = AggregatorMapping::where('aggregator', $aggregator)
                    ->where('external_item_id', $externalItemId)
                    ->first();

                if ($mapping) {
                    OrderItem::create([
                        'order_id' => $order->id,
                        'menu_item_id' => $mapping->menu_item_id,
                        'quantity' => $item['quantity'] ?? 1,
                        'price' => $item['price'] ?? $mapping->external_price,
                        'status' => 'pending',
                        'notes' => $item['instructions'] ?? null,
                    ]);
                } else {
                    Log::warning("Aggregator order mapping missing for item ID: {$externalItemId} ({$aggregator})");
                }
            }

            // 6. Sync database standard registers
            $order->syncToCentralRegistry();

            DB::connection('tenant')->commit();

            return response()->json([
                'status' => 'success',
                'message' => 'Order successfully ingested',
                'order_id' => $order->id,
            ]);

        } catch (\Exception $e) {
            DB::connection('tenant')->rollBack();
            Log::error("Aggregator Order Ingestion failed: " . $e->getMessage(), ['trace' => $e->getTraceAsString()]);
            return response()->json(['status' => 'error', 'message' => 'Failed to ingest order: ' . $e->getMessage()], 500);
        }
    }
}
