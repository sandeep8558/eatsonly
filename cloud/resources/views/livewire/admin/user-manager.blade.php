<div>
    <x-slot name="header">
        <h2 class="font-bold text-2xl text-white leading-tight">
            {{ __('User Manager') }}
        </h2>
    </x-slot>

    <div class="py-12">
        <div class="max-w-7xl mx-auto sm:px-6 lg:px-8">
            <!-- Flash Messages -->
            @if (session()->has('message'))
                <div class="mb-6 p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 font-bold flex items-center gap-3">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>
                    {{ session('message') }}
                </div>
            @endif

            @if (session()->has('error'))
                <div class="mb-6 p-4 rounded-2xl bg-rose-500/10 border border-rose-500/20 text-rose-400 font-bold flex items-center gap-3">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                    {{ session('error') }}
                </div>
            @endif

            <!-- Header Actions & Search -->
            <div class="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-6 mb-10">
                <div class="w-full lg:w-1/3">
                    <div class="relative group">
                        <input type="text" wire:model.live.debounce.300ms="search" 
                            class="w-full bg-black/50 backdrop-blur-xl border-amber-500/20 rounded-2xl px-12 py-4 text-white focus:border-amber-500 focus:ring-amber-500/40 transition-all"
                            placeholder="Search by name, email or mobile...">
                        <div class="absolute left-4 top-1/2 -translate-y-1/2 text-slate-500 group-focus-within:text-amber-400 transition-colors">
                            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                        </div>
                    </div>
                </div>
                
                <button wire:click="openModal" class="w-full lg:w-auto px-8 py-4 bg-amber-600 hover:bg-amber-500 text-white rounded-2xl font-black transition-all shadow-xl shadow-amber-600/40 flex items-center justify-center gap-3 transform hover:-translate-y-1">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"></path></svg>
                    Add New User
                </button>
            </div>

            <!-- Users List (Full Width Cards) -->
            <div class="space-y-4">
                @forelse($users as $user)
                    <div class="group bg-black/40 backdrop-blur-2xl border border-amber-500/20 rounded-[2.5rem] overflow-hidden shadow-2xl hover:border-amber-500/40 transition-all duration-500">
                        <div class="flex flex-col md:flex-row items-center p-6 md:p-8 gap-6">
                            
                            <!-- Avatar & Name -->
                            <div class="flex items-center gap-6 md:w-1/3 min-w-0">
                                <div class="w-14 h-14 bg-gradient-to-br from-amber-500 to-amber-700 rounded-2xl flex items-center justify-center text-white font-black text-xl shadow-lg">
                                    {{ substr($user->name, 0, 1) }}
                                </div>
                                <div class="min-w-0">
                                    <h4 class="text-xl font-black text-white truncate">{{ $user->name }}</h4>
                                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-black uppercase tracking-widest bg-amber-500/10 text-amber-400 mt-1">
                                         {{ $user->roles->pluck('display_name')->join(' | ') }}
                                     </span>
                                </div>
                            </div>

                            <!-- Contact Info -->
                            <div class="flex flex-col sm:flex-row flex-grow gap-6 md:gap-12 items-start sm:items-center">
                                <div class="flex items-center gap-3 text-slate-400">
                                    <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
                                    <span class="text-sm font-medium">{{ $user->email }}</span>
                                </div>
                                <div class="flex items-center gap-3 text-slate-400">
                                    <svg class="w-4 h-4 text-slate-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path></svg>
                                    <span class="text-sm font-medium">{{ $user->mobile }}</span>
                                </div>
                            </div>

                            <!-- Actions -->
                            <div class="flex items-center gap-2 flex-shrink-0">
                                <button wire:click="edit('{{ $user->id }}')" class="p-2.5 rounded-xl bg-white/5 hover:bg-white/10 text-slate-400 hover:text-white transition-all border border-amber-500/20 shadow-lg shadow-black/20">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"></path></svg>
                                </button>
                                <button onclick="confirm('Are you sure?') || event.stopImmediatePropagation()" wire:click="delete('{{ $user->id }}')" class="p-2.5 rounded-xl bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 transition-all border border-rose-500/20 shadow-lg shadow-rose-500/5">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path></svg>
                                </button>
                            </div>
                        </div>
                    </div>
                @empty
                    <div class="py-20 bg-black/30 rounded-[3rem] border border-dashed border-amber-500/30 flex flex-col items-center justify-center text-center">
                        <div class="w-20 h-20 bg-amber-600/10 rounded-full flex items-center justify-center mb-6 text-amber-400">
                            <svg class="w-10 h-10" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path></svg>
                        </div>
                        <h3 class="text-2xl font-bold text-white mb-2">No users found</h3>
                        <p class="text-slate-500 max-w-xs mx-auto mb-8">Try adjusting your search criteria or add a new user manually.</p>
                        <button wire:click="openModal" class="px-8 py-3 bg-amber-600 text-white rounded-xl font-bold">Add First User</button>
                    </div>
                @endforelse
            </div>

            <!-- Load More -->
            @if($users->hasMorePages())
                <div class="mt-12 flex justify-center">
                    <button wire:click="loadMore" class="px-10 py-4 bg-white/5 hover:bg-white/10 text-white rounded-2xl font-bold border border-amber-500/30 transition-all flex items-center gap-3">
                        <svg class="w-5 h-5 animate-bounce" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
                        Load More Users
                    </button>
                </div>
            @endif
        </div>
    </div>

    <!-- Modal -->
    @if($showModal)
        <div class="fixed inset-0 z-[60] flex items-center justify-center p-4 sm:p-6 overflow-y-auto">
            <div class="fixed inset-0 bg-black/80 backdrop-blur-md" wire:click="closeModal"></div>
            
            <div class="relative bg-black border border-amber-500/30 rounded-[2.5rem] w-full max-w-2xl shadow-2xl overflow-hidden transition-all transform scale-100">
                <div class="p-8 md:p-12">
                    <div class="flex justify-between items-center mb-10">
                        <h2 class="text-3xl font-black text-white">{{ $isEdit ? 'Edit User' : 'Add New User' }}</h2>
                        <button wire:click="closeModal" class="text-slate-500 hover:text-white transition-colors">
                            <svg class="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
                        </button>
                    </div>

                    <form wire:submit.prevent="save" class="space-y-6">
                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div class="space-y-2">
                                <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">Full Name</label>
                                <input type="text" wire:model="name" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-amber-500 focus:ring-amber-500/40" placeholder="John Doe">
                                @error('name') <span class="text-rose-500 text-[10px] ml-2">{{ $message }}</span> @enderror
                            </div>
                            <div class="space-y-2">
                                <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">Email Address</label>
                                <input type="email" wire:model="email" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-amber-500 focus:ring-amber-500/40" placeholder="john@example.com">
                                @error('email') <span class="text-rose-500 text-[10px] ml-2">{{ $message }}</span> @enderror
                            </div>
                        </div>

                        <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div class="space-y-2">
                                <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">Mobile Number</label>
                                <input type="text" wire:model="mobile" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-amber-500 focus:ring-amber-500/40" placeholder="9988776655">
                                @error('mobile') <span class="text-rose-500 text-[10px] ml-2">{{ $message }}</span> @enderror
                            </div>
                        </div>

                        <div class="space-y-4">
                            <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">Assign Roles / Duties</label>
                            <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-3">
                                @foreach($roles as $roleModel)
                                    <label class="relative flex items-center group cursor-pointer">
                                        <input type="checkbox" wire:model="selectedRoles" value="{{ $roleModel->name }}" class="peer sr-only">
                                        <div class="w-full px-4 py-3 bg-white/5 border border-amber-500/10 rounded-xl text-[10px] font-black uppercase tracking-widest text-slate-500 peer-checked:bg-amber-600 peer-checked:text-white peer-checked:border-amber-400 peer-checked:shadow-lg peer-checked:shadow-amber-600/30 transition-all group-hover:bg-white/10 text-center flex items-center justify-center min-h-[60px]">
                                            {{ $roleModel->display_name }}
                                        </div>
                                    </label>
                                @endforeach
                            </div>
                            @error('selectedRoles') <span class="text-rose-500 text-[10px] ml-2">{{ $message }}</span> @enderror
                        </div>

                        <div class="space-y-2">
                            <label class="text-[10px] font-black uppercase tracking-widest text-slate-500 ml-2">Password {{ $isEdit ? '(Leave blank to keep current)' : '' }}</label>
                            <input type="password" wire:model="password" class="w-full bg-white/5 border-amber-500/30 rounded-2xl px-6 py-4 text-white focus:border-amber-500 focus:ring-amber-500/40" placeholder="••••••••">
                            @error('password') <span class="text-rose-500 text-[10px] ml-2">{{ $message }}</span> @enderror
                        </div>

                        <div class="pt-6">
                            <button type="submit" class="w-full py-5 bg-amber-600 hover:bg-amber-500 text-white rounded-2xl font-black text-lg transition-all shadow-xl shadow-amber-600/30 transform hover:-translate-y-1">
                                {{ $isEdit ? 'Update User Information' : 'Create User Account' }}
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    @endif
</div>
