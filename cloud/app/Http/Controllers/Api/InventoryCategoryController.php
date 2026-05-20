<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\InventoryCategory;
use App\Models\InventoryItem;
use App\Services\TenantService;
use Illuminate\Http\Request;

class InventoryCategoryController extends Controller
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

        $categories = InventoryCategory::where('restaurant_id', $request->restaurant_id)
            ->orderBy('name', 'asc')
            ->get();

        // Auto seed default categories if none exist
        if ($categories->isEmpty()) {
            $defaults = [
                'Poultry & Meat',
                'Fresh Vegetables',
                'Dairy Products',
                'Packaging Materials',
                'Dry Goods & Spices'
            ];

            foreach ($defaults as $name) {
                InventoryCategory::create([
                    'restaurant_id' => $request->restaurant_id,
                    'name' => $name,
                ]);
            }

            $categories = InventoryCategory::where('restaurant_id', $request->restaurant_id)
                ->orderBy('name', 'asc')
                ->get();
        }

        return response()->json([
            'status' => 'success',
            'data' => $categories
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'name' => 'required|string|max:255',
        ]);
        $this->setTenant();

        // Check for duplicates
        $exists = InventoryCategory::where('restaurant_id', $request->restaurant_id)
            ->where('name', $request->name)
            ->exists();

        if ($exists) {
            return response()->json([
                'status' => 'error',
                'message' => 'Category already exists.'
            ], 422);
        }

        $category = InventoryCategory::create([
            'restaurant_id' => $request->restaurant_id,
            'name' => $request->name,
        ]);

        return response()->json([
            'status' => 'success',
            'data' => $category
        ]);
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'name' => 'required|string|max:255',
        ]);
        $this->setTenant();

        $category = InventoryCategory::findOrFail($id);
        $oldName = $category->name;

        // Check if new name exists elsewhere
        $exists = InventoryCategory::where('restaurant_id', $category->restaurant_id)
            ->where('name', $request->name)
            ->where('id', '!=', $id)
            ->exists();

        if ($exists) {
            return response()->json([
                'status' => 'error',
                'message' => 'Category with this name already exists.'
            ], 422);
        }

        $category->update([
            'name' => $request->name
        ]);

        // Cascading update to matching items under this old category name
        InventoryItem::where('restaurant_id', $category->restaurant_id)
            ->where('category', $oldName)
            ->update(['category' => $request->name]);

        return response()->json([
            'status' => 'success',
            'data' => $category
        ]);
    }

    public function destroy(Request $request, $id)
    {
        $this->setTenant();

        $category = InventoryCategory::findOrFail($id);
        $catName = $category->name;

        // Cascade/orphans safety check: update matching items' category to 'Uncategorized'
        InventoryItem::where('restaurant_id', $category->restaurant_id)
            ->where('category', $catName)
            ->update(['category' => 'Uncategorized']);

        $category->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Category deleted successfully.'
        ]);
    }
}
