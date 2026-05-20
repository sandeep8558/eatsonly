<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" class="scroll-smooth">

<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ $title ?? 'EatsOnly - Ultimate Restaurant Management Software' }}</title>
    <meta name="description"
        content="{{ $description ?? 'Streamline your restaurant operations with EatsOnly. The all-in-one POS, inventory, and staff management system designed for modern culinary businesses.' }}">
    <meta name="keywords"
        content="{{ $keywords ?? 'restaurant management software, POS system, kitchen display system, restaurant inventory management, SaaS for restaurants' }}">

    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website">
    <meta property="og:url" content="{{ url()->current() }}">
    <meta property="og:title" content="{{ $title ?? 'EatsOnly - Ultimate Restaurant Management Software' }}">
    <meta property="og:description"
        content="{{ $description ?? 'Streamline your restaurant operations with EatsOnly. The all-in-one POS, inventory, and staff management system.' }}">
    <meta property="og:image" content="{{ asset('images/hero.png') }}">

    <!-- Twitter -->
    <meta property="twitter:card" content="summary_large_image">
    <meta property="twitter:url" content="{{ url()->current() }}">
    <meta property="twitter:title" content="{{ $title ?? 'EatsOnly - Ultimate Restaurant Management Software' }}">
    <meta property="twitter:description"
        content="{{ $description ?? 'Streamline your restaurant operations with EatsOnly. The all-in-one POS, inventory, and staff management system.' }}">
    <meta property="twitter:image" content="{{ asset('images/hero.png') }}">

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

        .glass {
            background: rgba(255, 255, 255, 0.03);
            backdrop-filter: blur(12px);
            border: 1px solid rgba(255, 255, 255, 0.05);
        }

        .gradient-text {
            background: linear-gradient(135deg, #fff 0%, #94a3b8 100%);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
        }
    </style>
</head>

<body class="antialiased bg-[#000000] text-slate-200 overflow-x-hidden">
    <!-- Background Decoration -->
    <div class="fixed inset-0 pointer-events-none overflow-hidden">
        <div class="absolute -top-[10%] -left-[10%] w-[40%] h-[40%] bg-amber-500/10 blur-[120px] rounded-full"></div>
        <div class="absolute top-[20%] -right-[10%] w-[30%] h-[30%] bg-amber-600/10 blur-[120px] rounded-full"></div>
    </div>

    <div class="min-h-screen flex flex-col bg-[#000000] text-slate-200" x-data="{ mobileMenuOpen: false }">
        <!-- Navigation -->
        <nav class="sticky top-0 z-50 border-b border-amber-500/20 bg-[#000000]/80 backdrop-blur-md">
            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div class="flex justify-between h-20 items-center">
                    <a href="{{ url('/') }}" class="flex items-center gap-2 group">
                        <img src="{{ asset('logo.png') }}"
                            class="w-10 h-10 object-contain group-hover:scale-105 transition-transform"
                            alt="EatsOnly Logo">
                        <span class="text-xl font-bold tracking-tight text-white">Eats<span
                                class="text-amber-400">Only</span></span>
                    </a>

                    <div class="hidden md:flex items-center gap-8 text-sm font-medium text-slate-400">
                        <a href="{{ route('features') }}"
                            class="{{ request()->routeIs('features') ? 'text-white' : 'hover:text-white' }} transition-colors">Features</a>
                        <a href="{{ route('pricing') }}"
                            class="{{ request()->routeIs('pricing') ? 'text-white' : 'hover:text-white' }} transition-colors">Pricing</a>
                        <a href="{{ route('download') }}"
                            class="{{ request()->routeIs('download') ? 'text-white' : 'hover:text-white' }} transition-colors">Download</a>
                        <a href="{{ route('contact') }}"
                            class="{{ request()->routeIs('contact') ? 'text-white' : 'hover:text-white' }} transition-colors">Contact</a>
                    </div>

                    <div class="flex items-center gap-4">
                        <div class="hidden md:flex items-center gap-4">
                            @if (Route::has('login'))
                                @auth
                                    <a href="{{ url('/dashboard') }}"
                                        class="text-sm font-semibold text-white bg-amber-600 px-6 py-2.5 rounded-full hover:bg-amber-500 transition-all">Dashboard</a>
                                @else
                                    <a href="{{ route('login') }}"
                                        class="text-sm font-semibold text-slate-300 hover:text-white transition-colors">Log
                                        in</a>
                                    <a href="{{ route('register') }}"
                                        class="text-sm font-semibold text-white bg-white/10 px-6 py-2.5 rounded-full hover:bg-white/20 transition-all border border-amber-500/30">Start
                                        Free Trial</a>
                                @endauth
                            @endif
                        </div>

                        <!-- Mobile Menu Button -->
                        <button @click="mobileMenuOpen = !mobileMenuOpen"
                            class="md:hidden p-2 text-slate-400 hover:text-white transition-colors">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"
                                x-show="!mobileMenuOpen">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M4 6h16M4 12h16M4 18h16"></path>
                            </svg>
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"
                                x-show="mobileMenuOpen" style="display: none;">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                    d="M6 18L18 6M6 6l12 12"></path>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>

            <!-- Mobile Menu Overlay -->
            <div x-show="mobileMenuOpen" x-transition:enter="transition ease-out duration-200"
                x-transition:enter-start="opacity-0 -translate-y-4" x-transition:enter-end="opacity-100 translate-y-0"
                x-transition:leave="transition ease-in duration-150"
                x-transition:leave-start="opacity-100 translate-y-0" x-transition:leave-end="opacity-0 -translate-y-4"
                class="md:hidden border-b border-amber-500/20 bg-[#000000] px-4 py-6 space-y-4" style="display: none;">
                <a href="{{ route('features') }}"
                    class="block text-lg font-medium text-slate-300 hover:text-white">Features</a>
                <a href="{{ route('pricing') }}"
                    class="block text-lg font-medium text-slate-300 hover:text-white">Pricing</a>
                <a href="{{ route('download') }}"
                    class="block text-lg font-medium text-slate-300 hover:text-white">Download</a>
                <a href="{{ route('contact') }}"
                    class="block text-lg font-medium text-slate-300 hover:text-white">Contact</a>
                <hr class="border-amber-500/20">
                <div class="flex flex-col gap-4">
                    @auth
                        <a href="{{ url('/dashboard') }}"
                            class="w-full text-center py-4 bg-amber-600 text-white rounded-2xl font-bold">Dashboard</a>
                    @else
                        <a href="{{ route('login') }}"
                            class="w-full text-center py-4 bg-white/5 text-white rounded-2xl font-bold border border-amber-500/30">Log
                            in</a>
                        <a href="{{ route('register') }}"
                            class="w-full text-center py-4 bg-amber-600 text-white rounded-2xl font-bold shadow-lg shadow-amber-600/40">Start
                            Free Trial</a>
                    @endauth
                </div>
            </div>
        </nav>

        <!-- Page Content -->
        <main class="flex-grow">
            {{ $slot }}
        </main>

        <!-- Footer -->
        <footer class="bg-[#000000] border-t border-amber-500/20 pt-20 pb-10 relative overflow-hidden">
            <!-- Background Glow -->
            <div
                class="absolute bottom-0 left-1/2 -translate-x-1/2 w-[60%] h-[30%] bg-amber-600/5 blur-[120px] rounded-full pointer-events-none">
            </div>

            <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
                <div class="grid grid-cols-2 md:grid-cols-4 gap-12 mb-20">
                    <!-- Brand Section -->
                    <div class="col-span-2">
                        <a href="{{ url('/') }}" class="flex items-center gap-2 mb-6 group">
                            <img src="{{ asset('logo.png') }}"
                                class="w-10 h-10 object-contain group-hover:scale-105 transition-transform"
                                alt="EatsOnly Logo">
                            <span class="text-2xl font-bold tracking-tight text-white">Eats<span
                                    class="text-amber-400">Only</span></span>
                        </a>
                        <p class="text-slate-400 text-lg leading-relaxed mb-8 max-w-sm">
                            The all-in-one restaurant management platform designed to scale your culinary business with
                            AI-driven insights.
                        </p>
                        <div class="text-xs font-bold text-slate-500 uppercase tracking-widest mb-4">
                            Developed & Maintained By
                            <a href="https://leenaitsolutions.in" target="_blank"
                                class="block text-amber-500 hover:text-white transition-colors mt-1 text-sm">Leena IT
                                Solutions</a>
                        </div>
                        <div class="flex gap-4">
                            <a href="#"
                                class="w-10 h-10 rounded-full bg-white/5 border border-amber-500/30 flex items-center justify-center text-slate-400 hover:bg-amber-600 hover:text-white hover:border-amber-600 transition-all">
                                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                                    <path
                                        d="M24 4.557c-.883.392-1.832.656-2.828.775 1.017-.609 1.798-1.574 2.165-2.724-.951.564-2.005.974-3.127 1.195-.897-.957-2.178-1.555-3.594-1.555-3.179 0-5.515 2.966-4.797 6.045-4.091-.205-7.719-2.165-10.148-5.144-1.29 2.213-.669 5.108 1.523 6.574-.806-.026-1.566-.247-2.229-.616-.054 2.281 1.581 4.415 3.949 4.89-.693.188-1.452.232-2.224.084.626 1.956 2.444 3.379 4.6 3.419-2.07 1.623-4.678 2.348-7.29 2.04 2.179 1.397 4.768 2.212 7.548 2.212 9.142 0 14.307-7.721 13.995-14.646.962-.695 1.797-1.562 2.457-2.549z" />
                                </svg>
                            </a>
                            <a href="#"
                                class="w-10 h-10 rounded-full bg-white/5 border border-amber-500/30 flex items-center justify-center text-slate-400 hover:bg-amber-600 hover:text-white hover:border-amber-600 transition-all">
                                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                                    <path
                                        d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zm0-2.163c-3.259 0-3.667.014-4.947.072-4.358.2-6.78 2.618-6.98 6.98-.059 1.281-.073 1.689-.073 4.948 0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98 1.281.058 1.689.072 4.948.072 3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98-1.281-.059-1.69-.073-4.949-.073zm0 5.838c-3.403 0-6.162 2.759-6.162 6.162s2.759 6.163 6.162 6.163 6.162-2.759 6.162-6.163c0-3.403-2.759-6.162-6.162-6.162zm0 10.162c-2.209 0-4-1.79-4-4 0-2.209 1.791-4 4-4s4 1.791 4 4c0 2.21-1.791 4-4 4zm6.406-11.845c-.796 0-1.441.645-1.441 1.44s.645 1.44 1.441 1.44c.795 0 1.439-.645 1.439-1.44s-.644-1.44-1.439-1.44z" />
                                </svg>
                            </a>
                            <a href="#"
                                class="w-10 h-10 rounded-full bg-white/5 border border-amber-500/30 flex items-center justify-center text-slate-400 hover:bg-amber-600 hover:text-white hover:border-amber-600 transition-all">
                                <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                                    <path
                                        d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.761 0 5-2.239 5-5v-14c0-2.761-2.239-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.113-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z" />
                                </svg>
                            </a>
                        </div>
                    </div>

                    <!-- Product Links -->
                    <div>
                        <h4
                            class="text-amber-500 font-black text-xs uppercase tracking-[0.2em] mb-8 flex items-center gap-3">
                            Product
                            <span class="h-px w-8 bg-amber-500/20"></span>
                        </h4>
                        <ul class="space-y-4 text-sm font-medium">
                            <li><a href="{{ route('features') }}"
                                    class="text-slate-400 hover:text-amber-400 transition-colors">Features</a></li>
                            <li><a href="{{ route('pricing') }}"
                                    class="text-slate-400 hover:text-amber-400 transition-colors">Pricing</a></li>
                            <li><a href="{{ route('download') }}"
                                    class="text-slate-400 hover:text-amber-400 transition-colors">Download App</a></li>
                            <li><a href="#" class="text-slate-400 hover:text-amber-400 transition-colors">Live Demo</a>
                            </li>
                            <li><a href="#"
                                    class="text-slate-400 hover:text-amber-400 transition-colors">Integrations</a></li>
                        </ul>
                    </div>

                    <!-- Company Links -->
                    <div>
                        <h4
                            class="text-amber-500 font-black text-xs uppercase tracking-[0.2em] mb-8 flex items-center gap-3">
                            Company
                            <span class="h-px w-8 bg-amber-500/20"></span>
                        </h4>
                        <ul class="space-y-4 text-sm font-medium">
                            <li><a href="{{ route('about') }}"
                                    class="text-slate-400 hover:text-amber-400 transition-colors">About Us</a></li>
                            <li><a href="{{ route('contact') }}"
                                    class="text-slate-400 hover:text-amber-400 transition-colors">Contact</a></li>
                            <li><a href="{{ route('careers') }}"
                                    class="text-slate-400 hover:text-amber-400 transition-colors">Careers</a></li>
                            <li><a href="#" class="text-slate-400 hover:text-amber-400 transition-colors">Blog</a></li>
                        </ul>
                    </div>
                </div>

                <!-- Bottom Bar -->
                <div
                    class="pt-12 border-t border-amber-500/20 flex flex-col md:flex-row justify-between items-center gap-6">
                    <p class="text-slate-500 text-sm">© 2026 EatsOnly. All rights reserved.</p>
                    <div class="flex gap-8 text-sm font-medium">
                        <a href="{{ route('privacy') }}"
                            class="text-slate-500 hover:text-white transition-colors">Privacy Policy</a>
                        <a href="{{ route('terms') }}" class="text-slate-500 hover:text-white transition-colors">Terms
                            of Service</a>
                        <a href="{{ route('cookies') }}"
                            class="text-slate-500 hover:text-white transition-colors">Cookie Policy</a>
                    </div>
                </div>
            </div>
        </footer>

        <!-- Floating Action Buttons -->
        <div class="fixed bottom-8 right-8 z-[60] flex flex-col gap-4">
            <!-- Call Button -->
            <a href="tel:+919096189183"
                class="w-14 h-14 bg-amber-600 text-white rounded-full flex items-center justify-center shadow-2xl shadow-amber-600/40 hover:scale-110 transition-all group relative">
                <span
                    class="absolute right-full mr-4 px-3 py-1 bg-[#000000]/80 backdrop-blur-md border border-amber-500/30 rounded-lg text-xs font-bold whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity">Call
                    Sales</span>
                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z">
                    </path>
                </svg>
            </a>
            <!-- WhatsApp Button -->
            <a href="https://wa.me/919096189183" target="_blank"
                class="w-14 h-14 bg-emerald-500 text-white rounded-full flex items-center justify-center shadow-2xl shadow-emerald-500/40 hover:scale-110 transition-all group relative">
                <span
                    class="absolute right-full mr-4 px-3 py-1 bg-[#000000]/80 backdrop-blur-md border border-amber-500/30 rounded-lg text-xs font-bold whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity">Chat
                    on WhatsApp</span>
                <svg class="w-7 h-7" fill="currentColor" viewBox="0 0 24 24">
                    <path
                        d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z" />
                </svg>
            </a>
        </div>
    </div>
    @livewireScripts

    @stack('scripts')
</body>

</html>