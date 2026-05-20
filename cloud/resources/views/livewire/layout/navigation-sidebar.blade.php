<div class="space-y-4">
    <div class="flex items-center gap-3 px-2">
        <div class="w-10 h-10 rounded-xl bg-slate-800 border border-amber-500/20 flex items-center justify-center text-amber-400 font-bold overflow-hidden">
            <img src="https://ui-avatars.com/api/?name={{ urlencode(auth()->user()->name) }}&background=6366f1&color=fff" alt="{{ auth()->user()->name }}">
        </div>
        <div class="flex-grow min-w-0">
            <p class="text-sm font-bold text-white truncate">{{ auth()->user()->name }}</p>
            <p class="text-[10px] text-amber-500/60 truncate uppercase tracking-widest font-black">
                {{ auth()->user()->roles->pluck('display_name')->join(' | ') }}
            </p>
        </div>
    </div>

    <div class="pt-2">
        <button wire:click="logout" class="flex items-center gap-3 w-full p-1.5 px-3 rounded-lg bg-rose-500/10 hover:bg-rose-500/20 transition-all border border-rose-500/20 group">
            <div class="w-7 h-7 rounded-md bg-rose-500/10 flex items-center justify-center text-rose-400 transition-colors shrink-0">
                <svg class="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"></path></svg>
            </div>
            <span class="text-[10px] font-black text-rose-400 uppercase tracking-widest">Logout</span>
        </button>
    </div>
</div>
