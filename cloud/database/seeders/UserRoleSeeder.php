<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Role;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UserRoleSeeder extends Seeder
{
    public function run(): void
    {
        // Clean up deprecated roles
        $deprecatedRoles = Role::whereIn('name', ['bartender', 'service_provider'])->get();
        foreach ($deprecatedRoles as $deprecatedRole) {
            $deprecatedRole->users()->detach();
            $deprecatedRole->delete();
        }

        // 1. Create Roles
        $roles = [
            'saas_super_admin' => 'SaaS Super Admin',
            'admin' => 'Restaurant Admin',
            'manager' => 'Manager',
            'cashier' => 'Cashier',
            'waiter' => 'Waiter',
            'chef' => 'Chef',
            'accountant' => 'Accountant',
            'delivery_executive' => 'Delivery Executive',
            'customer' => 'Customer',
        ];

        foreach ($roles as $name => $displayName) {
            Role::firstOrCreate(['name' => $name], ['display_name' => $displayName]);
        }

        // 2. Create Super Admins
        $superAdminRole = Role::where('name', 'saas_super_admin')->first();
        
        $admins = [
            [
                'name' => 'Sandeep Rathod',
                'email' => 'sandeep198558@yahoo.com',
                'mobile' => '9664588677',
                'password' => Hash::make('password'),
            ],
            [
                'name' => 'Leena Adam',
                'email' => 'leenaadam28@gmail.com',
                'mobile' => '9769409405',
                'password' => Hash::make('password'),
            ],
        ];

        foreach ($admins as $adminData) {
            $user = User::updateOrCreate(['email' => $adminData['email']], $adminData);
            $user->roles()->sync([$superAdminRole->id]);
        }
    }
}
