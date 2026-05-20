<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        if (app()->runningInConsole() || !\Illuminate\Support\Facades\Schema::hasTable('settings')) {
            return;
        }

        try {
            $domain = \App\Models\Setting::get('mailgun_domain');
            $secret = \App\Models\Setting::get('mailgun_secret');
            $fromAddress = \App\Models\Setting::get('mailgun_from_address');
            $fromName = \App\Models\Setting::get('mailgun_from_name');

            if ($domain && $secret && $fromAddress) {
                config([
                    'mail.mailers.mailgun.transport' => 'mailgun',
                    'services.mailgun.domain' => $domain,
                    'services.mailgun.secret' => $secret,
                    'mail.from.address' => $fromAddress,
                    'mail.from.name' => $fromName ?? config('app.name'),
                ]);
            }
        } catch (\Exception $e) {
            // Silently fail in boot to avoid crashing the app during setup
        }
    }
}
