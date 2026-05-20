<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" class="dark">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0">
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <title>{{ $title ?? config('app.name', 'EatsOnly') }}</title>

    <!-- Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;500;600;700;800;900&display=swap" rel="stylesheet">

    <!-- Scripts -->
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    
    <style>
        body {
            font-family: 'Outfit', sans-serif;
            -webkit-tap-highlight-color: transparent;
        }
        .no-scrollbar::-webkit-scrollbar { display: none; }
        .no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
        
        [x-cloak] { display: none !important; }

        /* Premium Dark Theme Overrides */
        .bg-mesh {
            background-color: #000000;
            background-image: 
                radial-gradient(at 0% 0%, hsla(28,100%,16%,0.15) 0, transparent 50%), 
                radial-gradient(at 50% 0%, hsla(215,100%,10%,0.15) 0, transparent 50%),
                radial-gradient(at 100% 0%, hsla(28,100%,16%,0.15) 0, transparent 50%);
        }
    </style>
</head>
<body class="bg-mesh min-h-screen text-slate-200 antialiased selection:bg-amber-500/30">
    <!-- App Download Banner -->
    <div class="bg-gradient-to-r from-amber-600 via-orange-600 to-amber-600 py-2.5 px-4 flex items-center justify-between shadow-lg sticky top-0 z-[100] border-b border-white/10">
        <div class="flex items-center gap-3">
            <div class="w-8 h-8 bg-black/40 backdrop-blur-md rounded-lg flex items-center justify-center border border-white/20">
                <img src="{{ asset('logo.png') }}" class="w-5 h-5 object-contain" alt="Logo">
            </div>
            <div>
                <p class="text-[9px] font-black uppercase tracking-widest text-amber-100/60 leading-none mb-0.5">Premium Experience</p>
                <p class="text-[11px] font-extrabold text-white leading-none">EatsOnly Mobile App</p>
            </div>
        </div>
        <a href="{{ route('download') }}" class="bg-white text-amber-700 text-[10px] font-black uppercase tracking-widest px-4 py-1.5 rounded-full hover:bg-black hover:text-white transition-all shadow-sm">Install</a>
    </div>

    <main>
        {{ $slot }}
    </main>

    @livewireScripts
</body>
</html>
