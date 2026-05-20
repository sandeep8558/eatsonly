# Web Views & Livewire Routes (`web.php`)

*   **Public Landing Pages:** Standard informative views (`welcome`, `pricing`, `features`, `about`, `careers`, `contact`).
*   **Customer QR Interface:** `PublicMenu.php` maps to URL `/m/{slug}` where scanning table QR-codes lands. This allows visitors to browse menus, add items, and place digital self-orders directly.
*   **Super Admin Workspace (`/admin`):** Livewire components for full system orchestration (`PricingPlanManager`, `UserManager`, `PaymentManager`, `AllRestaurants`, etc.).
*   **Restaurant Manager Workspace (`/restaurant`):** Features like POS analytics dashboard and dynamic `TipReport` tracking waiter tip allocations.

---
Back to [Wiki Index](README.md)
