import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/order_provider.dart';
import '../../core/table_provider.dart';
import '../../core/widgets/attendance_header.dart';

class CashierDashboard extends StatefulWidget {
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

class _CashierDashboardState extends State<CashierDashboard> {
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
      await resto.fetchRestaurants(auth.token!, myRestaurants: true);

      if (resto.selectedRestaurant != null) {
        final restaurantId = resto.selectedRestaurant!.id;

        await Future.wait([
          tables.fetchFloors(auth.token!, restaurantId),
          orders.fetchActiveOrders(auth.token!, restaurantId),
          orders.fetchAllOrders(auth.token!, restaurantId),
        ]);
      }
    } catch (_) {
      // Safe fallback
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

    // Calculate live numbers
    int pendingBillsCount = orders.activeOrders.length;
    double totalCollectedToday = 0.0;
    double cashCollected = 0.0;
    double upiCollected = 0.0;
    double cardCollected = 0.0;

    final now = DateTime.now();
    for (var order in orders.allOrders) {
      try {
        final createdAtStr = order['created_at']?.toString();
        if (createdAtStr != null) {
          final createdAt = DateTime.parse(createdAtStr.contains('Z') ? createdAtStr : '${createdAtStr}Z').toLocal();
          final bool isSameDay = createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day;

          if (isSameDay) {
            final String status = order['status']?.toString().toLowerCase() ?? '';
            if (status == 'completed') {
              final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;
              totalCollectedToday += total;

              final String paymentMethod = order['payment_method']?.toString().toLowerCase() ?? '';
              if (paymentMethod == 'cash') {
                cashCollected += total;
              } else if (paymentMethod == 'card') {
                cardCollected += total;
              } else {
                // All other payment methods (UPI, GPay, PhonePe, Razorpay, etc.) count as UPI/Digital
                upiCollected += total;
              }
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AttendanceHeader(),
                const SizedBox(height: 30),

                // Title Header & Switch Role
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedResto != null ? selectedResto.name.toUpperCase() : 'COUNTER TRANSACTIONS',
                          style: const TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Cashier Workspace',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _refreshData,
                          tooltip: 'Refresh Registry',
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
                          'Please select a restaurant outlet from the left sidebar to load live counter registry logs.',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Overview Stats Cards
                  const Text(
                    'COLLECTION REGISTRY',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard('Total Collected', '₹${totalCollectedToday.toStringAsFixed(2)}', Icons.payments_rounded, Colors.tealAccent),
                      const SizedBox(width: 16),
                      _buildStatCard('Pending Bills', '$pendingBillsCount', Icons.pending_actions_rounded, Colors.orangeAccent),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMiniStatCard('Cash', '₹${cashCollected.toStringAsFixed(2)}', Icons.money_rounded, Colors.greenAccent),
                      const SizedBox(width: 16),
                      _buildMiniStatCard('UPI', '₹${upiCollected.toStringAsFixed(2)}', Icons.qr_code_scanner_rounded, Colors.lightBlueAccent),
                      const SizedBox(width: 16),
                      _buildMiniStatCard('Card', '₹${cardCollected.toStringAsFixed(2)}', Icons.credit_card_rounded, Colors.purpleAccent),
                    ],
                  ),
                ],
                const SizedBox(height: 40),

                // Operations Shortcuts
                const Text(
                  'COUNTER OPERATIONS',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.8,
                  children: [
                    _buildActionCard(
                      context,
                      'Point of Sale (POS)',
                      'Generate new bills & takeaway orders',
                      Icons.point_of_sale_rounded,
                      () => Navigator.of(context).pushNamed('/pos'),
                    ),
                    _buildActionCard(
                      context,
                      'Invoices Registry',
                      'Review bills, collections and refunds',
                      Icons.receipt_long_rounded,
                      () => Navigator.of(context).pushNamed('/orders'),
                    ),
                    _buildActionCard(
                      context,
                      'KDS Feed',
                      'Check statuses of active kitchen food items',
                      Icons.restaurant_menu_rounded,
                      () => Navigator.of(context).pushNamed('/kds'),
                    ),
                    _buildActionCard(
                      context,
                      'Delivery Terminal',
                      'Assign bills to courier riders',
                      Icons.delivery_dining_rounded,
                      () => Navigator.of(context).pushNamed('/delivery'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.04),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Outfit',
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color.withOpacity(0.8), size: 16),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                mainAxisAlignment: MainAxisAlignment.center,
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
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
