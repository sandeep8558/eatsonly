<?php

use App\Models\User;
use Illuminate\Auth\Events\Registered;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules;
use Livewire\Attributes\Layout;
use Livewire\Volt\Component;

use App\Enums\UserRole;

new #[Layout('layouts.guest')] class extends Component
{
    public string $name = '';
    public string $email = '';
    public string $mobile = '';
    public string $password = '';
    public string $password_confirmation = '';

    /**
     * Handle an incoming registration request.
     */
    public function register(\App\Services\AuthService $authService): void
    {
        $validated = $this->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'string', 'lowercase', 'email', 'max:255', 'unique:'.User::class],
            'mobile' => ['required', 'string', 'max:15', 'unique:'.User::class],
            'password' => ['required', 'string', 'confirmed', Rules\Password::defaults()],
        ]);

        $user = $authService->register($validated);

        event(new Registered($user));

        Auth::login($user);

        $this->redirectIntended(default: route('dashboard', absolute: false), navigate: true);
    }
}; ?>

<div class="min-h-[calc(100vh-80px)] flex flex-col lg:flex-row overflow-hidden">
    <!-- Left Side: Illustration -->
    <div class="hidden lg:flex lg:w-1/2 relative bg-indigo-950/20 items-center justify-center p-12 overflow-hidden border-r border-amber-500/20">
        <div class="absolute inset-0 z-0">
            <img src="/images/auth.png" alt="EatsOnly OS" class="w-full h-full object-cover opacity-50">
            <div class="absolute inset-0 bg-gradient-to-r from-indigo-950/80 to-transparent"></div>
        </div>
        
        <div class="relative z-10 max-w-lg">
            <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/10 border border-amber-500/40 text-amber-400 text-xs font-bold uppercase tracking-widest mb-8">
                Enterprise Ready
            </div>
            <h2 class="text-4xl md:text-5xl font-extrabold text-white mb-6 leading-tight">
                Scale your <br> <span class="text-amber-400">Empire.</span>
            </h2>
            <p class="text-slate-300 text-lg leading-relaxed mb-8">
                From a single cafe to a global franchise, EatsOnly provides the tools you need to grow without limits.
            </p>
            <div class="grid grid-cols-2 gap-6">
                <div class="glass p-4 rounded-2xl border border-amber-500/20">
                    <div class="text-2xl font-bold text-white mb-1">99.9%</div>
                    <div class="text-slate-400 text-xs uppercase tracking-wider">Uptime</div>
                </div>
                <div class="glass p-4 rounded-2xl border border-amber-500/20">
                    <div class="text-2xl font-bold text-white mb-1">24/7</div>
                    <div class="text-slate-400 text-xs uppercase tracking-wider">Support</div>
                </div>
            </div>
        </div>
    </div>

    <!-- Right Side: Form -->
    <div class="flex-grow lg:w-1/2 flex items-center justify-center p-8 md:p-16">
        <div class="w-full max-w-md">
            <div class="mb-10 lg:hidden">
                <a href="{{ url('/') }}" class="flex items-center gap-2 group">
                    <div class="w-10 h-10 bg-amber-600 rounded-xl flex items-center justify-center shadow-lg">
                        <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"></path></svg>
                    </div>
                    <span class="text-xl font-bold tracking-tight text-white">EatsOnly</span>
                </a>
            </div>

            <div class="mb-10">
                <h1 class="text-3xl font-bold text-white mb-2">Create Account</h1>
                <p class="text-slate-400">Join the future of restaurant management.</p>
            </div>

            <form wire:submit="register" class="space-y-5">
                <!-- Name -->
                <div class="space-y-2">
                    <x-input-label for="name" :value="__('Full Name')" class="text-slate-300 font-semibold ml-1" />
                    <x-text-input wire:model="name" id="name" class="block w-full bg-white/5 border-amber-500/30 text-white rounded-2xl px-5 py-3.5 focus:border-amber-500 focus:ring-amber-500/40" type="text" name="name" required autofocus autocomplete="name" placeholder="John Doe" />
                    <x-input-error :messages="$errors->get('name')" class="mt-2" />
                </div>

                <div class="grid md:grid-cols-2 gap-5">
                    <!-- Email Address -->
                    <div class="space-y-2">
                        <x-input-label for="email" :value="__('Email Address')" class="text-slate-300 font-semibold ml-1" />
                        <x-text-input wire:model="email" id="email" class="block w-full bg-white/5 border-amber-500/30 text-white rounded-2xl px-5 py-3.5 focus:border-amber-500 focus:ring-amber-500/40" type="email" name="email" required autocomplete="username" placeholder="john@restaurant.com" />
                        <x-input-error :messages="$errors->get('email')" class="mt-2" />
                    </div>

                    <!-- Mobile Number -->
                    <div class="space-y-2">
                        <x-input-label for="mobile" :value="__('Mobile Number')" class="text-slate-300 font-semibold ml-1" />
                        <x-text-input wire:model="mobile" id="mobile" class="block w-full bg-white/5 border-amber-500/30 text-white rounded-2xl px-5 py-3.5 focus:border-amber-500 focus:ring-amber-500/40" type="text" name="mobile" required placeholder="+1 234 567 890" />
                        <x-input-error :messages="$errors->get('mobile')" class="mt-2" />
                    </div>
                </div>

                <div class="grid md:grid-cols-2 gap-6">
                    <!-- Password -->
                    <div class="space-y-2">
                        <x-input-label for="password" :value="__('Password')" class="text-slate-300 font-semibold ml-1" />
                        <x-text-input wire:model="password" id="password" class="block w-full bg-white/5 border-amber-500/30 text-white rounded-2xl px-5 py-4 focus:border-amber-500 focus:ring-amber-500/40"
                                        type="password"
                                        name="password"
                                        required autocomplete="new-password" placeholder="••••••••" />
                        <x-input-error :messages="$errors->get('password')" class="mt-2" />
                    </div>

                    <!-- Confirm Password -->
                    <div class="space-y-2">
                        <x-input-label for="password_confirmation" :value="__('Confirm Password')" class="text-slate-300 font-semibold ml-1" />
                        <x-text-input wire:model="password_confirmation" id="password_confirmation" class="block w-full bg-white/5 border-amber-500/30 text-white rounded-2xl px-5 py-4 focus:border-amber-500 focus:ring-amber-500/40"
                                        type="password"
                                        name="password_confirmation" required autocomplete="new-password" placeholder="••••••••" />
                        <x-input-error :messages="$errors->get('password_confirmation')" class="mt-2" />
                    </div>
                </div>

                <div class="pt-4">
                    <button type="submit" class="w-full py-5 bg-amber-600 text-white rounded-2xl font-bold text-lg hover:bg-amber-500 transition-all shadow-xl shadow-amber-600/30 transform hover:-translate-y-1">
                        {{ __('Create My Account') }}
                    </button>
                </div>

                <div class="text-center mt-8">
                    <p class="text-sm text-slate-400">
                        Already have an account? 
                        <a href="{{ route('login') }}" class="text-amber-400 font-bold hover:text-indigo-300 transition-colors" wire:navigate>Sign In</a>
                    </p>
                </div>
            </form>
        </div>
    </div>
</div>
