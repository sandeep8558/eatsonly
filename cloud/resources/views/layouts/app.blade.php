<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" class="dark">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ config('app.name', 'EatsOnly') }}</title>

    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700;800&display=swap"
        rel="stylesheet">

    <!-- Scripts -->
    <!-- Google tag (gtag.js) -->
    <script async src="https://www.googletagmanager.com/gtag/js?id=G-5BTRJRJDGE"></script>
    <script>
        window.dataLayer = window.dataLayer || [];
        function gtag() { dataLayer.push(arguments); }
        gtag('js', new Date());

        gtag('config', 'G-5BTRJRJDGE');
    </script>

    @vite(['resources/css/app.css', 'resources/js/app.js'])
    @livewireStyles

    <link rel="icon" type="image/png" sizes="32x32" href="{{ asset('favicon-32x32.png') }}">
    <link rel="icon" type="image/png" sizes="16x16" href="{{ asset('favicon-16x16.png') }}">
    <link rel="apple-touch-icon" sizes="180x180" href="{{ asset('apple-touch-icon.png') }}">
    <link rel="icon" type="image/png" href="{{ asset('favicon.png') }}">

    <style>
        body {
            font-family: 'Plus Jakarta Sans', sans-serif;
        }

        .glass-sidebar {
            background: rgba(0, 0, 0, 0.9);
            backdrop-filter: blur(16px);
            border-right: 1px solid rgba(245, 158, 11, 0.3);
            box-shadow: 20px 0 50px -10px rgba(245, 158, 11, 0.15);
        }

        .custom-scrollbar::-webkit-scrollbar {
            width: 4px;
        }

        .custom-scrollbar::-webkit-scrollbar-track {
            background: transparent;
        }

        .custom-scrollbar::-webkit-scrollbar-thumb {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 10px;
        }

        .custom-scrollbar::-webkit-scrollbar-thumb:hover {
            background: rgba(255, 255, 255, 0.2);
        }
    </style>

</head>

<body class="antialiased bg-black text-slate-200" x-data="{ sidebarOpen: window.innerWidth >= 1024 }"
    @resize.window="sidebarOpen = window.innerWidth >= 1024">
    <div class="flex min-h-screen overflow-hidden">

        <!-- Mobile Backdrop -->
        <div x-show="sidebarOpen" @click="sidebarOpen = false"
            class="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm lg:hidden"
            x-transition:enter="transition opacity ease-out duration-300" x-transition:enter-start="opacity-0"
            x-transition:enter-end="opacity-100" x-transition:leave="transition opacity ease-in duration-300"
            x-transition:leave-start="opacity-100" x-transition:leave-end="opacity-0"></div>

        <!-- Sidebar Navigation -->
        <aside
            class="fixed inset-y-0 left-0 z-50 w-72 glass-sidebar transform transition-transform duration-300 lg:translate-x-0"
            :class="sidebarOpen ? 'translate-x-0' : '-translate-x-full'">
            <div class="flex flex-col h-full">
                <!-- Sidebar Header -->
                <div class="h-20 flex items-center justify-between px-8 border-b border-amber-500/20">
                    <a href="{{ url('/') }}" class="flex items-center gap-2 group">
                        <img src="{{ asset('logo.png') }}"
                            class="w-8 h-8 object-contain group-hover:scale-105 transition-transform"
                            alt="EatsOnly Logo">
                        <span class="text-lg font-bold tracking-tight text-white">EatsOnly</span>
                    </a>
                    <button @click="sidebarOpen = false" class="lg:hidden p-2 text-slate-400 hover:text-white">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M6 18L18 6M6 6l12 12"></path>
                        </svg>
                    </button>
                </div>

                <!-- Navigation Links -->
                <nav class="flex-grow p-6 space-y-2 overflow-y-auto custom-scrollbar">
                    @if(auth()->user()->isSuperAdmin())
                        <x-nav-link-sidebar :href="route('admin.dashboard')" :active="request()->routeIs('admin.dashboard')"
                            icon="dashboard">
                            Platform Overview
                        </x-nav-link-sidebar>
                    @endif

                    @if(auth()->user()->isRestaurant())
                        <x-nav-link-sidebar :href="route('restaurant.dashboard')"
                            :active="request()->routeIs('restaurant.dashboard')" icon="reports">
                            Restaurant Dashboard
                        </x-nav-link-sidebar>
                    @endif

                    @if(auth()->user()->isCustomer())
                        <x-nav-link-sidebar :href="route('customer.dashboard')"
                            :active="request()->routeIs('customer.dashboard')" icon="dashboard">
                            Customer Dashboard
                        </x-nav-link-sidebar>
                    @endif

                    @if(auth()->user()->isSuperAdmin())
                        <div class="pt-4 pb-2">
                            <p class="text-[10px] font-black uppercase tracking-widest text-amber-500/60 px-4">
                                Administration</p>
                        </div>
                        <x-nav-link-sidebar :href="route('admin.restaurants')"
                            :active="request()->routeIs('admin.restaurants')" icon="restaurants">
                            Restaurants
                        </x-nav-link-sidebar>
                        <x-nav-link-sidebar :href="route('admin.users')" :active="request()->routeIs('admin.users')"
                            icon="users">
                            Users
                        </x-nav-link-sidebar>
                        <x-nav-link-sidebar :href="route('admin.payments')" :active="request()->routeIs('admin.payments')"
                            icon="payments">
                            Payments
                        </x-nav-link-sidebar>
                        <x-nav-link-sidebar :href="route('admin.pricing-plans')"
                            :active="request()->routeIs('admin.pricing-plans')" icon="settings">
                            Pricing Plans
                        </x-nav-link-sidebar>
                        <x-nav-link-sidebar :href="route('admin.settings')" :active="request()->routeIs('admin.settings')"
                            icon="settings">
                            SaaS Settings
                        </x-nav-link-sidebar>

                        <div class="pt-4 pb-2">
                            <p class="text-[10px] font-black uppercase tracking-widest text-amber-500/60 px-4">Bootstrap</p>
                        </div>
                        <x-nav-link-sidebar :href="route('admin.categories')"
                            :active="request()->routeIs('admin.categories')" icon="menu">
                            Categories
                        </x-nav-link-sidebar>
                        <x-nav-link-sidebar :href="route('admin.menus')" :active="request()->routeIs('admin.menus')"
                            icon="orders">
                            Menus
                        </x-nav-link-sidebar>
                    @endif


                    <div class="pt-4 pb-2">
                        <p class="text-[10px] font-black uppercase tracking-widest text-amber-500/60 px-4">Account</p>
                    </div>
                    <x-nav-link-sidebar :href="route('profile')" :active="request()->routeIs('profile')" icon="users">
                        My Profile
                    </x-nav-link-sidebar>
                </nav>

                <!-- Sidebar Footer -->
                <div class="p-6 border-t border-amber-500/20">
                    <livewire:layout.navigation-sidebar />
                </div>
            </div>
        </aside>

        <!-- Main Content Area -->
        <div class="flex-grow flex flex-col min-w-0 lg:pl-72">
            <!-- Top Header -->
            <header
                class="h-20 flex items-center justify-between px-8 border-b border-amber-500/20 bg-black/50 backdrop-blur-md sticky top-0 z-40">
                <div class="flex items-center gap-4 min-w-0">
                    <button @click="sidebarOpen = !sidebarOpen"
                        class="p-2 -ml-2 text-slate-400 hover:text-white transition-colors flex-shrink-0">
                        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M4 6h16M4 12h16M4 18h16"></path>
                        </svg>
                    </button>

                    @if (isset($header))
                        <div class="min-w-0">
                            {{ $header }}
                        </div>
                    @endif
                </div>

                <div class="flex items-center gap-4 flex-shrink-0">
                    <livewire:layout.navigation-top />
                </div>
            </header>

            <!-- Page Content -->
            <main class="flex-grow p-8 overflow-y-auto">
                {{ $slot }}
            </main>
        </div>
    </div>

    @livewireScripts

    @stack('scripts')
</body>

</html>