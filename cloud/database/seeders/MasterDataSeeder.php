<?php

namespace Database\Seeders;

use App\Models\MasterCategory;
use App\Models\MasterMenu;
use Illuminate\Database\Seeder;

class MasterDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // 1. Create Comprehensive Categories with Veg/Non-Veg distinction
        $categories = [
            ['name' => 'Veg Starters'],
            ['name' => 'Non-Veg Starters'],
            ['name' => 'Veg Main Course'],
            ['name' => 'Non-Veg Main Course'],
            ['name' => 'Veg Soups'],
            ['name' => 'Non-Veg Soups'],
            ['name' => 'Veg Biryani'],
            ['name' => 'Non-Veg Biryani'],
            ['name' => 'Veg Chinese'],
            ['name' => 'Non-Veg Chinese'],
            ['name' => 'Beverages & Mocktails'],
            ['name' => 'Desserts & Ice Creams'],
            ['name' => 'Fast Food & Snacks'],
            ['name' => 'Italian & Pasta'],
            ['name' => 'North Indian Specials'],
            ['name' => 'South Indian Specials'],
            ['name' => 'Sea Food Specials'],
            ['name' => 'Street Food'],
            ['name' => 'Health & Salads'],
            ['name' => 'Bakery & Sweets'],
            ['name' => 'Pizza & Burgers'],
            ['name' => 'Grill & Tandoor'],
        ];

        $categoryModels = [];
        foreach ($categories as $cat) {
            $categoryModels[] = MasterCategory::firstOrCreate(['name' => $cat['name']], [
                'is_active' => true
            ]);
        }
    }
}
