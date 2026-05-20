# Decision 002: Payment Methods and Mode Checks

**Status:** Implemented
**Date:** 2026-05-17

## Context
1. The user wanted to add options to enable/disable COD and Online Payment in the app settings.
2. The user wanted to prevent customers from placing orders in a mode (Delivery, Takeaway, Dine-in) if the restaurant has disabled that mode in their settings.

## Decision
1. Added `cod_enabled` and `online_payment_enabled` toggles in the "Preferences" section of the Settings screen.
2. Updated the checkout sheet to check these settings and hide the respective payment options if disabled.
3. Added checks in the Customer Home screen to block navigation to the restaurant menu if the selected mode is not supported by the restaurant.
4. Added a check in the checkout sheet to disable the "Proceed & Place Order" button if the mode is not supported.

## Implementation Details

### 1. Settings & Checkout
- **`SettingsProvider.dart`**: Added getters `codEnabled` and `onlinePaymentEnabled` defaulting to true (if not set to 'no').
- **`settings_screen.dart`**: Added "Payment Methods" section with toggles.
- **`restaurant_menu_screen.dart`**: 
  - Initializes `paymentMethod` to 'COD' or 'ONLINE' based on what is enabled.
  - Hides the option if disabled.

### 2. Mode Checks
- **`customer_home_screen.dart`**: In `onTap` of the restaurant card, checks `customerProvider.orderType` against `r.isDelivery`, `r.isTakeaway`, `r.isDinein`.
- **`restaurant_menu_screen.dart`**: Checks `isModeAllowed` in the checkout sheet and updates the button text to "[MODE] NOT SUPPORTED" and disables it.

---
*Maintained by Antigravity*
