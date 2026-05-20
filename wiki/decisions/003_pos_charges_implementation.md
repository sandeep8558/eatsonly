# Decision 003: POS Charges Implementation

**Status:** Implemented
**Date:** 2026-05-17

## Context
The user found that charges for Delivery, Takeaway, and Dine-in (set in settings) were not being applied when placing orders in the POS system.

## Investigation
1. The logic to calculate these charges based on `SettingsProvider` was already present in `pos_screen.dart` (lines 1691-1701 and 2603-2613).
2. However, the charges were evaluating to 0 because `SettingsProvider.fetchSettings` was never called in the POS screen, leaving the settings map empty.

## Decision
1. Call `SettingsProvider.fetchSettings` in the `_initData` method of `pos_screen.dart` to ensure settings are loaded when the POS screen opens.
2. This enables the existing calculation logic to work as intended and apply the correct charges based on the selected order type.

## Implementation Details
- **`pos_screen.dart`**: Added `await settingsProvider.fetchSettings(auth.token!);` in `_initData`.

---
*Maintained by Antigravity*
