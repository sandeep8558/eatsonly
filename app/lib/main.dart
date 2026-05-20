import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/constants.dart';
import 'core/theme_provider.dart';
import 'core/widgets/main_layout.dart';
import 'core/auth_provider.dart';
import 'core/restaurant_provider.dart';
import 'core/staff_provider.dart';
import 'core/role_provider.dart';
import 'core/menu_provider.dart';
import 'core/table_provider.dart';
import 'core/attendance_provider.dart';
import 'core/order_provider.dart';
import 'core/settings_provider.dart';
import 'core/tax_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_hub.dart';
import 'features/auth/renew_subscription_screen.dart';
import 'features/restaurants/restaurants_screen.dart';
import 'features/staff/staff_management_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/menu/menu_manager_screen.dart';
import 'features/tables/tables_screen.dart';
import 'features/pos/pos_screen.dart';
import 'features/orders/orders_screen.dart';
import 'features/preferences/taxation_screen.dart';
import 'features/preferences/settings_screen.dart';
import 'features/preferences/integrations_screen.dart';
import 'features/kds/kds_screen.dart';
import 'features/kds/kds_stations_screen.dart';
import 'features/reports/tips_report_screen.dart';
import 'features/reports/sale_report_screen.dart';
import 'features/reports/purchase_report_screen.dart';
import 'features/reports/leakage_report_screen.dart';
import 'features/reports/menu_matrix_report_screen.dart';
import 'features/reports/ca_exports_screen.dart';
import 'features/customer/customer_orders_screen.dart';
import 'features/customer/customer_addresses_screen.dart';
import 'features/customer/customer_home_screen.dart';
import 'features/customer/business_screen.dart';
import 'features/delivery/delivery_screen.dart';
import 'features/inventory/inventory_screen.dart';
import 'features/inventory/suppliers_screen.dart';

import 'core/kot_provider.dart';
import 'core/kds_station_provider.dart';
import 'core/customer_provider.dart';
import 'core/delivery_provider.dart';
import 'core/inventory_provider.dart';
import 'core/recipe_provider.dart';
import 'core/integration_provider.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) => const ClampingScrollPhysics();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };

}


void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()..tryAutoLogin()),
        ChangeNotifierProxyProvider<AuthProvider, RestaurantProvider>(
          create: (_) => RestaurantProvider(),
          update: (_, auth, resto) => resto!..updateAuth(auth),
        ),
        ChangeNotifierProxyProvider<AuthProvider, StaffProvider>(
          create: (_) => StaffProvider(),
          update: (_, auth, staff) => staff!..updateAuth(auth),
        ),
        ChangeNotifierProvider<RoleProvider>(create: (_) => RoleProvider()),
        ChangeNotifierProxyProvider<AuthProvider, MenuProvider>(
          create: (_) => MenuProvider(),
          update: (_, auth, menu) => menu!..updateAuth(auth),
        ),
        ChangeNotifierProvider<TableProvider>(create: (_) => TableProvider()),
        ChangeNotifierProvider<AttendanceProvider>(create: (_) => AttendanceProvider()),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(),
          update: (_, auth, orders) => orders!..updateAuth(auth),
        ),
        ChangeNotifierProvider<KotProvider>(create: (_) => KotProvider()),
        ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
        ChangeNotifierProvider<TaxProvider>(create: (_) => TaxProvider()),
        ChangeNotifierProvider<KdsStationProvider>(create: (_) => KdsStationProvider()),
        ChangeNotifierProvider<CustomerProvider>(create: (_) => CustomerProvider()),
        ChangeNotifierProvider<DeliveryProvider>(create: (_) => DeliveryProvider()),
        ChangeNotifierProvider<InventoryProvider>(create: (_) => InventoryProvider()),
        ChangeNotifierProvider<RecipeProvider>(create: (_) => RecipeProvider()),
        ChangeNotifierProvider<IntegrationProvider>(create: (_) => IntegrationProvider()),
      ],
      child: const EatsOnlyApp(),
    ),
  );
}

class EatsOnlyApp extends StatelessWidget {
  const EatsOnlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'EatsOnly',
          debugShowCheckedModeBanner: false,
          scrollBehavior: AppScrollBehavior(),
          theme: themeProvider.themeData.copyWith(
            pageTransitionsTheme: PageTransitionsTheme(
              builders: {
                TargetPlatform.android: const ZoomPageTransitionsBuilder(),
                TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: const InstantPageTransitionsBuilder(),
                TargetPlatform.macOS: const InstantPageTransitionsBuilder(),
                TargetPlatform.windows: const InstantPageTransitionsBuilder(),
              },
            ),
          ),
      initialRoute: '/',
      builder: (context, child) {
        return Consumer<AuthProvider>(
          builder: (context, auth, _) {

            if (auth.isAuthenticated && auth.isSubscriptionBlocked && auth.user?.isSuperAdmin != true && !auth.isCustomerMode) {
              return const RenewSubscriptionScreen();
            }
            return child!;
          },
        );
      },
      routes: {
        '/': (context) => const AuthWrapper(),
        '/dashboard': (context) => const DashboardHub(),
        '/restaurants': (context) => const MainLayout(activePage: 'Restaurants', child: RestaurantsScreen()),
        '/menu-manager': (context) => const MainLayout(activePage: 'Menu Manager', child: MenuManagerScreen()),
        '/tables': (context) => const MainLayout(activePage: 'Tables', child: TablesScreen()),
        '/pos': (context) => const PosScreen(),
        '/orders': (context) => const MainLayout(activePage: 'Orders', child: OrdersScreen()),
        '/staff': (context) => const MainLayout(activePage: 'Staff & Roles', child: StaffManagementScreen()),
        '/profile': (context) => const MainLayout(activePage: 'Profile', child: ProfileScreen()),
        '/taxation': (context) => const MainLayout(activePage: 'Taxation', child: TaxationScreen()),
        '/settings': (context) => const MainLayout(activePage: 'Settings', child: SettingsScreen()),
        '/integrations': (context) => const MainLayout(activePage: 'Integrations', child: IntegrationsScreen()),
        '/kds': (context) => const MainLayout(activePage: 'KDS', child: KdsScreen()),
        '/kds-settings': (context) => const MainLayout(activePage: 'KDS Settings', child: KdsStationsScreen()),
        '/reports/tips': (context) => const MainLayout(activePage: 'Tip Management', child: TipsReportScreen()),
        '/reports/sale': (context) => const MainLayout(activePage: 'Sale Report', child: SaleReportScreen()),
        '/reports/purchase': (context) => const MainLayout(activePage: 'Purchase Report', child: PurchaseReportScreen()),
        '/reports/leakage': (context) => const MainLayout(activePage: 'Wastage & Leakage', child: LeakageReportScreen()),
        '/reports/menu-matrix': (context) => const MainLayout(activePage: 'Menu Matrix', child: MenuMatrixReportScreen()),
        '/reports/ca-exports': (context) => const MainLayout(activePage: 'CA Exports', child: CaExportsScreen()),
        '/inventory': (context) => const MainLayout(activePage: 'Inventory', child: InventoryScreen()),
        '/suppliers': (context) => const MainLayout(activePage: 'Suppliers', child: SuppliersScreen()),
        '/customer/orders': (context) => const MainLayout(activePage: 'My Orders', child: CustomerOrdersScreen()),
        '/customer/addresses': (context) => const MainLayout(activePage: 'Addresses', child: CustomerAddressesScreen()),
        '/customer/home': (context) => const MainLayout(activePage: 'Home', child: CustomerHomeScreen()),
        '/business': (context) => const MainLayout(activePage: 'Business', child: BusinessScreen()),
        '/delivery': (context) => const MainLayout(activePage: 'Delivery', child: DeliveryScreen()),
          },
        );
      },
    );
  }
}

class InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // On small windows (web-mobile), still allow animation
    if (MediaQuery.of(context).size.width < 1024) {
      return const FadeUpwardsPageTransitionsBuilder().buildTransitions(
        route, context, animation, secondaryAnimation, child,
      );
    }
    // On large screens, return the child directly (instant)
    return child;
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isAuthenticated) {
          // Check for subscription expiration (block staff/admins, allow super_admins and customers)
          if (auth.isSubscriptionBlocked && auth.user?.isSuperAdmin != true && !auth.isCustomerMode) {
            return const RenewSubscriptionScreen();
          }

          if (auth.isCustomerMode) {
            return const MainLayout(activePage: 'Home', child: CustomerHomeScreen());
          }
          return const DashboardHub();
        }
        return const LoginScreen();
      },
    );
  }
}
