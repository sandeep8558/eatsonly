<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class DeliveryController extends Controller
{
    protected $tenantService;

    public function __construct(TenantService $tenantService)
    {
        $this->tenantService = $tenantService;
    }

    /**
     * Set the active tenant context for the logged-in staff user.
     */
    private function setTenant()
    {
        $user = Auth::user();
        if (!$user) {
            return;
        }
        
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

    /**
     * Fetch all available delivery orders ready for pickup for this restaurant.
     */
    public function availableDeliveries(Request $request)
    {
        $this->setTenant();
 
        $query = Order::where('order_type', 'delivery')
            ->whereNull('delivery_staff_id')
            ->whereIn('status', ['cooking', 'completed', 'open', 'ready', 'preparing']) // Ready to dispatch states
            ->where('delivery_status', 'pending');

        if ($request->has('date') && $request->date) {
            $query->whereDate('created_at', $request->date);
        }

        $orders = $query->orderBy('created_at', 'desc')->get();
 
        return response()->json([
            'status' => 'success',
            'data' => $orders
        ]);
    }
 
    public function activeDeliveries(Request $request)
    {
        $this->setTenant();
        $user = Auth::user();
 
        $query = Order::where('order_type', 'delivery')
            ->where('delivery_staff_id', $user->id)
            ->whereIn('delivery_status', ['assigned', 'picked_up', 'on_the_way']);

        if ($request->has('date') && $request->date) {
            $query->whereDate('created_at', $request->date);
        }

        $orders = $query->orderBy('created_at', 'desc')->get();
 
        return response()->json([
            'status' => 'success',
            'data' => $orders
        ]);
    }

    /**
     * Fetch delivered orders for the logged-in staff member.
     */
    public function deliveredDeliveries(Request $request)
    {
        $this->setTenant();
        $user = Auth::user();

        $query = Order::where('order_type', 'delivery')
            ->where('delivery_staff_id', $user->id)
            ->where('delivery_status', 'delivered');

        if ($request->has('date') && $request->date) {
            $query->whereDate('created_at', $request->date);
        }

        $orders = $query->orderBy('created_at', 'desc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $orders
        ]);
    }

    /**
     * Self-assign a pending delivery order to the logged-in staff member.
     */
    public function acceptDelivery($id)
    {
        $this->setTenant();
        $user = Auth::user();

        $order = Order::find($id);

        if (!$order) {
            return response()->json([
                'status' => 'error',
                'message' => 'Order not found.'
            ], 404);
        }

        if ($order->delivery_staff_id !== null) {
            return response()->json([
                'status' => 'error',
                'message' => 'This delivery is already assigned to another staff member.'
            ], 422);
        }

        $order->update([
            'delivery_staff_id' => $user->id,
            'delivery_status' => 'assigned'
        ]);

        $order->syncToCentralRegistry();

        return response()->json([
            'status' => 'success',
            'message' => 'Delivery successfully self-assigned!',
            'data' => $order
        ]);
    }

    /**
     * Update the status of a delivery assignment (picked_up, on_the_way or delivered).
     */
    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|string|in:picked_up,on_the_way,delivered'
        ]);

        $this->setTenant();
        $user = Auth::user();

        $order = Order::find($id);

        if (!$order) {
            return response()->json([
                'status' => 'error',
                'message' => 'Order not found.'
            ], 404);
        }

        if ($order->delivery_staff_id != $user->id) {
            return response()->json([
                'status' => 'error',
                'message' => 'You are not authorized to manage this order.'
            ], 403);
        }

        $updateData = ['delivery_status' => $request->status];

        if ($request->status === 'picked_up' || $request->status === 'on_the_way') {
            if ($request->status === 'picked_up') {
                $updateData['dispatched_at'] = now();
            }
            $updateData['status'] = 'on the way';
        } elseif ($request->status === 'delivered') {
            $updateData['delivered_at'] = now();
            $updateData['status'] = 'completed';
        }

        $order->update($updateData);

        $order->syncToCentralRegistry();

        return response()->json([
            'status' => 'success',
            'message' => "Order delivery status successfully marked as {$request->status}!",
            'data' => $order
        ]);
    }

    public function earningsSummary(Request $request)
    {
        $this->setTenant();
        $user = Auth::user();
 
        $query = Order::where('delivery_staff_id', $user->id)
            ->where('delivery_status', 'delivered');

        if ($request->has('date') && $request->date) {
            $query->whereDate('created_at', $request->date);
        }

        $deliveredOrders = $query->get();
 
        $totalTips = $deliveredOrders->sum('tip_amount');
        $totalDeliveriesCount = $deliveredOrders->count();
        $cashCollected = $deliveredOrders->where('payment_method', 'cash')->sum('total');
 
        return response()->json([
            'status' => 'success',
            'data' => [
                'total_deliveries' => $totalDeliveriesCount,
                'total_tips' => $totalTips,
                'cash_in_hand' => $cashCollected,
                'recent_deliveries' => $deliveredOrders->take(10)
            ]
        ]);
    }

    /**
     * Update the rider's live location coordinates for an order.
     */
    public function updateLocation(Request $request, $id)
    {
        $request->validate([
            'latitude' => 'required|numeric',
            'longitude' => 'required|numeric'
        ]);

        // Retrieve and update central order registry (the landlord record)
        $registry = \App\Models\CustomerOrderRegistry::where('tenant_order_id', $id)->first();
        if ($registry) {
            $registry->update([
                'rider_latitude' => $request->latitude,
                'rider_longitude' => $request->longitude
            ]);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Rider location updated successfully'
        ]);
    }
}
