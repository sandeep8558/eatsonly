<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MasterCategory;
use App\Models\MasterMenu;
use App\Models\MenuCard;
use App\Models\MenuCategory;
use App\Models\MenuItem;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class MenuController extends Controller
{
    protected $tenantService;

    public function __construct(TenantService $tenantService)
    {
        $this->tenantService = $tenantService;
    }

    public function generateDescription(Request $request)
    {
        $request->validate(['name' => 'required|string|max:255']);
        $name = $request->name;

        $key = config('services.gemini.key');

        if (empty($key)) {
            // Fallback mock description if no key is provided
            return response()->json([
                'status' => 'success',
                'data' => "A delicious and perfectly prepared portion of {$name}, crafted with fresh ingredients and bursting with authentic flavors."
            ]);
        }

        try {
            $prompt = "Write a short, appetizing, 1-sentence restaurant menu description for a food item named '{$name}'. Make it sound delicious but keep it under 150 characters.";

            $response = Http::post("https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key={$key}", [
                'contents' => [
                    ['parts' => [['text' => $prompt]]]
                ]
            ]);

            if ($response->successful()) {
                $result = $response->json();
                $description = $result['candidates'][0]['content']['parts'][0]['text'] ?? null;
                if ($description) {
                    return response()->json([
                        'status' => 'success',
                        'data' => trim(str_replace('"', '', $description))
                    ]);
                }
            }

            throw new \Exception('AI generation failed.');
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'success',
                'data' => "A delicious and perfectly prepared portion of {$name}, crafted with fresh ingredients and bursting with authentic flavors."
            ]);
        }
    }

    private function setTenant()
    {
        $user = Auth::user();
        
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

    // --- SUGGESTIONS API (Hits Master DB) ---

    public function searchMasterCategories(Request $request)
    {
        $query = $request->input('query');
        $categories = MasterCategory::where('name', 'like', "%{$query}%")
            ->orderBy('usage_count', 'desc')
            ->limit(10)
            ->get();
        return response()->json(['status' => 'success', 'data' => $categories]);
    }

    public function searchMasterMenus(Request $request)
    {
        $query = $request->input('query');
        $menus = MasterMenu::where('name', 'like', "%{$query}%")
            ->orderBy('usage_count', 'desc')
            ->limit(10)
            ->get();
        return response()->json(['status' => 'success', 'data' => $menus]);
    }

    // --- TENANT API: MENU CARDS ---

    public function getMenuCards(Request $request)
    {
        $this->setTenant();
        $cards = MenuCard::with(['categories.items.taxGroup.taxes', 'categories.items.comboGroups.comboItems.menuItem'])->get();
        return response()->json(['status' => 'success', 'data' => $cards]);
    }

    public function storeMenuCard(Request $request)
    {
        $request->validate(['name' => 'required|string|max:255']);
        $this->setTenant();
        
        $card = MenuCard::create([
            'name' => $request->name,
            'is_active' => true,
        ]);
        
        return response()->json(['status' => 'success', 'data' => $card]);
    }

    public function deleteMenuCard($id)
    {
        $this->setTenant();
        $card = MenuCard::findOrFail($id);
        $card->delete();
        return response()->json(['status' => 'success']);
    }

    // --- TENANT API: CATEGORIES ---

    public function storeMenuCategory(Request $request)
    {
        $request->validate([
            'menu_card_id' => 'required|uuid',
            'name' => 'required|string|max:255',
            'sort_order' => 'integer',
            'kds_station_id' => 'nullable|uuid'
        ]);

        $this->setTenant();

        $category = MenuCategory::create([
            'menu_card_id' => $request->menu_card_id,
            'name' => $request->name,
            'sort_order' => $request->sort_order ?? 0,
            'kds_station_id' => $request->kds_station_id,
            'is_active' => true,
        ]);

        // Sync with Master
        $master = MasterCategory::firstOrCreate(['name' => $request->name]);
        $master->increment('usage_count');

        return response()->json(['status' => 'success', 'data' => $category]);
    }

    public function deleteMenuCategory($id)
    {
        $this->setTenant();
        $category = MenuCategory::findOrFail($id);
        $category->delete();
        return response()->json(['status' => 'success']);
    }

    public function updateMenuCard(Request $request, $id)
    {
        $request->validate(['name' => 'required|string|max:255']);
        $this->setTenant();
        $card = MenuCard::findOrFail($id);
        $card->update(['name' => $request->name]);
        return response()->json(['status' => 'success', 'data' => $card]);
    }

    public function updateMenuCategory(Request $request, $id)
    {
        $request->validate(['name' => 'required|string|max:255', 'sort_order' => 'nullable|integer', 'kds_station_id' => 'nullable|uuid']);
        $this->setTenant();
        $category = MenuCategory::findOrFail($id);
        $category->update([
            'name' => $request->name,
            'sort_order' => $request->sort_order ?? $category->sort_order,
            'kds_station_id' => $request->kds_station_id
        ]);
        return response()->json(['status' => 'success', 'data' => $category]);
    }

    // --- TENANT API: MENU ITEMS ---


    public function storeMenuItem(Request $request)
    {
        $request->validate([
            'menu_category_id' => 'required|uuid',
            'tax_group_id' => 'nullable|uuid',
            'name' => 'required|string|max:255',
            'type' => 'nullable|string|in:regular,combo',
            'description' => 'nullable|string',
            'price' => 'required|numeric',
            'is_veg' => 'nullable',
            'is_nonveg' => 'nullable',
            'is_jain' => 'nullable',
            'sort_order' => 'nullable|integer',
            'image' => 'nullable|image|max:2048',
            'image_path' => 'nullable|string',
        ]);

        $this->setTenant();

        $imagePath = null;
        if ($request->hasFile('image')) {
            $dbName = $this->tenantService->ensureTenantDatabase(Auth::user());
            $imagePath = $request->file('image')->store("tenants/{$dbName}/menu_items", 'public');
        } elseif ($request->has('image_path')) {
            $imagePath = $request->image_path;
        }

        $isVeg = $request->has('is_veg') ? filter_var($request->is_veg, FILTER_VALIDATE_BOOLEAN) : false;
        $isNonveg = $request->has('is_nonveg') ? filter_var($request->is_nonveg, FILTER_VALIDATE_BOOLEAN) : false;
        $isJain = $request->has('is_jain') ? filter_var($request->is_jain, FILTER_VALIDATE_BOOLEAN) : false;

        $item = MenuItem::create([
            'menu_category_id' => $request->menu_category_id,
            'tax_group_id' => $request->tax_group_id,
            'name' => $request->name,
            'type' => $request->type ?? 'regular',
            'description' => $request->description,
            'price' => $request->price,
            'is_veg' => $isVeg,
            'is_nonveg' => $isNonveg,
            'is_jain' => $isJain,
            'image' => $imagePath,
            'sort_order' => $request->sort_order ?? 0,
            'is_available' => true,
        ]);

        // Sync with Master
        $master = MasterMenu::firstOrCreate(
            ['name' => $request->name],
            [
                'description' => $request->description,
                'is_veg' => $item->is_veg,
                'is_nonveg' => $item->is_nonveg,
                'is_jain' => $item->is_jain,
            ]
        );
        $master->increment('usage_count');

        return response()->json(['status' => 'success', 'data' => $item]);
    }

    public function updateMenuItem(Request $request, $id)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'nullable|string|in:regular,combo',
            'tax_group_id' => 'nullable|uuid',
            'description' => 'nullable|string',
            'price' => 'required|numeric',
            'is_veg' => 'nullable',
            'is_nonveg' => 'nullable',
            'is_jain' => 'nullable',
            'sort_order' => 'nullable|integer',
            'image' => 'nullable|image|max:2048',
        ]);

        $this->setTenant();
        $item = MenuItem::findOrFail($id);

        $isVeg = $request->has('is_veg') ? filter_var($request->is_veg, FILTER_VALIDATE_BOOLEAN) : $item->is_veg;
        $isNonveg = $request->has('is_nonveg') ? filter_var($request->is_nonveg, FILTER_VALIDATE_BOOLEAN) : $item->is_nonveg;
        $isJain = $request->has('is_jain') ? filter_var($request->is_jain, FILTER_VALIDATE_BOOLEAN) : $item->is_jain;

        $updateData = [
            'name' => $request->name,
            'type' => $request->type ?? $item->type,
            'tax_group_id' => $request->tax_group_id,
            'description' => $request->description,
            'price' => $request->price,
            'is_veg' => $isVeg,
            'is_nonveg' => $isNonveg,
            'is_jain' => $isJain,
            'sort_order' => $request->sort_order ?? $item->sort_order,
        ];

        if ($request->hasFile('image')) {
            $dbName = $this->tenantService->ensureTenantDatabase(Auth::user());
            $updateData['image'] = $request->file('image')->store("tenants/{$dbName}/menu_items", 'public');
        }

        $item->update($updateData);

        return response()->json(['status' => 'success', 'data' => $item]);
    }

    public function saveComboGroups(Request $request, $id)
    {
        $request->validate([
            'groups' => 'required|array',
            'groups.*.name' => 'required|string',
            'groups.*.min_selections' => 'required|integer',
            'groups.*.max_selections' => 'required|integer',
            'groups.*.is_required' => 'required|boolean',
            'groups.*.items' => 'required|array',
            'groups.*.items.*.menu_item_id' => 'required|uuid',
            'groups.*.items.*.extra_price' => 'required|numeric',
            'groups.*.items.*.quantity' => 'required|integer',
            'groups.*.items.*.is_default' => 'required|boolean',
        ]);

        $this->setTenant();
        $item = MenuItem::findOrFail($id);

        DB::connection('tenant')->transaction(function () use ($item, $request) {
            // Clear existing groups and items
            $item->comboGroups()->each(function ($group) {
                $group->comboItems()->delete();
                $group->delete();
            });

            foreach ($request->groups as $groupData) {
                $group = $item->comboGroups()->create([
                    'name' => $groupData['name'],
                    'min_selections' => $groupData['min_selections'],
                    'max_selections' => $groupData['max_selections'],
                    'is_required' => $groupData['is_required'],
                ]);

                foreach ($groupData['items'] as $itemData) {
                    $group->comboItems()->create([
                        'menu_item_id' => $itemData['menu_item_id'],
                        'extra_price' => $itemData['extra_price'],
                        'quantity' => $itemData['quantity'],
                        'is_default' => $itemData['is_default'],
                    ]);
                }
            }
        });

        return response()->json(['status' => 'success']);
    }


    public function deleteMenuItem($id)
    {
        $this->setTenant();
        $item = MenuItem::findOrFail($id);
        $item->delete();
        return response()->json(['status' => 'success']);
    }

    public function reorderCategories(Request $request)
    {
        $orders = $request->input('orders');
        if (!$orders) return response()->json(['status' => 'error', 'message' => 'No orders provided'], 422);

        $this->setTenant();

        foreach ($orders as $order) {
            MenuCategory::where('id', $order['id'])->update(['sort_order' => $order['sort_order']]);
        }

        return response()->json(['status' => 'success']);
    }

    public function reorderItems(Request $request)
    {
        $orders = $request->input('orders');
        if (!$orders) return response()->json(['status' => 'error', 'message' => 'No orders provided'], 422);

        $this->setTenant();

        foreach ($orders as $order) {
            MenuItem::where('id', $order['id'])->update(['sort_order' => $order['sort_order']]);
        }

        return response()->json(['status' => 'success']);
    }

    public function cloneMenuCard(Request $request)
    {
        $request->validate([
            'source_card_id' => 'required|uuid',
            'target_card_id' => 'required|uuid',
        ]);

        $this->setTenant();

        $sourceCard = MenuCard::with('categories.items')->findOrFail($request->source_card_id);
        $targetCard = MenuCard::findOrFail($request->target_card_id);

        DB::transaction(function () use ($sourceCard, $targetCard) {
            foreach ($sourceCard->categories as $category) {
                $newCategory = $targetCard->categories()->create([
                    'name' => $category->name,
                    'sort_order' => $category->sort_order,
                    'kds_station_id' => $category->kds_station_id,
                    'is_active' => $category->is_active,
                ]);

                foreach ($category->items as $item) {
                    $newCategory->items()->create([
                        'name' => $item->name,
                        'description' => $item->description,
                        'price' => $item->price,
                        'is_veg' => $item->is_veg,
                        'is_nonveg' => $item->is_nonveg,
                        'is_jain' => $item->is_jain,
                        'image' => $item->image,
                        'sort_order' => $item->sort_order,
                        'is_available' => $item->is_available,
                    ]);
                }
            }
        });

        return response()->json(['status' => 'success', 'message' => 'Menu cloned successfully']);
    }
}
