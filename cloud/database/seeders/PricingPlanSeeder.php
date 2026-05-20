<?php

namespace Database\Seeders;

use App\Models\PricingPlan;
use Illuminate\Database\Seeder;

class PricingPlanSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $plans = [
            [
                'name' => 'Silver Plan',
                'monthly_price' => 100,
                'yearly_price' => 1000,
                'description' => 'Essential features for small cafes and individual restaurant owners.',
                'list' => [
                    '1 Outlet Managed',
                    'Offline-First POS',
                    'Cloud Sync',
                    'Basic Reports'
                ],
                'is_active' => true,
            ],
            [
                'name' => 'Gold Plan',
                'monthly_price' => 150,
                'yearly_price' => 1500,
                'description' => 'Perfect for growing brands and multi-location restaurant groups.',
                'list' => [
                    'Up to 3 Outlets',
                    'Advanced Inventory Sync',
                    'Priority Support',
                    'Chef & Staff Management'
                ],
                'is_active' => true,
            ],
            [
                'name' => 'Diamond Plan',
                'monthly_price' => 200,
                'yearly_price' => 2000,
                'description' => 'Enterprise-grade solution for national chains and global franchises.',
                'list' => [
                    'Unlimited Outlets',
                    'AI Predictive Analytics',
                    'White-label Support',
                    'Custom Integrations'
                ],
                'is_active' => true,
            ],
        ];

        foreach ($plans as $plan) {
            PricingPlan::updateOrCreate(
                ['name' => $plan['name']],
                $plan
            );
        }
    }
}
