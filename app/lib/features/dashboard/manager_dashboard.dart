import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/order_provider.dart';
import '../../core/table_provider.dart';
import '../../core/widgets/attendance_header.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final resto = Provider.of<RestaurantProvider>(context, listen: false);
    final tables = Provider.of<TableProvider>(context, listen: false);
    final orders = Provider.of<OrderProvider>(context, listen: false);

    if (auth.token == null) return;

    try {
      // 1. Fetch restaurants (ensures active context is populated)
      await resto.fetchRestaurants(auth.token!, myRestaurants: true);

      if (resto.selectedRestaurant != null) {
        final restaurantId = resto.selectedRestaurant!.id;

        // 2. Load floors, tables, active orders, and historical orders in parallel
        await Future.wait([
          tables.fetchFloors(auth.token!, restaurantId),
          orders.fetchActiveOrders(auth.token!, restaurantId),
          orders.fetchAllOrders(auth.token!, restaurantId),
        ]);
      }
    } catch (_) {
      // Graceful fallback
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final resto = Provider.of<RestaurantProvider>(context);
    final orders = Provider.of<OrderProvider>(context);
    
    final selectedResto = resto.selectedRestaurant;

    // Calculate real numbers
    int activeOrdersCount = orders.activeOrders.length;
    double todaySalesTotal = 0.0;
    int completedTodayCount = 0;

    final now = DateTime.now();
    for (var order in orders.allOrders) {
      try {
        final createdAtStr = order['created_at']?.toString();
        if (createdAtStr != null) {
          final createdAt = DateTime.parse(createdAtStr.contains('Z') ? createdAtStr : '${createdAtStr}Z').toLocal();
          final bool isSameDay = createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day;
          
          if (isSameDay) {
            if (order['status'] != 'cancelled') {
              final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;
              todaySalesTotal += total;
            }
            if (order['status'] == 'completed') {
              completedTodayCount++;
            }
          }
        }
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF16181D),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isSmall = constraints.maxWidth < 650;
              final double paddingVal = isSmall ? 16.0 : 24.0;

              return Padding(
                padding: EdgeInsets.all(paddingVal),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AttendanceHeader(),
                    const SizedBox(height: 30),

                    // Title Header & Switch Role
                    isSmall
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedResto != null ? selectedResto.name.toUpperCase() : 'RESTAURANT PERFORMANCE',
                                style: const TextStyle(
                                  color: Color(0xFFD4AF37),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Manager Workspace',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _refreshData,
                                    tooltip: 'Refresh statistics',
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)),
                                          )
                                        : const Icon(Icons.refresh_rounded, color: Colors.white54, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  if (auth.user?.hasMultipleDashboards == true)
                                    TextButton.icon(
                                      onPressed: () {
                                        Provider.of<AuthProvider>(context, listen: false).setSelectedRole(null);
                                        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                                      },
                                      icon: const Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFFD4AF37)),
                                      label: const Text('SWITCH ROLE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold)),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        backgroundColor: Colors.white.withOpacity(0.05),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      selectedResto != null ? selectedResto.name.toUpperCase() : 'RESTAURANT PERFORMANCE',
                                      style: const TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Manager Workspace',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _refreshData,
                                    tooltip: 'Refresh statistics',
                                    icon: _isLoading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)),
                                          )
                                        : const Icon(Icons.refresh_rounded, color: Colors.white54, size: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  if (auth.user?.hasMultipleDashboards == true)
                                    TextButton.icon(
                                      onPressed: () {
                                        Provider.of<AuthProvider>(context, listen: false).setSelectedRole(null);
                                        Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                                      },
                                      icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFFD4AF37)),
                                      label: const Text('SWITCH ROLE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        backgroundColor: Colors.white.withOpacity(0.05),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                    const SizedBox(height: 40),

                    if (selectedResto == null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_rounded, color: Colors.white24, size: 48),
                            SizedBox(height: 16),
                            Text(
                              'No Restaurant Context Selected',
                              style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Please select a restaurant outlet from the left sidebar to load live management statistics.',
                              style: TextStyle(color: Colors.white30, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Overview Stats Block
                      const Text(
                        'LIVE OVERVIEW',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      isSmall
                          ? Column(
                              children: [
                                _buildStatCard('Active Orders', '$activeOrdersCount', Icons.receipt_long_rounded, Colors.tealAccent, isSmall: true),
                                const SizedBox(height: 12),
                                _buildStatCard('Today Sales', '₹${todaySalesTotal.toStringAsFixed(2)}', Icons.payments_rounded, const Color(0xFFD4AF37), isSmall: true),
                                const SizedBox(height: 12),
                                _buildStatCard('Completed Bills', '$completedTodayCount', Icons.task_alt_rounded, Colors.greenAccent, isSmall: true),
                              ],
                            )
                          : Row(
                              children: [
                                _buildStatCard('Active Orders', '$activeOrdersCount', Icons.receipt_long_rounded, Colors.tealAccent),
                                const SizedBox(width: 16),
                                _buildStatCard('Today Sales', '₹${todaySalesTotal.toStringAsFixed(2)}', Icons.payments_rounded, const Color(0xFFD4AF37)),
                                const SizedBox(width: 16),
                                _buildStatCard('Completed Bills', '$completedTodayCount', Icons.task_alt_rounded, Colors.greenAccent),
                              ],
                            ),
                    ],
                    const SizedBox(height: 40),

                    // Operations & Reports Shortcuts
                    isSmall
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'OPERATIONS',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                               _buildActionCard(
                                context,
                                'Point of Sale (POS)',
                                'Take table or takeaway orders',
                                Icons.point_of_sale_rounded,
                                () => Navigator.of(context).pushNamed('/pos'),
                              ),
                              const SizedBox(height: 12),
                              _buildActionCard(
                                context,
                                'Stock Inventory',
                                'Manage raw materials and safety alerts',
                                Icons.inventory_2_rounded,
                                () => Navigator.of(context).pushNamed('/inventory'),
                              ),
                              const SizedBox(height: 12),
                              _buildActionCard(
                                context,
                                'Order History',
                                'Review and manage all invoices',
                                Icons.receipt_long_rounded,
                                () => Navigator.of(context).pushNamed('/orders'),
                              ),
                              const SizedBox(height: 12),
                              _buildActionCard(
                                context,
                                'KDS Feed',
                                'Monitor active kitchen preparation',
                                Icons.restaurant_menu_rounded,
                                () => Navigator.of(context).pushNamed('/kds'),
                              ),
                              const SizedBox(height: 12),
                              _buildActionCard(
                                context,
                                'Integrations',
                                'Link Swiggy & Zomato merchants',
                                Icons.sync_alt_rounded,
                                () => Navigator.of(context).pushNamed('/integrations'),
                              ),
                              const SizedBox(height: 32),
                              const Text(
                                'REPORTS & INSIGHTS',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildActionCard(
                                context,
                                'Sales Report',
                                'Analyze outlet revenue metrics',
                                Icons.trending_up_rounded,
                                () => Navigator.of(context).pushNamed('/reports/sale'),
                              ),
                              const SizedBox(height: 12),
                              _buildActionCard(
                                context,
                                'Purchase Registry',
                                'Track supply and raw materials cost',
                                Icons.shopping_bag_rounded,
                                () => Navigator.of(context).pushNamed('/reports/purchase'),
                              ),
                              const SizedBox(height: 12),
                              _buildActionCard(
                                context,
                                'Tip Management',
                                'Review waiter gratuities registry',
                                Icons.payments_rounded,
                                () => Navigator.of(context).pushNamed('/reports/tips'),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Operations Block
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'OPERATIONS',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildActionCard(
                                      context,
                                      'Point of Sale (POS)',
                                      'Take table or takeaway orders',
                                      Icons.point_of_sale_rounded,
                                      () => Navigator.of(context).pushNamed('/pos'),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildActionCard(
                                      context,
                                      'Stock Inventory',
                                      'Manage raw materials and safety alerts',
                                      Icons.inventory_2_rounded,
                                      () => Navigator.of(context).pushNamed('/inventory'),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildActionCard(
                                      context,
                                      'Order History',
                                      'Review and manage all invoices',
                                      Icons.receipt_long_rounded,
                                      () => Navigator.of(context).pushNamed('/orders'),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildActionCard(
                                      context,
                                      'KDS Feed',
                                      'Monitor active kitchen preparation',
                                      Icons.restaurant_menu_rounded,
                                      () => Navigator.of(context).pushNamed('/kds'),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildActionCard(
                                      context,
                                      'Integrations',
                                      'Link Swiggy & Zomato merchants',
                                      Icons.sync_alt_rounded,
                                      () => Navigator.of(context).pushNamed('/integrations'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),

                              // Analytics Block
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'REPORTS & INSIGHTS',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _buildActionCard(
                                      context,
                                      'Sales Report',
                                      'Analyze outlet revenue metrics',
                                      Icons.trending_up_rounded,
                                      () => Navigator.of(context).pushNamed('/reports/sale'),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildActionCard(
                                      context,
                                      'Purchase Registry',
                                      'Track supply and raw materials cost',
                                      Icons.shopping_bag_rounded,
                                      () => Navigator.of(context).pushNamed('/reports/purchase'),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildActionCard(
                                      context,
                                      'Tip Management',
                                      'Review waiter gratuities registry',
                                      Icons.payments_rounded,
                                      () => Navigator.of(context).pushNamed('/reports/tips'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, {bool isSmall = false}) {
    final cardContent = Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 10 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isSmall ? 20 : 24),
          ),
          SizedBox(width: isSmall ? 12 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: isSmall ? 10 : 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmall ? 18 : 20,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (isSmall) {
      return cardContent;
    }
    return Expanded(child: cardContent);
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
          ],
        ),
      ),
    );
  }
}
