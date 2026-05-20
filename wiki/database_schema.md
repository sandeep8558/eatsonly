# Database Schema Blueprint

## A. Central SaaS Database Tables (`mysql`)
These tables exist globally and store global SaaS state.

| Model / Table | Purpose | Key Attributes |
| :--- | :--- | :--- |
| `User` / `users` | Core SaaS account identities | `id`, `name`, `email`, `password`, `database_name` (tenant DB string) |
| `Restaurant` / `restaurants` | Registered restaurant brands | `id`, `user_id`, `name`, `slug`, `logo`, `address`, `is_active` |
| `PricingPlan` / `pricing_plans` | SaaS tier models | `id`, `name`, `price`, `interval` (monthly, yearly), `features` |
| `Subscription` / `subscriptions` | Active tenant memberships | `id`, `user_id`, `pricing_plan_id`, `status`, `expires_at` |
| `Payment` / `payments` | Centralized SaaS billing logs | `id`, `subscription_id`, `amount`, `payment_method`, `status` |
| `MasterCategory` / `master_categories` | Shared category list templates | `id`, `name`, `usage_count` |
| `MasterMenu` / `master_menus` | Shared item template catalogs | `id`, `name`, `description`, `image`, `dietary` (veg, nonveg, jain) |
| `Role` / `roles` | RBAC role list | `id`, `name` (saas_super_admin, admin, customer) |

## B. Tenant Database Tables (`tenant`)
These tables exist inside the isolated `resto_{user_uuid}` databases.

| Table Name | Purpose | Key Fields & Relationships |
| :--- | :--- | :--- |
| `restaurants` | Local tenant outlet config | `id`, `name`, `slug`, `upi_id`, `tax_name`, `fssai_number`, `bill_printer_ip`, `bill_printer_port` |
| `menu_cards` | Digital active menus | `id` (UUID), `name`, `is_active` |
| `menu_categories` | Menu catalog sections | `id`, `menu_card_id`, `kds_station_id`, `name`, `sort_order` |
| `menu_items` | Individual dishes & details | `id`, `menu_category_id`, `tax_group_id`, `name`, `price`, `type` (regular/combo), dietary flags |
| `menu_item_combo_groups` | Custom selection constraints | `id`, `menu_item_id`, `name`, `min_selections`, `max_selections` |
| `menu_item_combo_items` | Individual options within combos | `id`, `combo_group_id`, `menu_item_id`, `extra_price`, `is_default` |
| `floors` | Restaurant floor layers | `id`, `restaurant_id`, `menu_card_id` (floor-specific active menu), `name` |
| `tables` | Draggable floor tables | `id`, `floor_id`, `name`, `capacity`, `shape`, `x_pos`, `y_pos`, `status` |
| `attendances` | Clock records for staff | `id`, `user_id`, `restaurant_id`, `clock_in`, `clock_out`, `status` |
| `tax_groups` | Tax collections | `id`, `name`, `is_active`, `is_inclusive` |
| `taxes` | Individual tax lines | `id`, `tax_group_id`, `name`, `percentage` |
| `kds_stations` | Kitchen display station routings | `id`, `restaurant_id`, `name`, `printer_ip`, `printer_port` |
| `orders` | Core transaction records | `id`, `restaurant_id`, `table_id`, `user_id` (waiter), `source` (pos_waiter, qr_self, pos_counter), `customer_name`, `customer_phone`, financial breakdowns, `tip_amount` |
| `order_items` | Detail checkout rows | `id`, `order_id`, `menu_item_id`, `parent_order_item_id` (combos), `quantity`, `status` (pending, cooking, served) |
| `kots` | Kitchen tickets dispatched | `id`, `order_id`, `kds_station_id`, `status` (pending, cooking, completed) |
| `settings` | Local outlet behavior keys | `id`, `key`, `value` (e.g., packing charge, delivery fee toggles, currency) |
| `payments` | Transaction settlement splits | `id`, `order_id`, `amount`, `tip_amount`, `payment_method` (cash, card, upi, wallet) |

---
Back to [Wiki Index](README.md)
