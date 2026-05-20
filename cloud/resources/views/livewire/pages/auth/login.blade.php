<?php

use App\Livewire\Forms\LoginForm;
use Illuminate\Support\Facades\Session;
use Livewire\Attributes\Layout;
use Livewire\Volt\Component;

new #[Layout('layouts.guest')] class extends Component
{
    public LoginForm $form;

    /**
     * Handle an incoming authentication request.
     */
    public function login(): void
    {
        $this->validate();

        $this->form->authenticate();

        Session::regenerate();

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
                Next-Gen Kitchen OS
            </div>
            <h2 class="text-4xl md:text-5xl font-extrabold text-white mb-6 leading-tight">
                Empower your <br> <span class="text-amber-400">Culinary Vision.</span>
            </h2>
            <p class="text-slate-300 text-lg leading-relaxed mb-8">
                Join thousands of restaurant owners who have streamlined their operations with EatsOnly.
            </p>
            <div class="flex items-center gap-4">
                <div class="flex -space-x-3">
                    <img src="https://ui-avatars.com/api/?name=J+D&background=6366f1&color=fff" class="w-10 h-10 rounded-full border-2 border-indigo-950">
                    <img src="https://ui-avatars.com/api/?name=S+K&background=ec4899&color=fff" class="w-10 h-10 rounded-full border-2 border-indigo-950">
                    <img src="https://ui-avatars.com/api/?name=M+A&background=10b981&color=fff" class="w-10 h-10 rounded-full border-2 border-indigo-950">
                </div>
                <span class="text-slate-400 text-sm font-medium">Trusted by 5,000+ chefs worldwide</span>
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
                <h1 class="text-3xl font-bold text-white mb-2">Welcome Back</h1>
                <p class="text-slate-400">Sign in to manage your restaurant.</p>
            </div>

            <!-- Session Status -->
            <x-auth-session-status class="mb-6" :status="session('status')" />

            <form wire:submit="login" class="space-y-6">
                <!-- Email or Mobile -->
                <div class="space-y-2">
                    <x-input-label for="email" :value="__('Email or Mobile')" class="text-slate-300 font-semibold ml-1" />
                    <x-text-input wire:model="form.email" id="email" class="block w-full bg-white/5 border-amber-500/30 text-white rounded-2xl px-5 py-4 focus:border-amber-500 focus:ring-amber-500/40" type="text" name="email" required autofocus autocomplete="username" placeholder="Email or mobile number" />
                    <x-input-error :messages="$errors->get('form.email')" class="mt-2" />
                </div>

                <!-- Password -->
                <div class="space-y-2">
                    <div class="flex items-center justify-between ml-1">
                        <x-input-label for="password" :value="__('Password')" class="text-slate-300 font-semibold" />
                        @if (Route::has('password.request'))
                            <a class="text-xs text-amber-400 hover:text-indigo-300 transition-colors" href="{{ route('password.request') }}" wire:navigate>
                                {{ __('Forgot password?') }}
                            </a>
                        @endif
                    </div>

                    <x-text-input wire:model="form.password" id="password" class="block w-full bg-white/5 border-amber-500/30 text-white rounded-2xl px-5 py-4 focus:border-amber-500 focus:ring-amber-500/40"
                                    type="password"
                                    name="password"
                                    required autocomplete="current-password" placeholder="••••••••" />

                    <x-input-error :messages="$errors->get('form.password')" class="mt-2" />
                </div>

                <!-- Remember Me -->
                <div class="flex items-center ml-1">
                    <label for="remember" class="inline-flex items-center cursor-pointer">
                        <input wire:model="form.remember" id="remember" type="checkbox" class="rounded bg-white/5 border-amber-500/30 text-amber-600 shadow-sm focus:ring-amber-500 focus:ring-offset-0" name="remember">
                        <span class="ms-2 text-sm text-slate-400 select-none">{{ __('Keep me signed in') }}</span>
                    </label>
                </div>

                <button type="submit" class="w-full py-5 bg-amber-600 text-white rounded-2xl font-bold text-lg hover:bg-amber-500 transition-all shadow-xl shadow-amber-600/30 transform hover:-translate-y-1">
                    {{ __('Sign In') }}
                </button>

                @if (Route::has('register'))
                    <div class="text-center mt-8">
                        <p class="text-sm text-slate-400">
                            New to EatsOnly? 
                            <a href="{{ route('register') }}" class="text-amber-400 font-bold hover:text-indigo-300 transition-colors" wire:navigate>Create Account</a>
                        </p>
                    </div>
                @endif
            </form>
        </div>
    </div>
</div>
