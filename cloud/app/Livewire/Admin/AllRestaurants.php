<?php

namespace App\Livewire\Admin;

use App\Models\Restaurant;
use Livewire\Component;

class AllRestaurants extends Component
{
    public $perPage = 10;
    public $search = '';
    public $filter = 'all'; // all, active, expired

    protected $queryString = [
        'search' => ['except' => ''],
        'filter' => ['except' => 'all'],
    ];

    public function loadMore()
    {
        $this->perPage += 10;
    }

    public function updatingSearch()
    {
        $this->resetPage();
    }

    public function updatingFilter()
    {
        $this->resetPage();
    }

    public function resetPage()
    {
        $this->perPage = 10;
    }

    public function render()
    {
        $query = Restaurant::query()
            ->with(['user.activeSubscription.plan'])
            ->latest();

        if ($this->search) {
            $query->where(function($q) {
                $q->where('name', 'like', '%' . $this->search . '%')
                  ->orWhere('address', 'like', '%' . $this->search . '%')
                  ->orWhereHas('user', function($qu) {
                      $qu->where('name', 'like', '%' . $this->search . '%')
                        ->orWhere('email', 'like', '%' . $this->search . '%');
                  });
            });
        }

        if ($this->filter === 'active') {
            $query->whereHas('user.activeSubscription', function($q) {
                $q->where('ends_at', '>', now());
            });
        } elseif ($this->filter === 'expired') {
            $query->whereDoesntHave('user.activeSubscription', function($q) {
                $q->where('ends_at', '>', now());
            });
        }

        $restaurants = $query->take($this->perPage)->get();
        $totalCount = $query->count();

        return view('livewire.admin.all-restaurants', [
            'restaurants' => $restaurants,
            'hasMore' => $totalCount > $this->perPage
        ])->layout('layouts.app');
    }
}
