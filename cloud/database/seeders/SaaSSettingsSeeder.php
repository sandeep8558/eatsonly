<?php

namespace Database\Seeders;

use App\Models\Setting;
use Illuminate\Database\Seeder;

class SaaSSettingsSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $settings = [
            'razorpay_key' => 'rzp_test_placeholder',
            'razorpay_secret' => 'placeholder_secret',
            'mailgun_domain' => 'leenaitsolutions.in',
            'mailgun_secret' => 'placeholder_mailgun_secret',
            'mailgun_from_address' => 'leenaitsolutions@gmail.com',
            'mailgun_from_name' => 'Resto Cloud',
            'sales_enabled' => true,
        ];

        foreach ($settings as $key => $value) {
            Setting::updateOrCreate(
                ['key' => $key],
                ['value' => $value]
            );
        }
    }
}
