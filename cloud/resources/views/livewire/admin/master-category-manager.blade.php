<div class="p-6 sm:p-8">
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-6 mb-10">
        <div>
            <h2 class="text-3xl font-black text-white tracking-tight">Master Categories</h2>
            <p class="text-slate-500 mt-1 text-sm font-medium">Define global categories used for restaurant onboarding and menu templates.</p>
        </div>
        <div class="flex flex-col md:flex-row md:items-center gap-4 w-full md:w-auto">
            <!-- Search -->
            <div class="relative w-full md:w-64">
                <div class="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none text-amber-500/50">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                </div>
                <input wire:model.live.debounce.300ms="search" type="text" class="w-full pl-10 pr-5 py-3 bg-black/50 border border-amber-500/30 rounded-xl text-slate-300 text-xs font-black uppercase tracking-widest focus:outline-none focus:ring-2 focus:ring-amber-500/70 transition-all placeholder:text-slate-600" placeholder="Search categories...">
            </div>

            <button wire:click="create" class="flex items-center justify-center gap-2 px-6 py-3 bg-amber-600 hover:bg-amber-500 text-white rounded-xl font-black text-xs uppercase tracking-widest transition-all shadow-lg shadow-amber-600/40 active:scale-95 shrink-0">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                Add New Category
            </button>
        </div>
    </div>

    @if (session()->has('message'))
        <div class="mb-6 p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-2xl text-emerald-400 text-sm font-bold flex items-center gap-3">
            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>
            {{ session('message') }}
        </div>
    @endif

    <div class="space-y-4">
        @foreach($categories as $category)
            <div class="bg-black/50 border border-amber-500/20 rounded-[1.5rem] p-4 hover:border-amber-500/30 transition-all group flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div class="flex items-center gap-6">
                    <div class="w-14 h-14 bg-amber-500/10 rounded-2xl flex items-center justify-center text-amber-400 border border-amber-500/40 group-hover:scale-110 transition-transform">
                        <svg class="w-7 h-7" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"></path></svg>
                    </div>
                    <div>
                        <h3 class="text-xl font-black text-white">{{ $category->name }}</h3>
                        <p class="text-slate-500 text-xs font-bold uppercase tracking-widest mt-1">Master Category</p>
                    </div>
                </div>

                <div class="flex items-center gap-6">
                    <button wire:click="toggleStatus('{{ $category->id }}')" class="px-4 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest border transition-all {{ $category->is_active ? 'bg-emerald-500/10 border-emerald-500/20 text-emerald-400' : 'bg-rose-500/10 border-rose-500/20 text-rose-400' }}">
                        {{ $category->is_active ? 'Active' : 'Inactive' }}
                    </button>
                    
                    <div class="flex items-center gap-2">
                        <button wire:click="edit('{{ $category->id }}')" class="px-6 py-2 bg-white/5 hover:bg-white/10 border border-amber-500/20 rounded-xl text-white font-bold text-xs uppercase tracking-widest transition-all">Edit</button>
                        <button wire:click="delete('{{ $category->id }}')" wire:confirm="Are you sure you want to delete this category?" class="p-3 bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/10 rounded-xl text-rose-400 transition-all">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                        </button>
                    </div>
                </div>
            </div>
        @endforeach
    </div>

    <!-- Modal -->
    @if($isOpen)
        <div class="fixed inset-0 z-[60] flex items-center justify-center p-4">
            <div class="absolute inset-0 bg-black/60 backdrop-blur-sm" wire:click="closeModal"></div>
            <div class="bg-black border border-amber-500/30 w-full max-w-md rounded-[2.5rem] shadow-2xl relative z-10 overflow-hidden">
                <div class="p-8 border-b border-amber-500/20">
                    <h3 class="text-2xl font-black text-white">{{ $category_id ? 'Edit' : 'Add' }} Master Category</h3>
                </div>
                <form wire:submit.prevent="store" class="p-8 space-y-6">
                    <div class="space-y-2">
                        <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-1">Category Name</label>
                        <input wire:model="name" type="text" class="w-full px-5 py-4 bg-slate-800 border border-amber-500/20 rounded-2xl text-white focus:outline-none focus:ring-2 focus:ring-amber-500/70 transition-all" placeholder="e.g. Fast Food, Fine Dining">
                        @error('name') <span class="text-rose-500 text-[10px] font-bold">{{ $message }}</span> @enderror
                    </div>

                    <div class="flex items-center gap-3 p-4 bg-white/5 rounded-2xl border border-amber-500/20">
                        <input type="checkbox" wire:model="is_active" id="is_active" class="w-5 h-5 rounded border-amber-500/30 bg-slate-800 text-amber-600 focus:ring-amber-500/70">
                        <label for="is_active" class="text-sm font-bold text-slate-300 select-none">Active for Onboarding</label>
                    </div>

                    <div class="flex gap-3 pt-4">
                        <button type="button" wire:click="closeModal" class="flex-1 py-4 bg-white/5 hover:bg-white/10 text-white rounded-2xl font-black text-xs uppercase tracking-widest transition-all">Cancel</button>
                        <button type="submit" class="flex-1 py-4 bg-amber-600 hover:bg-amber-500 text-white rounded-2xl font-black text-xs uppercase tracking-widest transition-all shadow-lg shadow-amber-600/40">Save Category</button>
                    </div>
                </form>
            </div>
        </div>
    @endif
</div>
