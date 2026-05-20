<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\KDSStation;
use App\Services\TenantService;
use Illuminate\Http\Request;

class KDSStationController extends Controller
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
        $request->validate(['restaurant_id' => 'required']);
        $this->setTenant();

        $stations = KDSStation::where('restaurant_id', $request->restaurant_id)->get();
        return response()->json(['status' => 'success', 'data' => $stations]);
    }

    public function store(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required',
            'name' => 'required|string|max:255'
        ]);
        $this->setTenant();

        $station = KDSStation::create($request->all());
        return response()->json(['status' => 'success', 'data' => $station]);
    }

    public function update(Request $request, $id)
    {
        $this->setTenant();
        $station = KDSStation::findOrFail($id);
        $station->update($request->all());
        return response()->json(['status' => 'success', 'data' => $station]);
    }

    public function destroy($id)
    {
        $this->setTenant();
        $station = KDSStation::findOrFail($id);
        $station->delete();
        return response()->json(['status' => 'success', 'message' => 'Station deleted']);
    }
}
