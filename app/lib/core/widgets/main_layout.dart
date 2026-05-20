import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth_provider.dart';
import '../customer_provider.dart';
import '../restaurant_provider.dart';
import '../kds_station_provider.dart';
import '../menu_provider.dart';
import '../table_provider.dart';
import '../staff_provider.dart';
import '../order_provider.dart';
import '../delivery_provider.dart';
import '../theme_provider.dart';
import '../../models/restaurant_model.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final String activePage;

  const MainLayout({
    super.key,
    required this.child,
    this.title = 'EatsOnly',
    this.activePage = 'Dashboard',
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final ScrollController _sidebarScrollController = ScrollController();

  static const List<String> _setupPages = [
    'Restaurants',
    'Menu Manager',
    'Tables',
    'KDS Settings',
    'Staff & Roles',
    'Taxation',
    'Settings',
    'Integrations',
  ];

  late bool _showSetupMenu;

  @override
  void initState() {
    super.initState();
    _showSetupMenu = _setupPages.contains(widget.activePage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final resto = Provider.of<RestaurantProvider>(context, listen: false);
      if (auth.token != null) {
        if (auth.isCustomerMode) {
          if (resto.restaurants.isEmpty || resto.isMyRestaurants != false) {
            resto.fetchRestaurants(auth.token!, myRestaurants: false);
          }
        } else {
          if (resto.restaurants.isEmpty || resto.isMyRestaurants != true) {
            resto.fetchRestaurants(auth.token!, myRestaurants: true);
          }
        }
        _checkRenewalStatus();
      }
    });
  }

  void _checkRenewalStatus() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final sub = auth.user?.subscription;

    if (sub != null && sub.shouldRenew && !sub.isExpired && !auth.user!.isSuperAdmin) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        _showRenewalNotice(sub.daysRemaining);
      });
    }
  }

  void _showRenewalNotice(int days) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16181D),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD4AF37)),
            SizedBox(width: 12),
            Text('Renewal Notice', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Your subscription will expire in $days day${days == 1 ? "" : "s"}. Please renew your account soon to ensure uninterrupted service.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('LATER', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle renewal
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            child: const Text('RENEW NOW', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sidebarScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final user = auth.user;
    final isLargeScreen = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: isLargeScreen ? null : _buildSidebar(context),
      appBar: isLargeScreen
          ? null
          : AppBar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 2,
              centerTitle: false,
              title: Text(widget.title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
              iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), height: 1),
              ),
              actions: [
                if (user != null && !user.isOnlyCustomer)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: InkWell(
                      onTap: () async {
                        await auth.toggleMode();
                        final resto = Provider.of<RestaurantProvider>(context, listen: false);
                        if (auth.isCustomerMode) {
                          resto.fetchRestaurants(auth.token!, myRestaurants: false);
                          _navigateTo(context, '/customer/home', 'Home');
                        } else {
                          resto.fetchRestaurants(auth.token!, myRestaurants: true);
                          _navigateTo(context, '/dashboard', 'Dashboard');
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              auth.isCustomerMode ? Icons.admin_panel_settings_rounded : Icons.storefront_rounded,
                              color: const Color(0xFFD4AF37),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              auth.isCustomerMode ? 'ADMIN' : 'CUSTOMER',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
      body: Row(
        children: [
          if (isLargeScreen) _buildSidebar(context),
          Expanded(
            child: Container(
              alignment: Alignment.topLeft,
              color: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (!isLargeScreen && auth.isCustomerMode)
          ? Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), width: 1)),
              ),
              child: BottomNavigationBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedItemColor: const Color(0xFFD4AF37),
                unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                currentIndex: widget.activePage == 'Home' ? 0 : (widget.activePage == 'My Orders' ? 1 : (widget.activePage == 'Addresses' ? 2 : 0)),
                type: BottomNavigationBarType.fixed,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 10),
                onTap: (index) {
                  if (index == 0) {
                    _navigateTo(context, '/customer/home', 'Home');
                  } else if (index == 1) {
                    _navigateTo(context, '/customer/orders', 'My Orders');
                  } else if (index == 2) {
                    _navigateTo(context, '/customer/addresses', 'Addresses');
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_rounded, size: 22),
                    activeIcon: Icon(Icons.home_rounded, size: 24),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_bag_outlined, size: 22),
                    activeIcon: Icon(Icons.shopping_bag_rounded, size: 24),
                    label: 'My Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.location_on_outlined, size: 22),
                    activeIcon: Icon(Icons.location_on_rounded, size: 24),
                    label: 'Addresses',
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildSwitchModeButton(BuildContext context, AuthProvider auth) {
    final bool isCustomer = auth.isCustomerMode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () async {
          await auth.toggleMode();
          final resto = Provider.of<RestaurantProvider>(context, listen: false);
          if (auth.isCustomerMode) {
            resto.fetchRestaurants(auth.token!, myRestaurants: false);
            _navigateTo(context, '/customer/home', 'Home');
          } else {
            resto.fetchRestaurants(auth.token!, myRestaurants: true);
            _navigateTo(context, '/dashboard', 'Dashboard');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFD4AF37),
                Color(0xFFB59023),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isCustomer ? Icons.admin_panel_settings_rounded : Icons.storefront_rounded,
                color: Colors.black,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isCustomer ? 'Switch to Restaurant' : 'Switch to Customer',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Icon(
                Icons.swap_horiz_rounded,
                color: Colors.black54,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final resto = Provider.of<RestaurantProvider>(context);
    final isLargeScreen = MediaQuery.of(context).size.width >= 1024;

    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: SafeArea(
        bottom: true,
        top: false,
        child: Column(
          children: [
            _buildLogoSection(),
          if (user != null && !user.isOnlyCustomer) ...[
            _buildSwitchModeButton(context, auth),
            const SizedBox(height: 16),
          ],
          if (!auth.isCustomerMode && user != null && !user.isOnlyCustomer) ...[
            _buildRestaurantSelector(context, resto, auth),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: ListView(
                controller: _sidebarScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (auth.isCustomerMode) ...[
                    // Customer Mode Sidebar Menus:
                    _buildNavItem(
                      context,
                      'Home',
                      Icons.home_rounded,
                      widget.activePage == 'Home',
                      () => _navigateTo(context, '/customer/home', 'Home'),
                    ),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      context,
                      'My Orders',
                      Icons.shopping_bag_outlined,
                      widget.activePage == 'My Orders',
                      () => _navigateTo(context, '/customer/orders', 'My Orders'),
                    ),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      context,
                      'Addresses',
                      Icons.location_on_outlined,
                      widget.activePage == 'Addresses',
                      () => _navigateTo(context, '/customer/addresses', 'Addresses'),
                    ),
                    const SizedBox(height: 8),
                    _buildNavItem(
                      context,
                      'Business',
                      Icons.business_center_outlined,
                      widget.activePage == 'Business',
                      () => _navigateTo(context, '/business', 'Business'),
                    ),
                  ] else ...[
                    // Admin Mode Sidebar Menus:
                    if (!_showSetupMenu) ...[
                      // Switch to Setup Mode Button
                      if (user?.isAdmin == true || user?.isSuperAdmin == true) ...[
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFD4AF37).withOpacity(0.12),
                                const Color(0xFFD4AF37).withOpacity(0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2), width: 1),
                          ),
                          child: _buildNavItem(
                            context,
                            'Restaurant Setup Mode',
                            Icons.settings_suggest_rounded,
                            false,
                            () {
                              setState(() {
                                _showSetupMenu = true;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Dashboard (Visible to all staff members)
                      if (user?.isOnlyCustomer == false) ...[
                        _buildNavItem(
                          context,
                          'Dashboard',
                          Icons.dashboard_rounded,
                          widget.activePage == 'Dashboard',
                          () => _navigateTo(context, '/dashboard', 'Dashboard'),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Operations Section (POS, Orders, KDS, Delivery)
                      if (user?.isAdmin == true ||
                          user?.isSuperAdmin == true ||
                          user?.isManager == true ||
                          user?.isCashier == true ||
                          user?.isWaiter == true ||
                          user?.isChef == true ||
                          user?.isDeliveryExecutive == true) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 8, top: 8),
                          child: Text('OPERATIONS', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                      ],
                      if (user?.isAdmin == true || user?.isSuperAdmin == true || user?.isManager == true || user?.isCashier == true || user?.isWaiter == true) ...[
                        _buildNavItem(
                          context,
                          'Point of Sale (POS)',
                          Icons.point_of_sale_rounded,
                          widget.activePage == 'POS',
                          () => _navigateTo(context, '/pos', 'POS'),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (user?.isAdmin == true || user?.isSuperAdmin == true || user?.isManager == true || user?.isCashier == true) ...[
                        _buildNavItem(
                          context,
                          'Orders',
                          Icons.receipt_long_rounded,
                          widget.activePage == 'Orders',
                          () => _navigateTo(context, '/orders', 'Orders'),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (user?.isAdmin == true || user?.isSuperAdmin == true || user?.isManager == true || user?.isCashier == true || user?.isChef == true) ...[
                        _buildNavItem(
                          context,
                          'KDS',
                          Icons.restaurant_menu_rounded,
                          widget.activePage == 'KDS',
                          () => _navigateTo(context, '/kds', 'KDS'),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (user?.isAdmin == true || user?.isSuperAdmin == true || user?.isManager == true || user?.isCashier == true || user?.isDeliveryExecutive == true) ...[
                        _buildNavItem(
                          context,
                          'Delivery',
                          Icons.delivery_dining_rounded,
                          widget.activePage == 'Delivery',
                          () => _navigateTo(context, '/delivery', 'Delivery'),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Inventory & Procurement Section
                      if (user?.isAdmin == true || user?.isSuperAdmin == true || user?.isManager == true || user?.isAccountant == true) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 8, top: 8),
                          child: Text('INVENTORY & PROCUREMENT', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                        _buildNavItem(
                          context,
                          'Inventory',
                          Icons.inventory_2_rounded,
                          widget.activePage == 'Inventory',
                          () => _navigateTo(context, '/inventory', 'Inventory'),
                        ),
                        const SizedBox(height: 8),
                        _buildNavItem(
                          context,
                          'Suppliers',
                          Icons.storefront_rounded,
                          widget.activePage == 'Suppliers',
                          () => _navigateTo(context, '/suppliers', 'Suppliers'),
                        ),
                        const SizedBox(height: 8),
                        _buildNavItem(
                          context,
                          'Purchase',
                          Icons.shopping_bag_rounded,
                          widget.activePage == 'Purchase Report',
                          () => _navigateTo(context, '/reports/purchase', 'Purchase Report'),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Reports & Insight Section
                      if (user?.isAdmin == true || user?.isSuperAdmin == true || user?.isManager == true || user?.isAccountant == true) ...[
                        const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 8, top: 8),
                          child: Text('REPORTS & INSIGHT', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                        _buildNavItem(
                          context,
                          'Sale',
                          Icons.trending_up_rounded,
                          widget.activePage == 'Sale Report',
                          () => _navigateTo(context, '/reports/sale', 'Sale Report'),
                        ),
                        const SizedBox(height: 8),
                        _buildNavItem(
                          context,
                          'Wastage & Leakage',
                          Icons.delete_sweep_rounded,
                          widget.activePage == 'Wastage & Leakage',
                          () => _navigateTo(context, '/reports/leakage', 'Wastage & Leakage'),
                        ),
                        const SizedBox(height: 8),
                        _buildNavItem(
                          context,
                          'Menu Matrix',
                          Icons.grid_view_rounded,
                          widget.activePage == 'Menu Matrix',
                          () => _navigateTo(context, '/reports/menu-matrix', 'Menu Matrix'),
                        ),
                        const SizedBox(height: 8),
                        _buildNavItem(
                          context,
                          'Tip Management',
                          Icons.payments_rounded,
                          widget.activePage == 'Tip Management',
                          () => _navigateTo(context, '/reports/tips', 'Tip Management'),
                        ),
                        const SizedBox(height: 8),
                        _buildNavItem(
                          context,
                          'CA Exports',
                          Icons.download_for_offline_rounded,
                          widget.activePage == 'CA Exports',
                          () => _navigateTo(context, '/reports/ca-exports', 'CA Exports'),
                        ),
                      ],
                    ] else if (user?.isAdmin == true || user?.isSuperAdmin == true) ...[
                      // Switch to Operations Button
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.01),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                        ),
                        child: _buildNavItem(
                          context,
                          'Back to Operations',
                          Icons.arrow_back_rounded,
                          false,
                          () {
                            setState(() {
                              _showSetupMenu = false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),

                      _buildNavItem(
                        context,
                        'Dashboard',
                        Icons.dashboard_rounded,
                        widget.activePage == 'Dashboard',
                        () => _navigateTo(context, '/dashboard', 'Dashboard'),
                      ),
                      const SizedBox(height: 8),

                      // Restaurant Setup Section
                      const Padding(
                        padding: EdgeInsets.only(left: 16, bottom: 8, top: 8),
                        child: Text('RESTAURANT SETUP', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ),
                      _buildNavItem(
                        context,
                        'Restaurants',
                        Icons.storefront_rounded,
                        widget.activePage == 'Restaurants',
                        () => _navigateTo(context, '/restaurants', 'Restaurants'),
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        'KDS Settings',
                        Icons.kitchen_rounded,
                        widget.activePage == 'KDS Settings',
                        () => _navigateTo(context, '/kds-settings', 'KDS Settings'),
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        'Menu Manager',
                        Icons.restaurant_menu_rounded,
                        widget.activePage == 'Menu Manager',
                        () => _navigateTo(context, '/menu-manager', 'Menu Manager'),
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        'Table & Floor',
                        Icons.grid_view_rounded,
                        widget.activePage == 'Tables',
                        () => _navigateTo(context, '/tables', 'Tables'),
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        'Staff & Roles',
                        Icons.people_alt_rounded,
                        widget.activePage == 'Staff & Roles',
                        () => _navigateTo(context, '/staff', 'Staff & Roles'),
                      ),

                      // Preferences Section
                      const SizedBox(height: 16),
                      const Padding(
                        padding: EdgeInsets.only(left: 16, bottom: 8),
                        child: Text('PREFERENCES', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ),
                      _buildNavItem(
                        context,
                        'Taxation',
                        Icons.receipt_long_outlined,
                        widget.activePage == 'Taxation',
                        () => _navigateTo(context, '/taxation', 'Taxation'),
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        'Settings',
                        Icons.settings_outlined,
                        widget.activePage == 'Settings',
                        () => _navigateTo(context, '/settings', 'Settings'),
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        'Integrations',
                        Icons.sync_alt_rounded,
                        widget.activePage == 'Integrations',
                        () => _navigateTo(context, '/integrations', 'Integrations'),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), height: 1, indent: 24, endIndent: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildNavItem(
              context,
              'Profile',
              Icons.person_outline_rounded,
              widget.activePage == 'Profile',
              () => _navigateTo(context, '/profile', 'Profile'),
            ),
          ),
          _buildUserSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/app_logo.png',
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'EatsOnly',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      key: ValueKey(title),
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      hoverColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD4AF37).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 22),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                color: isActive ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
            if (isActive) ...[
              const Spacer(),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
            child: Text(auth.user?.name[0].toUpperCase() ?? 'A', style: const TextStyle(color: Color(0xFFD4AF37))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.user?.name ?? 'Admin',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  auth.user?.primaryRole.toUpperCase() ?? 'ROLE',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  size: 20,
                ),
                onPressed: () {
                  themeProvider.toggleTheme();
                },
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 20),
            onPressed: () {
              Provider.of<CustomerProvider>(context, listen: false).reset();
              Provider.of<RestaurantProvider>(context, listen: false).reset();
              Provider.of<KdsStationProvider>(context, listen: false).reset();
              Provider.of<MenuProvider>(context, listen: false).reset();
              Provider.of<TableProvider>(context, listen: false).reset();
              Provider.of<StaffProvider>(context, listen: false).reset();
              Provider.of<OrderProvider>(context, listen: false).reset();
              Provider.of<DeliveryProvider>(context, listen: false).reset();
              auth.logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantSelector(BuildContext context, RestaurantProvider resto, AuthProvider auth) {
    if (resto.isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.1), width: 1),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
            ),
          ),
        ),
      );
    }

    if (resto.restaurants.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.redAccent.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No restaurant setup found',
                style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFD4AF37).withOpacity(0.15),
          width: 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<RestaurantModel>(
          value: resto.selectedRestaurant,
          isExpanded: true,
          dropdownColor: const Color(0xFF16181D),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFFD4AF37)),
          selectedItemBuilder: (BuildContext context) {
            return resto.restaurants.map<Widget>((RestaurantModel r) {
              return Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: Color(0xFFD4AF37), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Active Restaurant',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: resto.restaurants.map((RestaurantModel r) {
            return DropdownMenuItem<RestaurantModel>(
              value: r,
              child: Row(
                children: [
                  const Icon(Icons.storefront_rounded, color: Color(0xFFD4AF37), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (RestaurantModel? val) {
            if (val != null) {
              resto.setSelectedRestaurant(val);
              // Force active route reload to fetch new restaurant context
              final activeName = ModalRoute.of(context)?.settings.name ?? '/dashboard';
              Navigator.of(context).pushNamedAndRemoveUntil(activeName, (route) => false);
            }
          },
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, String routeName, String pageName) {
    if (widget.activePage == pageName) return;

    final isLargeScreen = MediaQuery.of(context).size.width >= 1024;

    if (isLargeScreen) {
      Navigator.of(context).pushNamedAndRemoveUntil(routeName, (route) => false);
    } else {
      Navigator.of(context).pushNamed(routeName);
    }
  }
}
