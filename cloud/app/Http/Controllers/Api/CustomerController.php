<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Hash;

class CustomerController extends Controller
{
    public function index(Request $request)
    {
        $query = User::whereHas('roles', function($q) {
            $q->where('name', 'customer');
        });

        if ($request->has('search')) {
            $search = $request->get('search');
            $query->where(function($q) use ($search) {
                $q->where('mobile', 'like', "%{$search}%")
                  ->orWhere('name', 'like', "%{$search}%");
            });
        }

        $customers = $query->latest()->limit(10)->get();

        return response()->json($customers);
    }

    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'mobile' => 'required|string|max:15',
            'email' => 'nullable|email|max:255',
        ]);

        // Check for existing customer by mobile in master DB
        $customer = User::where('mobile', $request->mobile)->first();

        if ($customer) {
            // Ensure they have the customer role
            if (!$customer->isCustomer()) {
                $customerRole = Role::where('name', 'customer')->first();
                if ($customerRole) {
                    $customer->roles()->syncWithoutDetaching([$customerRole->id]);
                }
            }
            $customer->update($request->only(['name', 'email']));
        } else {
            $customer = User::create([
                'id' => Str::uuid(),
                'name' => $request->name,
                'mobile' => $request->mobile,
                'email' => $request->email,
                'password' => Hash::make(Str::random(12)), // Default random password for customers
            ]);

            $customerRole = Role::where('name', 'customer')->first();
            if ($customerRole) {
                $customer->roles()->attach($customerRole->id);
            }
        }

        return response()->json($customer);
    }
}
