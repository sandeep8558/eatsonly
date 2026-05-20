<?php

use Illuminate\Support\Facades\Route;
use App\Models\PricingPlan;
use App\Livewire\Admin\Dashboard as AdminDashboard;
use App\Livewire\Admin\PricingPlanManager;
use App\Livewire\Admin\UserManager;
use App\Livewire\Restaurant\Dashboard as RestaurantDashboard;
use App\Livewire\Customer\Dashboard as CustomerDashboard;

Route::get('/download', function () {
    return view('download');
})->name('download');

Route::get('/contact', function () {
    return view('contact');
})->name('contact');

Route::get('/terms', function () {
    return view('terms');
})->name('terms');

Route::get('/privacy', function () {
    return view('privacy');
})->name('privacy');

Route::get('/about', function () {
    return view('about');
})->name('about');

Route::get('/careers', function () {
    return view('careers');
})->name('careers');

Route::get('/cookies', function () {
    return view('cookies');
})->name('cookies');

Route::post('/contact', [\App\Http\Controllers\ContactController::class, 'submit'])->name('contact.submit');

Route::get('sitemap.xml', function () {
    return response()->view('sitemap')->header('Content-Type', 'text/xml');
});

Route::get('/pricing', function () {
    return view('pricing', [
        'plans' => PricingPlan::all(),
        'currentSubscription' => auth()->check() ? auth()->user()->activeSubscription : null
    ]);
})->name('pricing');

Route::get('/features', function () {
    return view('features');
})->name('features');

Route::view('/', 'welcome');
Route::get('/m/{slug}', \App\Livewire\PublicMenu::class)->name('public.menu');

Route::get('/dashboard', function () {
    $user = auth()->user();
    if ($user->hasRole('saas_super_admin')) {
        return redirect()->route('admin.dashboard');
    }
    if ($user->hasRole('admin')) {
        return redirect()->route('restaurant.dashboard');
    }
    return redirect()->route('customer.dashboard');
})->middleware(['auth', 'verified'])->name('dashboard');

use App\Livewire\Admin\SaaSSettings;

use App\Livewire\Checkout;

Route::get('/checkout/{plan}/{period}', Checkout::class)->middleware('auth')->name('checkout');

use App\Livewire\Admin\PaymentManager;

use App\Livewire\Admin\AllRestaurants;



Route::middleware(['auth', 'verified', 'role:saas_super_admin'])->prefix('admin')->group(function () {
    Route::get('/dashboard', AdminDashboard::class)->name('admin.dashboard');
    Route::get('/pricing-plans', PricingPlanManager::class)->name('admin.pricing-plans');
    Route::get('/users', UserManager::class)->name('admin.users');
    Route::get('/settings', SaaSSettings::class)->name('admin.settings');
    Route::get('/payments', PaymentManager::class)->name('admin.payments');
    Route::get('/restaurants', AllRestaurants::class)->name('admin.restaurants');
    Route::get('/categories', \App\Livewire\Admin\MasterCategoryManager::class)->name('admin.categories');
    Route::get('/menus', \App\Livewire\Admin\MasterMenuManager::class)->name('admin.menus');
});

Route::middleware(['auth', 'verified', 'role:admin'])->prefix('restaurant')->group(function () {
    Route::get('/dashboard', RestaurantDashboard::class)->name('restaurant.dashboard');
});

Route::middleware(['auth', 'verified', 'role:customer'])->prefix('customer')->group(function () {
    Route::get('/dashboard', CustomerDashboard::class)->name('customer.dashboard');
});

Route::view('profile', 'profile')
    ->middleware(['auth'])
    ->name('profile');

require __DIR__ . '/auth.php';
