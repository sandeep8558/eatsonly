<div class="min-h-screen bg-black flex items-center justify-center py-20 px-4">
    <div class="max-w-md w-full bg-black/50 backdrop-blur-2xl border border-amber-500/30 rounded-[2.5rem] p-10 shadow-2xl text-center relative overflow-hidden">
        <!-- Background Glow -->
        <div class="absolute -top-20 -right-20 w-40 h-40 bg-amber-600/20 blur-[100px] rounded-full"></div>
        
        <div class="relative z-10">
            <h2 class="text-3xl font-black text-white mb-2">Checkout</h2>
            <p class="text-slate-500 mb-10 text-sm">Review your plan details and complete payment.</p>

            @if(session()->has('error'))
                <div class="mb-8 p-4 bg-rose-500/10 border border-rose-500/20 rounded-2xl text-rose-400 text-sm font-bold">
                    {{ session('error') }}
                </div>
            @endif

            <div class="bg-white/5 border border-amber-500/20 rounded-3xl p-6 mb-10 text-left">
                <div class="flex justify-between items-center mb-4">
                    <span class="text-slate-400 text-xs font-black uppercase tracking-widest">Selected Plan</span>
                    <span class="px-3 py-1 bg-amber-500/10 text-amber-400 rounded-full text-[10px] font-black uppercase tracking-widest border border-amber-500/40">{{ $plan->name }}</span>
                </div>
                <div class="flex justify-between items-center mb-6">
                    <span class="text-slate-400 text-xs font-black uppercase tracking-widest">Outlets Selected</span>
                    <span class="px-3 py-1 bg-white/10 text-white rounded-full text-xs font-bold border border-white/20">{{ $outlets }}</span>
                </div>
                <div class="mt-4 pt-4 border-t border-amber-500/20 flex justify-between items-baseline mb-6">
                    <span class="text-4xl font-black text-white">₹{{ number_format($amount) }}</span>
                    <span class="text-slate-500 text-sm">/ {{ $period }}</span>
                </div>
                <div class="mt-2 space-y-3">
                    @foreach(array_slice($plan->list ?? [], 0, 3) as $feature)
                        <div class="flex items-center gap-2 text-slate-400 text-xs">
                            <svg class="w-4 h-4 text-emerald-500" fill="currentColor" viewBox="0 0 20 20"><path d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"></path></svg>
                            {{ $feature }}
                        </div>
                    @endforeach
                </div>
            </div>

            @if($orderId)
                <button id="rzp-button1" class="w-full py-5 bg-amber-600 hover:bg-amber-500 text-white rounded-2xl font-black text-lg transition-all shadow-xl shadow-amber-600/30 transform hover:-translate-y-1">
                    Pay Securely with Razorpay
                </button>
            @endif

            <a href="{{ route('pricing') }}" class="inline-block mt-8 text-slate-500 hover:text-white text-xs font-bold transition-colors">
                Cancel and Go Back
            </a>
        </div>
    </div>

    @if($orderId)
        @push('scripts')
            <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
            <script>
                document.addEventListener('livewire:navigated', function() {
                    const rzpButton = document.getElementById('rzp-button1');
                    if (!rzpButton) return;

                    const initializeRazorpay = () => {
                        if (typeof Razorpay === 'undefined') {
                            setTimeout(initializeRazorpay, 100);
                            return;
                        }

                        var options = {
                            "key": "{{ $razorpayKey }}",
                            "amount": "{{ $amount * 100 }}",
                            "currency": "INR",
                            "name": "EatsOnly",
                            "description": "Subscription for {{ $plan->name }}",
                            "image": "https://ui-avatars.com/api/?name=EatsOnly&background=6366f1&color=fff",
                            "order_id": "{{ $orderId }}",
                            "handler": function (response){
                                @this.handlePayment(response.razorpay_payment_id, response.razorpay_signature);
                            },
                            "prefill": {
                                "name": "{{ auth()->user()->name }}",
                                "email": "{{ auth()->user()->email }}",
                                "contact": "{{ auth()->user()->mobile }}"
                            },
                            "theme": {
                                "color": "#6366f1"
                            }
                        };
                        var rzp1 = new Razorpay(options);
                        rzpButton.onclick = function(e){
                            rzp1.open();
                            e.preventDefault();
                        }
                    };

                    initializeRazorpay();
                });
            </script>
        @endpush
    @endif
</div>
