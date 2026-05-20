<?php

namespace App\Livewire\Admin;

use App\Models\User;
use App\Models\Restaurant;
use App\Models\Payment;
use App\Models\Subscription;
use Livewire\Component;
use Livewire\Attributes\Layout;

class Dashboard extends Component
{
    #[Layout('layouts.app')]
    public function render()
    {
        // User Stats
        $totalUsers = User::whereHas('roles', fn($q) => $q->where('name', 'admin'))->count();
        $activeUsers = User::whereHas('activeSubscription')->count();
        $expiredUsers = User::whereHas('roles', fn($q) => $q->where('name', 'admin'))
            ->whereDoesntHave('activeSubscription')
            ->count();

        // Revenue Stats
        $totalRevenue = Payment::where('status', 'success')->sum('amount');
        $todayRevenue = Payment::where('status', 'success')
            ->whereDate('created_at', now()->today())
            ->sum('amount');
        $thisMonthRevenue = Payment::where('status', 'success')
            ->whereMonth('created_at', now()->month)
            ->whereYear('created_at', now()->year)
            ->sum('amount');

        // Restaurant Stats
        $totalRestaurants = Restaurant::count();

        // Recent Payments
        $recentPayments = Payment::with(['user', 'subscription.plan'])
            ->latest()
            ->take(5)
            ->get();

        return view('livewire.admin.dashboard', [
            'stats' => [
                'total_users' => $totalUsers,
                'active_users' => $activeUsers,
                'expired_users' => $expiredUsers,
                'total_revenue' => $totalRevenue,
                'today_revenue' => $todayRevenue,
                'monthly_revenue' => $thisMonthRevenue,
                'total_restaurants' => $totalRestaurants,
            ],
            'recentPayments' => $recentPayments
        ]);
    }
}
