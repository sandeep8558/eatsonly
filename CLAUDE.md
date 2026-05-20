# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**EatsOnly** is a multi-tenant SaaS platform for restaurant management, comprising:
- `cloud/` — Laravel 13 backend (REST API + Livewire admin/public portal)
- `app/` — Flutter cross-platform POS/KDS client (iOS, Android, macOS, Windows, Web)
- `email_api` — standalone email API helper (single file)

## Wiki & Documentation Rules

This project uses an **LLM Wiki** pattern located in the `wiki/` directory to compound knowledge.
- **Proactive Updates:** Whenever changes are made to the database, API endpoints, app structure, or architecture, the AI assistant MUST proactively update the corresponding file in the `wiki/` folder.
- **No Prompting Needed:** The user does not need to explicitly ask to update the wiki; it should be a default part of the workflow.
- **Interlinking:** Ensure files within the `wiki/` folder remain interlinked.

---

## Cloud Backend (`cloud/`)

### Commands

```bash
# Start all dev services (server + queue + logs + Vite) concurrently
composer dev

# Or individually:
php artisan serve
npm run dev

# Run tests (Pest)
composer test
# or a single test file:
php artisan test tests/Feature/ExampleTest.php

# Lint / format PHP (Laravel Pint)
./vendor/bin/pint

# Run migrations
php artisan migrate

# Artisan tinker (REPL)
php artisan tinker
```

### Architecture

Laravel 13 with Livewire 3, Tailwind CSS, Vite. Auth via Laravel Sanctum (token-based for the Flutter app). Payments via Razorpay.

**Multi-Tenancy Pattern** — this is the most critical design constraint:
- A **central MySQL database** (`eatsonly`) stores global SaaS data: users, restaurants, pricing plans, subscriptions, payments, master menu catalogs, roles.
- Each restaurant owner gets an **isolated tenant database** named `resto_{user_uuid}` (with hyphens replaced by underscores). This database holds all operational data: menu cards, categories, items, tables, floors, orders, KOTs, KDS stations, taxes, staff attendance, payments, settings.
- The tenant DB connection is named `'tenant'` in `config/database.php` and starts with `'database' => null`. It is switched dynamically at runtime using `TenantService::switchToTenant($dbName)` which calls `Config::set(...)`, `DB::purge('tenant')`, `DB::reconnect('tenant')`.
- `TenantService::ensureTenantDatabase($user)` provisions the DB and runs `syncSchema()` (Laravel Schema builder, not standard migrations) to create/update tenant tables on demand.
- Tenant models must use `->on('tenant')` or `$connection = 'tenant'` — never the default connection.

**Route Structure:**
- `routes/api.php` — REST API consumed by Flutter; all protected routes require `auth:sanctum`
- `routes/web.php` — Livewire pages: public landing, `/m/{slug}` QR self-order menu, `/admin` super-admin workspace, `/restaurant` manager workspace
- `routes/auth.php` — Breeze auth for web portal login

**Key directories:**
- `app/Http/Controllers/Api/` — one controller per domain (Auth, Menu, Order, KOT, Table, Staff, etc.)
- `app/Services/` — business logic (TenantService, AuthService, etc.)
- `app/Livewire/` — Livewire components for web portal (Admin/, Customer/, Checkout.php, PublicMenu.php)
- `app/Models/` — Eloquent models; central models use default connection, tenant models use `'tenant'`

**Media serving:** Images stored in `storage/app/public/tenants/{dbName}/` are proxied via `GET /api/media/{path}` to allow cross-origin access from the Flutter app.

---

## Flutter App (`app/`)

### Commands

```bash
# Run on connected device or simulator
flutter run

# Run on specific platform
flutter run -d macos
flutter run -d android

# Build APK
flutter build apk --release

# Get dependencies
flutter pub get

# Analyze (lint)
flutter analyze

# Run tests
flutter test

# Run single test file
flutter test test/widget_test.dart

# Regenerate splash screen
dart run flutter_native_splash:create

# Regenerate launcher icons
dart run flutter_launcher_icons
```

### Architecture

State management uses **Provider** (`ChangeNotifierProvider`) with a provider per domain. All providers are registered in `main.dart` via `MultiProvider`.

**Layer structure:**
- `lib/core/` — providers (one per domain, e.g., `order_provider.dart`), app constants, shared widgets (`MainLayout`)
- `lib/services/` — HTTP service classes that call the Laravel API; each corresponds to a provider
- `lib/models/` — JSON deserializers for API responses
- `lib/features/` — UI screens organized by domain: `auth`, `dashboard`, `pos`, `kds`, `tables`, `menu`, `staff`, `orders`, `reports`, `preferences`, `restaurants`, `profile`, `customer`

**API base URL** is defined in `lib/core/constants.dart` as `ApiConstants.baseUrl` (defaults to `http://localhost:8000/api`). Change this for production builds.

**Key Flutter dependencies:**
- `provider` — state management
- `flutter_secure_storage` — persists Sanctum auth token
- `http` — REST API calls
- `esc_pos_utils_plus` + TCP sockets — direct ESC/POS commands to network thermal printers (`print_service.dart`)
- `pdf` + `printing` — PDF receipt generation (`pdf_service.dart`)
- `flutter_map` + `geolocator` — map/location features
- `qr_flutter` — QR code display

**Auth flow:** `AuthProvider.tryAutoLogin()` is called on startup and reads the stored token from secure storage. `AuthWrapper` in `main.dart` routes to `LoginScreen` or `DashboardHub` based on auth state, or to `CustomerHomeScreen` if the user role is `customer`.

**Role-based UX:** The `user.isCustomer` flag on the auth model determines which navigation tree is shown (customer home vs. restaurant POS/KDS/management views).

**Thermal printing:** `print_service.dart` opens a raw TCP socket to the printer IP/port configured per restaurant and KDS station in the backend settings. It does not use platform print APIs.

---

## Multi-Tenant Data Flow (end-to-end)

1. Flutter sends `POST /api/login` → receives Sanctum token
2. All subsequent requests include `Authorization: Bearer {token}`
3. Backend middleware resolves the authenticated user → calls `TenantService::switchToTenant($user->database_name)` to wire the `'tenant'` DB connection to that user's isolated database
4. Controllers use tenant-scoped models to read/write operational data
5. Central models (User, Restaurant in central DB, Subscription) always use the default `'mysql'` connection

## QR Self-Order Flow

Customer scans QR code → lands on `https://eatsonly.com/m/{slug}?t={table_id}` → `PublicMenu` Livewire component renders menu and accepts orders → orders dispatched via `Checkout.php` Livewire component → appears in Flutter POS app as active order.
