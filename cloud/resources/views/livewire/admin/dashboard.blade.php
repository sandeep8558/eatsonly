<div class="p-6 sm:p-8">
    <!-- Header Section -->
    <div class="flex flex-col md:flex-row md:items-center justify-between gap-6 mb-10">
        <div>
            <h2 class="text-3xl font-black text-white tracking-tight">Platform Overview</h2>
            <p class="text-slate-500 mt-1 text-sm font-medium">Real-time health monitoring of your SaaS business.</p>
        </div>
        <div class="flex items-center gap-3">
            <span class="px-4 py-2 bg-emerald-500/10 text-emerald-400 rounded-xl text-xs font-black uppercase tracking-widest border border-emerald-500/20">
                System Live
            </span>
        </div>
    </div>

    <!-- Stats Grid -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-6 mb-10">
        <!-- Total Revenue -->
        <div class="bg-amber-600 rounded-[2rem] p-8 text-white shadow-2xl shadow-amber-600/40 relative overflow-hidden group">
            <div class="absolute top-0 right-0 p-4 opacity-10 translate-x-1/4 -translate-y-1/4 group-hover:scale-110 transition-transform">
                <svg class="w-32 h-32" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 14h-2v-2h2v2zm0-4h-2V7h2v5z"/></svg>
            </div>
            <p class="text-amber-100/60 text-[10px] font-black uppercase tracking-widest mb-1">Total Revenue</p>
            <h3 class="text-3xl font-black mb-4">₹{{ number_format($stats['total_revenue']) }}</h3>
            <div class="flex items-center gap-2 text-xs font-bold bg-white/10 w-fit px-3 py-1 rounded-full">
                <span class="text-amber-100">Today: ₹{{ number_format($stats['today_revenue']) }}</span>
            </div>
        </div>

        <!-- Active Users -->
        <div class="bg-black/50 border border-amber-500/20 rounded-[2rem] p-8 hover:border-emerald-500/30 transition-all group">
            <div class="flex items-center justify-between mb-4">
                <div class="w-12 h-12 bg-emerald-500/10 rounded-2xl flex items-center justify-center text-emerald-400 border border-emerald-500/20">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path></svg>
                </div>
                <span class="text-[10px] font-black text-emerald-500 uppercase tracking-widest bg-emerald-500/10 px-2 py-1 rounded-md">Paid</span>
            </div>
            <p class="text-slate-500 text-[10px] font-black uppercase tracking-widest mb-1">Active Customers</p>
            <h3 class="text-3xl font-black text-white">{{ $stats['active_users'] }}</h3>
            <p class="text-slate-600 text-xs mt-1 font-bold">out of {{ $stats['total_users'] }} total users</p>
        </div>

        <!-- Monthly Volume -->
        <div class="bg-black/50 border border-amber-500/20 rounded-[2rem] p-8 hover:border-amber-500/30 transition-all">
            <div class="flex items-center justify-between mb-4">
                <div class="w-12 h-12 bg-amber-500/10 rounded-2xl flex items-center justify-center text-amber-400 border border-amber-500/40">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path></svg>
                </div>
            </div>
            <p class="text-slate-500 text-[10px] font-black uppercase tracking-widest mb-1">Monthly Revenue</p>
            <h3 class="text-3xl font-black text-white">₹{{ number_format($stats['monthly_revenue']) }}</h3>
            <p class="text-slate-600 text-xs mt-1 font-bold">for {{ now()->format('F Y') }}</p>
        </div>

        <!-- Expired Users -->
        <div class="bg-black/50 border border-amber-500/20 rounded-[2rem] p-8 hover:border-rose-500/30 transition-all">
            <div class="flex items-center justify-between mb-4">
                <div class="w-12 h-12 bg-rose-500/10 rounded-2xl flex items-center justify-center text-rose-400 border border-rose-500/20">
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                </div>
                <span class="text-[10px] font-black text-rose-500 uppercase tracking-widest bg-rose-500/10 px-2 py-1 rounded-md">Renewals Due</span>
            </div>
            <p class="text-slate-500 text-[10px] font-black uppercase tracking-widest mb-1">Expired Users</p>
            <h3 class="text-3xl font-black text-white">{{ $stats['expired_users'] }}</h3>
            <p class="text-slate-600 text-xs mt-1 font-bold">lost or pending renewals</p>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <!-- Recent Payments -->
        <div class="lg:col-span-2 bg-black/30 border border-amber-500/20 rounded-[2.5rem] overflow-hidden">
            <div class="p-8 border-b border-amber-500/20 flex items-center justify-between">
                <div>
                    <h4 class="text-xl font-black text-white">Recent Transactions</h4>
                    <p class="text-slate-500 text-xs font-medium">Latest incoming payments from customers.</p>
                </div>
                <a href="{{ route('admin.payments') }}" class="text-amber-400 text-xs font-black uppercase tracking-widest hover:text-indigo-300 transition-colors">View All</a>
            </div>
            <div class="p-4 overflow-x-auto">
                <table class="w-full">
                    <thead>
                        <tr class="text-left">
                            <th class="px-4 py-3 text-[10px] font-black uppercase tracking-widest text-slate-500">Customer</th>
                            <th class="px-4 py-3 text-[10px] font-black uppercase tracking-widest text-slate-500">Plan</th>
                            <th class="px-4 py-3 text-[10px] font-black uppercase tracking-widest text-slate-500">Amount</th>
                            <th class="px-4 py-3 text-[10px] font-black uppercase tracking-widest text-slate-500">Date</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-white/5">
                        @foreach($recentPayments as $payment)
                            <tr class="group hover:bg-white/5 transition-colors">
                                <td class="px-4 py-4">
                                    <div class="flex items-center gap-3">
                                        <div class="w-8 h-8 rounded-full bg-slate-800 flex items-center justify-center text-[10px] font-bold text-white border border-amber-500/30">
                                            {{ substr($payment->user->name, 0, 1) }}
                                        </div>
                                        <div>
                                            <p class="text-xs font-bold text-white">{{ $payment->user->name }}</p>
                                            <p class="text-[10px] text-slate-500">{{ $payment->user->email }}</p>
                                        </div>
                                    </div>
                                </td>
                                <td class="px-4 py-4">
                                    <span class="px-2 py-0.5 bg-amber-500/10 text-amber-400 rounded-md text-[10px] font-black uppercase tracking-widest border border-amber-500/40">
                                        {{ $payment->subscription->plan->name ?? 'N/A' }}
                                    </span>
                                </td>
                                <td class="px-4 py-4">
                                    <p class="text-xs font-black text-white">₹{{ number_format($payment->amount) }}</p>
                                </td>
                                <td class="px-4 py-4">
                                    <p class="text-[10px] font-bold text-slate-500 uppercase">{{ $payment->created_at->diffForHumans() }}</p>
                                </td>
                            </tr>
                        @endforeach
                    </tbody>
                </table>
            </div>
        </div>

        <!-- Quick Insights -->
        <div class="space-y-6">
            <div class="bg-amber-600/5 border border-amber-500/30 rounded-[2.5rem] p-8">
                <h4 class="text-lg font-black text-white mb-6">Business Growth</h4>
                <div class="space-y-6">
                    <div>
                        <div class="flex justify-between text-xs font-bold mb-2">
                            <span class="text-slate-400 uppercase tracking-widest">Active Rate</span>
                            <span class="text-white">{{ $stats['total_users'] > 0 ? round(($stats['active_users'] / $stats['total_users']) * 100) : 0 }}%</span>
                        </div>
                        <div class="h-2 bg-slate-800 rounded-full overflow-hidden">
                            <div class="h-full bg-emerald-500" style="width: {{ $stats['total_users'] > 0 ? ($stats['active_users'] / $stats['total_users']) * 100 : 0 }}%"></div>
                        </div>
                    </div>
                    <div>
                        <div class="flex justify-between text-xs font-bold mb-2">
                            <span class="text-slate-400 uppercase tracking-widest">Expansion</span>
                            <span class="text-white">{{ $stats['total_restaurants'] }} Outlets</span>
                        </div>
                        <p class="text-[10px] text-slate-500 font-medium">Average {{ $stats['total_users'] > 0 ? round($stats['total_restaurants'] / $stats['total_users'], 1) : 0 }} outlets per customer.</p>
                    </div>
                </div>
            </div>

            <div class="bg-white p-8 rounded-[2.5rem] shadow-2xl shadow-amber-600/40">
                <p class="text-slate-500 text-[10px] font-black uppercase tracking-widest mb-1">Projected Annual</p>
                <h3 class="text-2xl font-black text-black">₹{{ number_format($stats['monthly_revenue'] * 12) }}</h3>
                <p class="text-slate-400 text-xs mt-1 font-bold">based on current monthly run rate</p>
                <button class="w-full mt-6 py-4 bg-amber-600 hover:bg-indigo-700 text-white rounded-2xl font-black transition-all text-xs uppercase tracking-widest">
                    Download Report
                </button>
            </div>
        </div>
    </div>
</div>
