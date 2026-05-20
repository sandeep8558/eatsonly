# System Architecture 🚀

**EatsOnly** is built as a highly scalable, multi-tenant Software-as-a-Service (SaaS) ecosystem designed to handle end-to-end restaurant operations, Point of Sale (POS) checkouts, kitchen orchestration (KDS), and dynamic QR-based customer self-ordering.

## Overview

```mermaid
graph TD
    subgraph Frontend [Multi-Platform Clients]
        FlutterApp[Flutter POS / KDS App]
        LivewirePortal[Web Public QR Menu / Admin Panel]
    end

    subgraph Backend [Laravel Cloud SaaS]
        Router[API & Web Router]
        TenantService[Tenant Connection Service]
        CentralDB[(Central MySQL DB)]
        TenantDB1[(Tenant DB: resto_user1)]
        TenantDB2[(Tenant DB: resto_user2)]
    end

    FlutterApp -->|REST API & Sanctum Auth| Router
    LivewirePortal -->|Web Routes & Livewire| Router
    Router --> TenantService
    TenantService -->|Auth & Billing| CentralDB
    TenantService -->|Dynamic Connection| TenantDB1
    TenantService -->|Dynamic Connection| TenantDB2
```

## Technology Stack

*   **Backend SaaS Engine:** Laravel 11, Livewire (Admin Panels, Checkout, & Public Menu), Tailwind CSS, Vite.
*   **Database Isolation Model:** Separate database per tenant (Restaurant Group/Owner).
*   **Mobile / Desktop / Web POS Client:** Flutter (supporting offline-resilient flows, local thermal receipt printing, custom split payment processing).

---
Back to [Wiki Index](README.md)
