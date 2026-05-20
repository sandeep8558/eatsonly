# Multi-Tenant Database Strategy

To guarantee absolute security, data isolation, and performant operations, EatsOnly utilizes a **Single-Database-per-Tenant** architecture managed by a dynamic connection manager.

## Dynamic Tenant DB Connections

*   **Central Connection (`mysql`):** Connected to the core SaaS database (`eatsonly`). Manages users, restaurant owner registration, plans, subscriptions, payment logs, and global master menu catalogs.
*   **Tenant Connection (`tenant`):** Initialized with `'database' => null` in `config/database.php`. When a tenant registers or logs in, the backend dynamically switches the connection using:
    ```php
    Config::set('database.connections.tenant.database', $dbName);
    DB::purge('tenant');
    DB::reconnect('tenant');
    ```

## Schema Lifecycle Management

Instead of running heavy standard Laravel migrations on every tenant database, the system uses `TenantService.php`. 
*   It dynamically executes `CREATE DATABASE IF NOT EXISTS resto_{user_uuid}`.
*   It verifies, synchronizes, and builds schemas dynamically using Laravel Schema builders upon tenant initialization or update requests (`syncSchema` routine).

---
Back to [Wiki Index](README.md)
