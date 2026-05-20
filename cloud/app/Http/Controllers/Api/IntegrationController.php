<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AggregatorCredential;
use App\Models\AggregatorMapping;
use App\Models\MenuItem;
use App\Models\Restaurant;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class IntegrationController extends Controller
{
    protected $tenantService;

    public function __construct(TenantService $tenantService)
    {
        $this->tenantService = $tenantService;
    }

    private function setTenant($restaurantId = null)
    {
        $user = auth()->user();
        $id = $restaurantId ?? request()->input('restaurant_id') ?? request()->header('X-Restaurant-ID');

        if ($id) {
            $restaurant = Restaurant::find($id);
            if ($restaurant) {
                $dbName = 'resto_' . str_replace('-', '_', $restaurant->user_id);
                $this->tenantService->switchToTenant($dbName);
                return;
            }
        }

        $this->tenantService->ensureTenantDatabase($user);
    }

    /**
     * GET /api/integrations
     * Fetch active integration configurations for a restaurant
     */
    public function index(Request $request)
    {
        $request->validate(['restaurant_id' => 'required']);

        $credentials = AggregatorCredential::where('restaurant_id', $request->restaurant_id)->get();

        return response()->json([
            'status' => 'success',
            'data' => [
                'zomato' => $credentials->where('aggregator', 'zomato')->first(),
                'swiggy' => $credentials->where('aggregator', 'swiggy')->first(),
            ]
        ]);
    }

    /**
     * POST /api/integrations/credentials
     * Save/update Zomato or Swiggy credentials
     */
    public function saveCredentials(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'aggregator' => 'required|in:zomato,swiggy',
            'merchant_id' => 'required|string',
            'access_token' => 'nullable|string',
            'refresh_token' => 'nullable|string',
            'is_active' => 'required|boolean',
        ]);

        $credential = AggregatorCredential::updateOrCreate(
            [
                'restaurant_id' => $request->restaurant_id,
                'aggregator' => $request->aggregator,
            ],
            [
                'merchant_id' => $request->merchant_id,
                'access_token' => $request->access_token,
                'refresh_token' => $request->refresh_token,
                'is_active' => $request->is_active,
            ]
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Credentials saved successfully',
            'data' => $credential
        ]);
    }

    /**
     * GET /api/integrations/menu
     * Fetch menu items with their aggregator mappings for config
     */
    public function getMenuMapping(Request $request)
    {
        $request->validate(['restaurant_id' => 'required']);
        $this->setTenant($request->restaurant_id);

        $restaurantId = $request->restaurant_id;
        $restaurant = Restaurant::find($restaurantId);
        $deliveryMenuCardId = $restaurant ? $restaurant->delivery_menu_card_id : null;

        if ($deliveryMenuCardId) {
            $items = MenuItem::whereHas('category', function ($query) use ($deliveryMenuCardId) {
                $query->where('menu_card_id', $deliveryMenuCardId);
            })->with('category')->get();
        } else {
            $items = MenuItem::with('category')->get();
        }
        $mappings = AggregatorMapping::all();

        $data = $items->map(function ($item) use ($mappings) {
            return [
                'id' => $item->id,
                'name' => $item->name,
                'category' => $item->category ? $item->category->name : 'Uncategorized',
                'price' => $item->price,
                'type' => $item->type,
                'is_available' => $item->is_available,
                'zomato_mapping' => $mappings->where('menu_item_id', $item->id)->where('aggregator', 'zomato')->first(),
                'swiggy_mapping' => $mappings->where('menu_item_id', $item->id)->where('aggregator', 'swiggy')->first(),
            ];
        });

        return response()->json([
            'status' => 'success',
            'data' => $data
        ]);
    }

    /**
     * POST /api/integrations/map-item
     * Save an item mapping mapping link
     */
    public function mapItem(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'menu_item_id' => 'required|uuid',
            'aggregator' => 'required|in:zomato,swiggy',
            'external_item_id' => 'required|string',
            'external_price' => 'nullable|numeric',
        ]);

        $this->setTenant($request->restaurant_id);

        $mapping = AggregatorMapping::updateOrCreate(
            [
                'menu_item_id' => $request->menu_item_id,
                'aggregator' => $request->aggregator,
            ],
            [
                'external_item_id' => $request->external_item_id,
                'external_price' => $request->external_price ?? 0,
                'is_synced' => true,
            ]
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Item mapped successfully',
            'data' => $mapping
        ]);
    }
}
