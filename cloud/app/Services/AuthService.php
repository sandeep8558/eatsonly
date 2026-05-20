<?php

namespace App\Services;

use App\Models\User;
use App\Models\Restaurant;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use App\Enums\UserRole;

class AuthService
{
    public function register(array $data)
    {
        try {
            $user = DB::transaction(function () use ($data) {
                // 1. Create user in main database (resto_cloud)
                $user = User::create([
                    'name' => $data['name'],
                    'email' => $data['email'],
                    'mobile' => $data['mobile'],
                    'password' => Hash::make($data['password']),
                ]);

                $roleName = $this->getRoleNameForEmail($data['email']);
                $role = \App\Models\Role::where('name', $roleName)->first();
                
                if ($role) {
                    $user->roles()->attach($role->id);
                    \Illuminate\Support\Facades\Log::info("Assigned role {$roleName} to user {$user->email}");
                } else {
                    \Illuminate\Support\Facades\Log::error("Role {$roleName} not found during registration for {$user->email}");
                }

                return $user;
            });

            return $user;
        } catch (\Illuminate\Database\UniqueConstraintViolationException $e) {
            throw \Illuminate\Validation\ValidationException::withMessages([
                'email' => ['This email or mobile number is already registered in our system.'],
            ]);
        }
    }

    protected function getRoleNameForEmail(string $email): string
    {
        $adminEmails = ['sandeep198558@yahoo.com', 'leenaadam28@gmail.com'];
        return in_array($email, $adminEmails) ? 'saas_super_admin' : 'customer';
    }
}
