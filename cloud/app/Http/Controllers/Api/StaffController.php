<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Restaurant;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class StaffController extends Controller
{
    public function __construct()
    {
    }

    /**
     * Search for an existing user by email or mobile.
     */
    public function search(Request $request)
    {
        $request->validate(['query' => 'required|string']);
        $query = $request->input('query');

        $user = User::where('email', $query)
            ->orWhere('mobile', $query)
            ->first();

        if ($user) {
            return response()->json([
                'status' => 'success',
                'exists' => true,
                'data' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'email' => $user->email,
                    'mobile' => $user->mobile,
                ]
            ]);
        }

        return response()->json([
            'status' => 'success',
            'exists' => false
        ]);
    }

    /**
     * Get all staff linked to the authenticated owner's restaurants.
     */
    public function index(Request $request)
    {
        $user = Auth::user();
        $selectedRestaurantId = $request->query('restaurant_id');
        
        $restaurantIds = Restaurant::where('user_id', $user->id);
        if ($selectedRestaurantId) {
            $restaurantIds = $restaurantIds->where('id', $selectedRestaurantId);
        }
        $restaurantIds = $restaurantIds->pluck('id');

        $staff = DB::table('restaurant_user')
            ->join('users', 'restaurant_user.user_id', '=', 'users.id')
            ->join('restaurants', 'restaurant_user.restaurant_id', '=', 'restaurants.id')
            ->whereIn('restaurant_user.restaurant_id', $restaurantIds)
            ->select(
                'users.id',
                'users.name',
                'users.email',
                'users.mobile',
                'restaurants.id as restaurant_id',
                'restaurants.name as restaurant_name'
            )
            ->get()
            ->map(function ($item) {
                $roles = DB::table('restaurant_role_user')
                    ->join('roles', 'restaurant_role_user.role_id', '=', 'roles.id')
                    ->where('restaurant_role_user.user_id', $item->id)
                    ->where('restaurant_role_user.restaurant_id', $item->restaurant_id)
                    ->pluck('roles.name')
                    ->toArray();
                $item->roles = $roles;
                return $item;
            });

        return response()->json([
            'status' => 'success',
            'data' => $staff
        ]);
    }

    /**
     * Create or link a staff member. Roles are stored in global role_user table.
     */
    public function store(Request $request)
    {
        $request->validate([
            'restaurant_id' => 'required|exists:restaurants,id',
            'name' => 'required|string|max:255',
            'email' => 'required|email',
            'mobile' => 'required|string',
            'roles' => 'required|array',
            'password' => 'nullable|string|min:8',
        ]);

        $owner = Auth::user();
        $restaurant = Restaurant::where('id', $request->restaurant_id)
            ->where('user_id', $owner->id)
            ->firstOrFail();

        $user = User::where('email', $request->email)
            ->orWhere('mobile', $request->mobile)
            ->first();

        if (!$user) {
            $user = User::create([
                'id' => (string) Str::uuid(),
                'name' => $request->name,
                'email' => $request->email,
                'mobile' => $request->mobile,
                'password' => Hash::make($request->password ?? 'password123'),
            ]);
        }

        // Link in restaurant pivot (No roles column here now)
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

        // Save roles specifically under this restaurant in restaurant_role_user
        DB::table('restaurant_role_user')
            ->where('restaurant_id', $restaurant->id)
            ->where('user_id', $user->id)
            ->delete();

        $roleIds = Role::whereIn('name', $request->roles)->pluck('id')->toArray();
        foreach ($roleIds as $roleId) {
            DB::table('restaurant_role_user')->insert([
                'restaurant_id' => $restaurant->id,
                'user_id' => $user->id,
                'role_id' => $roleId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Staff member added successfully.',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'roles' => $request->roles,
                'restaurant_name' => $restaurant->name
            ]
        ]);
    }

    /**
     * Update staff details and global roles.
     */
    public function update(Request $request, $id)
    {
        $request->validate([
            'restaurant_id' => 'required|exists:restaurants,id',
            'roles' => 'required|array',
            'name' => 'required|string',
        ]);

        $owner = Auth::user();
        $restaurant = Restaurant::where('id', $request->restaurant_id)
            ->where('user_id', $owner->id)
            ->firstOrFail();

        User::where('id', $id)->update(['name' => $request->name]);

        // Sync roles under specific restaurant in restaurant_role_user
        DB::table('restaurant_role_user')
            ->where('restaurant_id', $restaurant->id)
            ->where('user_id', $id)
            ->delete();

        $roleIds = Role::whereIn('name', $request->roles)->pluck('id')->toArray();
        foreach ($roleIds as $roleId) {
            DB::table('restaurant_role_user')->insert([
                'restaurant_id' => $restaurant->id,
                'user_id' => $id,
                'role_id' => $roleId,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Staff details updated successfully.'
        ]);
    }

    /**
     * Unlink staff.
     */
    public function destroy(Request $request, $id)
    {
        $request->validate([
            'restaurant_id' => 'required|exists:restaurants,id',
        ]);

        $owner = Auth::user();
        $restaurant = Restaurant::where('id', $request->restaurant_id)
            ->where('user_id', $owner->id)
            ->firstOrFail();

        DB::table('restaurant_user')
            ->where('restaurant_id', $request->restaurant_id)
            ->where('user_id', $id)
            ->delete();

        DB::table('restaurant_role_user')
            ->where('restaurant_id', $request->restaurant_id)
            ->where('user_id', $id)
            ->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Staff member removed from this restaurant.'
        ]);
    }
}
