# API Endpoint Map (`api.php`)

All requests under `api.php` use a custom request lifecycle to map connection states dynamically based on the authenticated user's header token or session.

## Core Endpoints

```
🔑 /api
 ├── POST  /register                             -> SaaS account registration
 ├── POST  /login                                -> SaaS account login (returns Sanctum token)
 ├── POST  /forgot-password                      -> Initiate password reset
 └── POST  /reset-password                       -> Set new password
```

## Protected Endpoints (Requires `auth:sanctum`)

```
🔒 /api
 ├── GET   /me                                   -> Retrieve current logged in user details
 ├── POST  /logout                               -> Revoke access token
  │
 ├── 🕒 ATTENDANCE
 │    ├── GET   /attendance/status               -> Current clock-in status
 │    ├── POST  /attendance/clock-in             -> Punch in waiter/chef
 │    ├── POST  /attendance/clock-out            -> Punch out waiter/chef
 │    └── GET   /attendance/history              -> Historical attendance logs
 │
 ├── 🏠 RESTAURANTS
 │    ├── GET   /restaurants                     -> List user's outlets
 │    ├── POST  /restaurants                     -> Add a new outlet
 │    ├── PUT   /restaurants/{id}                -> Modify outlet details
 │    └── DELETE/restaurants/{id}                -> Remove outlet
 │
 ├── 👥 STAFF & ROLES
 │    ├── GET   /staff/search                    -> Quick query staff list
 │    ├── GET   /staff                           -> List all linked outlet employees
 │    ├── POST  /staff                           -> Hire / register new staff
 │    ├── PUT   /staff/{id}                      -> Update staff role & profile
 │    ├── DELETE/staff/{id}                      -> Terminate staff link
 │    └── GET   /roles                           -> Get available RBAC roles
 │
 ├── 🍔 MENU MANAGEMENT
 │    ├── POST  /menu/generate-description       -> Auto-generate item description via AI
 │    ├── GET   /menu/suggestions/categories     -> Auto-suggest categories based on master templates
 │    ├── GET   /menu/suggestions/items          -> Auto-suggest items based on master templates
 │    ├── GET   /menu/cards                      -> List active menu sheets
 │    ├── POST  /menu/cards                      -> Create custom menu sheet
 │    ├── POST  /menu/cards/clone                -> Clone an entire menu card (e.g. for seasonal menus)
 │    ├── POST  /menu/sync-menus                 -> Sync central menus to tenant
 │    ├── POST  /menu/categories                 -> Add section category to menu sheet
 │    └── POST  /menu/items                      -> Add item to category sheet (with combos and taxes)
 │
 ├── 🪑 TABLE & FLOOR WORKSPACE
 │    ├── GET   /floors                          -> Fetch floors with table status
 │    ├── POST  /floors                          -> Create floor sheet
 │    ├── POST  /tables                          -> Add table to floor
 │    └── POST  /tables/layout                   -> Batch-update draggable (x, y) table placements
 │
 ├── 💳 POS & TRANSACTION ENGINE
 │    ├── GET   /orders                          -> Query list of history orders
 │    ├── GET   /orders/active                   -> Active Dine-In tickets tracking
 │    ├── POST  /orders/kot                      -> Submit/Dispatch Kitchen Order Ticket
 │    ├── POST  /orders/{id}/bill                -> Set order to 'billed' status (generates final invoice)
 │    ├── POST  /orders/transfer                 -> Transfer items/orders from Table A to Table B
 │    ├── POST  /orders/merge                    -> Merge multiple dining tables into a unified check
 │    ├── GET   /kots                            -> Query kitchen dispatch tickets
 │    └── POST  /kots/{id}/status                -> Dispatch KOT stage (pending -> cooking -> done)
 │
 └── ⚙️ SYSTEM SETTINGS
      ├── GET   /settings                        -> Fetch tax rates, delivery fee parameters, payment toggles (COD/Online)
      └── POST  /settings                        -> Bulk edit settings
```

---
Back to [Wiki Index](README.md)
