<?php

namespace Database\Seeders;

use App\Models\InventoryCategory;
use App\Models\Restaurant;
use App\Services\TenantService;
use Illuminate\Database\Seeder;

class InventoryCategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $tenantService = app(TenantService::class);
        $restaurants = Restaurant::all();

        if ($restaurants->isEmpty()) {
            return;
        }

        $defaults = [
            'Raw Materials',
            'Beverages',
            'Prepared Items',
            'Packaging',
            'Cleaning Supplies',
            'Consumables',
            'Poultry & Meat',
            'Fresh Vegetables',
            'Dairy Products',
            'Packaging Materials',
            'Dry Goods & Spices'
        ];

        foreach ($restaurants as $restaurant) {
            // Switch database context to this restaurant's tenant db
            $dbName = 'resto_' . str_replace('-', '_', $restaurant->user_id);
            try {
                $tenantService->switchToTenant($dbName);
                $tenantService->syncSchema($restaurant->user);

                foreach ($defaults as $name) {
                    InventoryCategory::on('tenant')->firstOrCreate(
                        [
                            'restaurant_id' => $restaurant->id,
                            'name' => $name,
                        ]
                    );
                }
            } catch (\Exception $e) {
                // If a tenant DB does not exist yet, skip it safely
                continue;
            }
        }
    }
}
