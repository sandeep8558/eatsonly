<x-guest-layout title="EatsOnly - All-in-One Restaurant Management SaaS"
    description="Elevate your restaurant's efficiency with EatsOnly. Advanced POS, real-time inventory tracking, and AI-driven analytics in one powerful platform."
    keywords="restaurant POS, cloud restaurant software, kitchen management, restaurant analytics, SaaS POS">
    <x-slot name="title">EatsOnly — Smart Restaurant Management</x-slot>

    <!-- Hero Section -->
    <section class="relative pt-20 pb-32 overflow-hidden">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative">
            <div class="text-center max-w-4xl mx-auto">
                <div
                    class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/10 border border-amber-500/40 text-amber-400 text-xs font-bold tracking-widest uppercase mb-8">
                    <span class="relative flex h-2 w-2">
                        <span
                            class="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75"></span>
                        <span class="relative inline-flex rounded-full h-2 w-2 bg-amber-500"></span>
                    </span>
                    Trusted by 5,000+ Restaurants
                </div>
                <h1 class="text-5xl md:text-7xl font-extrabold tracking-tight mb-8 leading-[1.1]">
                    The Operating System for <br />
                    <span class="gradient-text">Modern Gastronomy</span>
                </h1>
                <p class="text-lg md:text-xl text-slate-400 mb-10 max-w-2xl mx-auto leading-relaxed">
                    Empower your restaurant with seamless POS, inventory management, and real-time analytics. Designed
                    for the fast-paced kitchen and the ambitious owner.
                </p>
                <div class="flex flex-col sm:flex-row items-center justify-center gap-4">
                    <a href="{{ route('register') }}"
                        class="w-full sm:w-auto px-8 py-4 bg-amber-600 text-white rounded-full font-bold text-lg hover:bg-amber-500 transition-all shadow-2xl shadow-amber-500/40 transform hover:-translate-y-1">
                        Launch Your Restaurant
                    </a>
                </div>
            </div>

            <div class="mt-20 relative mx-auto max-w-5xl group">
                <div
                    class="absolute -inset-1 bg-gradient-to-r from-amber-500 to-amber-700 rounded-2xl blur opacity-25 group-hover:opacity-40 transition duration-1000 group-hover:duration-200">
                </div>
                <div class="relative glass rounded-2xl p-2 overflow-hidden border border-amber-500/30 shadow-2xl">
                    <img src="/images/hero.png" alt="EatsOnly Interface" class="w-full rounded-xl">
                </div>
            </div>
        </div>
    </section>

    <!-- Features Grid -->
    <section id="features" class="py-32 bg-black/50 relative">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="text-center mb-20">
                <h2 class="text-3xl md:text-5xl font-bold text-white mb-4">Everything you need to scale</h2>
                <p class="text-slate-400">One platform. Infinite possibilities for your culinary business.</p>
            </div>

            <div class="grid md:grid-cols-3 gap-8">
                <div class="glass p-8 rounded-3xl hover:bg-white/5 transition-all group">
                    <div
                        class="w-14 h-14 bg-amber-500/20 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                        <svg class="w-8 h-8 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M13 10V3L4 14h7v7l9-11h-7z"></path>
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-white mb-4">Lightning Fast POS</h3>
                    <p class="text-slate-400 leading-relaxed text-sm">Offline-first architecture ensures you never miss
                        a sale, even when the internet goes down.</p>
                </div>
                <div class="glass p-8 rounded-3xl hover:bg-white/5 transition-all group">
                    <div
                        class="w-14 h-14 bg-emerald-500/20 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                        <svg class="w-8 h-8 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z">
                            </path>
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-white mb-4">Smart Analytics</h3>
                    <p class="text-slate-400 leading-relaxed text-sm">Deep insights into your best-selling dishes, peak
                        hours, and staff performance.</p>
                </div>
                <div class="glass p-8 rounded-3xl hover:bg-white/5 transition-all group">
                    <div
                        class="w-14 h-14 bg-rose-500/20 rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform">
                        <svg class="w-8 h-8 text-rose-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                                d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>
                        </svg>
                    </div>
                    <h3 class="text-xl font-bold text-white mb-4">Inventory Control</h3>
                    <p class="text-slate-400 leading-relaxed text-sm">Automated stock alerts and recipe-level ingredient
                        tracking to minimize waste.</p>
                </div>
            </div>
        </div>
    </section>
</x-guest-layout>