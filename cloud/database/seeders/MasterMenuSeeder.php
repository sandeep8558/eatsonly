<?php

namespace Database\Seeders;

use App\Models\MasterMenu;
use App\Models\MasterCategory;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class MasterMenuSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $categories = MasterCategory::all();
        $catMap = $categories->pluck('id', 'name')->toArray();

        $raw_items = [
            // --- STARTERS (VEG) ---
            ['name' => 'Paneer Tikka', 'cats' => ['Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers', 'North Indian Specials']],
            ['name' => 'Paneer Malai Tikka', 'cats' => ['Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Paneer Achari Tikka', 'cats' => ['Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Paneer Hariyali Tikka', 'cats' => ['Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Veg Seekh Kabab', 'cats' => ['Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Hara Bhara Kabab', 'cats' => ['Veg Starters', 'Starters & Appetizers']],
            ['name' => 'Mushroom Tikka', 'cats' => ['Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Tandoori Aloo', 'cats' => ['Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Dahi Ke Sholay', 'cats' => ['Veg Starters', 'Starters & Appetizers']],
            ['name' => 'Soya Chaap Tikka', 'cats' => ['Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Veg Manchurian Dry', 'cats' => ['Veg Chinese', 'Veg Starters', 'Chinese Specials', 'Starters & Appetizers']],
            ['name' => 'Paneer Chilli Dry', 'cats' => ['Veg Chinese', 'Veg Starters', 'Chinese Specials', 'Starters & Appetizers']],
            ['name' => 'Veg Crispy', 'cats' => ['Veg Chinese', 'Veg Starters', 'Chinese Specials', 'Starters & Appetizers']],
            ['name' => 'Honey Chilli Potato', 'cats' => ['Veg Chinese', 'Fast Food & Snacks', 'Chinese Specials', 'Street Food']],
            ['name' => 'Veg Spring Roll', 'cats' => ['Veg Chinese', 'Veg Starters', 'Chinese Specials', 'Starters & Appetizers']],
            ['name' => 'Crispy Corn', 'cats' => ['Veg Chinese', 'Veg Starters', 'Chinese Specials', 'Starters & Appetizers']],
            
            // --- STARTERS (NON-VEG) ---
            ['name' => 'Chicken Tikka', 'cats' => ['Non-Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers', 'North Indian Specials']],
            ['name' => 'Chicken Malai Tikka', 'cats' => ['Non-Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Chicken Afgani Tikka', 'cats' => ['Non-Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Tandoori Chicken (Full)', 'cats' => ['Non-Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Chicken Tangdi Kabab', 'cats' => ['Non-Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Chicken Seekh Kabab', 'cats' => ['Non-Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Mutton Seekh Kabab', 'cats' => ['Non-Veg Starters', 'Grill & Tandoor', 'Starters & Appetizers']],
            ['name' => 'Chicken 65', 'cats' => ['Non-Veg Starters', 'South Indian Specials', 'Starters & Appetizers', 'South Indian']],
            ['name' => 'Chicken Chilli Dry', 'cats' => ['Non-Veg Chinese', 'Non-Veg Starters', 'Chinese Specials', 'Starters & Appetizers']],
            ['name' => 'Chicken Lollipop', 'cats' => ['Non-Veg Chinese', 'Non-Veg Starters', 'Chinese Specials', 'Starters & Appetizers']],
            ['name' => 'Fish Fry (Surmai)', 'cats' => ['Non-Veg Starters', 'Sea Food Specials', 'Sea Food', 'Starters & Appetizers']],
            ['name' => 'Fish Amritsari', 'cats' => ['Non-Veg Starters', 'Sea Food Specials', 'Sea Food', 'Starters & Appetizers']],
            ['name' => 'Butter Garlic Prawns', 'cats' => ['Non-Veg Starters', 'Sea Food Specials', 'Sea Food', 'Starters & Appetizers']],
            
            // --- MAIN COURSE (VEG) ---
            ['name' => 'Paneer Butter Masala', 'cats' => ['Veg Main Course', 'North Indian Specials', 'Main Course', 'North Indian']],
            ['name' => 'Kadai Paneer', 'cats' => ['Veg Main Course', 'North Indian Specials', 'Main Course', 'North Indian']],
            ['name' => 'Paneer Lababdar', 'cats' => ['Veg Main Course', 'North Indian Specials', 'Main Course', 'North Indian']],
            ['name' => 'Mix Vegetable', 'cats' => ['Veg Main Course', 'Main Course', 'North Indian']],
            ['name' => 'Dal Makhani', 'cats' => ['Veg Main Course', 'North Indian Specials', 'Main Course', 'North Indian']],
            ['name' => 'Dal Tadka', 'cats' => ['Veg Main Course', 'Main Course', 'North Indian']],
            ['name' => 'Malai Kofta', 'cats' => ['Veg Main Course', 'North Indian Specials', 'Main Course', 'North Indian']],
            ['name' => 'Chana Masala', 'cats' => ['Veg Main Course', 'North Indian Specials', 'Main Course', 'North Indian']],
            ['name' => 'Veg Kolhapuri', 'cats' => ['Veg Main Course', 'Main Course']],
            
            // --- MAIN COURSE (NON-VEG) ---
            ['name' => 'Butter Chicken', 'cats' => ['Non-Veg Main Course', 'Main Course', 'North Indian', 'North Indian Specials']],
            ['name' => 'Chicken Tikka Masala', 'cats' => ['Non-Veg Main Course', 'Main Course', 'North Indian', 'North Indian Specials']],
            ['name' => 'Chicken Handi', 'cats' => ['Non-Veg Main Course', 'Main Course']],
            ['name' => 'Chicken Rara', 'cats' => ['Non-Veg Main Course', 'Main Course']],
            ['name' => 'Mutton Rogan Josh', 'cats' => ['Non-Veg Main Course', 'Main Course', 'North Indian']],
            ['name' => 'Mutton Bhuna Gosht', 'cats' => ['Non-Veg Main Course', 'Main Course']],
            ['name' => 'Fish Curry (Coastal)', 'cats' => ['Non-Veg Main Course', 'Sea Food Specials', 'Sea Food', 'Main Course']],
            ['name' => 'Egg Curry', 'cats' => ['Non-Veg Main Course', 'Main Course']],
            
            // --- CHINESE MAIN ---
            ['name' => 'Veg Manchurian Gravy', 'cats' => ['Veg Chinese', 'Chinese Specials', 'Main Course']],
            ['name' => 'Chicken Chilli Gravy', 'cats' => ['Non-Veg Chinese', 'Chinese Specials', 'Main Course']],
            ['name' => 'Veg Fried Rice', 'cats' => ['Veg Chinese', 'Chinese Specials']],
            ['name' => 'Veg Hakka Noodles', 'cats' => ['Veg Chinese', 'Chinese Specials']],
            ['name' => 'Chicken Fried Rice', 'cats' => ['Non-Veg Chinese', 'Chinese Specials']],
            ['name' => 'Chicken Hakka Noodles', 'cats' => ['Non-Veg Chinese', 'Chinese Specials']],
            
            // --- SOUTH INDIAN ---
            ['name' => 'Plain Dosa', 'cats' => ['South Indian Specials', 'South Indian', 'Breakfast Specials']],
            ['name' => 'Masala Dosa', 'cats' => ['South Indian Specials', 'South Indian', 'Breakfast Specials']],
            ['name' => 'Idli Sambhar', 'cats' => ['South Indian Specials', 'South Indian', 'Breakfast Specials']],
            ['name' => 'Medu Vada', 'cats' => ['South Indian Specials', 'South Indian', 'Breakfast Specials']],
            ['name' => 'Onion Uttapam', 'cats' => ['South Indian Specials', 'South Indian', 'Breakfast Specials']],
            
            // --- BIRYANI & RICE ---
            ['name' => 'Chicken Dum Biryani', 'cats' => ['Non-Veg Biryani', 'Biryani & Pulao']],
            ['name' => 'Mutton Dum Biryani', 'cats' => ['Non-Veg Biryani', 'Biryani & Pulao']],
            ['name' => 'Veg Biryani', 'cats' => ['Veg Biryani', 'Biryani & Pulao']],
            ['name' => 'Veg Pulao', 'cats' => ['Veg Biryani', 'Biryani & Pulao', 'Main Course']],
            ['name' => 'Jeera Rice', 'cats' => ['Veg Main Course', 'Biryani & Pulao', 'Main Course']],
            
            // --- BREADS ---
            ['name' => 'Butter Naan', 'cats' => ['Veg Main Course', 'Main Course']],
            ['name' => 'Tandoori Roti', 'cats' => ['Veg Main Course', 'Main Course']],
            ['name' => 'Garlic Naan', 'cats' => ['Veg Main Course', 'Main Course']],
            
            // --- FAST FOOD / PIZZA / BURGER ---
            ['name' => 'Veg Burger', 'cats' => ['Pizza & Burgers', 'Fast Food & Snacks']],
            ['name' => 'Chicken Burger', 'cats' => ['Pizza & Burgers', 'Fast Food & Snacks']],
            ['name' => 'Margherita Pizza', 'cats' => ['Pizza & Burgers', 'Italian & Pasta']],
            ['name' => 'Veg Corn Pizza', 'cats' => ['Pizza & Burgers', 'Fast Food & Snacks']],
            ['name' => 'Chicken Tikka Pizza', 'cats' => ['Pizza & Burgers']],
            ['name' => 'French Fries', 'cats' => ['Fast Food & Snacks', 'Street Food']],
            
            // --- STREET FOOD ---
            ['name' => 'Pav Bhaji', 'cats' => ['Street Food', 'Fast Food & Snacks']],
            ['name' => 'Vada Pav', 'cats' => ['Street Food', 'Fast Food & Snacks']],
            ['name' => 'Paneer Kathi Roll', 'cats' => ['Street Food', 'Fast Food & Snacks']],
            ['name' => 'Chicken Kathi Roll', 'cats' => ['Street Food', 'Fast Food & Snacks']],
            
            // --- BEVERAGES ---
            ['name' => 'Sweet Lassi', 'cats' => ['Beverages & Mocktails']],
            ['name' => 'Virgin Mojito', 'cats' => ['Beverages & Mocktails']],
            ['name' => 'Cold Coffee', 'cats' => ['Beverages & Mocktails']],
            
            // --- DESSERTS ---
            ['name' => 'Gulab Jamun', 'cats' => ['Desserts & Ice Cream', 'Bakery & Sweets', 'Desserts & Ice Creams']],
            ['name' => 'Ras Malai', 'cats' => ['Desserts & Ice Cream', 'Bakery & Sweets', 'Desserts & Ice Creams']],
            ['name' => 'Sizzling Brownie', 'cats' => ['Desserts & Ice Cream', 'Desserts & Ice Creams']],
            
            // --- THALI ---
            ['name' => 'Executive Veg Thali', 'cats' => ['Traditional Thali', 'Main Course']],
            ['name' => 'Royal Non-Veg Thali', 'cats' => ['Traditional Thali', 'Main Course']],
            ['name' => 'Maharaja Thali', 'cats' => ['Traditional Thali', 'Main Course']],
            
            // --- CONTINENTAL / HEALTH ---
            ['name' => 'Grilled Chicken Salad', 'cats' => ['Health & Salads', 'Continental', 'Soups & Salads']],
            ['name' => 'Greek Salad', 'cats' => ['Health & Salads', 'Continental', 'Soups & Salads']],
            ['name' => 'Penne Alfredo Pasta', 'cats' => ['Italian & Pasta', 'Continental', 'Main Course']],
            ['name' => 'Pesto Pasta', 'cats' => ['Italian & Pasta', 'Continental', 'Main Course']],
            
            // --- SOUPS ---
            ['name' => 'Veg Manchow Soup', 'cats' => ['Veg Soups', 'Soups & Salads']],
            ['name' => 'Chicken Sweet Corn Soup', 'cats' => ['Non-Veg Soups', 'Soups & Salads']],
            ['name' => 'Tomato Soup', 'cats' => ['Veg Soups', 'Soups & Salads']],
        ];

        // Generate 500 items by adding variants
        $final_items = [];
        foreach ($raw_items as $item) {
            $final_items[] = [
                'name' => $item['name'],
                'desc' => "Premium preparation of " . $item['name'] . " using traditional recipes.",
                'cats' => $item['cats']
            ];

            // Add Half/Full variants for main course/biryani
            if (Str::contains($item['name'], ['Paneer', 'Chicken', 'Mutton', 'Dal', 'Biryani', 'Rice'])) {
                $final_items[] = [
                    'name' => $item['name'] . ' (Full)',
                    'desc' => "Large portion of " . $item['name'] . ".",
                    'cats' => $item['cats']
                ];
                $final_items[] = [
                    'name' => $item['name'] . ' (Half)',
                    'desc' => "Regular portion of " . $item['name'] . ".",
                    'cats' => $item['cats']
                ];
            }

            // Add Double Cheese variants for Pizzas/Burgers
            if (Str::contains($item['name'], ['Pizza', 'Burger'])) {
                $final_items[] = [
                    'name' => 'Double Cheese ' . $item['name'],
                    'desc' => "Extra cheesy " . $item['name'] . ".",
                    'cats' => $item['cats']
                ];
            }
        }

        // Fill up to 500 with unique names
        $names = [];
        $unique_items = [];
        foreach ($final_items as $f) {
            if (!in_array($f['name'], $names)) {
                $names[] = $f['name'];
                $unique_items[] = $f;
            }
        }

        $unique_items = array_slice($unique_items, 0, 500);

        foreach ($unique_items as $item) {
            $menu = MasterMenu::updateOrCreate(['name' => $item['name']], [
                'description' => $item['desc'],
                'image' => null,
                'is_active' => true,
            ]);

            $catIds = [];
            foreach ($item['cats'] as $cName) {
                if (isset($catMap[$cName])) {
                    $catIds[] = $catMap[$cName];
                }
            }
            $menu->categories()->sync($catIds);
        }
    }
}
