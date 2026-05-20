<div class="min-h-screen pb-24">

    <!-- Restaurant Header -->
    <div class="p-6 pt-8">
        <div class="flex items-center gap-4 mb-6">
            @if($restaurant->logo)
                <img src="{{ Storage::url($restaurant->logo) }}" class="w-16 h-16 rounded-2xl object-cover border border-amber-500/20" alt="{{ $restaurant->name }}">
            @else
                <div class="w-16 h-16 rounded-2xl bg-amber-500/10 border border-amber-500/20 flex items-center justify-center">
                    <span class="text-2xl font-bold text-amber-500">{{ substr($restaurant->name, 0, 1) }}</span>
                </div>
            @endif
            <div class="flex items-center gap-3">
                <div class="text-right">
                    <h1 class="text-lg font-black tracking-tight text-white leading-tight">{{ $restaurant->name }}</h1>
                    <div class="flex items-center justify-end gap-2 text-[10px] text-slate-400 font-bold uppercase tracking-wider">
                        <span>{{ $restaurant->address }}</span>
                        <span class="w-1 h-1 bg-slate-600 rounded-full"></span>
                        <span class="text-amber-500">Table {{ $tableName ?: 'N/A' }}</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Search Bar -->
        <div class="relative group">
            <div class="absolute inset-y-0 left-4 flex items-center pointer-events-none text-slate-500">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
            </div>
            <input 
                wire:model.live.debounce.300ms="search"
                type="text" 
                placeholder="Search dishes..." 
                class="w-full bg-white/5 border border-white/10 rounded-2xl py-4 pl-12 pr-4 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-amber-500/50 transition-all">
        </div>
    </div>

    <!-- Category Scroller -->
    <div class="sticky top-[56px] z-50 bg-black/80 backdrop-blur-md border-b border-white/5 overflow-x-auto no-scrollbar">
        <div class="flex px-6 py-4 gap-4 min-w-max">
            @foreach($categories as $category)
                <button 
                    wire:click="selectCategory('{{ $category->id }}')"
                    class="px-4 py-2 rounded-xl text-xs font-bold uppercase tracking-widest transition-all {{ $selectedCategoryId == $category->id ? 'bg-amber-600 text-white shadow-lg shadow-amber-600/20' : 'bg-white/5 text-slate-400 border border-white/5' }}">
                    {{ $category->name }}
                </button>
            @endforeach
        </div>
    </div>

    <!-- Menu Items -->
    <div class="p-6 space-y-8">
        @foreach($categories as $category)
            @if($search || $selectedCategoryId == null || $selectedCategoryId == $category->id)
                <div id="cat-{{ $category->id }}" class="space-y-4">
                    <h2 class="text-xs font-black uppercase tracking-[0.2em] text-amber-500 flex items-center gap-3">
                        {{ $category->name }}
                        <span class="h-px flex-1 bg-amber-500/10"></span>
                    </h2>
                    
                    <div class="grid grid-cols-1 gap-4">
                        @foreach($category->items as $item)
                            <div class="bg-white/5 border border-white/5 rounded-2xl p-3 flex gap-4 hover:bg-white/[0.07] transition-all group">
                                @if($item->image)
                                    <div class="w-24 h-24 rounded-xl overflow-hidden flex-shrink-0 border border-white/10 shadow-lg">
                                        <img src="{{ Storage::url($item->image) }}" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" alt="{{ $item->name }}">
                                    </div>
                                @else
                                    <div class="w-24 h-24 rounded-xl bg-slate-800/50 flex items-center justify-center flex-shrink-0 border border-white/5">
                                        <svg class="w-8 h-8 text-slate-700" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                                    </div>
                                @endif

                                <div class="flex-1 flex flex-col justify-between min-w-0">
                                    <div>
                                        <div class="flex items-start justify-between gap-2 mb-1">
                                            <div class="flex items-center gap-2 min-w-0">
                                                @if($item->is_veg)
                                                    <div class="w-3 h-3 border border-emerald-500 flex-shrink-0 flex items-center justify-center p-0.5">
                                                        <div class="w-full h-full bg-emerald-500 rounded-full"></div>
                                                    </div>
                                                @elseif($item->is_nonveg)
                                                    <div class="w-3 h-3 border border-rose-500 flex-shrink-0 flex items-center justify-center p-0.5">
                                                        <div class="w-full h-full bg-rose-500 rounded-full"></div>
                                                    </div>
                                                @endif
                                                <h3 class="font-bold text-slate-100 group-hover:text-white transition-colors truncate">{{ $item->name }}</h3>
                                            </div>
                                            <span class="text-sm font-black text-amber-500 flex-shrink-0">₹{{ number_format($item->price, 2) }}</span>
                                        </div>
                                        <p class="text-[11px] text-slate-500 line-clamp-2 leading-tight">{{ $item->description }}</p>
                                    </div>
                                    
                                    <div class="mt-2 flex items-center justify-between">
                                        <div class="flex gap-2">
                                            @if($item->type == 'combo')
                                                <span class="px-2 py-0.5 bg-blue-500/10 text-blue-400 text-[9px] font-bold rounded uppercase tracking-tighter">Combo</span>
                                            @endif
                                        </div>
                                        
                                        @if(isset($cart[$item->id]))
                                            <div class="flex items-center gap-3 bg-amber-600 rounded-full px-2 py-1 shadow-lg shadow-amber-600/20">
                                                <button wire:click="removeFromCart('{{ $item->id }}')" class="w-5 h-5 flex items-center justify-center text-white active:scale-90 transition-transform">
                                                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 12H4"></path></svg>
                                                </button>
                                                <span class="text-xs font-black text-white w-4 text-center">{{ $cart[$item->id]['quantity'] }}</span>
                                                <button wire:click="addToCart('{{ $item->id }}')" class="w-5 h-5 flex items-center justify-center text-white active:scale-90 transition-transform">
                                                    <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                                                </button>
                                            </div>
                                        @else
                                            <button 
                                                wire:click="addToCart('{{ $item->id }}')"
                                                class="w-7 h-7 bg-amber-600 rounded-full flex items-center justify-center text-white shadow-lg shadow-amber-600/20 active:scale-90 transition-transform">
                                                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                                            </button>
                                        @endif
                                    </div>
                                </div>
                            </div>
                        @endforeach
                    </div>
                </div>
            @endif
        @endforeach
    </div>

    <!-- Floating Order History Button (Bottom Center) -->
    <div class="fixed left-1/2 -translate-x-1/2 bottom-8 z-[55]">
        <button 
            wire:click="toggleHistory"
            class="bg-slate-900/90 backdrop-blur-md text-white py-3 px-6 rounded-2xl shadow-2xl flex items-center gap-3 border border-white/10 hover:bg-slate-800 transition-all group whitespace-nowrap">
            <div class="relative">
                <svg class="w-5 h-5 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path></svg>
                @if(count($previousOrderItems) > 0)
                    <span class="absolute -top-2 -right-2 w-4 h-4 bg-amber-500 rounded-full border-2 border-slate-900 flex items-center justify-center text-[8px] font-black text-black">
                        {{ collect($previousOrderItems)->sum('quantity') }}
                    </span>
                @endif
            </div>
            <span class="text-[10px] font-black uppercase tracking-widest">My Order</span>
        </button>
    </div>

    <!-- Floating Cart Bar (Sticky Bottom) -->
    @if(count($cart) > 0 && !$orderSuccess)
        <div class="fixed bottom-6 left-6 right-6 z-[60]" x-data x-show="true" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="translate-y-20 opacity-0" x-transition:enter-end="translate-y-0 opacity-100">
            <button 
                wire:click="toggleCart"
                class="w-full bg-amber-600 text-white rounded-2xl py-4 px-6 flex items-center justify-between shadow-2xl shadow-amber-600/40 hover:bg-amber-500 transition-all group overflow-hidden relative">
                <div class="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-1000"></div>
                <div class="flex items-center gap-3 relative z-10">
                    <div class="w-10 h-10 bg-black/20 rounded-xl flex items-center justify-center">
                        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path></svg>
                    </div>
                    <div class="text-left">
                        <p class="text-[10px] font-black uppercase tracking-widest opacity-70">Review Order</p>
                        <p class="text-sm font-bold">{{ $this->cartCount }} Items Selected</p>
                    </div>
                </div>
                <div class="text-right relative z-10">
                    <p class="text-lg font-black tracking-tight">₹{{ number_format($this->cartTotal, 2) }}</p>
                </div>
            </button>
        </div>
    @endif

    <!-- Cart Modal -->
    @if($showCart)
        <div class="fixed inset-0 z-[100] overflow-y-auto" x-data x-transition>
            <div class="min-h-screen px-4 text-center">
                <div class="fixed inset-0 bg-black/90 backdrop-blur-sm transition-opacity" wire:click="toggleCart"></div>

                <div class="inline-block w-full max-w-md my-8 overflow-hidden text-left align-middle transition-all transform bg-slate-900 border border-white/10 rounded-3xl shadow-2xl relative z-10">
                    <div class="p-6">
                        <div class="flex items-center justify-between mb-6">
                            <h2 class="text-xl font-black tracking-tight text-white">Your Order</h2>
                            <button wire:click="toggleCart" class="text-slate-400 hover:text-white">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                            </button>
                        </div>

                        <div class="space-y-4 mb-8">
                            @foreach($cart as $item)
                                <div class="flex items-center justify-between gap-4">
                                    <div class="flex items-center gap-3">
                                        <div class="w-10 h-10 bg-white/5 rounded-lg flex items-center justify-center text-xs font-bold text-amber-500 border border-white/5">
                                            {{ $item['quantity'] }}x
                                        </div>
                                        <div>
                                            <p class="text-sm font-bold text-slate-100">{{ $item['name'] }}</p>
                                            <p class="text-[10px] text-slate-500">₹{{ number_format($item['price'], 2) }} each</p>
                                        </div>
                                    </div>
                                    <p class="text-sm font-black text-white">₹{{ number_format($item['price'] * $item['quantity'], 2) }}</p>
                                </div>
                            @endforeach
                        </div>

                        <div class="bg-white/5 rounded-2xl p-4 space-y-3 mb-8">
                            <div class="flex justify-between text-xs text-slate-400">
                                <span>Subtotal</span>
                                <span>₹{{ number_format($this->cartTotal, 2) }}</span>
                            </div>
                            <div class="h-px bg-white/10"></div>
                            <div class="flex justify-between text-lg font-black text-amber-500">
                                <span>Total</span>
                                <span>₹{{ number_format($this->cartTotal, 2) }}</span>
                            </div>
                        </div>

                        <div class="space-y-4">
                            <input type="text" wire:model="customerName" placeholder="Your Name (Optional)" class="w-full bg-white/5 border border-white/10 rounded-xl py-3 px-4 text-sm font-medium focus:outline-none focus:ring-1 focus:ring-amber-500/50">
                            <input type="tel" wire:model="customerPhone" placeholder="Phone Number (Optional)" class="w-full bg-white/5 border border-white/10 rounded-xl py-3 px-4 text-sm font-medium focus:outline-none focus:ring-1 focus:ring-amber-500/50">
                            
                            <button 
                                wire:click="placeOrder"
                                class="w-full bg-amber-600 text-white rounded-xl py-4 font-black uppercase tracking-widest text-xs shadow-lg shadow-amber-600/20 active:scale-95 transition-all">
                                Confirm & Send to Kitchen
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    @endif

    <!-- Order Success Screen -->
    @if($orderSuccess)
        <div class="fixed inset-0 z-[110] bg-black flex flex-col items-center justify-center p-8 text-center" x-data x-transition>
            <div class="w-24 h-24 bg-amber-500/10 rounded-full flex items-center justify-center mb-6 relative">
                <div class="absolute inset-0 bg-amber-500 rounded-full animate-ping opacity-20"></div>
                <svg class="w-12 h-12 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg>
            </div>

            <h2 class="text-3xl font-black tracking-tight mb-2">Order Confirmed!</h2>
            <p class="text-slate-400 text-sm mb-12">Your food is being prepared and will be served shortly.</p>

            <!-- Registration Promotion Card -->
            <div class="w-full max-w-sm bg-gradient-to-b from-white/10 to-transparent border border-white/10 rounded-3xl p-6 relative overflow-hidden">
                <div class="absolute top-0 right-0 p-4 opacity-10">
                    <svg class="w-24 h-24" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1.41 16.09V20h-2.82v-1.91c-1.64-.21-2.91-1.12-3.32-2.52h2.09c.27.65.84 1.05 1.57 1.05.81 0 1.48-.48 1.48-1.16 0-1.89-4.82-1.39-4.82-4.56 0-1.16.81-2.09 2.05-2.43V6h2.82v1.9c1.37.21 2.39 1.03 2.72 2.21h-2.05c-.2-.48-.68-.83-1.16-.83-.75 0-1.32.41-1.32.96 0 1.76 4.82 1.27 4.82 4.41 0 1.1-.81 2.04-2.28 2.44z"/></svg>
                </div>
                
                <h3 class="text-lg font-black mb-2 text-amber-500">Get 10% Off Every Order</h3>
                <p class="text-xs text-slate-300 mb-6 leading-relaxed">Register on the **EatsOnly App** now to track your order live and unlock exclusive rewards & loyalty points!</p>
                
                <div class="flex flex-col gap-3">
                    <a href="{{ route('download') }}" class="w-full bg-white text-black py-3 rounded-xl text-[10px] font-black uppercase tracking-widest hover:scale-105 transition-all">Download & Register Now</a>
                    <button wire:click="$set('orderSuccess', false)" class="text-[10px] font-bold text-slate-500 hover:text-white uppercase tracking-widest">Maybe Later</button>
                </div>
            </div>
        </div>
    @endif

    <!-- Order History Modal (Bottom Sheet) -->
    @if($showHistory)
        <div class="fixed inset-0 z-[100] flex items-end justify-center" x-data x-transition>
            <div class="fixed inset-0 bg-black/80 backdrop-blur-sm transition-opacity" wire:click="toggleHistory"></div>

            <div 
                x-show="true"
                x-transition:enter="transition ease-out duration-300 transform"
                x-transition:enter-start="translate-y-full"
                x-transition:enter-end="translate-y-0"
                x-transition:leave="transition ease-in duration-200 transform"
                x-transition:leave-start="translate-y-0"
                x-transition:leave-end="translate-y-full"
                class="w-full max-w-md bg-slate-900 border-t border-x border-white/10 rounded-t-[2.5rem] shadow-2xl relative z-10 overflow-hidden max-h-[85vh] flex flex-col">
                
                <!-- Handle Bar -->
                <div class="w-12 h-1.5 bg-white/10 rounded-full mx-auto my-4 shrink-0"></div>

                <div class="p-6 pt-2 overflow-y-auto no-scrollbar">
                    <div class="flex items-center justify-between mb-8">
                        <div>
                            <h2 class="text-2xl font-black tracking-tight text-white">My Active Order</h2>
                            <p class="text-[10px] text-slate-500 font-bold uppercase tracking-widest mt-1">Live tracking for Table {{ $tableName ?: 'N/A' }}</p>
                        </div>
                        <button wire:click="toggleHistory" class="w-10 h-10 bg-white/5 rounded-full flex items-center justify-center text-slate-400 hover:text-white">
                            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                        </button>
                    </div>

                    <div class="space-y-4 mb-8">
                        @forelse($previousOrderItems as $item)
                            <div class="flex items-center justify-between gap-4 p-4 bg-white/5 rounded-2xl border border-white/5">
                                <div class="flex items-center gap-4">
                                    <div class="w-12 h-12 bg-amber-500/10 rounded-2xl flex items-center justify-center text-sm font-black text-amber-500 border border-amber-500/20">
                                        {{ $item->quantity }}x
                                    </div>
                                    <div>
                                        <p class="text-sm font-bold text-slate-100">{{ $item->name }}</p>
                                        <div class="flex items-center gap-2 mt-1.5">
                                            <div class="relative flex items-center justify-center">
                                                <span class="w-2 h-2 rounded-full {{ ($item->status ?? 'pending') == 'ready' ? 'bg-green-500' : 'bg-amber-500 animate-pulse' }}"></span>
                                                @if(($item->status ?? 'pending') != 'ready')
                                                    <span class="absolute w-4 h-4 bg-amber-500 rounded-full animate-ping opacity-20"></span>
                                                @endif
                                            </div>
                                            <span class="text-[9px] font-black uppercase tracking-widest {{ ($item->status ?? 'pending') == 'ready' ? 'text-green-500' : 'text-amber-500' }}">
                                                {{ $item->status ?? 'pending' }}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                                <p class="text-sm font-black text-white">₹{{ number_format($item->price * $item->quantity, 2) }}</p>
                            </div>
                        @empty
                            <div class="py-12 text-center">
                                <div class="w-20 h-20 bg-white/5 rounded-full flex items-center justify-center mx-auto mb-6 text-slate-700">
                                    <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 11V7a4 4 0 00-8 0v4M5 9h14l1 12H4L5 9z"></path></svg>
                                </div>
                                <p class="text-lg font-bold text-slate-400">Your table is empty</p>
                                <p class="text-[10px] text-slate-600 uppercase tracking-widest mt-2 max-w-[200px] mx-auto leading-relaxed">Add some items from the menu to start your session!</p>
                            </div>
                        @endforelse

                        @if(count($previousOrderItems) > 0)
                            <div class="mt-8 pt-6 border-t border-white/10 flex items-center justify-between">
                                <div>
                                    <p class="text-[10px] font-black text-slate-500 uppercase tracking-widest">Running Total</p>
                                    <p class="text-xs text-slate-600 mt-0.5">Includes all rounds ordered</p>
                                </div>
                                <p class="text-2xl font-black text-amber-500">₹{{ number_format(collect($previousOrderItems)->sum(fn($item) => $item->price * $item->quantity), 2) }}</p>
                            </div>
                        @endif
                    </div>

                    <div class="pb-8">
                        <button 
                            wire:click="toggleHistory"
                            class="w-full bg-white/5 border border-white/10 text-white rounded-2xl py-4 font-black uppercase tracking-widest text-xs hover:bg-white/10 transition-all active:scale-[0.98]">
                            Close Details
                        </button>
                    </div>
                </div>
            </div>
        </div>
    @endif

    <style>
        .no-scrollbar::-webkit-scrollbar { display: none; }
        .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
    </style>
</div>
