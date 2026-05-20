<?php

namespace App\Livewire\Admin;

use App\Models\Payment;
use Livewire\Component;
use Livewire\WithPagination;

class PaymentManager extends Component
{
    use WithPagination;

    public $search = '';
    public $status = 'all'; // all, success, failed
    public $dateFilter = ''; // YYYY-MM-DD
    public $perPage = 10;

    protected $queryString = [
        'search' => ['except' => ''],
        'status' => ['except' => 'all'],
        'dateFilter' => ['except' => ''],
    ];

    public function updatingSearch()
    {
        $this->resetPage();
    }

    public function updatingStatus()
    {
        $this->resetPage();
    }

    public function updatingDateFilter()
    {
        $this->resetPage();
    }

    public function render()
    {
        $query = Payment::query()
            ->with(['user', 'subscription.plan'])
            ->latest();

        if ($this->search) {
            $query->where(function($q) {
                $q->where('razorpay_payment_id', 'like', '%' . $this->search . '%')
                  ->orWhere('razorpay_order_id', 'like', '%' . $this->search . '%')
                  ->orWhereHas('user', function($qu) {
                      $qu->where('name', 'like', '%' . $this->search . '%')
                        ->orWhere('email', 'like', '%' . $this->search . '%');
                  });
            });
        }

        if ($this->status !== 'all') {
            $query->where('status', $this->status);
        }

        if ($this->dateFilter) {
            $query->whereDate('created_at', $this->dateFilter);
        }

        return view('livewire.admin.payment-manager', [
            'payments' => $query->paginate($this->perPage)
        ])->layout('layouts.app');
    }
}
