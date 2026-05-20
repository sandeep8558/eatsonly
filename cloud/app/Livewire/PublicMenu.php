<?php

namespace App\Livewire;

use Livewire\Component;
use App\Models\Restaurant;
use App\Models\MenuCard;
use App\Models\RestaurantTable;
use App\Services\TenantService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Str;

class PublicMenu extends Component
{
    public $slug;
    public $tableId;
    public $dbName;
    public $search = '';
    public $selectedCategoryId = null;
    public $cart = [];
    public $showCart = false;
    public $showHistory = false;
    public $previousOrderItems = [];
    public $tableName = '';
    public $orderSuccess = false;
    public $customerName = '';
    public $customerPhone = '';
    
    protected $restaurant;
    protected $menuCard;
    protected $categories = [];

    public function setupTenant()
    {
        // Always ensure restaurant is loaded for protected property access
        if (!$this->restaurant && $this->slug) {
            $this->restaurant = Restaurant::where('slug', $this->slug)->first();
        }

        // Initialize dbName if it's the first time
        if (!$this->dbName && $this->restaurant) {
            $this->dbName = 'resto_' . str_replace('-', '_', $this->restaurant->user_id);
        }
        
        if ($this->dbName) {
            Config::set('database.connections.tenant.database', $this->dbName);
            DB::purge('tenant');
            DB::reconnect('tenant');
        }
    }

    public function booted()
    {
        $this->setupTenant();
        $this->cart = session()->get('cart_' . $this->slug, []);
    }

    public function mount($slug)
    {
        $this->slug = $slug;
        $this->setupTenant();
        $this->tableId = request()->query('t');
        
        $this->loadMenu();
    }

    public function loadMenu()
    {
        $this->menuCard = null;

        if ($this->tableId) {
            $table = RestaurantTable::on('tenant')->find($this->tableId);
            $this->tableName = $table ? $table->name : 'N/A';
            if ($table && $table->floor && $table->floor->menu_card_id) {
                $this->menuCard = MenuCard::on('tenant')->find($table->floor->menu_card_id);
            }
        }

        if (!$this->menuCard) {
            $menuCardId = $this->restaurant->takeaway_menu_card_id ?? $this->restaurant->delivery_menu_card_id;
            if ($menuCardId) {
                $this->menuCard = MenuCard::on('tenant')->find($menuCardId);
            }
        }

        if ($this->menuCard) {
            $query = $this->menuCard->categories()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->with(['items' => function($q) {
                    $q->where('is_available', true);
                    if ($this->search) {
                        $q->where('name', 'like', '%' . $this->search . '%');
                    }
                    $q->orderBy('sort_order');
                }]);

            if ($this->search) {
                // Only get categories that have matching items
                $this->categories = $query->whereHas('items', function($q) {
                    $q->where('is_available', true)
                      ->where('name', 'like', '%' . $this->search . '%');
                })->get();

                // Auto-switch to the first matching category if the current one isn't in results
                if ($this->categories->isNotEmpty()) {
                    $currentVisible = $this->categories->contains('id', $this->selectedCategoryId);
                    if (!$currentVisible) {
                        $this->selectedCategoryId = $this->categories->first()->id;
                    }
                }
            } else {
                $this->categories = $query->get();
            }
            
            if ($this->categories->isNotEmpty() && !$this->selectedCategoryId) {
                $this->selectedCategoryId = $this->categories->first()->id;
            }
        }
    }

    public function selectCategory($id)
    {
        $this->selectedCategoryId = $id;
    }

    public function addToCart($itemId)
    {
        $this->setupTenant();
        $item = DB::connection('tenant')->table('menu_items')->where('id', $itemId)->first();
        
        if (!$item) return;

        $cart = session()->get('cart_' . $this->slug, []);
        
        if (isset($cart[$itemId])) {
            $cart[$itemId]['quantity']++;
        } else {
            $cart[$itemId] = [
                'id' => $item->id,
                'name' => $item->name,
                'price' => $item->price,
                'quantity' => 1,
                'image' => $item->image
            ];
        }

        session()->put('cart_' . $this->slug, $cart);
        $this->cart = $cart;
        
        $this->dispatch('cartUpdated');
    }

    public function removeFromCart($itemId)
    {
        $cart = session()->get('cart_' . $this->slug, []);
        
        if (isset($cart[$itemId])) {
            if ($cart[$itemId]['quantity'] > 1) {
                $cart[$itemId]['quantity']--;
            } else {
                unset($cart[$itemId]);
            }
        }

        session()->put('cart_' . $this->slug, $cart);
        $this->cart = $cart;
        
        $this->dispatch('cartUpdated');
    }

    public function getCartTotalProperty()
    {
        return collect($this->cart)->sum(fn($item) => $item['price'] * $item['quantity']);
    }

    public function getCartCountProperty()
    {
        return collect($this->cart)->sum('quantity');
    }

    public function toggleCart()
    {
        $this->showCart = !$this->showCart;
    }

    public function placeOrder()
    {
        $this->setupTenant();
        
        if (empty($this->cart)) return;

        $tenantDb = DB::connection('tenant');
        $orderId = null;

        // 1. Check for an existing active order for this table
        if ($this->tableId) {
            $existingOrder = $tenantDb->table('orders')
                ->where('table_id', $this->tableId)
                ->whereIn('status', ['open', 'preparing', 'ready'])
                ->first();
            
            if ($existingOrder) {
                $orderId = $existingOrder->id;
                // Update existing order total
                $tenantDb->table('orders')
                    ->where('id', $orderId)
                    ->update([
                        'total' => $existingOrder->total + $this->cartTotal,
                        'updated_at' => now(),
                    ]);
            }
        }

        // 2. Create new order if none exists
        if (!$orderId) {
            $orderId = (string) Str::uuid();
            $tenantDb->table('orders')->insert([
                'id' => $orderId,
                'restaurant_id' => 1, 
                'table_id' => $this->tableId,
                'customer_name' => $this->customerName,
                'customer_phone' => $this->customerPhone,
                'status' => 'open',
                'source' => 'qr_self',
                'order_type' => $this->tableId ? 'dine_in' : 'takeaway',
                'total' => $this->cartTotal,
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            // Update table status if it's a dine-in order
            if ($this->tableId) {
                $tenantDb->table('tables')
                    ->where('id', $this->tableId)
                    ->update(['status' => 'occupied']);
            }
        }

        // 2. Fetch KDS stations for each item's category to group them correctly
        $itemIds = array_keys($this->cart);
        $itemsWithStations = $tenantDb->table('menu_items')
            ->join('menu_categories', 'menu_items.menu_category_id', '=', 'menu_categories.id')
            ->whereIn('menu_items.id', $itemIds)
            ->select('menu_items.id as item_id', 'menu_categories.kds_station_id')
            ->get()
            ->groupBy('kds_station_id');

        // 3. Create KOTs per station and Link Items
        foreach ($itemsWithStations as $stationId => $stationItems) {
            $kotId = (string) Str::uuid();
            
            $tenantDb->table('kots')->insert([
                'id' => $kotId,
                'order_id' => $orderId,
                'kds_station_id' => $stationId ?: null,
                'restaurant_id' => 1,
                'status' => 'pending',
                'created_at' => now(),
                'updated_at' => now(),
            ]);

            foreach ($stationItems as $itemInfo) {
                $cartItem = $this->cart[$itemInfo->item_id];
                
                // Check if this item already exists in the current order with 'pending' status
                $existingItem = $tenantDb->table('order_items')
                    ->where('order_id', $orderId)
                    ->where('menu_item_id', $itemInfo->item_id)
                    ->where('status', 'pending')
                    ->first();

                if ($existingItem) {
                    $tenantDb->table('order_items')
                        ->where('id', $existingItem->id)
                        ->update([
                            'quantity' => $existingItem->quantity + $cartItem['quantity'],
                            'updated_at' => now(),
                        ]);
                } else {
                    $tenantDb->table('order_items')->insert([
                        'id' => (string) Str::uuid(),
                        'order_id' => $orderId,
                        'kot_id' => $kotId,
                        'menu_item_id' => $itemInfo->item_id,
                        'quantity' => $cartItem['quantity'],
                        'price' => $cartItem['price'],
                        'status' => 'pending',
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            }
        }

        // 4. Clear the cart and state
        session()->forget('cart_' . $this->slug);
        $this->cart = [];
        $this->showCart = false;
        $this->orderSuccess = true;
        $this->loadPreviousOrder();
    }

    public function loadPreviousOrder()
    {
        $this->setupTenant();
        if (!$this->tableId) return;

        $tenantDb = DB::connection('tenant');
        $existingOrder = $tenantDb->table('orders')
            ->where('table_id', $this->tableId)
            ->whereIn('status', ['open', 'preparing', 'ready'])
            ->first();

        if ($existingOrder) {
            $this->previousOrderItems = $tenantDb->table('order_items')
                ->join('menu_items', 'order_items.menu_item_id', '=', 'menu_items.id')
                ->where('order_items.order_id', $existingOrder->id)
                ->select('menu_items.name', 'order_items.quantity', 'order_items.price', 'order_items.status')
                ->get()
                ->toArray();
        } else {
            $this->previousOrderItems = [];
        }
    }

    public function toggleHistory()
    {
        $this->loadPreviousOrder();
        $this->showHistory = !$this->showHistory;
    }

    public function render()
    {
        // setupTenant is already called in booted, which runs before render
        // But restaurant/menuCard are protected, so we need to ensure loadMenu handles them
        $this->loadMenu();

        return view('livewire.public-menu', [
            'restaurant' => $this->restaurant,
            'menuCard' => $this->menuCard,
            'categories' => $this->categories,
        ])
            ->layout('layouts.qr-order', [
                'title' => ($this->restaurant->name ?? 'Menu') . ' | Digital Menu',
            ]);
    }
}
