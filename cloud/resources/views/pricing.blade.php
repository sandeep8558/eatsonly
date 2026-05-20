<x-guest-layout
    title="Pricing Plans | EatsOnly - Flexible Subscriptions for Any Size"
    description="Choose the perfect plan for your restaurant. Basic, Pro, and Pro Max tiers designed to scale with your business. Transparent pricing, no hidden fees."
    keywords="restaurant software pricing, POS subscription, restaurant SaaS costs, affordable POS"
>
    <!-- Pricing Header -->
    <section class="pt-20 pb-16">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
            <h1 class="text-4xl md:text-6xl font-extrabold tracking-tight mb-6">
                Scalable Pricing for <span class="gradient-text">Every Restaurant</span>
            </h1>
            <p class="text-lg text-slate-400 max-w-2xl mx-auto">
                No hidden fees. No long-term contracts. Just powerful software designed to help you succeed.
            </p>
        </div>
    </section>

    <!-- Pricing Grid -->
    <section class="py-20" x-data="{ billingPeriod: 'monthly' }">
        <div class="mx-auto px-4 sm:px-6 lg:px-8 {{ (count($plans) == 2 || count($plans) == 4) ? 'max-w-5xl' : 'max-w-7xl' }}">
            
            <!-- Billing Toggle -->
            <div class="flex items-center justify-center gap-4 mb-16">
                <span class="text-sm font-bold" :class="billingPeriod === 'monthly' ? 'text-white' : 'text-slate-500'">Monthly</span>
                <button @click="billingPeriod = (billingPeriod === 'monthly' ? 'yearly' : 'monthly')" 
                    class="relative w-14 h-8 rounded-full bg-slate-800 border border-amber-500/30 transition-colors focus:outline-none">
                    <div class="absolute top-1 left-1 w-6 h-6 rounded-full bg-amber-600 transition-transform duration-300 shadow-lg shadow-amber-600/40"
                        :class="billingPeriod === 'yearly' ? 'translate-x-6' : 'translate-x-0'"></div>
                </button>
                <div class="flex items-center gap-2">
                    <span class="text-sm font-bold" :class="billingPeriod === 'yearly' ? 'text-white' : 'text-slate-500'">Yearly</span>
                    <span class="px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 text-[10px] font-black uppercase tracking-widest border border-emerald-500/20">Save ~20%</span>
                </div>
            </div>

            <div class="grid grid-cols-1 {{ count($plans) == 1 ? 'max-w-md mx-auto' : (count($plans) == 3 ? 'md:grid-cols-3' : 'md:grid-cols-2') }} gap-8">
                @forelse($plans as $index => $plan)
                    @php
                        $isMiddle = count($plans) == 3 && $index == 1;
                        $accentColor = $isMiddle ? 'amber' : ($index == 0 ? 'slate' : 'cyan');
                        $iconPath = $isMiddle 
                            ? 'M5 3v4M3 5h4M6 17v4m-2-2h4m5-16l2.286 6.857L21 12l-5.714 2.143L13 21l-2.286-6.857L5 12l5.714-2.143L13 3z'
                            : ($index == 0 
                                ? 'M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4'
                                : 'M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z');
                    @endphp

                    <div x-data="{ selectedOutlets: {{ $plan->outlets }} }" class="relative glass p-10 rounded-[2.5rem] flex flex-col border {{ $isMiddle ? 'border-amber-500/50 bg-amber-500/[0.02] transform md:-translate-y-4 shadow-2xl shadow-amber-500/10' : 'border-slate-500/20 hover:border-slate-400/40' }} transition-all group">
                        @if($isMiddle)
                            <div class="absolute -top-4 left-1/2 -translate-x-1/2 bg-amber-500 text-black text-[10px] font-black uppercase tracking-widest px-4 py-1.5 rounded-full shadow-lg">Most Popular</div>
                        @endif

                        <div class="w-12 h-12 bg-{{ $accentColor }}-500/10 rounded-xl flex items-center justify-center mb-6 border border-{{ $accentColor }}-500/20">
                            <svg class="w-6 h-6 text-{{ $accentColor }}-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="{{ $iconPath }}"></path></svg>
                        </div>

                        <h3 class="text-xl font-bold text-{{ $accentColor }}-400 mb-2">{{ $plan->name }}</h3>
                        
                        <div class="flex flex-col gap-1 mb-6 h-20 justify-center">
                            <div class="flex items-baseline gap-1">
                                <span class="text-5xl font-bold text-white transition-all duration-300" x-text="billingPeriod === 'monthly' ? '₹' + ({{ $plan->monthly_price }}{{ $plan->is_outlets_fixed ? '' : ' * selectedOutlets' }}).toLocaleString('en-IN') : '₹' + ({{ $plan->yearly_price }}{{ $plan->is_outlets_fixed ? '' : ' * selectedOutlets' }}).toLocaleString('en-IN')"></span>
                                <span class="text-slate-400 text-lg transition-all duration-300" x-text="billingPeriod === 'monthly' ? '/mo' : '/yr'"></span>
                            </div>
                            <template x-if="billingPeriod === 'yearly'">
                                <p class="text-[10px] font-bold text-emerald-400 uppercase tracking-widest">Billed annually</p>
                            </template>
                        </div>

                        <p class="text-slate-400 text-sm mb-4 leading-relaxed h-10">{{ $plan->description }}</p>

                        @if(!$plan->is_outlets_fixed)
                            <div class="mb-6 bg-white/5 border border-amber-500/20 rounded-2xl p-3 flex items-center justify-between">
                                <span class="text-xs font-bold text-slate-400 uppercase tracking-widest ml-2">Outlets</span>
                                <div class="flex items-center gap-3">
                                    <button @click="if(selectedOutlets > {{ $plan->outlets }}) selectedOutlets--" class="w-8 h-8 rounded-lg bg-white/10 flex items-center justify-center text-white hover:bg-amber-500/20 disabled:opacity-30 disabled:cursor-not-allowed transition-colors" :disabled="selectedOutlets <= {{ $plan->outlets }}">-</button>
                                    <span class="text-white font-black w-6 text-center" x-text="selectedOutlets"></span>
                                    <button @click="selectedOutlets++" class="w-8 h-8 rounded-lg bg-white/10 flex items-center justify-center text-white hover:bg-amber-500/20 transition-colors">+</button>
                                </div>
                            </div>
                        @else
                            <div class="mb-6 border border-transparent rounded-2xl p-3 flex items-center justify-between opacity-70">
                                <span class="text-xs font-bold text-slate-400 uppercase tracking-widest ml-2">Included</span>
                                <span class="text-white text-sm font-bold">{{ $plan->outlets }} Outlet{{ $plan->outlets > 1 ? 's' : '' }}</span>
                            </div>
                        @endif

                        <ul class="space-y-4 mb-10 flex-grow text-slate-300">
                            @foreach($plan->list ?? [] as $feature)
                                <li class="flex items-center gap-3 text-sm font-medium">
                                    <svg class="w-5 h-5 text-{{ $accentColor }}-500" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"></path></svg>
                                    {{ $feature }}
                                </li>
                            @endforeach
                        </ul>

                        @php
                            $buttonText = $isMiddle ? 'Go '.$plan->name : 'Get Started';
                            if ($currentSubscription) {
                                if ($currentSubscription->pricing_plan_id == $plan->id) {
                                    $buttonText = 'Renew Plan';
                                } elseif ($plan->monthly_price > ($currentSubscription->plan->monthly_price ?? 0)) {
                                    $buttonText = 'Upgrade Now';
                                }
                            }
                        @endphp

                        <a :href="'/checkout/' + {{ $plan->id }} + '/' + billingPeriod + '?outlets=' + selectedOutlets" class="w-full py-4 rounded-2xl {{ ($currentSubscription && $currentSubscription->pricing_plan_id == $plan->id) ? 'bg-emerald-600 hover:bg-emerald-500 shadow-xl shadow-emerald-600/30' : ($isMiddle ? 'bg-amber-600 hover:bg-amber-500 shadow-xl shadow-amber-600/30' : 'bg-white/5 hover:bg-white/10 border border-amber-500/30') }} text-white font-bold text-center transition-all">
                            {{ $buttonText }}
                        </a>
                    </div>
                @empty
                    <div class="col-span-full py-20 text-center">
                        <p class="text-slate-500">Custom plans coming soon. Please contact us for a quote.</p>
                    </div>
                @endforelse
            </div>
        </div>
    </section>

    <!-- FAQ Section -->
    <section class="py-32">
        <div class="max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">
            <h2 class="text-3xl font-bold text-white mb-12 text-center">Frequently Asked Questions</h2>
            <div class="space-y-6">
                <div class="glass p-6 rounded-2xl border border-amber-500/20">
                    <h4 class="text-white font-bold mb-2">Can I switch plans later?</h4>
                    <p class="text-slate-400 text-sm">Yes! You can upgrade or downgrade your plan at any time directly from your dashboard. Changes are prorated instantly.</p>
                </div>
                <div class="glass p-6 rounded-2xl border border-amber-500/20">
                    <h4 class="text-white font-bold mb-2">What happens if my internet goes down?</h4>
                    <p class="text-slate-400 text-sm">EatsOnly is offline-first. You can keep taking orders and generating receipts. All data will sync to the cloud once the connection is restored.</p>
                </div>
                <div class="glass p-6 rounded-2xl border border-amber-500/20">
                    <h4 class="text-white font-bold mb-2">Are there any hidden transaction fees?</h4>
                    <p class="text-slate-400 text-sm">No. We only charge a flat monthly subscription fee. Your payment processor may have their own fees, but we don't take a cut.</p>
                </div>
            </div>
        </div>
    </section>
</x-guest-layout>
