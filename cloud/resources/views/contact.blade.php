<x-guest-layout
    title="Contact Us | EatsOnly Support & Sales"
    description="Have questions? Get in touch with our team. Whether you need a demo, technical support, or enterprise pricing, we're here to help you scale your restaurant."
    keywords="contact EatsOnly, restaurant software support, POS sales, restaurant management help"
>
    <div class="py-20">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="grid lg:grid-cols-2 gap-20 items-center">
                <!-- Content Side -->
                <div>
                    <h1 class="text-4xl md:text-6xl font-extrabold tracking-tight mb-8">
                        Let's Talk <span class="gradient-text">Restaurant Growth</span>
                    </h1>
                    <p class="text-lg text-slate-400 mb-12 leading-relaxed">
                        Our team of experts is ready to help you optimize your kitchen, streamline your staff, and maximize your profits. Reach out today for a personalized consultation.
                    </p>
                    
                    <div class="space-y-8">
                        <div class="flex items-center gap-6 group">
                            <div class="w-14 h-14 bg-amber-500/10 rounded-2xl flex items-center justify-center border border-amber-500/40 group-hover:scale-110 transition-transform">
                                <svg class="w-6 h-6 text-amber-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
                            </div>
                            <div>
                                <h4 class="text-white font-bold text-lg">Email Us</h4>
                                <p class="text-slate-400">leenaitsolutions@gmail.com</p>
                            </div>
                        </div>
                        <div class="flex items-center gap-6 group">
                            <div class="w-14 h-14 bg-emerald-500/10 rounded-2xl flex items-center justify-center border border-emerald-500/20 group-hover:scale-110 transition-transform">
                                <svg class="w-6 h-6 text-emerald-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg>
                            </div>
                            <div>
                                <h4 class="text-white font-bold text-lg">Visit Us</h4>
                                <p class="text-slate-400">Sarvodaya Nagar, Jambhul Road, Ambernath West 421505 MS India</p>
                            </div>
                        </div>
                        <div class="flex items-center gap-6 group">
                            <div class="w-14 h-14 bg-blue-500/10 rounded-2xl flex items-center justify-center border border-blue-500/20 group-hover:scale-110 transition-transform">
                                <svg class="w-6 h-6 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path></svg>
                            </div>
                            <div>
                                <h4 class="text-white font-bold text-lg">Call Us</h4>
                                <p class="text-slate-400">+91 90961 89183</p>
                            </div>
                        </div>
                    </div>

                    <div class="mt-16 p-8 glass rounded-3xl border border-amber-500/20 relative overflow-hidden">
                        <div class="absolute top-0 right-0 p-4 opacity-10">
                            <svg class="w-20 h-20 text-white" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/></svg>
                        </div>
                        <h4 class="text-white font-bold mb-2">Need immediate help?</h4>
                        <p class="text-slate-400 text-sm mb-4">Our support team is available 24/7 for all Pro and Pro Max customers via the in-app chat.</p>
                        <a href="#" class="text-amber-400 font-bold text-sm hover:text-indigo-300 transition-colors">Launch Help Center →</a>
                    </div>
                </div>

                <!-- Form Side -->
                <div class="relative">
                    <div class="absolute -inset-4 bg-amber-500/10 blur-3xl rounded-full opacity-50"></div>
                    <div class="relative glass p-8 md:p-12 rounded-[3rem] border border-amber-500/30 shadow-2xl">
                        @if(session('success'))
                            <div class="mb-8 p-4 bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 rounded-2xl animate-fade-in">
                                {{ session('success') }}
                            </div>
                        @endif
                        <form action="{{ route('contact.submit') }}" method="POST" class="space-y-6">
                            @csrf
                            <div class="grid md:grid-cols-2 gap-6">
                                <div class="space-y-2">
                                    <label class="text-sm font-semibold text-slate-300 ml-1">First Name</label>
                                    <input type="text" name="first_name" required placeholder="Jane" class="w-full bg-white/5 border border-amber-500/30 rounded-2xl px-5 py-4 text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500 transition-all">
                                </div>
                                <div class="space-y-2">
                                    <label class="text-sm font-semibold text-slate-300 ml-1">Last Name</label>
                                    <input type="text" name="last_name" required placeholder="Doe" class="w-full bg-white/5 border border-amber-500/30 rounded-2xl px-5 py-4 text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500 transition-all">
                                </div>
                            </div>
                            <div class="grid md:grid-cols-2 gap-6">
                                <div class="space-y-2">
                                    <label class="text-sm font-semibold text-slate-300 ml-1">Email Address</label>
                                    <input type="email" name="email" required placeholder="jane@example.com" class="w-full bg-white/5 border border-amber-500/30 rounded-2xl px-5 py-4 text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500 transition-all">
                                </div>
                                <div class="space-y-2">
                                    <label class="text-sm font-semibold text-slate-300 ml-1">Mobile Number</label>
                                    <input type="text" name="mobile" required placeholder="9096189183" class="w-full bg-white/5 border border-amber-500/30 rounded-2xl px-5 py-4 text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500 transition-all">
                                </div>
                            </div>
                            <div class="space-y-2">
                                <label class="text-sm font-semibold text-slate-300 ml-1">Message</label>
                                <textarea name="message" required rows="4" placeholder="How can we help you?" class="w-full bg-white/5 border border-amber-500/30 rounded-2xl px-5 py-4 text-white focus:outline-none focus:border-amber-500 focus:ring-1 focus:ring-amber-500 transition-all resize-none"></textarea>
                            </div>
                            <button type="submit" class="w-full py-5 bg-amber-600 text-white rounded-2xl font-bold text-lg hover:bg-amber-500 transition-all shadow-xl shadow-amber-600/30 transform hover:-translate-y-1">
                                Send Message
                            </button>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-guest-layout>
