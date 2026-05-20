<div>
    <x-slot name="header">
        <h2 class="font-black text-3xl text-white tracking-tight leading-tight">
            {{ __('Customer Dashboard') }}
        </h2>
    </x-slot>

    <div class="p-6 sm:p-8 space-y-10">
        <!-- Welcome Hero -->
        <div class="bg-gradient-to-br from-indigo-600 to-violet-700 rounded-[3rem] p-10 text-white shadow-2xl shadow-indigo-600/40 relative overflow-hidden group">
            <div class="absolute top-0 right-0 p-4 opacity-10 translate-x-1/4 -translate-y-1/4 group-hover:scale-110 transition-transform">
                <svg class="w-64 h-64" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
            </div>
            
            <div class="relative z-10">
                <h3 class="text-4xl font-black mb-4">Hello, {{ auth()->user()->name }}!</h3>
                <p class="text-indigo-100/80 text-lg font-medium max-w-xl">Welcome to your EatsOnly personal account. Explore local flavors, manage your dining history, and discover exclusive offers from our partner restaurants.</p>
                
                <div class="mt-8 flex flex-wrap gap-4">
                    <div class="bg-white/10 px-6 py-3 rounded-2xl border border-white/10 backdrop-blur-md">
                        <span class="text-[10px] font-black uppercase tracking-widest text-white">Member Status: Silver</span>
                    </div>
                    <div class="bg-white/10 px-6 py-3 rounded-2xl border border-white/10 backdrop-blur-md">
                        <span class="text-[10px] font-black uppercase tracking-widest text-white">Points: 250</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Upgrade CTA Banner -->
        @if(!auth()->user()->isRestaurant())
            <div class="bg-black/40 border-2 border-dashed border-amber-500/30 rounded-[3rem] p-8 md:p-12 text-center group hover:border-amber-500/50 transition-all duration-500">
                <div class="w-20 h-20 bg-amber-600/10 rounded-full flex items-center justify-center mx-auto mb-8 text-amber-500 group-hover:scale-110 transition-transform">
                    <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path></svg>
                </div>
                <h3 class="text-3xl font-black text-white mb-4">Own a Restaurant?</h3>
                <p class="text-slate-400 max-w-lg mx-auto mb-10 text-lg">Switch to a business account to create your outlets, manage menus, and access our professional POS system.</p>
                <button wire:click="confirmUpgrade" class="px-12 py-5 bg-amber-600 hover:bg-amber-500 text-white rounded-2xl font-black text-sm uppercase tracking-widest transition-all transform hover:-translate-y-1 shadow-2xl shadow-amber-600/40">
                    Setup Business Account
                </button>
            </div>
        @endif

        <!-- Quick Actions -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div class="bg-black/40 border border-amber-500/10 rounded-[2.5rem] p-8 hover:border-amber-500/30 transition-all group cursor-pointer">
                <div class="w-14 h-14 bg-amber-500/10 rounded-2xl flex items-center justify-center text-amber-500 mb-6 group-hover:scale-110 transition-transform">
                    <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                </div>
                <h4 class="text-xl font-black text-white mb-2">Find Food</h4>
                <p class="text-slate-500 text-sm">Discover top-rated restaurants near your current location.</p>
            </div>

            <div class="bg-black/40 border border-amber-500/10 rounded-[2.5rem] p-8 hover:border-amber-500/30 transition-all group cursor-pointer">
                <div class="w-14 h-14 bg-emerald-500/10 rounded-2xl flex items-center justify-center text-emerald-500 mb-6 group-hover:scale-110 transition-transform">
                    <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path></svg>
                </div>
                <h4 class="text-xl font-black text-white mb-2">My Orders</h4>
                <p class="text-slate-500 text-sm">Track your ongoing orders or view your dining history.</p>
            </div>

            <div class="bg-black/40 border border-amber-500/10 rounded-[2.5rem] p-8 hover:border-amber-500/30 transition-all group cursor-pointer">
                <div class="w-14 h-14 bg-sky-500/10 rounded-2xl flex items-center justify-center text-sky-500 mb-6 group-hover:scale-110 transition-transform">
                    <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"></path></svg>
                </div>
                <h4 class="text-xl font-black text-white mb-2">Favorites</h4>
                <p class="text-slate-500 text-sm">Access your saved restaurants and go-to menu items.</p>
            </div>
        </div>

        <!-- Recent Activity Placeholder -->
        <div class="bg-black/40 border border-amber-500/10 rounded-[3rem] p-10">
            <div class="flex items-center justify-between mb-8">
                <h3 class="text-2xl font-black text-white tracking-tight">Recent Activity</h3>
                <button class="text-amber-500 text-xs font-black uppercase tracking-widest hover:text-amber-400 transition-colors">View All</button>
            </div>
            
            <div class="flex flex-col items-center justify-center py-20 text-center">
                <div class="w-20 h-20 bg-white/5 rounded-full flex items-center justify-center mb-6 text-slate-600">
                    <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                </div>
                <h4 class="text-xl font-bold text-white mb-2">No recent activity</h4>
                <p class="text-slate-500 max-w-xs mx-auto">Your dining history will appear here once you start exploring our partner restaurants.</p>
            </div>
        </div>
    </div>

    <!-- Upgrade Confirmation Modal -->
    @if($confirmingUpgrade)
        <div class="fixed inset-0 z-[100] flex items-center justify-center p-4 sm:p-6 overflow-y-auto">
            <div class="fixed inset-0 bg-black/90 backdrop-blur-xl" wire:click="cancelUpgrade"></div>
            
            <div class="relative bg-black border border-amber-500/30 rounded-[3rem] w-full max-w-lg shadow-2xl transition-all transform scale-100 p-10 md:p-14 text-center">
                <div class="w-24 h-24 bg-amber-600/10 rounded-3xl flex items-center justify-center mx-auto mb-8 text-amber-500">
                    <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
                </div>
                
                <h3 class="text-3xl font-black text-white mb-4">Unlock Business Features</h3>
                <p class="text-slate-400 mb-12 text-lg">Are you sure you want to upgrade to a **Restaurant Admin** account? This will give you access to outlet management, POS tools, and staff settings.</p>
                
                <div class="grid grid-cols-2 gap-6">
                    <button wire:click="cancelUpgrade" class="px-8 py-5 bg-white/5 hover:bg-white/10 text-white rounded-2xl font-black text-xs uppercase tracking-widest border border-white/10 transition-all">
                        Maybe Later
                    </button>
                    <button wire:click="upgradeToRestaurantAdmin" class="px-8 py-5 bg-amber-600 hover:bg-amber-500 text-white rounded-2xl font-black text-xs uppercase tracking-widest shadow-xl shadow-amber-600/20 transition-all transform hover:-translate-y-1">
                        Confirm Upgrade
                    </button>
                </div>
            </div>
        </div>
    @endif
</div>
