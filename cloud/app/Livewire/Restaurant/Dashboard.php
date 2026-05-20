<?php

namespace App\Livewire\Restaurant;

use App\Models\Restaurant;
use Livewire\Component;
use Livewire\WithFileUploads;
use Illuminate\Support\Str;
use Illuminate\Support\Facades\Auth;
use Livewire\Attributes\Layout;

class Dashboard extends Component
{
    use WithFileUploads;

    public $restaurants;
    public $restaurantId;
    public $name, $address, $logo, $slug;
    public $is_veg = true;
    public $is_nonveg = true;
    public $is_jain = false;
    public $isModalOpen = false;

    protected $rules = [
        'name' => 'required|min:3',
        'address' => 'required',
        'slug' => 'required|unique:restaurants,slug',
    ];

    public function mount()
    {
        $this->loadRestaurants();
    }

    public function loadRestaurants()
    {
        $this->restaurants = Restaurant::where('user_id', Auth::id())->latest()->get();
    }

    public function updatedName($value)
    {
        $this->slug = Str::slug($value);
    }

    public function create()
    {
        $this->resetFields();
        $this->openModal();
    }

    public function openModal()
    {
        $this->isModalOpen = true;
    }

    public function closeModal()
    {
        $this->isModalOpen = false;
        $this->resetFields();
    }

    public function resetFields()
    {
        $this->name = '';
        $this->address = '';
        $this->logo = '';
        $this->slug = '';
        $this->is_veg = true;
        $this->is_nonveg = true;
        $this->is_jain = false;
        $this->restaurantId = null;
    }

    public function store()
    {
        $validationRules = $this->rules;
        if ($this->restaurantId) {
            $validationRules['slug'] = 'required|unique:restaurants,slug,' . $this->restaurantId;
        }

        $this->validate($validationRules);

        $logoPath = $this->logo;
        
        if ($this->restaurantId) {
            $restaurant = Restaurant::findOrFail($this->restaurantId);
            
            if ($this->logo && !is_string($this->logo)) {
                if ($restaurant->logo) {
                    \Illuminate\Support\Facades\Storage::disk('public')->delete($restaurant->logo);
                }
                $logoPath = $this->logo->store('logos', 'public');
            }
        } else {
            if ($this->logo && !is_string($this->logo)) {
                $logoPath = $this->logo->store('logos', 'public');
            }
        }

        $data = [
            'user_id' => Auth::id(),
            'name' => $this->name,
            'address' => $this->address,
            'logo' => $logoPath,
            'slug' => $this->slug,
            'is_veg' => $this->is_veg,
            'is_nonveg' => $this->is_nonveg,
            'is_jain' => $this->is_jain,
        ];

        if ($this->restaurantId) {
            $restaurant->update($data);
        } else {
            $restaurant = Restaurant::create($data);
        }

        // SYNC TO TENANT DATABASE
        try {
            $tenantService = new \App\Services\TenantService();
            $tenantService->syncRestaurantToTenant(Auth::user(), $restaurant->toArray());
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error("Tenant Sync Failed: " . $e->getMessage());
            // We don't block the user if tenant sync fails, but we log it
        }

        session()->flash('message', $this->restaurantId ? 'Restaurant updated successfully.' : 'Restaurant created successfully.');

        $this->closeModal();
        $this->loadRestaurants();
    }

    public function edit($id)
    {
        $restaurant = Restaurant::findOrFail($id);
        $this->restaurantId = $id;
        $this->name = $restaurant->name;
        $this->address = $restaurant->address;
        $this->logo = $restaurant->logo;
        $this->slug = $restaurant->slug;
        $this->is_veg = $restaurant->is_veg;
        $this->is_nonveg = $restaurant->is_nonveg;
        $this->is_jain = $restaurant->is_jain;

        $this->openModal();
    }

    public function delete($id)
    {
        $restaurant = Restaurant::findOrFail($id);
        
        // SYNC DELETION TO TENANT
        try {
            $tenantService = new \App\Services\TenantService();
            $tenantService->switchToTenant('resto_' . str_replace('-', '_', Auth::id()));
            \Illuminate\Support\Facades\DB::connection('tenant')->table('restaurants')->where('id', $id)->delete();
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error("Tenant Delete Sync Failed: " . $e->getMessage());
        }

        $restaurant->delete();
        session()->flash('message', 'Restaurant deleted successfully.');
        $this->loadRestaurants();
    }

    #[Layout('layouts.app')]
    public function render()
    {
        return view('livewire.restaurant.dashboard', [
            'activeSubscription' => auth()->user()->activeSubscription
        ]);
    }
}
