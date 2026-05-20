<div class="flex items-center gap-4">
    <div class="hidden sm:flex flex-col items-end">
        <span class="text-sm font-bold text-white">{{ auth()->user()->name }}</span>
        <span class="text-[10px] text-amber-400 font-black uppercase tracking-widest">
            {{ auth()->user()->roles->pluck('display_name')->join(' | ') }}
        </span>
    </div>
    <div class="w-10 h-10 rounded-full border-2 border-amber-500/40 p-0.5">
        <img src="https://ui-avatars.com/api/?name={{ urlencode(auth()->user()->name) }}&background=6366f1&color=fff" class="w-full h-full rounded-full" alt="">
    </div>
</div>
