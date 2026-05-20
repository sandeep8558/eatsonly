<div class="p-6 sm:p-8">
    <!-- Header Section -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-6 mb-10">
        <div>
            <h2 class="text-3xl font-black text-white tracking-tight">Platform Restaurants</h2>
            <p class="text-slate-500 mt-1 text-sm font-medium">Oversee all restaurant outlets and their subscription status.</p>
        </div>
        <div class="flex items-center gap-3">
            <div class="px-4 py-2 bg-amber-500/10 border border-amber-500/40 rounded-xl">
                <span class="text-amber-400 text-xs font-black uppercase tracking-widest">Total Outlets</span>
                <p class="text-white font-black">{{ \App\Models\Restaurant::count() }}</p>
            </div>
        </div>
    </div>

    <!-- Filters & Search -->
    <div class="flex flex-col lg:flex-row gap-6 mb-8 items-start lg:items-center justify-between">
        <!-- Search Bar -->
        <div class="relative w-full max-w-md">
            <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <svg class="h-5 w-5 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
            </div>
            <input wire:model.live="search" type="text" placeholder="Search name, owner, email..." 
                class="block w-full pl-11 pr-4 py-4 bg-black/50 border border-amber-500/20 rounded-2xl text-sm text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-amber-500/70 transition-all">
        </div>

        <!-- Filter Tabs -->
        <div class="flex p-1 bg-black/50 border border-amber-500/20 rounded-2xl">
            <button wire:click="$set('filter', 'all')" class="px-6 py-2 rounded-xl text-xs font-black uppercase tracking-widest transition-all {{ $filter === 'all' ? 'bg-amber-600 text-white shadow-lg shadow-amber-600/40' : 'text-slate-500 hover:text-slate-300' }}">
                All
            </button>
            <button wire:click="$set('filter', 'active')" class="px-6 py-2 rounded-xl text-xs font-black uppercase tracking-widest transition-all {{ $filter === 'active' ? 'bg-emerald-600 text-white shadow-lg shadow-emerald-600/20' : 'text-slate-500 hover:text-slate-300' }}">
                Active
            </button>
            <button wire:click="$set('filter', 'expired')" class="px-6 py-2 rounded-xl text-xs font-black uppercase tracking-widest transition-all {{ $filter === 'expired' ? 'bg-rose-600 text-white shadow-lg shadow-rose-600/20' : 'text-slate-500 hover:text-slate-300' }}">
                Expired
            </button>
        </div>
    </div>

    <!-- Restaurants List -->
    <div class="space-y-6">
        @forelse($restaurants as $restaurant)
            <div class="group bg-black/30 hover:bg-black/50 border border-amber-500/20 hover:border-amber-500/30 rounded-[2.5rem] p-8 transition-all duration-300">
                <div class="flex flex-col lg:flex-row lg:items-center gap-8">
                    <!-- Logo -->
                    <div class="w-20 h-20 bg-white/5 rounded-3xl flex items-center justify-center border border-amber-500/20 overflow-hidden shrink-0">
                        @if($restaurant->logo)
                            <img src="{{ asset('storage/' . $restaurant->logo) }}" class="w-full h-full object-cover" alt="{{ $restaurant->name }}">
                        @else
                            <div class="text-2xl font-black text-slate-700 uppercase">{{ substr($restaurant->name, 0, 1) }}</div>
                        @endif
                    </div>

                    <!-- Info -->
                    <div class="flex-grow">
                        <div class="flex items-center flex-wrap gap-3 mb-2">
                            <h3 class="text-xl font-black text-white">{{ $restaurant->name }}</h3>
                            <span class="px-2 py-0.5 bg-amber-500/10 text-amber-400 rounded-md text-[10px] font-black uppercase tracking-widest border border-amber-500/40">
                                {{ $restaurant->slug }}
                            </span>
                            @if($restaurant->is_veg)
                                <span class="px-2 py-0.5 bg-green-500/10 text-green-400 rounded-md text-[10px] font-black uppercase tracking-widest border border-green-500/40">
                                    Veg
                                </span>
                            @endif
                            @if($restaurant->is_nonveg)
                                <span class="px-2 py-0.5 bg-red-500/10 text-red-400 rounded-md text-[10px] font-black uppercase tracking-widest border border-red-500/40">
                                    Non-Veg
                                </span>
                            @endif
                            @if($restaurant->is_jain)
                                <span class="px-2 py-0.5 bg-purple-500/10 text-purple-400 rounded-md text-[10px] font-black uppercase tracking-widest border border-purple-500/40">
                                    Jain
                                </span>
                            @endif
                        </div>
                        <p class="text-slate-400 text-sm font-medium mb-4 line-clamp-1">{{ $restaurant->address }}</p>
                        
                        <!-- Owner Info -->
                        <div class="flex items-center gap-3 py-3 px-4 bg-white/5 rounded-2xl border border-amber-500/20 w-fit">
                            <div class="w-8 h-8 rounded-full overflow-hidden border border-amber-500/30">
                                <img src="https://ui-avatars.com/api/?name={{ urlencode($restaurant->user->name) }}&background=6366f1&color=fff" alt="">
                            </div>
                            <div>
                                <p class="text-[10px] font-black uppercase tracking-widest text-slate-500 leading-none mb-1">Owner</p>
                                <p class="text-xs font-bold text-slate-300">{{ $restaurant->user->name }} <span class="text-slate-600 font-medium ml-1">({{ $restaurant->user->email }})</span></p>
                            </div>
                        </div>
                    </div>

                    <!-- Subscription Info -->
                    <div class="lg:w-64 lg:border-l lg:border-amber-500/20 lg:pl-10 shrink-0">
                        @if($restaurant->user->activeSubscription)
                            <div class="mb-4">
                                <p class="text-[10px] font-black uppercase tracking-widest text-slate-500 mb-1">Active Plan</p>
                                <div class="flex items-center gap-2">
                                    <span class="text-white font-black text-lg">{{ $restaurant->user->activeSubscription->plan->name }}</span>
                                    <span class="px-2 py-0.5 bg-emerald-500/10 text-emerald-400 rounded-md text-[10px] font-black uppercase tracking-widest border border-emerald-500/20">Active</span>
                                </div>
                            </div>
                            <div>
                                <p class="text-[10px] font-black uppercase tracking-widest text-slate-500 mb-1">Expires On</p>
                                <p class="text-slate-300 font-bold text-sm">{{ $restaurant->user->activeSubscription->ends_at->format('M d, Y') }}</p>
                                <p class="text-slate-500 text-[10px] font-medium">{{ $restaurant->user->activeSubscription->ends_at->diffForHumans() }}</p>
                            </div>
                        @else
                            <div class="py-4 px-6 bg-rose-500/5 rounded-2xl border border-rose-500/10">
                                <p class="text-[10px] font-black uppercase tracking-widest text-rose-500/60 mb-1">Subscription</p>
                                <p class="text-rose-500 font-black text-sm">Expired / No Plan</p>
                            </div>
                        @endif
                    </div>

                    <!-- Action placeholder removed -->
                </div>
            </div>
        @empty
            <div class="text-center py-20 bg-black/20 border border-dashed border-amber-500/30 rounded-[2.5rem]">
                <h3 class="text-xl font-bold text-slate-400">No restaurants found matching your criteria</h3>
                <p class="text-slate-500 text-sm mt-2">Try adjusting your filters or search terms.</p>
            </div>
        @endforelse
    </div>

    <!-- Load More -->
    @if($hasMore)
        <div class="mt-12 flex justify-center">
            <button wire:click="loadMore" class="group flex items-center gap-3 px-10 py-4 bg-white text-black rounded-2xl font-black transition-all hover:scale-105 active:scale-95 shadow-xl shadow-white/5">
                <span>Load More Restaurants</span>
                <svg class="w-5 h-5 group-hover:translate-y-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
            </button>
        </div>
    @endif
</div>
