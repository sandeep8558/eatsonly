<?php

use Illuminate\Support\Facades\Password;
use Livewire\Attributes\Layout;
use Livewire\Volt\Component;

new #[Layout('layouts.guest')] class extends Component
{
    public string $email = '';

    /**
     * Send a password reset link to the provided email address.
     */
    public function sendPasswordResetLink(): void
    {
        $this->validate([
            'email' => ['required', 'string', 'email'],
        ]);

        // We will send the password reset link to this user. Once we have attempted
        // to send the link, we will examine the response then see the message we
        // need to show to the user. Finally, we'll send out a proper response.
        $status = Password::sendResetLink(
            $this->only('email')
        );

        if ($status != Password::RESET_LINK_SENT) {
            $this->addError('email', __($status));

            return;
        }

        $this->reset('email');

        session()->flash('status', __($status));
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
                Security First
            </div>
            <h2 class="text-4xl md:text-5xl font-extrabold text-white mb-6 leading-tight">
                Don't worry, <br> <span class="text-amber-400">We got you.</span>
            </h2>
            <p class="text-slate-300 text-lg leading-relaxed mb-8">
                Resetting your password is quick and secure. Follow the link in your email to get back to your kitchen dashboard.
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
                <h1 class="text-3xl font-bold text-white mb-2">Reset Password</h1>
                <p class="text-slate-400">Enter your email for a secure link.</p>
            </div>

            <!-- Session Status -->
            <x-auth-session-status class="mb-6" :status="session('status')" />

            <form wire:submit="sendPasswordResetLink" class="space-y-6">
                <!-- Email Address -->
                <div class="space-y-2">
                    <x-input-label for="email" :value="__('Email Address')" class="text-slate-300 font-semibold ml-1" />
                    <x-text-input wire:model="email" id="email" class="block w-full bg-white/5 border-amber-500/30 text-white rounded-2xl px-5 py-4 focus:border-amber-500 focus:ring-amber-500/40" type="email" name="email" required autofocus placeholder="name@restaurant.com" />
                    <x-input-error :messages="$errors->get('email')" class="mt-2" />
                </div>

                <button type="submit" class="w-full py-5 bg-amber-600 text-white rounded-2xl font-bold text-lg hover:bg-amber-500 transition-all shadow-xl shadow-amber-600/30 transform hover:-translate-y-1">
                    {{ __('Send Reset Link') }}
                </button>

                <div class="text-center mt-8">
                    <a href="{{ route('login') }}" class="text-sm text-amber-400 font-bold hover:text-indigo-300 transition-colors" wire:navigate>
                        Back to Login
                    </a>
                </div>
            </form>
        </div>
    </div>
</div>
