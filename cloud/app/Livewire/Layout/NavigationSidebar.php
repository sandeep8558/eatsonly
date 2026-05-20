<?php

namespace App\Livewire\Layout;

use App\Livewire\Actions\Logout;
use Livewire\Volt\Component;
use Livewire\Component as LivewireComponent;

class NavigationSidebar extends LivewireComponent
{
    /**
     * Log the current user out of the application.
     */
    public function logout(Logout $logout): void
    {
        $logout();

        $this->redirect('/', navigate: true);
    }

    public function render()
    {
        return view('livewire.layout.navigation-sidebar');
    }
}
