<x-app-layout>
    <div class="p-6 sm:p-8" x-data="{ activeTab: 'profile' }">
        <!-- Header Section -->
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-6 mb-10">
            <div>
                <h2 class="text-3xl font-black text-white tracking-tight">Account Settings</h2>
                <p class="text-slate-500 mt-1 text-sm font-medium">Manage your personal information, security, and account preferences.</p>
            </div>
            <div class="flex items-center gap-3">
                <div class="flex items-center gap-2 px-4 py-2 bg-white/5 border border-amber-500/20 rounded-xl">
                    <div class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></div>
                    <span class="text-slate-300 text-xs font-bold uppercase tracking-widest">Active Session</span>
                </div>
            </div>
        </div>

        <!-- Identity & Status Header -->
        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-10">
            <div class="lg:col-span-2 bg-amber-600 rounded-[2.5rem] p-8 text-white shadow-2xl shadow-amber-600/40 relative overflow-hidden group">
                <div class="absolute top-0 right-0 p-4 opacity-10 translate-x-1/4 -translate-y-1/4 group-hover:scale-110 transition-transform">
                    <svg class="w-48 h-48" fill="currentColor" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm0 3c1.66 0 3 1.34 3 3s-1.34 3-3 3-3-1.34-3-3 1.34-3 3-3zm0 14.2c-2.5 0-4.71-1.28-6-3.22.03-1.99 4-3.08 6-3.08 1.99 0 5.97 1.09 6 3.08-1.29 1.94-3.5 3.22-6 3.22z"/></svg>
                </div>
                <div class="flex flex-col md:flex-row md:items-center gap-8 relative z-10">
                    <div class="w-24 h-24 rounded-3xl bg-white/20 flex items-center justify-center text-4xl font-black border border-white/20 shadow-xl">
                        {{ substr(auth()->user()->name, 0, 1) }}
                    </div>
                    <div>
                        <h3 class="text-3xl font-black mb-1">{{ auth()->user()->name }}</h3>
                        <p class="text-amber-100/60 text-sm font-bold uppercase tracking-widest mb-6">{{ auth()->user()->roles->pluck('display_name')->join(' | ') }} Account</p>
                        
                        <div class="flex flex-wrap gap-6">
                            <div class="flex items-center gap-3 text-sm font-bold text-white">
                                <div class="w-8 h-8 rounded-lg bg-white/10 flex items-center justify-center">
                                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg>
                                </div>
                                {{ auth()->user()->email }}
                            </div>
                            @if(auth()->user()->mobile)
                                <div class="flex items-center gap-3 text-sm font-bold text-white">
                                    <div class="w-8 h-8 rounded-lg bg-white/10 flex items-center justify-center">
                                        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path></svg>
                                    </div>
                                    {{ auth()->user()->mobile }}
                                </div>
                            @endif
                        </div>
                    </div>
                </div>
            </div>

            <div class="bg-black/30 border border-amber-500/20 rounded-[2.5rem] p-8 flex flex-col justify-center">
                <p class="text-[10px] font-black uppercase tracking-widest text-slate-500 mb-6 px-2">Account Status</p>
                <div class="space-y-4">
                    <div class="flex items-center justify-between p-4 bg-emerald-500/5 rounded-2xl border border-emerald-500/10">
                        <span class="text-sm font-bold text-slate-300">Email Verified</span>
                        <div class="w-3 h-3 rounded-full bg-emerald-500 shadow-lg shadow-emerald-500/50"></div>
                    </div>
                    <div class="flex items-center justify-between p-4 bg-white/5 rounded-2xl border border-amber-500/20">
                        <span class="text-sm font-bold text-slate-300">Member Since</span>
                        <span class="text-sm font-black text-white">{{ auth()->user()->created_at->format('M Y') }}</span>
                    </div>
                </div>
            </div>
        </div>

        <!-- Tab Navigation -->
        <div class="flex flex-wrap gap-2 mb-10 p-1.5 bg-black/50 border border-amber-500/20 rounded-2xl w-fit">
            <button @click="activeTab = 'profile'" :class="activeTab === 'profile' ? 'bg-amber-600 text-white shadow-lg shadow-amber-600/40' : 'text-slate-500 hover:text-slate-300'" class="px-6 py-3 rounded-xl text-xs font-black uppercase tracking-widest transition-all">
                Profile Information
            </button>
            <button @click="activeTab = 'password'" :class="activeTab === 'password' ? 'bg-amber-600 text-white shadow-lg shadow-amber-600/40' : 'text-slate-500 hover:text-slate-300'" class="px-6 py-3 rounded-xl text-xs font-black uppercase tracking-widest transition-all">
                Update Password
            </button>
            <button @click="activeTab = 'delete'" :class="activeTab === 'delete' ? 'bg-rose-600 text-white shadow-lg shadow-rose-600/20' : 'text-slate-500 hover:text-slate-300'" class="px-6 py-3 rounded-xl text-xs font-black uppercase tracking-widest transition-all">
                Delete Account
            </button>
        </div>

        <!-- Tabbed Content -->
        <div class="max-w-4xl">
            <!-- Profile Information Tab -->
            <div x-show="activeTab === 'profile'" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="opacity-0 translate-y-4" x-transition:enter-end="opacity-100 translate-y-0">
                <div class="bg-black/30 border border-amber-500/20 rounded-[2.5rem] overflow-hidden shadow-2xl">
                    <div class="p-8 border-b border-amber-500/20">
                        <h3 class="text-xl font-black text-white">Profile Information</h3>
                        <p class="text-slate-500 text-xs font-medium mt-1">Update your account's profile information and email address.</p>
                    </div>
                    <div class="p-8">
                        <livewire:profile.update-profile-information-form />
                    </div>
                </div>
            </div>

            <!-- Update Password Tab -->
            <div x-show="activeTab === 'password'" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="opacity-0 translate-y-4" x-transition:enter-end="opacity-100 translate-y-0">
                <div class="bg-black/30 border border-amber-500/20 rounded-[2.5rem] overflow-hidden shadow-2xl">
                    <div class="p-8 border-b border-amber-500/20">
                        <h3 class="text-xl font-black text-white">Update Password</h3>
                        <p class="text-slate-500 text-xs font-medium mt-1">Ensure your account is using a long, random password to stay secure.</p>
                    </div>
                    <div class="p-8">
                        <livewire:profile.update-password-form />
                    </div>
                </div>
            </div>

            <!-- Delete Account Tab -->
            <div x-show="activeTab === 'delete'" x-transition:enter="transition ease-out duration-300" x-transition:enter-start="opacity-0 translate-y-4" x-transition:enter-end="opacity-100 translate-y-0">
                <div class="bg-rose-500/5 border border-rose-500/10 rounded-[2.5rem] overflow-hidden shadow-2xl">
                    <div class="p-8 border-b border-rose-500/10">
                        <h3 class="text-xl font-black text-rose-500">Delete Account</h3>
                        <p class="text-rose-500/60 text-xs font-medium mt-1">Permanently delete your account. This action cannot be undone.</p>
                    </div>
                    <div class="p-8">
                        <livewire:profile.delete-user-form />
                    </div>
                </div>
            </div>
        </div>
    </div>
</x-app-layout>
