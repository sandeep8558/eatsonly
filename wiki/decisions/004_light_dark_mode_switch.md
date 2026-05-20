# Decision 004: Light and Dark Mode Switch

**Status:** Implemented
**Date:** 2026-05-17

## Context
The user wanted to add a switch in the left navigation (sidebar) to toggle between Light and Dark modes in the app.

## Decision
1. Created a `ThemeProvider` to manage the theme state and persist it using `SharedPreferences`.
2. Wrapped the `MaterialApp` in `main.dart` with a `Consumer<ThemeProvider>` to react to theme changes.
3. Added a toggle button (icon) in the user section at the bottom of the left navigation sidebar in `main_layout.dart`.

## Implementation Details

### 1. ThemeProvider (`theme_provider.dart`)
- Manages `_isDarkMode` boolean.
- Loads preference from `SharedPreferences` on initialization.
- Provides `ThemeData` for both light and dark modes using `BrandColors.primaryGold` as the seed color.

### 2. Main App (`main.dart`)
- Registered `ThemeProvider` in `MultiProvider`.
- Updated `MaterialApp` to use `themeProvider.themeData`.

### 3. Sidebar Switch (`main_layout.dart`)
- Added a `Consumer<ThemeProvider>` in `_buildUserSection`.
- Displays `Icons.light_mode_rounded` when in dark mode and `Icons.dark_mode_rounded` when in light mode.
- **UI Fix**: Wrapped the sidebar `Column` in a `SafeArea` (with `bottom: true`) to prevent the logout button and user section from overlapping with Android/iOS system navigation bars.

---
*Maintained by Antigravity*
