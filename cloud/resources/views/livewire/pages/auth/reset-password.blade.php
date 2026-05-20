<?php

use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Facades\Session;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules;
use Livewire\Attributes\Layout;
use Livewire\Attributes\Locked;
use Livewire\Volt\Component;

new #[Layout('layouts.guest')] class extends Component
{
    #[Locked]
    public string $token = '';
    public string $email = '';
    public string $password = '';
    public string $password_confirmation = '';

    /**
     * Mount the component.
     */
    public function mount(string $token): void
    {
        $this->token = $token;

        $this->email = request()->string('email');
    }

    /**
     * Reset the password for the given user.
     */
    public function resetPassword(): void
    {
        $this->validate([
            'token' => ['required'],
            'email' => ['required', 'string', 'email'],
            'password' => ['required', 'string', 'confirmed', Rules\Password::defaults()],
        ]);

        // Here we will attempt to reset the user's password. If it is successful we
        // will update the password on an actual user model and persist it to the
        // database. Otherwise we will parse the error and return the response.
        $status = Password::reset(
            $this->only('email', 'password', 'password_confirmation', 'token'),
            function ($user) {
                $user->forceFill([
                    'password' => Hash::make($this->password),
                    'remember_token' => Str::random(60),
                ])->save();

                event(new PasswordReset($user));
            }
        );

        // If the password was successfully reset, we will redirect the user back to
        // the application's home authenticated view. If there is an error we can
        // redirect them back to where they came from with their error message.
        if ($status != Password::PASSWORD_RESET) {
            $this->addError('email', __($status));

            return;
        }

        Session::flash('status', __($status));

        $this->redirectRoute('login', navigate: true);
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
                Reset Success
            </div>
            <h2 class="text-4xl md:text-5xl font-extrabold text-white mb-6 leading-tight">
                Secure your <br> <span class="text-amber-400">Future.</span>
            </h2>
            <p class="text-slate-300 text-lg leading-relaxed mb-8">
                Your security is our priority. Choose a strong password and get back to managing your restaurant with peace of mind.
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
                <h1 class="text-3xl font-bold text-white mb-2">New Password</h1>
                <p class="text-slate-400">Secure your account with a new password.</p>
            </div>

            <form wire:submit="resetPassword" class="space-y-6">
                <!-- Email Address -->
                <div class="space-y-2">
                    <x-input-label for="email" :value="__('Email Address')" class="text-slate-300 font-semibold ml-1" />
                    <x-text-input wire:model="email" id="email" class="block w-full bg-white/5 border-amber-500/30 text-white rounded-2xl px-5 py-4 focus:border-amber-500 focus:ring-amber-500/40" type="email" name="email" required autofocus autocomplete="username" placeholder="name@restaurant.com" />
                    <x-input-error :messages="$errors->get('email')" class="mt-2" />
                </div>

                <!-- Password -->
                <div class="space-y-2">
                    <x-input-label for="password" :value="__('New Password')" class="text-slate-300 font-semibold ml-1" />
                    <x-text-input wire:model="password" id="password" class="block w-full bg-white/5 border-amber-500/30 text-white rounded-2xl px-5 py-4 focus:border-amber-500 focus:ring-amber-500/40" type="password" name="password" required autocomplete="new-password" placeholder="••••••••" />
                    <x-input-error :messages="$errors->get('password')" class="mt-2" />
                </div>

                <!-- Confirm Password -->
                <div class="space-y-2">
                    <x-input-label for="password_confirmation" :value="__('Confirm New Password')" class="text-slate-300 font-semibold ml-1" />
                    <x-text-input wire:model="password_confirmation" id="password_confirmation" class="block w-full bg-white/5 border-amber-500/30 text-white rounded-2xl px-5 py-4 focus:border-amber-500 focus:ring-amber-500/40"
                                    type="password"
                                    name="password_confirmation" required autocomplete="new-password" placeholder="••••••••" />
                    <x-input-error :messages="$errors->get('password_confirmation')" class="mt-2" />
                </div>

                <div class="pt-4">
                    <button type="submit" class="w-full py-5 bg-amber-600 text-white rounded-2xl font-bold text-lg hover:bg-amber-500 transition-all shadow-xl shadow-amber-600/30 transform hover:-translate-y-1">
                        {{ __('Update Password') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
