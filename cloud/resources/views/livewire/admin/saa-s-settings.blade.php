<div>
    <x-slot name="header">
        <h2 class="font-bold text-2xl text-white leading-tight">
            {{ __('SaaS Settings') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-4xl mx-auto sm:px-6 lg:px-8 space-y-8">
            
            <!-- Section 1: Public Sales -->
            <div class="bg-black/40 backdrop-blur-2xl border border-amber-500/20 rounded-[2.5rem] overflow-hidden shadow-2xl">
                <div class="p-8 md:p-10">
                    <div class="flex items-center justify-between gap-6 mb-8">
                        <div class="flex items-center gap-6">
                            <div class="w-14 h-14 bg-amber-600/10 rounded-2xl flex items-center justify-center text-amber-400">
                                <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path></svg>
                            </div>
                            <div>
                                <h3 class="text-xl font-black text-white">Public Sales</h3>
                                <p class="text-slate-500 text-sm">Enable or disable new subscriptions from the website.</p>
                            </div>
                        </div>
                        <button type="button" wire:click="toggleSales" 
                            class="relative inline-flex h-8 w-14 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none {{ $sales_enabled ? 'bg-amber-600' : 'bg-slate-800' }}">
                            <span class="pointer-events-none inline-block h-7 w-7 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out {{ $sales_enabled ? 'translate-x-6' : 'translate-x-0' }}"></span>
                        </button>
                    </div>

                    <div class="flex items-center justify-between">
                        @if (session()->has('message_sales'))
                            <div class="text-emerald-400 text-[10px] font-black uppercase tracking-widest flex items-center gap-2">
                                <span class="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                                {{ session('message_sales') }}
                            </div>
                        @else
                            <div class="text-slate-600 text-[10px] font-black uppercase tracking-widest flex items-center gap-2">
                                <span class="w-1.5 h-1.5 rounded-full bg-slate-700"></span>
                                Auto-saves on change
                            </div>
                        @endif
                    </div>
                </div>
            </div>

            <!-- Section 2: Razorpay Gateway -->
            <div class="bg-black/40 backdrop-blur-2xl border border-amber-500/20 rounded-[2.5rem] overflow-hidden shadow-2xl">
                <div class="p-8 md:p-10">
                    <div class="flex items-center gap-4 mb-10">
                        <div class="w-10 h-10 bg-blue-600/10 rounded-xl flex items-center justify-center text-blue-400">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"></path></svg>
                        </div>
                        <h3 class="text-xl font-black text-white uppercase tracking-wider">Razorpay Gateway</h3>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-10">
                        <div class="space-y-2">
                            <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">Razorpay Key ID</label>
                            <input type="text" wire:model="razorpay_key" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-blue-500 focus:ring-blue-500/20" placeholder="rzp_test_...">
                        </div>
                        <div class="space-y-2">
                            <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">Razorpay Secret</label>
                            <input type="password" wire:model="razorpay_secret" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-blue-500 focus:ring-blue-500/20" placeholder="••••••••••••">
                        </div>
                    </div>

                    @if (session()->has('message_razorpay'))
                        <div class="mb-6 text-blue-400 text-sm font-bold flex items-center gap-2">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                            {{ session('message_razorpay') }}
                        </div>
                    @endif

                    <div class="flex justify-end">
                        <button wire:click="saveRazorpay" class="px-8 py-3 bg-blue-600/10 hover:bg-blue-600 text-blue-400 hover:text-white rounded-xl font-bold text-sm transition-all border border-blue-600/20">
                            Save Razorpay Config
                        </button>
                    </div>
                </div>
            </div>

            <!-- Section 3: Google Maps & Delivery -->
            <div class="bg-black/40 backdrop-blur-2xl border border-amber-500/20 rounded-[2.5rem] overflow-hidden shadow-2xl">
                <div class="p-8 md:p-10">
                    <div class="flex items-center gap-4 mb-10">
                        <div class="w-10 h-10 bg-emerald-600/10 rounded-xl flex items-center justify-center text-emerald-400">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                        </div>
                        <h3 class="text-xl font-black text-white uppercase tracking-wider">Google Maps & Delivery</h3>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-10">
                        <div class="space-y-2 md:col-span-1">
                            <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">Google Maps API Key</label>
                            <input type="password" wire:model="google_maps_api_key" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-emerald-500 focus:ring-emerald-500/20" placeholder="AIza...">
                            <p class="text-slate-600 text-[10px] ml-2">Used for customer address lookup and delivery radius calculation.</p>
                        </div>
                        <div class="space-y-2">
                            <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">Delivery Radius (km)</label>
                            <input type="number" wire:model="delivery_radius_km" min="1" max="500" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-emerald-500 focus:ring-emerald-500/20" placeholder="10">
                            <p class="text-slate-600 text-[10px] ml-2">Maximum delivery distance from the restaurant.</p>
                        </div>
                    </div>

                    @if (session()->has('message_google_maps'))
                        <div class="mb-6 text-emerald-400 text-sm font-bold flex items-center gap-2">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                            {{ session('message_google_maps') }}
                        </div>
                    @endif

                    <div class="flex justify-end">
                        <button wire:click="saveGoogleMaps" class="px-8 py-3 bg-emerald-600/10 hover:bg-emerald-600 text-emerald-400 hover:text-white rounded-xl font-bold text-sm transition-all border border-emerald-600/20">
                            Save Maps Config
                        </button>
                    </div>
                </div>
            </div>

            <!-- Section 4: Mailgun Configuration -->

            <div class="bg-black/40 backdrop-blur-2xl border border-amber-500/20 rounded-[2.5rem] overflow-hidden shadow-2xl">
                <div class="p-8 md:p-10">
                    <div class="flex items-center gap-4 mb-10">
                        <div class="w-10 h-10 bg-rose-600/10 rounded-xl flex items-center justify-center text-rose-400">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
                        </div>
                        <h3 class="text-xl font-black text-white uppercase tracking-wider">Mailgun Configuration</h3>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-8">
                        <div class="space-y-2">
                            <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">Domain</label>
                            <input type="text" wire:model="mailgun_domain" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-rose-500 focus:ring-rose-500/20" placeholder="mg.yourdomain.com">
                        </div>
                        <div class="space-y-2">
                            <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">API Key</label>
                            <input type="password" wire:model="mailgun_secret" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-rose-500 focus:ring-rose-500/20" placeholder="key-...">
                        </div>
                    </div>

                    <div class="grid grid-cols-1 md:grid-cols-2 gap-8 mb-10">
                        <div class="space-y-2">
                            <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">From Address</label>
                            <input type="email" wire:model="mailgun_from_address" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-rose-500 focus:ring-rose-500/20" placeholder="support@yourdomain.com">
                        </div>
                        <div class="space-y-2">
                            <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">From Name</label>
                            <input type="text" wire:model="mailgun_from_name" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-rose-500 focus:ring-rose-500/20" placeholder="EatsOnly Support">
                        </div>
                    </div>

                    @if (session()->has('message_mailgun'))
                        <div class="mb-6 text-rose-400 text-sm font-bold flex items-center gap-2">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                            {{ session('message_mailgun') }}
                        </div>
                    @endif

                    <div class="flex justify-end">
                        <button wire:click="saveMailgun" class="px-8 py-3 bg-rose-600/10 hover:bg-rose-600 text-rose-400 hover:text-white rounded-xl font-bold text-sm transition-all border border-rose-600/20">
                            Save Mailgun Config
                        </button>
                    </div>
                </div>
            </div>

        </div>
    </div>
</div>
