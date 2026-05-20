<?php

namespace App\Livewire\Customer;

use Livewire\Component;
use Livewire\Attributes\Layout;
use App\Models\Role;
use Illuminate\Support\Facades\Auth;

class Dashboard extends Component
{
    public $confirmingUpgrade = false;

    public function confirmUpgrade()
    {
        $this->confirmingUpgrade = true;
    }

    public function cancelUpgrade()
    {
        $this->confirmingUpgrade = false;
    }

    public function upgradeToRestaurantAdmin()
    {
        $user = Auth::user();
        $adminRole = Role::where('name', 'admin')->first();

        if ($adminRole && !$user->hasRole('admin')) {
            $user->roles()->attach($adminRole->id);
            session()->flash('message', 'Welcome to the business side! You are now a Restaurant Admin.');
            return redirect()->route('restaurant.dashboard');
        }

        $this->confirmingUpgrade = false;
    }

    #[Layout('layouts.app')]
    public function render()
    {
        return view('livewire.customer.dashboard');
    }
}
