<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\TaxGroup;
use App\Models\Tax;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class TaxGroupController extends Controller
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

    /**
     * Display a listing of the tax groups.
     */
    public function index()
    {
        $this->setTenant();
        $groups = TaxGroup::with('taxes')->get();
        
        return response()->json([
            'status' => 'success',
            'data' => $groups
        ]);
    }

    /**
     * Store a newly created tax group in storage.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'is_active' => 'boolean',
            'is_inclusive' => 'boolean',
            'taxes' => 'required|array|min:1',
            'taxes.*.name' => 'required|string|max:255',
            'taxes.*.percentage' => 'required|numeric|min:0|max:100',
        ]);

        $this->setTenant();

        try {
            DB::connection('tenant')->beginTransaction();

            $group = TaxGroup::create([
                'name' => $request->name,
                'is_active' => $request->is_active ?? true,
                'is_inclusive' => $request->is_inclusive ?? false,
            ]);

            foreach ($request->taxes as $taxData) {
                $group->taxes()->create([
                    'name' => $taxData['name'],
                    'percentage' => $taxData['percentage'],
                ]);
            }

            DB::connection('tenant')->commit();

            return response()->json([
                'status' => 'success',
                'message' => 'Tax group created successfully',
                'data' => $group->load('taxes')
            ], 201);

        } catch (\Exception $e) {
            DB::connection('tenant')->rollBack();
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to create tax group',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Display the specified tax group.
     */
    public function show($id)
    {
        $this->setTenant();
        $group = TaxGroup::with('taxes')->findOrFail($id);
        
        return response()->json([
            'status' => 'success',
            'data' => $group
        ]);
    }

    /**
     * Update the specified tax group in storage.
     */
    public function update(Request $request, $id)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'is_active' => 'boolean',
            'is_inclusive' => 'boolean',
            'taxes' => 'required|array|min:1',
            'taxes.*.id' => 'nullable|uuid',
            'taxes.*.name' => 'required|string|max:255',
            'taxes.*.percentage' => 'required|numeric|min:0|max:100',
        ]);

        $this->setTenant();

        try {
            DB::connection('tenant')->beginTransaction();

            $group = TaxGroup::findOrFail($id);
            $group->update([
                'name' => $request->name,
                'is_active' => $request->is_active ?? $group->is_active,
                'is_inclusive' => $request->is_inclusive ?? $group->is_inclusive,
            ]);

            // Sync taxes
            $existingTaxIds = collect($request->taxes)->pluck('id')->filter()->toArray();
            $group->taxes()->whereNotIn('id', $existingTaxIds)->delete();

            foreach ($request->taxes as $taxData) {
                if (isset($taxData['id'])) {
                    $tax = Tax::find($taxData['id']);
                    if ($tax) {
                        $tax->update([
                            'name' => $taxData['name'],
                            'percentage' => $taxData['percentage'],
                        ]);
                    }
                } else {
                    $group->taxes()->create([
                        'name' => $taxData['name'],
                        'percentage' => $taxData['percentage'],
                    ]);
                }
            }

            DB::connection('tenant')->commit();

            return response()->json([
                'status' => 'success',
                'message' => 'Tax group updated successfully',
                'data' => $group->load('taxes')
            ]);

        } catch (\Exception $e) {
            DB::connection('tenant')->rollBack();
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to update tax group',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * Remove the specified tax group from storage.
     */
    public function destroy($id)
    {
        $this->setTenant();
        $group = TaxGroup::findOrFail($id);
        $group->delete(); 

        return response()->json([
            'status' => 'success',
            'message' => 'Tax group deleted successfully'
        ]);
    }
}
