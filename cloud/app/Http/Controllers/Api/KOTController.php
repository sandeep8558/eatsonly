<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\KOT;
use App\Models\OrderItem;
use App\Services\TenantService;
use Illuminate\Http\Request;

class KOTController extends Controller
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
                return;
            }
        }

        $this->tenantService->ensureTenantDatabase($user);
    }

    public function index(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'kds_station_id' => 'nullable'
        ]);

        $this->setTenant();

        $query = KOT::with(['order.table', 'items.menuItem', 'items.parent.menuItem', 'items.children.menuItem'])

                   ->where('restaurant_id', $request->restaurant_id)
                   ->whereIn('status', ['pending', 'cooking']);



        if ($request->filled('kds_station_id') && $request->kds_station_id !== 'null') {
            $query->where('kds_station_id', $request->kds_station_id);
        }
 else {
            // If no station ID is provided, we might want to only show KOTs without a station (legacy) 
            // or show all. For now, if null is passed, show all.
        }

        $kots = $query->orderBy('created_at', 'asc')->get();

        return response()->json(['status' => 'success', 'data' => $kots]);
    }

    public function updateStatus(Request $request, $id)
    {
        $request->validate([
            'status' => 'required|in:pending,cooking,completed,cancelled'
        ]);

        $this->setTenant();

        $kot = KOT::with('order')->findOrFail($id);
        $kot->status = $request->status;
        $kot->save();

        // Update all items in this KOT if completed
        if ($request->status === 'completed') {
            OrderItem::where('kot_id', $kot->id)->update(['status' => 'ready']);
        } elseif ($request->status === 'cooking') {
            OrderItem::where('kot_id', $kot->id)->update(['status' => 'cooking']);
        }

        // Transition parent Order status dynamically and sync to Master Registry
        $order = $kot->order;
        if ($order) {
            if ($request->status === 'cooking' && ($order->status === 'open' || $order->status === 'placed')) {
                $order->status = 'preparing';
                $order->save();
                $order->syncToCentralRegistry();
            } elseif ($request->status === 'completed') {
                // If all other KOTs of this order are completed, mark order as ready
                $hasPendingOrCooking = KOT::where('order_id', $order->id)
                    ->where('id', '!=', $kot->id)
                    ->whereIn('status', ['pending', 'cooking'])
                    ->exists();

                if (!$hasPendingOrCooking && ($order->status === 'open' || $order->status === 'preparing')) {
                    $order->status = 'ready';
                    $order->save();
                    $order->syncToCentralRegistry();
                }
            }
        }

        return response()->json(['status' => 'success', 'data' => $kot]);
    }
}
