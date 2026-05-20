# Flutter Client Architecture (`app/lib`)

The front-end is designed as a fast, cross-platform client that links waitstaff and cashiers directly to local thermal printers and the central cloud engine.

```
📁 app/lib
 ├── 📁 core                  -> Theme, routing, dynamic widgets, network helpers
 ├── 📁 models                -> JSON serializers (Order, MenuItem, User, Table, Tax)
 ├── 📁 features              -> Visual views and view models
 │    ├── 👥 auth             -> Login and token caching
 │    ├── 📊 dashboard        -> Manager insights and analytics
 │    ├── 🍳 kds              -> Chef screen showing incoming station tickets
 │    ├── 🪑 tables           -> Draggable interactive dining layout planner
 │    └── 💳 pos              -> Checkouts panel & Split Settlement sheet
 └── 📁 services              -> Dedicated dynamic HTTP repositories
```

## Core Flutter Services Breakdown
The services in `services` make API integrations seamless:
*   `order_service.dart`: Manages carts, sends KOT additions, handles payment splits, and manages table transfer requests.
*   `print_service.dart`: Directly dispatches network ESC/POS thermal printing commands to kitchen and bill printers dynamically using TCP/IP sockets.
*   `pdf_service.dart`: Formats receipts and reports into sleek, premium printable PDF templates.
*   `tax_service.dart`: Computes taxes, handling complex local CGST/SGST inclusive/exclusive models.

## State Management & Providers
The app uses `Provider` for state management. Key providers include:
*   `ThemeProvider`: Manages dynamic light/dark theme switching and persistence.
*   `AuthProvider`: Handles Sanctum token authentication and user roles.
*   `OrderProvider`: Manages active orders, carts, and kitchen tickets.

---
Back to [Wiki Index](README.md)
