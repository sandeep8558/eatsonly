<x-app-layout>
    <x-slot name="header">
        <h2 class="font-semibold text-xl text-gray-800 dark:text-gray-200 leading-tight">
            {{ __('Dashboard') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <div class="bg-black border border-amber-500/40 overflow-hidden shadow-2xl sm:rounded-2xl">
                <div class="p-8 text-slate-200">
                    <h3 class="text-2xl font-bold mb-2">Welcome back!</h3>
                    <p class="text-slate-400">{{ __("You're logged in to your EatsOnly dashboard.") }}</p>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
