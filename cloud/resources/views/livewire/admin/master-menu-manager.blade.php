<div class="p-6 sm:p-8">
    <div class="mb-12">
        <div class="flex items-center justify-between gap-6 mb-2">
            <h2 class="text-3xl font-black text-white tracking-tight">Master Menus</h2>
            <div class="px-4 py-1.5 bg-amber-500/10 border border-amber-500/40 rounded-full text-amber-400 text-[10px] font-black uppercase tracking-widest shrink-0">
                Total: {{ count($menus) }} Menus
            </div>
        </div>
        <p class="text-slate-500 text-sm font-medium max-w-2xl mb-8">Create pre-defined menu structures (like Fast Food or Fine Dining) to speed up restaurant onboarding.</p>
        
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div class="flex flex-col md:flex-row md:items-center gap-4 w-full">
                <!-- Search -->
                <div class="relative w-full md:w-auto md:min-w-[280px]">
                    <div class="absolute inset-y-0 left-0 flex items-center pl-4 pointer-events-none text-amber-500/50">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                    </div>
                    <input wire:model.live.debounce.300ms="search" type="text" class="w-full pl-10 pr-5 py-4 bg-black/50 border border-amber-500/30 rounded-2xl text-slate-300 text-xs font-black uppercase tracking-widest focus:outline-none focus:ring-2 focus:ring-amber-500/70 transition-all placeholder:text-slate-600" placeholder="Search menus...">
                </div>

                <!-- Category Filter -->
                <div class="relative w-full md:w-auto md:min-w-[280px]">
                    <select wire:model.live="filterCategory" class="w-full pl-5 pr-10 py-4 bg-black/50 border border-amber-500/30 rounded-2xl text-slate-300 text-xs font-black uppercase tracking-widest focus:outline-none focus:ring-2 focus:ring-amber-500/70 transition-all appearance-none cursor-pointer">
                        <option value="">All Categories</option>
                        @foreach($availableCategories as $cat)
                            <option value="{{ $cat->id }}">{{ $cat->name }}</option>
                        @endforeach
                    </select>
                    <div class="absolute inset-y-0 right-0 flex items-center pr-5 pointer-events-none text-slate-500">
                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                    </div>
                </div>
            </div>

            <div class="flex gap-3 shrink-0">
                <button wire:click="autoCategorizeAll" wire:loading.attr="disabled" class="flex items-center justify-center gap-2 px-6 py-4 bg-indigo-600/20 hover:bg-indigo-600/40 border border-indigo-500/30 text-indigo-400 rounded-2xl font-black text-xs uppercase tracking-widest transition-all">
                    <svg class="w-4 h-4" wire:loading.remove wire:target="autoCategorizeAll" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M19 9l1.25-2.75L23 5l-2.75-1.25L19 1l-1.25 2.75L15 5l2.75 1.25L19 9zm-7.5.5L9 4 6.5 9.5 1 12l5.5 2.5L9 20l2.5-5.5L17 12l-5.5-2.5zM19 15l-1.25 2.75L15 19l2.75 1.25L19 23l1.25-2.75L23 19l-2.75-1.25L19 15z"/></svg>
                    <svg class="w-4 h-4 animate-spin" wire:loading wire:target="autoCategorizeAll" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg>
                    Auto-Categorize
                </button>
                <button wire:click="create" class="flex items-center justify-center gap-2 px-8 py-4 bg-amber-600 hover:bg-amber-500 text-white rounded-2xl font-black text-xs uppercase tracking-widest transition-all shadow-lg shadow-amber-600/40">
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path></svg>
                    Add New Menu
                </button>
            </div>
        </div>
    </div>

    @if (session()->has('message'))
        <div class="mb-6 p-4 bg-emerald-500/10 border border-emerald-500/20 rounded-2xl text-emerald-400 text-sm font-bold flex items-center gap-3">
            <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path></svg>
            {{ session('message') }}
        </div>
    @endif

    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        @foreach($menus as $menu)
            <div class="bg-black/50 border border-amber-500/20 rounded-[2.5rem] overflow-hidden hover:border-amber-500/30 transition-all group relative">
                <div class="aspect-video relative overflow-hidden bg-slate-800">
                    @if($menu->image)
                        <img src="{{ Storage::url($menu->image) }}" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" alt="{{ $menu->name }}">
                    @else
                        <div class="w-full h-full flex items-center justify-center text-slate-600">
                            <svg class="w-12 h-12" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                        </div>
                    @endif
                    <div class="absolute top-4 right-4">
                        <button wire:click="toggleStatus('{{ $menu->id }}')" class="px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-widest border transition-all {{ $menu->is_active ? 'bg-emerald-500/10 border-emerald-500/20 text-emerald-400' : 'bg-rose-500/10 border-rose-500/20 text-rose-400' }}">
                            {{ $menu->is_active ? 'Active' : 'Inactive' }}
                        </button>
                    </div>
                </div>

                <div class="p-8">
                    <h3 class="text-2xl font-black text-white mb-2">{{ $menu->name }}</h3>
                    <p class="text-slate-500 text-xs font-medium mb-6 line-clamp-2">{{ $menu->description ?: 'No description provided.' }}</p>

                    <div class="space-y-2 mb-8">
                        <p class="text-[10px] font-black uppercase tracking-widest text-slate-500">Categories Included</p>
                        <div class="flex flex-wrap gap-2">
                            @foreach($menu->categories as $category)
                                <span class="px-3 py-1 bg-white/5 border border-amber-500/20 rounded-lg text-[10px] font-black text-slate-400">{{ $category->name }}</span>
                            @endforeach
                        </div>
                    </div>

                    <div class="flex items-center gap-2">
                        <button wire:click="edit('{{ $menu->id }}')" class="flex-1 py-3 bg-white/5 hover:bg-white/10 border border-amber-500/20 rounded-xl text-white font-bold text-xs uppercase tracking-widest transition-all">Edit Menu</button>
                        <button wire:click="delete('{{ $menu->id }}')" wire:confirm="Delete this menu?" class="p-3 bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/10 rounded-xl text-rose-400 transition-all">
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
            <div class="bg-black border border-amber-500/30 w-full max-w-2xl rounded-[2.5rem] shadow-2xl relative z-10 overflow-hidden max-h-[90vh] flex flex-col">
                <div class="p-8 border-b border-amber-500/20 shrink-0">
                    <h3 class="text-2xl font-black text-white">{{ $menu_id ? 'Edit' : 'Add New' }} Menu</h3>
                </div>
                
                <form wire:submit.prevent="store" class="p-8 space-y-8 overflow-y-auto custom-scrollbar">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
                        <div class="space-y-6">
                            <div class="space-y-2">
                                <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-1">Menu Name</label>
                                <input wire:model="name" type="text" class="w-full px-5 py-4 bg-slate-800 border border-amber-500/20 rounded-2xl text-white focus:outline-none focus:ring-2 focus:ring-amber-500/70 transition-all" placeholder="e.g. Standard Fast Food">
                                @error('name') <span class="text-rose-500 text-[10px] font-bold">{{ $message }}</span> @enderror
                            </div>

                            <div class="space-y-2 relative">
                                <div class="flex items-center justify-between">
                                    <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-1">Description</label>
                                    <button type="button" wire:click="generateDescription" wire:loading.attr="disabled" class="text-amber-400 hover:text-amber-300 text-[10px] font-black uppercase tracking-widest flex items-center gap-1 transition-all">
                                        <svg class="w-3 h-3" wire:loading.remove wire:target="generateDescription" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M19 9l1.25-2.75L23 5l-2.75-1.25L19 1l-1.25 2.75L15 5l2.75 1.25L19 9zm-7.5.5L9 4 6.5 9.5 1 12l5.5 2.5L9 20l2.5-5.5L17 12l-5.5-2.5zM19 15l-1.25 2.75L15 19l2.75 1.25L19 23l1.25-2.75L23 19l-2.75-1.25L19 15z"/></svg>
                                        <svg class="w-3 h-3 animate-spin" wire:loading wire:target="generateDescription" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg>
                                        Auto-Generate
                                    </button>
                                </div>
                                <textarea wire:model="description" rows="4" class="w-full px-5 py-4 bg-slate-800 border border-amber-500/20 rounded-2xl text-white focus:outline-none focus:ring-2 focus:ring-amber-500/70 transition-all" placeholder="Briefly describe what this menu setup includes..."></textarea>
                                @error('description') <span class="text-rose-500 text-[10px] font-bold">{{ $message }}</span> @enderror
                            </div>
                        </div>

                        <div class="space-y-2">
                            <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-1">Menu Photo</label>
                            <div class="relative group aspect-video rounded-2xl overflow-hidden bg-slate-800 border-2 border-dashed border-amber-500/30 hover:border-amber-500/50 transition-all">
                                @if ($image)
                                    <img src="{{ $image->temporaryUrl() }}" class="w-full h-full object-cover">
                                @elseif($oldImage)
                                    <img src="{{ Storage::url($oldImage) }}" class="w-full h-full object-cover">
                                @else
                                    <div class="absolute inset-0 flex flex-col items-center justify-center text-slate-500">
                                        <svg class="w-10 h-10 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg>
                                        <span class="text-[10px] font-black uppercase tracking-widest">Upload Photo</span>
                                    </div>
                                @endif
                                <input type="file" wire:model="image" class="absolute inset-0 opacity-0 cursor-pointer">
                            </div>
                            @error('image') <span class="text-rose-500 text-[10px] font-bold">{{ $message }}</span> @enderror
                        </div>
                    </div>

                    <div class="space-y-4">
                        <div class="flex items-center justify-between">
                            <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-1">Select Categories</label>
                            <button type="button" wire:click="autoCategorizeSingle" wire:loading.attr="disabled" class="text-indigo-400 hover:text-indigo-300 text-[10px] font-black uppercase tracking-widest flex items-center gap-1 transition-all">
                                <svg class="w-3 h-3" wire:loading.remove wire:target="autoCategorizeSingle" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M19 9l1.25-2.75L23 5l-2.75-1.25L19 1l-1.25 2.75L15 5l2.75 1.25L19 9zm-7.5.5L9 4 6.5 9.5 1 12l5.5 2.5L9 20l2.5-5.5L17 12l-5.5-2.5zM19 15l-1.25 2.75L15 19l2.75 1.25L19 23l1.25-2.75L23 19l-2.75-1.25L19 15z"/></svg>
                                <svg class="w-3 h-3 animate-spin" wire:loading wire:target="autoCategorizeSingle" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg>
                                Auto-Select (AI)
                            </button>
                        </div>
                        <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
                            @foreach($availableCategories as $category)
                                <label for="cat-{{ $category->id }}" class="flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-all select-none {{ in_array($category->id, $selectedCategories) ? 'bg-amber-600/10 border-amber-500 text-amber-400 shadow-lg shadow-amber-500/10' : 'bg-white/5 border-amber-500/20 text-slate-500 hover:border-amber-500/30' }}">
                                    <input type="checkbox" wire:model.live="selectedCategories" id="cat-{{ $category->id }}" value="{{ $category->id }}" class="hidden">
                                    <span class="text-[10px] font-black uppercase tracking-widest">{{ $category->name }}</span>
                                </label>
                            @endforeach
                        </div>
                        @error('selectedCategories') <span class="text-rose-500 text-[10px] font-bold">{{ $message }}</span> @enderror
                    </div>

                    <div class="flex items-center gap-3 p-4 bg-white/5 rounded-2xl border border-amber-500/20">
                        <input type="checkbox" wire:model="is_active" id="is_active" class="w-5 h-5 rounded border-amber-500/30 bg-slate-800 text-amber-600 focus:ring-amber-500/70">
                        <label for="is_active" class="text-sm font-bold text-slate-300 select-none">Active for Onboarding</label>
                    </div>

                    <div class="flex gap-3 pt-4 shrink-0">
                        <button type="button" wire:click="closeModal" class="flex-1 py-4 bg-white/5 hover:bg-white/10 text-white rounded-2xl font-black text-xs uppercase tracking-widest transition-all">Cancel</button>
                        <button type="submit" class="flex-1 py-4 bg-amber-600 hover:bg-amber-500 text-white rounded-2xl font-black text-xs uppercase tracking-widest transition-all shadow-lg shadow-amber-600/40">Save Menu</button>
                    </div>
                </form>
            </div>
        </div>
    @endif
</div>
