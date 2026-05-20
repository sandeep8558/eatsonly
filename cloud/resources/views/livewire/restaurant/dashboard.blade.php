<div>
    <x-slot name="header">
        <h2 class="font-black text-3xl text-white tracking-tight leading-tight">
            {{ __('Restaurant Dashboard') }}
        </h2>
    </x-slot>

    <div class="p-6 sm:p-8 space-y-10">
        <!-- Subscription Status -->
        @if($activeSubscription)
            <div class="bg-amber-600 rounded-[3rem] p-10 text-white shadow-2xl shadow-amber-600/40 relative overflow-hidden group">
                <div class="absolute top-0 right-0 p-4 opacity-10 translate-x-1/4 -translate-y-1/4 group-hover:scale-110 transition-transform">
                    <svg class="w-64 h-64" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-2 15l-5-5 1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
                </div>
                
                <div class="flex flex-col md:flex-row items-start md:items-center justify-between gap-10 relative z-10">
                    <div class="flex items-center gap-8">
                        <div class="w-20 h-20 bg-white/20 backdrop-blur-md rounded-3xl flex items-center justify-center text-white shadow-inner">
                            <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>
                        </div>
                        <div>
                            <p class="text-[12px] font-black uppercase tracking-[0.2em] text-amber-100/80 mb-2">Active License</p>
                            <h3 class="text-4xl font-black">{{ $activeSubscription->plan->name }}</h3>
                            <p class="text-amber-100/60 text-sm mt-2 font-bold flex items-center gap-2">
                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                                Valid until {{ $activeSubscription->ends_at->format('M d, Y') }}
                            </p>
                        </div>
                    </div>

                    <div class="flex flex-col gap-4 items-end">
                        <div class="flex flex-wrap gap-2 justify-end">
                            @foreach(array_slice($activeSubscription->plan->list ?? [], 0, 3) as $feature)
                                <div class="bg-white/10 px-4 py-2 rounded-xl border border-white/10 backdrop-blur-sm">
                                    <span class="text-[10px] font-black uppercase tracking-widest text-white">{{ $feature }}</span>
                                </div>
                            @endforeach
                        </div>
                        <a href="{{ route('checkout', ['plan' => $activeSubscription->pricing_plan_id, 'period' => $activeSubscription->billing_period]) }}" class="px-8 py-4 bg-white text-amber-600 rounded-2xl font-black text-sm uppercase tracking-widest shadow-2xl transition-all hover:scale-105 active:scale-95">
                            Renew Subscription
                        </a>
                    </div>
                </div>
            </div>
        @else
            <div class="bg-rose-600 rounded-[3rem] p-10 text-white shadow-2xl shadow-rose-600/40 flex flex-col md:flex-row items-center justify-between gap-10">
                <div class="flex items-center gap-8">
                    <div class="w-20 h-20 bg-white/20 backdrop-blur-md rounded-3xl flex items-center justify-center text-white shadow-inner">
                        <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg>
                    </div>
                    <div>
                        <h3 class="text-3xl font-black">Account Restricted</h3>
                        <p class="text-rose-100/60 text-sm mt-2 font-bold">Please upgrade to access all restaurant management features.</p>
                    </div>
                </div>
                <a href="{{ route('pricing') }}" class="px-10 py-5 bg-white text-rose-600 rounded-2xl font-black text-sm uppercase tracking-widest transition-all hover:scale-105 active:scale-95 shadow-2xl">
                    Explore Plans
                </a>
            </div>
        @endif


        <!-- My Restaurants Section -->
        <div class="space-y-8">
            <div class="flex items-center justify-between">
                <div>
                    <h3 class="text-2xl font-black text-white tracking-tight">My Restaurants</h3>
                    <p class="text-slate-500 text-sm mt-1 font-medium">Manage your outlets and access POS settings.</p>
                </div>
                <button wire:click="create" class="px-8 py-4 bg-amber-600 hover:bg-amber-500 text-white rounded-2xl font-black text-xs uppercase tracking-widest transition-all transform hover:-translate-y-1 shadow-xl shadow-amber-600/20 flex items-center gap-3">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 6v6m0 0v6m0-6h6m-6 0H6"></path></svg>
                    New Outlet
                </button>
            </div>

            <div class="space-y-8">
                @forelse($restaurants as $restaurant)
                    <div class="group bg-black/40 backdrop-blur-2xl border border-amber-500/20 rounded-[3rem] overflow-hidden shadow-2xl hover:border-amber-500/40 transition-all duration-500">
                        <div class="p-8 md:p-10">
                            <div class="flex flex-col md:flex-row md:items-center justify-between gap-8">
                                <div class="flex items-center gap-8">
                                    <div class="w-24 h-24 bg-gradient-to-br from-amber-500/20 to-amber-600/5 rounded-[2rem] border border-amber-500/20 flex items-center justify-center p-3 group-hover:scale-105 transition-transform shadow-inner">
                                        @if($restaurant->logo)
                                            <img src="{{ asset('storage/' . $restaurant->logo) }}" alt="{{ $restaurant->name }}" class="w-full h-full object-contain rounded-xl">
                                        @else
                                            <span class="text-4xl font-black text-amber-500">{{ substr($restaurant->name, 0, 1) }}</span>
                                        @endif
                                    </div>
                                    <div>
                                        <div class="flex flex-wrap items-center gap-4 mb-3">
                                            <h4 class="text-3xl font-black text-white tracking-tight">{{ $restaurant->name }}</h4>
                                            <span class="px-4 py-1.5 bg-emerald-500/10 text-emerald-400 rounded-full text-[10px] font-black uppercase tracking-widest border border-emerald-500/20">
                                                Active Outlet
                                            </span>
                                            @if($restaurant->is_veg)
                                                <span class="px-4 py-1.5 bg-green-500/10 text-green-400 rounded-full text-[10px] font-black uppercase tracking-widest border border-green-500/20">
                                                    Veg
                                                </span>
                                            @endif
                                            @if($restaurant->is_nonveg)
                                                <span class="px-4 py-1.5 bg-red-500/10 text-red-400 rounded-full text-[10px] font-black uppercase tracking-widest border border-red-500/20">
                                                    Non-Veg
                                                </span>
                                            @endif
                                            @if($restaurant->is_jain)
                                                <span class="px-4 py-1.5 bg-purple-500/10 text-purple-400 rounded-full text-[10px] font-black uppercase tracking-widest border border-purple-500/20">
                                                    Jain
                                                </span>
                                            @endif
                                        </div>
                                        <div class="flex items-start gap-3 text-slate-400 max-w-xl">
                                            <svg class="w-5 h-5 flex-shrink-0 mt-0.5 text-amber-500/40" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                                            <p class="text-sm font-medium leading-relaxed">{{ $restaurant->address }}</p>
                                        </div>
                                    </div>
                                </div>

                                <div class="flex items-center gap-4">
                                    <button wire:click="edit('{{ $restaurant->id }}')" class="px-8 py-5 bg-white/5 hover:bg-white/10 text-white rounded-[1.5rem] font-black text-xs uppercase tracking-widest border border-white/10 transition-all flex items-center gap-3">
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                                        Settings
                                    </button>
                                    <button onclick="confirm('Permanently remove this outlet?') || event.stopImmediatePropagation()" wire:click="delete('{{ $restaurant->id }}')" class="p-5 bg-rose-500/10 hover:bg-rose-500/20 text-rose-500 rounded-[1.5rem] border border-rose-500/20 transition-all">
                                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                                    </button>
                                </div>
                            </div>
                        </div>
                    </div>
                @empty
                    <div class="lg:col-span-3 py-20 bg-white/5 rounded-[3rem] border border-dashed border-amber-500/30 flex flex-col items-center justify-center text-center">
                        <div class="w-24 h-24 bg-amber-600/10 rounded-full flex items-center justify-center mb-8 text-amber-500">
                            <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path></svg>
                        </div>
                        <h3 class="text-3xl font-black text-white mb-2">Initialize Your First Outlet</h3>
                        <p class="text-slate-500 max-w-sm mx-auto mb-10">Start by creating your first restaurant outlet to access point-of-sale features and menu building.</p>
                        <button wire:click="create" class="px-10 py-5 bg-amber-600 text-white rounded-2xl font-black text-sm uppercase tracking-widest shadow-2xl shadow-amber-600/40 transform hover:-translate-y-1 transition-all">Setup Restaurant Now</button>
                    </div>
                @endforelse
            </div>
        </div>
    </div>

    <!-- Modal -->
    @if($isModalOpen)
        <div class="fixed inset-0 z-[60] flex items-center justify-center p-4 sm:p-6 overflow-y-auto">
            <div class="fixed inset-0 bg-black/90 backdrop-blur-xl" wire:click="closeModal"></div>
            
            <div class="relative bg-black border border-amber-500/20 rounded-[3rem] w-full max-w-2xl shadow-2xl transition-all transform scale-100 flex flex-col max-h-[calc(100vh-2rem)] sm:max-h-[calc(100vh-3rem)]">
                <div class="p-8 md:p-12 overflow-y-auto custom-scrollbar">
                    <div class="flex justify-between items-center mb-8 shrink-0">
                        <h2 class="text-4xl font-black text-white">{{ $restaurantId ? 'Update Outlet' : 'New Restaurant' }}</h2>
                        <button wire:click="closeModal" class="text-slate-500 hover:text-white transition-colors">
                            <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                        </button>
                    </div>

                    <form wire:submit.prevent="store" class="space-y-8">
                        <div class="space-y-3">
                            <label class="text-[12px] font-black uppercase tracking-widest text-slate-500 ml-4">Restaurant Name</label>
                            <input type="text" wire:model.live="name" class="w-full bg-white/5 border-amber-500/20 rounded-3xl px-8 py-5 text-white focus:border-amber-500 focus:ring-amber-500/40 transition-all text-lg font-bold" placeholder="e.g. Gourmet Garden">
                            @error('name') <span class="text-rose-500 text-xs ml-4">{{ $message }}</span> @enderror
                        </div>

                        <div class="space-y-3">
                            <label class="text-[12px] font-black uppercase tracking-widest text-slate-500 ml-4">Identifier (Slug)</label>
                            <input type="text" wire:model="slug" class="w-full bg-white/5 border-amber-500/20 rounded-3xl px-8 py-5 text-white focus:border-amber-500 focus:ring-amber-500/40 transition-all font-mono text-sm" placeholder="gourmet-garden">
                            @error('slug') <span class="text-rose-500 text-xs ml-4">{{ $message }}</span> @enderror
                        </div>

                        <div class="space-y-3">
                            <label class="text-[12px] font-black uppercase tracking-widest text-slate-500 ml-4">Full Address</label>
                            <textarea wire:model="address" rows="3" class="w-full bg-white/5 border-amber-500/20 rounded-3xl px-8 py-5 text-white focus:border-amber-500 focus:ring-amber-500/40 transition-all text-sm font-medium" placeholder="Street name, City, Zip"></textarea>
                            @error('address') <span class="text-rose-500 text-xs ml-4">{{ $message }}</span> @enderror
                        </div>

                        <div class="space-y-3">
                            <label class="text-[12px] font-black uppercase tracking-widest text-slate-500 ml-4">Outlet Logo</label>
                            <div class="flex items-center gap-6">
                                <div class="w-24 h-24 bg-white/5 border-2 border-dashed border-amber-500/30 rounded-3xl flex items-center justify-center overflow-hidden">
                                    @if ($logo && !is_string($logo))
                                        <img src="{{ $logo->temporaryUrl() }}" class="w-full h-full object-cover">
                                    @elseif ($logo)
                                        <img src="{{ asset('storage/' . $logo) }}" class="w-full h-full object-cover">
                                    @else
                                        <svg class="w-10 h-10 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                                    @endif
                                </div>
                                <input type="file" wire:model="logo" class="text-sm text-slate-400 file:mr-4 file:py-2 file:px-4 file:rounded-full file:border-0 file:text-[10px] file:font-black file:uppercase file:bg-amber-600/10 file:text-amber-400 hover:file:bg-amber-600/20 cursor-pointer">
                            </div>
                        </div>

                        <div class="space-y-4">
                            <label class="text-[12px] font-black uppercase tracking-widest text-slate-500 ml-4">Dietary Offerings</label>
                            
                            <div class="grid grid-cols-1 gap-4">
                                <!-- Veg Toggle -->
                                <label class="flex items-center justify-between p-4 bg-white/5 border border-amber-500/20 rounded-3xl cursor-pointer hover:bg-white/10 transition-all group">
                                    <div class="flex items-center gap-4">
                                        <div class="p-2 bg-green-500/10 rounded-xl text-green-500 group-hover:scale-110 transition-transform">
                                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 6l3 1m0 0l-3 9a5.002 5.002 0 006.001 0M6 7l3 9M6 7l6-2m6 2l3-1m-3 1l-3 9a5.002 5.002 0 006.001 0M18 7l3 9m-3-9l-6-2m0-2v2m0 16V5m0 16H9m3 0h3"></path></svg>
                                        </div>
                                        <div>
                                            <p class="text-white font-bold text-sm">Veg</p>
                                            <p class="text-slate-500 text-xs">Serves vegetarian food</p>
                                        </div>
                                    </div>
                                    <div class="relative inline-flex items-center cursor-pointer">
                                      <input type="checkbox" wire:model="is_veg" class="sr-only peer">
                                      <div class="w-11 h-6 bg-slate-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-green-500"></div>
                                    </div>
                                </label>

                                <!-- Non-Veg Toggle -->
                                <label class="flex items-center justify-between p-4 bg-white/5 border border-amber-500/20 rounded-3xl cursor-pointer hover:bg-white/10 transition-all group">
                                    <div class="flex items-center gap-4">
                                        <div class="p-2 bg-red-500/10 rounded-xl text-red-500 group-hover:scale-110 transition-transform">
                                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
                                        </div>
                                        <div>
                                            <p class="text-white font-bold text-sm">Non-Veg</p>
                                            <p class="text-slate-500 text-xs">Serves non-vegetarian food</p>
                                        </div>
                                    </div>
                                    <div class="relative inline-flex items-center cursor-pointer">
                                      <input type="checkbox" wire:model="is_nonveg" class="sr-only peer">
                                      <div class="w-11 h-6 bg-slate-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-red-500"></div>
                                    </div>
                                </label>

                                <!-- Jain Toggle -->
                                <label class="flex items-center justify-between p-4 bg-white/5 border border-amber-500/20 rounded-3xl cursor-pointer hover:bg-white/10 transition-all group">
                                    <div class="flex items-center gap-4">
                                        <div class="p-2 bg-purple-500/10 rounded-xl text-purple-500 group-hover:scale-110 transition-transform">
                                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"></path></svg>
                                        </div>
                                        <div>
                                            <p class="text-white font-bold text-sm">Jain</p>
                                            <p class="text-slate-500 text-xs">Serves food without root vegetables</p>
                                        </div>
                                    </div>
                                    <div class="relative inline-flex items-center cursor-pointer">
                                      <input type="checkbox" wire:model="is_jain" class="sr-only peer">
                                      <div class="w-11 h-6 bg-slate-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-purple-500"></div>
                                    </div>
                                </label>
                            </div>
                        </div>

                        <div class="pt-8">
                            <button type="submit" class="w-full py-6 bg-amber-600 hover:bg-amber-500 text-white rounded-3xl font-black text-lg uppercase tracking-[0.2em] transition-all transform hover:-translate-y-1 shadow-2xl shadow-amber-600/40">
                                {{ $restaurantId ? 'Save Configuration' : 'Establish Outlet' }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    @endif
</div>
