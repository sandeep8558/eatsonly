# Decision 001: Online Payment Checkout Flow

**Status:** Implemented
**Date:** 2026-05-17

## Context
In the customer section of the Flutter app, creating an order and KOT (Kitchen Order Ticket) before online payment confirmation led to "phantom" orders in the POS and KDS if the payment fails or is cancelled.

## Decision
We chose the **Delayed KOT Generation** method. 
Instead of creating a new `carts` table, we use the existing `orders` and `order_items` tables but modify the behavior for online payments.

## Implementation Details

### 1. Backend (`OrderController.php`)
- **`sendKOT`**: If the order status is `pending_payment` (triggered by online payment method), the creation of `KOT` records is skipped. `OrderItem`s are created with a `null` `kot_id`.
- **`generateBill`**: When payment is successful and the order status updates to `preparing`, the backend checks for `OrderItem`s with `null` `kot_id`, groups them by KDS station, creates the `KOT`s, and updates the items.

### 2. App Impact
- **POS**: Unpaid orders are filtered out of active lists.
- **Customer App**: Needs to handle `pending_payment` status and clear cart only after success.
- **Pay Now Button**: Added a "Pay Now" button in the customer orders screen for orders with `pending_payment` status to retry Razorpay checkout.

## Use Cases Handled
- **Abandoned Checkout Recovery:** We can now track users who intended to buy but failed payment.
- **No Phantom Tickets:** Kitchen only gets tickets after payment is secure.

---
*Maintained by Antigravity*
