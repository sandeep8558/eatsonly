<?php

use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Livewire\Attributes\Layout;
use Livewire\Volt\Component;

new #[Layout('layouts.guest')] class extends Component
{
    public string $password = '';

    /**
     * Confirm the current user's password.
     */
    public function confirmPassword(): void
    {
        $this->validate([
            'password' => ['required', 'string'],
        ]);

        if (! Auth::guard('web')->validate([
            'email' => Auth::user()->email,
            'password' => $this->password,
        ])) {
            throw ValidationException::withMessages([
                'password' => __('auth.password'),
            ]);
        }

        session(['auth.password_confirmed_at' => time()]);

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
                Identity Verified
            </div>
            <h2 class="text-4xl md:text-5xl font-extrabold text-white mb-6 leading-tight">
                One last check <br> <span class="text-amber-400">For Safety.</span>
            </h2>
            <p class="text-slate-300 text-lg leading-relaxed mb-8">
                EatsOnly uses bank-grade security. Please confirm your password to access the restricted area of your dashboard.
            </p>
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
                <h1 class="text-3xl font-bold text-white mb-2">Security Check</h1>
                <p class="text-slate-400">Please confirm your password to continue.</p>
            </div>

            <form wire:submit="confirmPassword" class="space-y-6">
                <!-- Password -->
                <div class="space-y-2">
                    <x-input-label for="password" :value="__('Password')" class="text-slate-300 font-semibold ml-1" />
                    <x-text-input wire:model="password" id="password" class="block w-full bg-white/5 border-amber-500/30 text-white rounded-2xl px-5 py-4 focus:border-amber-500 focus:ring-amber-500/40"
                                    type="password"
                                    name="password"
                                    required autocomplete="current-password" placeholder="••••••••" />
                    <x-input-error :messages="$errors->get('password')" class="mt-2" />
                </div>

                <div class="pt-4">
                    <button type="submit" class="w-full py-5 bg-amber-600 text-white rounded-2xl font-bold text-lg hover:bg-amber-500 transition-all shadow-xl shadow-amber-600/30 transform hover:-translate-y-1">
                        {{ __('Confirm Identity') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
