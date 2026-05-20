<div class="p-6 sm:p-8">
    <!-- Cinematic Header & Stats -->
    <div class="grid grid-cols-1 lg:grid-cols-4 gap-6 mb-12">
        <div class="lg:col-span-2">
            <h2 class="text-4xl font-black text-white tracking-tighter mb-2">Platform Treasury</h2>
            <p class="text-slate-500 text-sm font-medium">Real-time oversight of all subscription transactions and financial health.</p>
        </div>
        
        <div class="bg-amber-600 rounded-[2rem] p-6 shadow-xl shadow-amber-600/40 flex flex-col justify-between">
            <span class="text-indigo-200 text-[10px] font-black uppercase tracking-widest">Total Revenue</span>
            <div class="mt-2">
                <h3 class="text-3xl font-black text-white">₹{{ number_format(\App\Models\Payment::where('status', 'success')->sum('amount')) }}</h3>
                <p class="text-indigo-200/60 text-[10px] font-bold mt-1 uppercase">Processed Successfully</p>
            </div>
        </div>

        <div class="bg-black/50 border border-amber-500/20 rounded-[2rem] p-6 flex flex-col justify-between">
            <span class="text-slate-500 text-[10px] font-black uppercase tracking-widest">Success Rate</span>
            <div class="mt-2">
                @php
                    $totalCount = \App\Models\Payment::count();
                    $successCount = \App\Models\Payment::where('status', 'success')->count();
                    $rate = $totalCount > 0 ? round(($successCount / $totalCount) * 100, 1) : 0;
                @endphp
                <h3 class="text-3xl font-black text-white">{{ $rate }}%</h3>
                <div class="w-full bg-white/5 h-1.5 rounded-full mt-2 overflow-hidden">
                    <div class="bg-emerald-500 h-full rounded-full" style="width: {{ $rate }}%"></div>
                </div>
            </div>
        </div>
    </div>

    <!-- Smart Filter Action Bar -->
    <div class="bg-black/30 border border-amber-500/20 rounded-[2.5rem] p-4 mb-10 flex flex-col lg:flex-row items-center gap-4">
        <div class="relative flex-1 w-full">
            <div class="absolute inset-y-0 left-0 pl-6 flex items-center pointer-events-none">
                <svg class="h-5 w-5 text-amber-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
            </div>
            <input wire:model.live="search" type="text" placeholder="Filter by Payment ID, Customer, or Order..." 
                class="block w-full pl-14 pr-6 py-4 bg-transparent border-none rounded-2xl text-sm text-white placeholder-slate-600 focus:ring-0 transition-all">
        </div>

        <div class="flex items-center gap-3 w-full lg:w-auto pr-2">
            <select wire:model.live="status" class="px-6 py-3 bg-white/5 border border-amber-500/20 rounded-2xl text-xs font-black text-slate-300 uppercase tracking-widest focus:outline-none focus:ring-2 focus:ring-amber-500/70 transition-all cursor-pointer">
                <option value="all">All Status</option>
                <option value="success">Success</option>
                <option value="failed">Failed</option>
            </select>

            <input wire:model.live="dateFilter" type="date" 
                class="px-6 py-3 bg-white/5 border border-amber-500/20 rounded-2xl text-xs font-black text-slate-300 uppercase tracking-widest focus:outline-none focus:ring-2 focus:ring-amber-500/70 transition-all cursor-pointer">

            <select wire:model.live="perPage" class="px-6 py-3 bg-white/5 border border-amber-500/20 rounded-2xl text-xs font-black text-slate-300 uppercase tracking-widest focus:outline-none focus:ring-2 focus:ring-amber-500/70 transition-all cursor-pointer">
                <option value="10">10 Rows</option>
                <option value="25">25 Rows</option>
                <option value="50">50 Rows</option>
            </select>
        </div>
    </div>

    <!-- Cinematic Ledger -->
    <div class="bg-black/20 border border-amber-500/20 rounded-[2.5rem] overflow-hidden">
        <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
                <thead>
                    <tr class="border-b border-amber-500/20 bg-white/[0.02]">
                        <th class="px-8 py-5 text-[10px] font-black uppercase tracking-[0.2em] text-slate-500">Customer Details</th>
                        <th class="px-8 py-5 text-[10px] font-black uppercase tracking-[0.2em] text-slate-500">Transaction ID</th>
                        <th class="px-8 py-5 text-[10px] font-black uppercase tracking-[0.2em] text-slate-500">Plan & Method</th>
                        <th class="px-8 py-5 text-[10px] font-black uppercase tracking-[0.2em] text-slate-500 text-right">Amount & Status</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-white/5">
                    @forelse($payments as $payment)
                        <tr class="group hover:bg-white/[0.02] transition-colors">
                            <td class="px-8 py-6">
                                <div class="flex items-center gap-4">
                                    <div class="relative flex-shrink-0">
                                        <img src="https://ui-avatars.com/api/?name={{ urlencode($payment->user->name) }}&background=6366f1&color=fff&bold=true" 
                                             class="w-11 h-11 rounded-xl border border-amber-500/30 group-hover:border-amber-500/50 transition-all shadow-lg"
                                             alt="{{ $payment->user->name }}">
                                        @if($payment->status === 'success')
                                            <div class="absolute -top-1 -right-1 w-4 h-4 bg-emerald-500 rounded-full border-2 border-black flex items-center justify-center">
                                                <svg class="w-2 h-2 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg>
                                            </div>
                                        @endif
                                    </div>
                                    <div class="min-w-0">
                                        <h3 class="text-white font-bold text-sm truncate">{{ $payment->user->name }}</h3>
                                        <p class="text-slate-500 text-[10px] font-medium truncate">{{ $payment->user->email }}</p>
                                    </div>
                                </div>
                            </td>

                            <td class="px-8 py-6">
                                <div class="flex flex-col gap-1">
                                    <div class="flex items-center gap-2">
                                        <span class="text-slate-200 font-mono text-xs font-bold">{{ $payment->razorpay_payment_id }}</span>
                                        <button onclick="navigator.clipboard.writeText('{{ $payment->razorpay_payment_id }}')" class="text-slate-600 hover:text-amber-400 transition-colors">
                                            <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"></path></svg>
                                        </button>
                                    </div>
                                    <span class="text-slate-600 text-[9px] font-bold uppercase tracking-wider">{{ $payment->created_at->format('M d, Y • h:i A') }}</span>
                                </div>
                            </td>

                            <td class="px-8 py-6">
                                <div class="flex flex-col gap-2">
                                    <span class="px-2.5 py-1 bg-amber-500/10 text-amber-400 rounded-lg text-[9px] font-black uppercase tracking-widest border border-amber-500/40 w-fit">
                                        {{ $payment->subscription->plan->name ?? 'Standard' }}
                                    </span>
                                    <span class="text-slate-400 font-bold text-[10px] uppercase tracking-tighter">{{ $payment->method ?? 'UPI / NetBanking' }}</span>
                                </div>
                            </td>

                            <td class="px-8 py-6 text-right">
                                <div class="flex flex-col items-end gap-3">
                                    <p class="text-xl font-black text-white tracking-tighter">₹{{ number_format($payment->amount) }}</p>
                                    
                                    @if($payment->status === 'success')
                                        <div class="px-3 py-1 bg-emerald-500/10 text-emerald-500 rounded-lg border border-emerald-500/20 flex items-center gap-2">
                                            <div class="w-1 h-1 rounded-full bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.8)]"></div>
                                            <span class="text-[9px] font-black uppercase tracking-widest">Captured</span>
                                        </div>
                                    @elseif($payment->status === 'failed')
                                        <div class="px-3 py-1 bg-rose-500/10 text-rose-500 rounded-lg border border-rose-500/20 flex items-center gap-2">
                                            <div class="w-1 h-1 rounded-full bg-rose-500"></div>
                                            <span class="text-[9px] font-black uppercase tracking-widest">Failed</span>
                                        </div>
                                    @else
                                        <div class="px-3 py-1 bg-amber-500/10 text-amber-500 rounded-lg border border-amber-500/40 flex items-center gap-2">
                                            <div class="w-1 h-1 rounded-full bg-amber-500 animate-pulse"></div>
                                            <span class="text-[9px] font-black uppercase tracking-widest">Pending</span>
                                        </div>
                                    @endif
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="py-20 text-center">
                                <div class="w-20 h-20 bg-slate-800/50 rounded-full flex items-center justify-center mx-auto mb-6">
                                    <svg class="w-10 h-10 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"></path></svg>
                                </div>
                                <h3 class="text-xl font-bold text-slate-400">No transactions found</h3>
                                <p class="text-slate-500 text-sm mt-2">Try adjusting your filters or search terms.</p>
                            </td>
                        </tr>
                    @endforelse
                </tbody>
            </table>
        </div>
    </div>

    <!-- Pagination -->
    <div class="mt-8">
        {{ $payments->links() }}
    </div>
</div>
