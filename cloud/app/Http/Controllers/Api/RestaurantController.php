<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Restaurant;
use App\Models\Role;
use App\Models\Setting;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class RestaurantController extends Controller
{
    protected $tenantService;

    public function __construct(TenantService $tenantService)
    {
        $this->tenantService = $tenantService;
    }

    public function index(Request $request)
    {
        $user = Auth::user();

        try {
            // Check if we want only the user's own restaurants
            $myRestaurants = $request->query('my_restaurants') === '1' || $request->has('my_restaurants');

            // Retrieve delivery radius from SaaS Settings
            $radius = (float) Setting::get('delivery_radius_km', 2.0);

            if ($user) {
                // Determine if the user is restaurant staff (e.g., manager, waiter, chef, cashier, etc.)
                $isStaff = DB::table('restaurant_role_user')->where('user_id', $user->id)->exists()
                    || DB::table('restaurant_user')->where('user_id', $user->id)->exists();

                // If the user is a restaurant owner (admin) or staff, and they are managing outlets, fetch from their central list
                if (($user->isRestaurant() || $isStaff) && $myRestaurants) {
                    $ownerIds = DB::table('restaurant_user')
                        ->where('user_id', $user->id)
                        ->pluck('restaurant_id')
                        ->toArray();

                    $staffIds = DB::table('restaurant_role_user')
                        ->where('user_id', $user->id)
                        ->pluck('restaurant_id')
                        ->toArray();

                    $restaurantIds = array_unique(array_merge($ownerIds, $staffIds));

                    $restaurants = Restaurant::where('user_id', $user->id)
                        ->orWhereIn('id', $restaurantIds)
                        ->get();

                    return response()->json([
                        'status' => 'success',
                        'data' => $restaurants,
                        'delivery_radius_km' => $radius,
                    ]);
                }

                // If a pure customer is managing their own created businesses (if any)
                if ($user->isCustomer() && $myRestaurants) {
                    $restaurants = Restaurant::where('user_id', $user->id)->get();

                    return response()->json([
                        'status' => 'success',
                        'data' => $restaurants,
                        'delivery_radius_km' => $radius,
                    ]);
                }
            }

            // Default fallback: return all platform restaurants from central DB (e.g. for customer home delivery feed)
            $restaurants = Restaurant::get();

            return response()->json([
                'status' => 'success',
                'data' => $restaurants,
                'delivery_radius_km' => $radius,
            ]);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Tenant database not found or inaccessible.',
                'error' => $e->getMessage(),
            ], 404);
        }
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'slug' => 'nullable|string|max:255|unique:restaurants,slug',
            'address' => 'nullable|string',
            'logo' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'is_veg' => 'boolean',
            'is_nonveg' => 'boolean',
            'is_jain' => 'boolean',
            'upi_id' => 'nullable|string|max:255',
            'takeaway_menu_card_id' => 'nullable|uuid',
            'delivery_menu_card_id' => 'nullable|uuid',
            'tax_name' => 'nullable|string|max:255',
            'tax_registration_number' => 'nullable|string|max:255',
            'fssai_number' => 'nullable|string|max:255',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'is_delivery' => 'boolean',
            'is_takeaway' => 'boolean',
            'is_dinein' => 'boolean',
            'bill_printer_ip' => 'nullable|string|max:255',
            'bill_printer_port' => 'nullable|integer',
        ]);

        $user = Auth::user();
        $dbName = $this->tenantService->ensureTenantDatabase($user);
        $logoPath = null;

        if ($request->hasFile('logo')) {
            $logoPath = $request->file('logo')->store("tenants/{$dbName}/logos", 'public');
        }

        // 1. Create in master database
        $restaurant = Restaurant::create([
            'user_id' => $user->id,
            'name' => $request->name,
            'slug' => $request->slug ?: (Str::slug($request->name).'-'.Str::random(5)),
            'address' => $request->address,
            'upi_id' => $request->upi_id,
            'logo' => $logoPath,
            'is_veg' => $request->has('is_veg') ? filter_var($request->is_veg, FILTER_VALIDATE_BOOLEAN) : true,
            'is_nonveg' => $request->has('is_nonveg') ? filter_var($request->is_nonveg, FILTER_VALIDATE_BOOLEAN) : true,
            'is_jain' => $request->has('is_jain') ? filter_var($request->is_jain, FILTER_VALIDATE_BOOLEAN) : false,
            'takeaway_menu_card_id' => $request->takeaway_menu_card_id,
            'delivery_menu_card_id' => $request->delivery_menu_card_id,
            'tax_name' => $request->tax_name,
            'tax_registration_number' => $request->tax_registration_number,
            'fssai_number' => $request->fssai_number,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'is_delivery' => $request->has('is_delivery') ? filter_var($request->is_delivery, FILTER_VALIDATE_BOOLEAN) : true,
            'is_takeaway' => $request->has('is_takeaway') ? filter_var($request->is_takeaway, FILTER_VALIDATE_BOOLEAN) : true,
            'is_dinein' => $request->has('is_dinein') ? filter_var($request->is_dinein, FILTER_VALIDATE_BOOLEAN) : true,
            'bill_printer_ip' => $request->bill_printer_ip,
            'bill_printer_port' => $request->bill_printer_port ?: 9100,
        ]);

        // 2. Link user to their own restaurant in the pivot table
        DB::table('restaurant_user')->updateOrInsert(
            [
                'restaurant_id' => $restaurant->id,
                'user_id' => $user->id,
            ],
            [
                'updated_at' => now(),
                'created_at' => now(),
            ]
        );

        // 3. Ensure the user has the global 'admin' role
        $adminRole = Role::where('name', 'admin')->first();
        if ($adminRole) {
            $user->roles()->syncWithoutDetaching([$adminRole->id]);
        }

        // 4. Sync to tenant database
        $this->tenantService->syncRestaurantToTenant($user, $restaurant->toArray());

        return response()->json([
            'status' => 'success',
            'message' => 'Restaurant created successfully and you have been assigned as Admin.',
            'data' => $restaurant,
        ], 201);
    }

    public function update(Request $request, $id)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'slug' => 'nullable|string|max:255|unique:restaurants,slug,'.$id,
            'address' => 'nullable|string',
            'logo' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'is_veg' => 'boolean',
            'is_nonveg' => 'boolean',
            'is_jain' => 'boolean',
            'upi_id' => 'nullable|string|max:255',
            'takeaway_menu_card_id' => 'nullable|uuid',
            'delivery_menu_card_id' => 'nullable|uuid',
            'tax_name' => 'nullable|string|max:255',
            'tax_registration_number' => 'nullable|string|max:255',
            'fssai_number' => 'nullable|string|max:255',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'is_delivery' => 'boolean',
            'is_takeaway' => 'boolean',
            'is_dinein' => 'boolean',
            'bill_printer_ip' => 'nullable|string|max:255',
            'bill_printer_port' => 'nullable|integer',
        ]);

        $user = Auth::user();
        $restaurant = Restaurant::where('id', $id)->where('user_id', $user->id)->firstOrFail();

        $data = [
            'name' => $request->name,
            'address' => $request->address,
            'upi_id' => $request->upi_id,
            'takeaway_menu_card_id' => $request->takeaway_menu_card_id,
            'delivery_menu_card_id' => $request->delivery_menu_card_id,
            'tax_name' => $request->tax_name,
            'tax_registration_number' => $request->tax_registration_number,
            'fssai_number' => $request->fssai_number,
            'latitude' => $request->latitude,
            'longitude' => $request->longitude,
            'bill_printer_ip' => $request->bill_printer_ip,
            'bill_printer_port' => $request->bill_printer_port ?: 9100,
        ];
        if ($request->has('slug') && ! empty($request->slug)) {
            $data['slug'] = $request->slug;
        }
        if ($request->has('is_veg')) {
            $data['is_veg'] = filter_var($request->is_veg, FILTER_VALIDATE_BOOLEAN);
        }
        if ($request->has('is_nonveg')) {
            $data['is_nonveg'] = filter_var($request->is_nonveg, FILTER_VALIDATE_BOOLEAN);
        }
        if ($request->has('is_jain')) {
            $data['is_jain'] = filter_var($request->is_jain, FILTER_VALIDATE_BOOLEAN);
        }
        if ($request->has('is_delivery')) {
            $data['is_delivery'] = filter_var($request->is_delivery, FILTER_VALIDATE_BOOLEAN);
        }
        if ($request->has('is_takeaway')) {
            $data['is_takeaway'] = filter_var($request->is_takeaway, FILTER_VALIDATE_BOOLEAN);
        }
        if ($request->has('is_dinein')) {
            $data['is_dinein'] = filter_var($request->is_dinein, FILTER_VALIDATE_BOOLEAN);
        }

        if ($request->hasFile('logo')) {
            // Delete old logo if exists
            if ($restaurant->logo) {
                Storage::disk('public')->delete($restaurant->logo);
            }
            $dbName = $this->tenantService->ensureTenantDatabase(Auth::user());
            $data['logo'] = $request->file('logo')->store("tenants/{$dbName}/logos", 'public');
        }

        // 1. Update in master database
        $restaurant->update($data);

        // 2. Sync to tenant database
        $this->tenantService->syncRestaurantToTenant($user, $restaurant->toArray());

        return response()->json([
            'status' => 'success',
            'message' => 'Restaurant updated successfully.',
            'data' => $restaurant,
        ]);
    }

    public function destroy($id)
    {
        $user = Auth::user();
        $restaurant = Restaurant::where('id', $id)->where('user_id', $user->id)->firstOrFail();

        // Delete logo file
        if ($restaurant->logo) {
            Storage::disk('public')->delete($restaurant->logo);
        }

        // 1. Delete from master database
        $restaurant->delete();

        // 2. Delete from tenant database
        $this->tenantService->deleteRestaurantFromTenant($user, $id);

        return response()->json([
            'status' => 'success',
            'message' => 'Restaurant deleted successfully.',
        ]);
    }
}
