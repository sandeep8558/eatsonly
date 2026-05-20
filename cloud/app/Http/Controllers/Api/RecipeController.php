<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Recipe;
use App\Models\InventoryItem;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class RecipeController extends Controller
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
        $request->validate([
            'restaurant_id' => 'required',
            'menu_item_id' => 'required',
        ]);
        $this->setTenant();

        $recipes = Recipe::where('menu_item_id', $request->menu_item_id)
            ->with('inventoryItem')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $recipes
        ]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'menu_item_id' => 'required',
            'ingredients' => 'present|array',
            'ingredients.*.inventory_item_id' => 'required|uuid',
            'ingredients.*.quantity_needed' => 'required|numeric|min:0.0001',
            'ingredients.*.consumption_unit' => 'required|string',
        ]);
        $this->setTenant();

        DB::connection('tenant')->transaction(function () use ($request) {
            // Remove existing recipe elements first
            Recipe::where('menu_item_id', $request->menu_item_id)->delete();

            // Insert new recipe elements
            foreach ($request->ingredients as $ing) {
                Recipe::create([
                    'menu_item_id' => $request->menu_item_id,
                    'inventory_item_id' => $ing['inventory_item_id'],
                    'quantity_needed' => $ing['quantity_needed'],
                    'consumption_unit' => $ing['consumption_unit'],
                ]);
            }
        });

        $recipes = Recipe::where('menu_item_id', $request->menu_item_id)
            ->with('inventoryItem')
            ->get();

        return response()->json([
            'status' => 'success',
            'message' => 'Recipe saved successfully',
            'data' => $recipes
        ]);
    }
}
