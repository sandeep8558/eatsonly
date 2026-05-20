<?php

namespace App\Livewire\Admin;

use App\Models\Setting;
use Livewire\Component;
use Livewire\Attributes\Layout;

#[Layout('layouts.app')]
class SaaSSettings extends Component
{
    // Razorpay
    public $razorpay_key;
    public $razorpay_secret;

    // Mailgun
    public $mailgun_domain;
    public $mailgun_secret;
    public $mailgun_from_address;
    public $mailgun_from_name;

    // Google Maps
    public $google_maps_api_key;
    public $delivery_radius_km;

    // Sales
    public $sales_enabled = true;

    public function mount()
    {
        $this->razorpay_key = Setting::get('razorpay_key');
        $this->razorpay_secret = Setting::get('razorpay_secret');

        $this->mailgun_domain = Setting::get('mailgun_domain');
        $this->mailgun_secret = Setting::get('mailgun_secret');
        $this->mailgun_from_address = Setting::get('mailgun_from_address');
        $this->mailgun_from_name = Setting::get('mailgun_from_name');

        $this->google_maps_api_key = Setting::get('google_maps_api_key');
        $this->delivery_radius_km = Setting::get('delivery_radius_km', 10);

        $this->sales_enabled = (bool) Setting::get('sales_enabled', true);
    }

    public function toggleSales()
    {
        $this->sales_enabled = !$this->sales_enabled;
        Setting::set('sales_enabled', $this->sales_enabled);
        session()->flash('message_sales', 'Sales status updated instantly.');
    }

    public function saveRazorpay()
    {
        $this->validate([
            'razorpay_key' => 'nullable|string',
            'razorpay_secret' => 'nullable|string',
        ]);

        Setting::set('razorpay_key', $this->razorpay_key);
        Setting::set('razorpay_secret', $this->razorpay_secret);
        
        session()->flash('message_razorpay', 'Razorpay settings updated successfully.');
    }

    public function saveGoogleMaps()
    {
        $this->validate([
            'google_maps_api_key' => 'nullable|string',
            'delivery_radius_km' => 'nullable|numeric|min:1|max:500',
        ]);

        Setting::set('google_maps_api_key', $this->google_maps_api_key);
        Setting::set('delivery_radius_km', $this->delivery_radius_km);

        session()->flash('message_google_maps', 'Google Maps settings updated successfully.');
    }

    public function saveMailgun()
    {
        $this->validate([
            'mailgun_domain' => 'nullable|string',
            'mailgun_secret' => 'nullable|string',
            'mailgun_from_address' => 'nullable|email',
            'mailgun_from_name' => 'nullable|string',
        ]);

        Setting::set('mailgun_domain', $this->mailgun_domain);
        Setting::set('mailgun_secret', $this->mailgun_secret);
        Setting::set('mailgun_from_address', $this->mailgun_from_address);
        Setting::set('mailgun_from_name', $this->mailgun_from_name);
        
        session()->flash('message_mailgun', 'Mailgun settings updated successfully.');
    }

    public function render()
    {
        return view('livewire.admin.saa-s-settings');
    }
}
