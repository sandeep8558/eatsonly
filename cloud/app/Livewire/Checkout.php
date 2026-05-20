<?php

namespace App\Livewire;

use App\Models\PricingPlan;
use App\Models\Subscription;
use App\Models\Setting;
use App\Models\Payment;
use Livewire\Component;
use Razorpay\Api\Api;
use Illuminate\Support\Facades\Auth;

class Checkout extends Component
{
    public $plan;
    public $period;
    public $amount;
    public $outlets;
    public $orderId;
    public $razorpayKey;

    public function mount($plan, $period)
    {
        if (!Auth::check()) {
            return redirect()->route('login', ['redirect' => url()->current()]);
        }

        $this->plan = PricingPlan::findOrFail($plan);
        $this->period = $period; // monthly or yearly
        
        $requestedOutlets = request()->query('outlets', $this->plan->outlets);
        $this->outlets = max((int) $requestedOutlets, $this->plan->outlets);
        
        $basePrice = $this->period === 'monthly' ? $this->plan->monthly_price : $this->plan->yearly_price;
        if ($this->plan->is_outlets_fixed) {
            $this->amount = $basePrice;
        } else {
            $this->amount = $basePrice * $this->outlets;
        }
        
        $this->razorpayKey = Setting::get('razorpay_key');
        $razorpaySecret = Setting::get('razorpay_secret');

        if (!$this->razorpayKey || !$razorpaySecret) {
            session()->flash('error', 'Payment gateway is not configured. Please contact support.');
            return;
        }

        // Create Razorpay Order
        try {
            $api = new Api($this->razorpayKey, $razorpaySecret);
            $orderData = [
                'receipt'         => 'rc_'.time(),
                'amount'          => $this->amount * 100, // in paise
                'currency'        => 'INR',
                'payment_capture' => 1 // auto capture
            ];
            
            $razorpayOrder = $api->order->create($orderData);
            $this->orderId = $razorpayOrder['id'];
        } catch (\Exception $e) {
            session()->flash('error', 'Unable to initiate payment: ' . $e->getMessage());
        }
    }

    public function handlePayment($paymentId, $signature)
    {
        $razorpaySecret = Setting::get('razorpay_secret');
        $api = new Api($this->razorpayKey, $razorpaySecret);

        // Verify signature
        try {
            $attributes = [
                'razorpay_order_id' => $this->orderId,
                'razorpay_payment_id' => $paymentId,
                'razorpay_signature' => $signature
            ];
            $api->utility->verifyPaymentSignature($attributes);
            
            // Get payment method details
            $razorpayPayment = $api->payment->fetch($paymentId);
            $method = $razorpayPayment->method;

            // Get current active subscription
            $currentSub = Auth::user()->activeSubscription;
            $startsAt = now();
            $endsAt = $this->period === 'monthly' ? now()->addMonth() : now()->addYear();

            if ($currentSub) {
                if ($currentSub->pricing_plan_id == $this->plan->id) {
                    // SAME PLAN: Extend validity
                    // If current plan is still valid, start new one from old expiry
                    if ($currentSub->ends_at->isFuture()) {
                        $startsAt = $currentSub->ends_at;
                        $endsAt = $this->period === 'monthly' ? $startsAt->copy()->addMonth() : $startsAt->copy()->addYear();
                    }
                    // We keep current sub as active, and this new one will also be active (but starts in future)
                    // Or we could just update the current sub's ends_at. 
                    // Let's update the CURRENT one if it's the same plan to keep it simple for the user.
                    $currentSub->update([
                        'ends_at' => $endsAt,
                        'razorpay_payment_id' => $paymentId, // update with latest payment
                        'razorpay_order_id' => $this->orderId,
                        'razorpay_signature' => $signature,
                        'outlets' => max($currentSub->outlets, $this->outlets), // Update outlets if upgraded
                    ]);
                    $subscription = $currentSub;
                } else {
                    // UPGRADE/CHANGE PLAN: Start fresh, cancel old
                    $currentSub->update(['status' => 'cancelled']);
                    
                    $subscription = Subscription::create([
                        'user_id' => Auth::id(),
                        'pricing_plan_id' => $this->plan->id,
                        'razorpay_order_id' => $this->orderId,
                        'razorpay_payment_id' => $paymentId,
                        'razorpay_signature' => $signature,
                        'payment_method' => $method,
                        'amount' => $this->amount,
                        'outlets' => $this->outlets,
                        'billing_period' => $this->period,
                        'status' => 'active',
                        'starts_at' => $startsAt,
                        'ends_at' => $endsAt,
                    ]);
                }
            } else {
                // FIRST TIME PURCHASE
                $subscription = Subscription::create([
                    'user_id' => Auth::id(),
                    'pricing_plan_id' => $this->plan->id,
                    'razorpay_order_id' => $this->orderId,
                    'razorpay_payment_id' => $paymentId,
                    'razorpay_signature' => $signature,
                    'payment_method' => $method,
                    'amount' => $this->amount,
                    'outlets' => $this->outlets,
                    'billing_period' => $this->period,
                    'status' => 'active',
                    'starts_at' => $startsAt,
                    'ends_at' => $endsAt,
                ]);
            }

            // 2. Create payment record (Always create a new transaction record)
            Payment::create([
                'user_id' => Auth::id(),
                'subscription_id' => $subscription->id,
                'razorpay_order_id' => $this->orderId,
                'razorpay_payment_id' => $paymentId,
                'amount' => $this->amount,
                'method' => $method,
                'status' => 'success',
                'raw_response' => json_encode($razorpayPayment->toArray()),
            ]);

            // 3. Ensure user has Restaurant Admin role
            $user = Auth::user();
            if (!$user->hasRole('admin')) {
                $adminRole = \App\Models\Role::where('name', 'admin')->first();
                if ($adminRole) {
                    $user->roles()->attach($adminRole->id);
                }
            }

            return redirect()->route('dashboard')->with('message', 'Subscription successful! Welcome to ' . $this->plan->name);

        } catch (\Exception $e) {
            session()->flash('error', 'Payment verification failed: ' . $e->getMessage());
        }
    }

    public function render()
    {
        return view('livewire.checkout')->layout('layouts.guest');
    }
}
