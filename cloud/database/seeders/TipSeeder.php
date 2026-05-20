<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Order;
use App\Models\User;
use App\Services\TenantService;
use Illuminate\Support\Str;

class TipSeeder extends Seeder
{
    public function run()
    {
        $admin = User::where('email', 'admin@admin.com')->first();
        if (!$admin) return;

        $tenantService = app(TenantService::class);
        $dbName = 'resto_' . str_replace('-', '_', $admin->id);
        $tenantService->switchToTenant($dbName);

        // Get some users to be waiters
        $waiters = User::take(3)->get();
        if ($waiters->isEmpty()) return;

        for ($i = 0; $i < 20; $i++) {
            Order::on('tenant')->create([
                'id' => Str::uuid(),
                'restaurant_id' => 1, // Assuming first resto
                'table_id' => null,
                'user_id' => $waiters->random()->id,
                'order_type' => 'dine-in',
                'status' => 'paid',
                'subtotal' => rand(500, 2000),
                'tax' => rand(50, 200),
                'total' => rand(600, 2500),
                'tip_amount' => rand(50, 300),
                'created_at' => now()->subDays(rand(0, 15)),
                'updated_at' => now(),
            ]);
        }
    }
}
