<div>
    <x-slot name="header">
        <h2 class="font-bold text-2xl text-white leading-tight">
            {{ __('Pricing Plan Manager') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <!-- Flash Message -->
            @if (session()->has('message'))
                <div class="mb-6 p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 font-bold flex items-center gap-3">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                    {{ session('message') }}
                </div>
            @endif

            <!-- Header Actions -->
            <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-6 mb-10">
                <div>
                    <h3 class="text-2xl font-black text-white">All Plans</h3>
                    <p class="text-slate-400 text-sm">Manage subscription tiers for EatsOnly.</p>
                </div>
                <button wire:click="openModal" class="w-full sm:w-auto px-8 py-4 bg-amber-600 hover:bg-amber-500 text-white rounded-2xl font-bold transition-all shadow-xl shadow-amber-600/40 flex items-center justify-center gap-2 transform hover:-translate-y-1">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                    Create New Plan
                </button>
            </div>

            <!-- Plans List (Re-engineered Structured Cards) -->
            <div class="space-y-8">
                @forelse($plans as $plan)
                    <div class="group bg-black/40 backdrop-blur-2xl border border-amber-500/20 rounded-[3rem] overflow-hidden shadow-2xl hover:border-amber-500/40 transition-all duration-500">
                        <div class="flex flex-col lg:flex-row min-h-full">
                            
                            <!-- Col 1: Identity (Solid Left Section) -->
                            <div class="lg:w-1/3 p-6 md:p-8 bg-white/[0.02] border-b lg:border-b-0 lg:border-r border-amber-500/20">
                                <div class="w-12 h-12 bg-amber-600 rounded-2xl flex items-center justify-center text-white mb-6 shadow-xl shadow-amber-600/40">
                                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"></path></svg>
                                </div>
                                <h4 class="text-xl font-black text-white mb-2">{{ $plan->name }}</h4>
                                <p class="text-slate-400 text-xs leading-relaxed mb-4">{{ $plan->description }}</p>
                                <div class="inline-flex items-center gap-2 px-3 py-1.5 rounded-lg bg-amber-500/10 border border-amber-500/20">
                                    <svg class="w-4 h-4 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"></path></svg>
                                    <span class="text-xs font-bold text-amber-400">
                                        {{ $plan->outlets }} Outlet{{ $plan->outlets > 1 ? 's' : '' }}
                                        <span class="text-amber-500/50 font-medium">({{ $plan->is_outlets_fixed ? 'Fixed' : 'Expandable' }})</span>
                                    </span>
                                </div>
                            </div>

                            <!-- Col 2: Features (Center Focus) -->
                            <div class="lg:w-1/3 p-6 md:p-8 border-b lg:border-b-0 lg:border-r border-amber-500/20">
                                <p class="text-[9px] font-black uppercase tracking-widest text-amber-400 mb-6 flex items-center gap-2">
                                    <span class="w-6 h-[1px] bg-amber-500/30"></span>
                                    Included Features
                                </p>
                                <div class="space-y-3">
                                    @foreach($plan->list ?? [] as $feature)
                                        <div class="flex items-start gap-3 group/item">
                                            <div class="mt-0.5 w-5 h-5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center flex-shrink-0 group-hover/item:bg-emerald-500/20 transition-colors">
                                                <svg class="w-2.5 h-2.5 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg>
                                            </div>
                                            <span class="text-slate-300 text-xs font-medium group-hover/item:text-white transition-colors">{{ $feature }}</span>
                                        </div>
                                    @endforeach
                                </div>
                            </div>

                            <!-- Col 3: Pricing & Meta (Right Sidebar) -->
                            <div class="lg:w-1/3 p-5 flex flex-col justify-between gap-6 bg-white/[0.01]">
                                <div class="flex flex-col gap-2 items-center lg:items-stretch">
                                    <div class="w-full px-4 py-2.5 rounded-xl bg-white/[0.03] border border-amber-500/20 flex items-center justify-between shadow-lg shadow-black/20 group-hover:bg-white/5 transition-all">
                                        <p class="text-[9px] font-black uppercase tracking-widest text-slate-500">Monthly</p>
                                        <div class="flex items-baseline gap-1">
                                            <span class="text-base font-black text-white">₹{{ number_format($plan->monthly_price) }}</span>
                                            <span class="text-slate-500 text-[8px] font-bold uppercase tracking-tighter">/ mo</span>
                                        </div>
                                    </div>
                                    <div class="w-full px-4 py-2.5 rounded-xl bg-amber-600/10 border border-amber-500/40 flex items-center justify-between shadow-xl shadow-amber-600/5 group-hover:bg-amber-600/20 transition-all">
                                        <p class="text-[9px] font-black uppercase tracking-widest text-amber-400/70">Yearly</p>
                                        <div class="flex items-baseline gap-1">
                                            <span class="text-base font-black text-amber-400">₹{{ number_format($plan->yearly_price) }}</span>
                                            <span class="text-amber-400/50 text-[8px] font-bold uppercase tracking-tighter">/ yr</span>
                                        </div>
                                    </div>
                                </div>

                                <div class="flex gap-2 mt-auto">
                                    <button wire:click="edit({{ $plan->id }})" class="flex-grow py-2.5 px-4 rounded-xl bg-white/5 hover:bg-white/10 text-white font-bold text-[11px] transition-all border border-amber-500/30 flex items-center justify-center gap-2">
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
                                        Edit
                                    </button>
                                    <button onclick="confirm('Are you sure?') || event.stopImmediatePropagation()" wire:click="delete({{ $plan->id }})" class="p-2.5 rounded-xl bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 transition-all border border-rose-500/20">
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                                    </button>
                                </div>
                            </div>

                        </div>
                    </div>
                @empty
                    <div class="py-20 bg-black/30 rounded-[3rem] border border-dashed border-amber-500/30 flex flex-col items-center justify-center text-center">
                        <div class="w-20 h-20 bg-amber-600/10 rounded-full flex items-center justify-center mb-6 text-amber-400">
                            <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"></path></svg>
                        </div>
                        <h3 class="text-2xl font-bold text-white mb-2">Build Your Tiers</h3>
                        <p class="text-slate-500 max-w-xs mx-auto mb-8">Create your first pricing plan to start offering subscriptions.</p>
                        <button wire:click="openModal" class="px-8 py-3 bg-amber-600 text-white rounded-xl font-bold">Add First Plan</button>
                    </div>
                @endforelse
            </div>
    </div>
</div>

    <!-- Modal Layout -->
    @if($showModal)
        <div class="fixed inset-0 z-[60] flex items-center justify-center p-4 sm:p-6 overflow-y-auto">
            <div class="fixed inset-0 bg-black/80 backdrop-blur-md" wire:click="closeModal"></div>
            
            <div class="relative bg-black border border-amber-500/30 rounded-[2.5rem] w-full max-w-2xl shadow-2xl overflow-hidden transition-all transform scale-100">
                <div class="p-8 md:p-12">
                    <div class="flex justify-between items-center mb-10">
                        <h2 class="text-3xl font-black text-white">{{ $isEdit ? 'Edit Plan' : 'Create New Plan' }}</h2>
                        <button wire:click="closeModal" class="text-slate-500 hover:text-white transition-colors">
                            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                        </button>
                    </div>

                    <form wire:submit.prevent="save" class="space-y-8">
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                            <div class="space-y-2">
                                <label class="text-xs font-black uppercase tracking-widest text-slate-500 ml-1">Plan Name</label>
                                <input type="text" wire:model="name" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-amber-500 focus:ring-amber-500/40" placeholder="e.g. Diamond">
                                @error('name') <span class="text-rose-500 text-xs">{{ $message }}</span> @enderror
                            </div>
                            <div class="space-y-2">
                                <label class="text-xs font-black uppercase tracking-widest text-slate-500 ml-1">Description</label>
                                <input type="text" wire:model="description" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-amber-500 focus:ring-amber-500/40" placeholder="Short tagline">
                                @error('description') <span class="text-rose-500 text-xs">{{ $message }}</span> @enderror
                            </div>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                            <div class="space-y-2">
                                <label class="text-xs font-black uppercase tracking-widest text-slate-500 ml-1">Monthly Price (INR)</label>
                                <input type="number" wire:model="monthly_price" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-amber-500 focus:ring-amber-500/40" placeholder="999">
                                @error('monthly_price') <span class="text-rose-500 text-xs">{{ $message }}</span> @enderror
                            </div>
                            <div class="space-y-2">
                                <label class="text-xs font-black uppercase tracking-widest text-slate-500 ml-1">Yearly Price (INR)</label>
                                <input type="number" wire:model="yearly_price" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-amber-500 focus:ring-amber-500/40" placeholder="9999">
                                @error('yearly_price') <span class="text-rose-500 text-xs">{{ $message }}</span> @enderror
                            </div>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                            <div class="space-y-2">
                                <label class="text-xs font-black uppercase tracking-widest text-slate-500 ml-1">Included Outlets</label>
                                <input type="number" wire:model="outlets" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-amber-500 focus:ring-amber-500/40" placeholder="1">
                                @error('outlets') <span class="text-rose-500 text-xs">{{ $message }}</span> @enderror
                            </div>
                            <div class="space-y-2">
                                <label class="text-xs font-black uppercase tracking-widest text-slate-500 ml-1">Outlet Modification</label>
                                <div class="w-full bg-white/5 border border-amber-500/30 rounded-2xl px-6 py-4 flex items-center gap-3">
                                    <input type="checkbox" wire:model="is_outlets_fixed" id="is_outlets_fixed" class="w-5 h-5 rounded border-amber-500/50 text-amber-500 focus:ring-amber-500 bg-black/50">
                                    <label for="is_outlets_fixed" class="text-white text-sm font-medium cursor-pointer flex-grow">Fixed (Cannot be modified)</label>
                                </div>
                                @error('is_outlets_fixed') <span class="text-rose-500 text-xs">{{ $message }}</span> @enderror
                            </div>
                        </div>

                        <div class="space-y-4">
                            <div class="flex justify-between items-center ml-1">
                                <label class="text-xs font-black uppercase tracking-widest text-slate-500">Plan Features</label>
                                <button type="button" wire:click="addFeature" class="text-amber-400 text-xs font-bold hover:text-indigo-300 flex items-center gap-1 transition-colors">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                                    Add Another
                                </button>
                            </div>
                            <div class="space-y-3">
                                @foreach($features as $index => $feature)
                                    <div class="flex gap-3">
                                        <input type="text" wire:model="features.{{ $index }}" class="flex-grow bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-amber-500 focus:ring-amber-500/40" placeholder="Feature description...">
                                        <button type="button" wire:click="removeFeature({{ $index }})" class="p-4 rounded-2xl bg-rose-500/10 text-rose-500 hover:bg-rose-500/20 transition-all border border-rose-500/10">
                                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                                        </button>
                                    </div>
                                    @error('features.'.$index) <span class="text-rose-500 text-xs ml-1">{{ $message }}</span> @enderror
                                @endforeach
                            </div>
                        </div>

                        <div class="pt-6">
                            <button type="submit" class="w-full py-5 bg-amber-600 hover:bg-amber-500 text-white rounded-2xl font-black text-lg transition-all shadow-xl shadow-amber-600/30 transform hover:-translate-y-1">
                                {{ $isEdit ? 'Update Pricing Plan' : 'Publish Pricing Plan' }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    @endif
</div>
