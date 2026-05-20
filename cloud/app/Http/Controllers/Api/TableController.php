<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Floor;
use App\Models\RestaurantTable;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TableController extends Controller
{
    protected $tenantService;

    public function __construct(TenantService $tenantService)
    {
        $this->tenantService = $tenantService;
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

    public function getFloors(Request $request)
    {
        $this->setTenant();
        $floors = Floor::with(['tables', 'menuCard'])
            ->where('restaurant_id', $request->restaurant_id)
            ->orderBy('sort_order')
            ->get();

        // Dynamically override status based on active orders
        $activeTableIds = \App\Models\Order::where('restaurant_id', $request->restaurant_id)
            ->whereIn('status', ['open', 'preparing', 'ready'])
            ->whereNotNull('table_id')
            ->pluck('table_id')
            ->toArray();

        foreach ($floors as $floor) {
            foreach ($floor->tables as $table) {
                if (in_array($table->id, $activeTableIds)) {
                    $table->status = 'occupied';
                }
            }
        }

        return response()->json(['status' => 'success', 'data' => $floors]);
    }

    public function storeFloor(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'name' => 'required|string|max:255',
            'menu_card_id' => 'nullable|uuid'
        ]);
        $this->setTenant();
        $floor = Floor::create($request->all());
        return response()->json(['status' => 'success', 'data' => $floor]);
    }

    public function updateFloor(Request $request, $id)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'menu_card_id' => 'nullable|uuid'
        ]);
        $this->setTenant();
        $floor = Floor::findOrFail($id);
        $floor->update($request->all());
        return response()->json(['status' => 'success', 'data' => $floor]);
    }

    public function deleteFloor($id)
    {
        $this->setTenant();
        Floor::where('id', $id)->delete();
        // Also delete tables for this floor
        RestaurantTable::where('floor_id', $id)->delete();
        return response()->json(['status' => 'success']);
    }

    public function storeTable(Request $request)
    {
        $request->validate([
            'floor_id' => 'required|uuid',
            'name' => 'required|string|max:255',
            'capacity' => 'integer',
            'shape' => 'string'
        ]);
        $this->setTenant();
        $table = RestaurantTable::create($request->all());
        return response()->json(['status' => 'success', 'data' => $table]);
    }

    public function updateTable(Request $request, $id)
    {
        $this->setTenant();
        $table = RestaurantTable::findOrFail($id);
        $table->update($request->all());
        return response()->json(['status' => 'success', 'data' => $table]);
    }

    public function deleteTable($id)
    {
        $this->setTenant();
        RestaurantTable::where('id', $id)->delete();
        return response()->json(['status' => 'success']);
    }

    public function updateLayout(Request $request)
    {
        $request->validate([
            'tables' => 'required|array',
            'tables.*.id' => 'required|uuid',
            'tables.*.x_pos' => 'required|numeric',
            'tables.*.y_pos' => 'required|numeric',
        ]);
        
        $this->setTenant();
        foreach ($request->tables as $tableData) {
            RestaurantTable::where('id', $tableData['id'])->update([
                'x_pos' => $tableData['x_pos'],
                'y_pos' => $tableData['y_pos']
            ]);
        }
        
        return response()->json(['status' => 'success']);
    }
}
