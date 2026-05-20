import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/widgets/main_layout.dart';
import '../dashboard/dashboard_screen.dart';
import '../dashboard/waiter_dashboard.dart';
import '../dashboard/chef_dashboard.dart';
import '../dashboard/customer_dashboard.dart';
import '../dashboard/manager_dashboard.dart';
import '../dashboard/cashier_dashboard.dart';
import '../dashboard/delivery_dashboard.dart';
import '../dashboard/accountant_dashboard.dart';
import '../customer/customer_home_screen.dart';

class DashboardHub extends StatefulWidget {
  const DashboardHub({super.key});

  @override
  State<DashboardHub> createState() => _DashboardHubState();
}

class _DashboardHubState extends State<DashboardHub> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoRefresh();
    });
  }

  Future<void> _autoRefresh() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await auth.refreshUser();
  }

  Future<void> _manualRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.refreshUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Roles updated from cloud successfully.', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Color(0xFFD4AF37),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update roles. Please check connection.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0C0D0E),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      );
    }

    // Dynamic Routing: Bypass selector if there's a saved selection
    if (auth.selectedRole != null) {
      final role = auth.selectedRole;
      if (role == 'admin' || role == 'saas_super_admin') {
        return const MainLayout(activePage: 'Dashboard', child: DashboardScreen());
      }
      if (role == 'manager') {
        return const MainLayout(activePage: 'Dashboard', child: ManagerDashboard());
      }
      if (role == 'cashier') {
        return const MainLayout(activePage: 'Dashboard', child: CashierDashboard());
      }
      if (role == 'waiter') {
        return const MainLayout(activePage: 'Dashboard', child: WaiterDashboard());
      }
      if (role == 'chef') {
        return const MainLayout(activePage: 'Dashboard', child: ChefDashboard());
      }
      if (role == 'delivery_executive') {
        return const MainLayout(activePage: 'Dashboard', child: DeliveryDashboard());
      }
      if (role == 'accountant') {
        return const MainLayout(activePage: 'Dashboard', child: AccountantDashboard());
      }
      if (role == 'customer') {
        return const MainLayout(activePage: 'Home', child: CustomerHomeScreen());
      }
    }

    if (user.hasMultipleDashboards) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C0D0E),
        body: _buildRoleSelector(context, user),
      );
    }

    // Single Role Fallbacks (in case user has only one specific role and no customer role)
    if (user.isSuperAdmin || user.isAdmin) {
      return const MainLayout(activePage: 'Dashboard', child: DashboardScreen());
    }

    if (user.isManager) {
      return const MainLayout(activePage: 'Dashboard', child: ManagerDashboard());
    }

    if (user.isChef) {
      return const MainLayout(activePage: 'Dashboard', child: ChefDashboard());
    }

    if (user.isWaiter) {
      return const MainLayout(activePage: 'Dashboard', child: WaiterDashboard());
    }

    if (user.isCashier) {
      return const MainLayout(activePage: 'Dashboard', child: CashierDashboard());
    }

    if (user.isDeliveryExecutive) {
      return const MainLayout(activePage: 'Dashboard', child: DeliveryDashboard());
    }

    if (user.isAccountant) {
      return const MainLayout(activePage: 'Dashboard', child: AccountantDashboard());
    }

    if (user.isCustomer) {
      return const MainLayout(activePage: 'Dashboard', child: CustomerDashboard());
    }

    return const MainLayout(activePage: 'Dashboard', child: DashboardScreen());
  }

  Widget _buildRoleSelector(BuildContext context, user) {
    return Stack(
      children: [
        Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Choose your workspace',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Select a role to switch your view and tools accordingly',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 56),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 24,
                  runSpacing: 24,
                  children: [
                    if (user.isSuperAdmin || user.isAdmin)
                      _buildRoleCard(context, 'Management', Icons.admin_panel_settings_outlined, const DashboardScreen(), 'admin'),
                    if (user.isManager)
                      _buildRoleCard(context, 'Manager', Icons.manage_accounts_outlined, const ManagerDashboard(), 'manager'),
                    if (user.isCashier)
                      _buildRoleCard(context, 'Cashier', Icons.point_of_sale_rounded, const CashierDashboard(), 'cashier'),
                    if (user.isWaiter)
                      _buildRoleCard(context, 'Waiter', Icons.shopping_cart_outlined, const WaiterDashboard(), 'waiter'),
                    if (user.isChef)
                      _buildRoleCard(context, 'Chef', Icons.kitchen_outlined, const ChefDashboard(), 'chef'),
                    if (user.isDeliveryExecutive)
                      _buildRoleCard(context, 'Delivery', Icons.delivery_dining_rounded, const DeliveryDashboard(), 'delivery_executive'),
                    if (user.isAccountant)
                      _buildRoleCard(context, 'Accountant', Icons.analytics_outlined, const AccountantDashboard(), 'accountant'),
                    if (user.isCustomer)
                      _buildRoleCard(context, 'Personal', Icons.person_outline, const CustomerHomeScreen(), 'customer', activePage: 'Home', isCustomerMode: true),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 36,
          right: 36,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  onPressed: _manualRefresh,
                  tooltip: 'Refresh Workspace Roles',
                  icon: _isRefreshing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)),
                        )
                      : const Icon(Icons.refresh_rounded, color: Color(0xFFD4AF37), size: 22),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleCard(BuildContext context, String title, IconData icon, Widget target, String roleKey, {String activePage = 'Dashboard', bool isCustomerMode = false}) {
    return SizedBox(
      width: 220,
      height: 200,
      child: InkWell(
        onTap: () {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          auth.setCustomerMode(isCustomerMode);
          auth.setSelectedRole(roleKey); // Persist user choice

          final resto = Provider.of<RestaurantProvider>(context, listen: false);
          resto.fetchRestaurants(auth.token!, myRestaurants: !isCustomerMode);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MainLayout(activePage: activePage, child: target),
              settings: RouteSettings(name: activePage == 'Home' ? '/customer/home' : '/dashboard'),
            ),
          );
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF16181D),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFFD4AF37), size: 44),
              const SizedBox(height: 18),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
