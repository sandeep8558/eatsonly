<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InventoryItem;
use App\Services\TenantService;
use Illuminate\Http\Request;

class InventoryController extends Controller
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

        $query = InventoryItem::where('restaurant_id', $request->restaurant_id);

        if ($request->boolean('low_stock')) {
            $query->whereColumn('quantity', '<=', 'min_threshold');
        }

        if ($request->filled('category')) {
            $query->where('category', $request->category);
        }

        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('sku', 'LIKE', "%{$search}%");
            });
        }

        $items = $query->orderBy('name', 'asc')->get();

        return response()->json([
            'status' => 'success',
            'data' => $items
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'name' => 'required|string|max:255',
            'category' => 'required|string|max:255',
            'quantity' => 'nullable|numeric|min:0',
            'unit' => 'required|string|max:50',
            'min_threshold' => 'nullable|numeric|min:0',
            'cost_per_unit' => 'nullable|numeric|min:0',
            'sku' => 'nullable|string|max:100',
            'storage_location' => 'nullable|string|max:100',
            'expiry_date' => 'nullable|date',
        ]);
        $this->setTenant();

        $item = InventoryItem::create([
            'restaurant_id' => $request->restaurant_id,
            'name' => $request->name,
            'sku' => $request->sku,
            'category' => $request->category,
            'quantity' => $request->input('quantity', 0.00),
            'unit' => $request->unit,
            'min_threshold' => $request->input('min_threshold', 5.00),
            'cost_per_unit' => $request->input('cost_per_unit', 0.00),
            'storage_location' => $request->input('storage_location', 'Dry Storage'),
            'expiry_date' => $request->expiry_date,
        ]);

        return response()->json([
            'status' => 'success',
            'data' => $item
        ]);
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'category' => 'sometimes|required|string|max:255',
            'quantity' => 'sometimes|nullable|numeric|min:0',
            'unit' => 'sometimes|required|string|max:50',
            'min_threshold' => 'sometimes|nullable|numeric|min:0',
            'cost_per_unit' => 'sometimes|nullable|numeric|min:0',
            'sku' => 'nullable|string|max:100',
            'storage_location' => 'nullable|string|max:100',
            'expiry_date' => 'nullable|date',
        ]);
        $this->setTenant();

        $item = InventoryItem::findOrFail($id);
        $item->update($request->all());

        return response()->json([
            'status' => 'success',
            'data' => $item
        ]);
    }

    public function destroy($id)
    {
        $this->setTenant();

        $item = InventoryItem::findOrFail($id);
        $item->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Inventory item deleted successfully'
        ]);
    }
}
