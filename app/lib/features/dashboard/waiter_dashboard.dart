import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/table_provider.dart';
import '../../core/order_provider.dart';
import '../../core/widgets/attendance_header.dart';

class WaiterDashboard extends StatefulWidget {
  const WaiterDashboard({super.key});

  @override
  State<WaiterDashboard> createState() => _WaiterDashboardState();
}

class _WaiterDashboardState extends State<WaiterDashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final resto = Provider.of<RestaurantProvider>(context, listen: false);
    final tables = Provider.of<TableProvider>(context, listen: false);
    final orders = Provider.of<OrderProvider>(context, listen: false);

    if (auth.token == null) return;

    // 1. Fetch restaurants (ensures we have active context)
    await resto.fetchRestaurants(auth.token!, myRestaurants: true);

    if (resto.selectedRestaurant != null) {
      final restaurantId = resto.selectedRestaurant!.id;

      // 2. Load tables, active orders and recent order history in parallel (no strict API date boundary to prevent timezone mismatches)
      await Future.wait([
        tables.fetchFloors(auth.token!, restaurantId),
        orders.fetchActiveOrders(auth.token!, restaurantId),
        orders.fetchAllOrders(auth.token!, restaurantId),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final resto = Provider.of<RestaurantProvider>(context);
    final tables = Provider.of<TableProvider>(context);
    final orders = Provider.of<OrderProvider>(context);

    final user = auth.user;
    final selectedResto = resto.selectedRestaurant;
    final bool isSmallScreen = MediaQuery.of(context).size.width < 768;

    // Filter today's shift orders taken by this specific waiter
    final todayWaiterOrders = orders.allOrders.where((order) {
      final orderUserId = order['user_id']?.toString();
      if (orderUserId != user?.id) return false;
      
      try {
        final createdAtStr = order['created_at']?.toString();
        if (createdAtStr != null) {
          final createdAt = DateTime.parse(createdAtStr.contains('Z') ? createdAtStr : '${createdAtStr}Z').toLocal();
          final now = DateTime.now();
          // Match same calendar day or within 18 hours (accounting for late night service shifts)
          final bool isSameDay = createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day;
          final bool isRecentShift = now.difference(createdAt).inHours < 18;
          return isSameDay || isRecentShift;
        }
      } catch (_) {}
      return true; // Fallback to displaying the order
    }).toList();

    // Today's completed orders by this waiter
    final completedOrders = todayWaiterOrders.where((o) => o['status'] == 'completed').toList();

    // Calculate today's sales for this waiter
    final double shiftSales = todayWaiterOrders.fold(0.0, (sum, order) {
      if (order['status'] == 'cancelled') return sum;
      final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;
      return sum + total;
    });

    // Calculate today's tips earned by this waiter
    final double shiftTips = todayWaiterOrders.fold(0.0, (sum, order) {
      final tip = double.tryParse(order['tip_amount']?.toString() ?? '0') ?? 0.0;
      return sum + tip;
    });

    // Filter waiter's active orders (dine-in/takeaway/delivery) that are not completed or cancelled
    final activeWaiterOrders = orders.activeOrders.entries.where((entry) {
      return true;
    }).toList();

    // Extract live ready-to-serve dishes from active orders (items with status 'ready')
    final List<Map<String, dynamic>> kitchenAlerts = [];
    orders.activeOrders.forEach((tableKey, items) {
      final customerName = orders.orderCustomerNames[tableKey] ?? 'Guest';
      
      String tableName = tableKey.startsWith('order_') ? 'Takeaway/Delivery' : tableKey;
      final matchTable = tables.allTables.where((t) => t.id == tableKey).firstOrNull;
      if (matchTable != null) {
        tableName = matchTable.name;
      }

      for (var ci in items) {
        if (ci.isSent) {
          kitchenAlerts.add({
            'table_id': tableKey,
            'table_name': tableName,
            'customer_name': customerName,
            'dish_name': ci.menuItem.name,
            'quantity': ci.quantity,
          });
        }
      }
    });

    final mainContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Attendance tracker and Clock-In/Clock-Out header
        const AttendanceHeader(),
        const SizedBox(height: 24),

        // Welcome row & Shift overview
        _buildWelcomeHeader(user, selectedResto),
        const SizedBox(height: 24),

        // Metrics grid
        _buildMetricsGrid(
          shiftSales: shiftSales,
          activeCount: activeWaiterOrders.length,
          completedCount: completedOrders.length,
          shiftTips: shiftTips,
          isSmallScreen: isSmallScreen,
        ),
        const SizedBox(height: 24),

        // Dynamic Main Section (Alerts, Tables Grid, Active Orders Feed)
        if (isSmallScreen) ...[
          const Text('TABLES & FLOORS STATUS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildTablesGrid(context, tables, isSmallScreen: true),
          const SizedBox(height: 24),
          const Text('MY ACTIVE WAITING ORDERS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildActiveOrdersList(context, orders, tables, activeWaiterOrders, isSmallScreen: true),
          const SizedBox(height: 24),
          const Text('LIVE KITCHEN KOT STATUS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          _buildKitchenAlertsPanel(context, kitchenAlerts, isSmallScreen: true),
        ] else ...[
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Tables Grid and Active Orders tracker
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TABLES & FLOORS STATUS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      Expanded(
                        flex: 3,
                        child: _buildTablesGrid(context, tables, isSmallScreen: false),
                      ),
                      const SizedBox(height: 24),
                      const Text('MY ACTIVE WAITING ORDERS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      Expanded(
                        flex: 2,
                        child: _buildActiveOrdersList(context, orders, tables, activeWaiterOrders, isSmallScreen: false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),

                // Right Column: Live Kitchen Ready Alerts Feed
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LIVE KITCHEN KOT STATUS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _buildKitchenAlertsPanel(context, kitchenAlerts, isSmallScreen: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF16181D),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: isSmallScreen
              ? SafeArea(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: mainContent,
                  ),
                )
              : mainContent,
        ),
      ),
    );
  }

  // Welcome Header Widget
  Widget _buildWelcomeHeader(user, selectedResto) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WELCOME BACK, ${user?.name.toUpperCase() ?? "STAFF"}',
                style: const TextStyle(
                  color: Color(0xFFD4AF37),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                selectedResto != null ? selectedResto.name : 'Restaurant Workspace',
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            if (user?.hasMultipleDashboards == true) ...[
              TextButton.icon(
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).setSelectedRole(null);
                  Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
                },
                icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFFD4AF37)),
                label: const Text('SWITCH ROLE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  backgroundColor: Colors.white.withOpacity(0.04),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
              tooltip: 'Refresh Dashboard',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.04),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Shift metrics grid block
  Widget _buildMetricsGrid({
    required double shiftSales,
    required int activeCount,
    required int completedCount,
    required double shiftTips,
    required bool isSmallScreen,
  }) {
    if (isSmallScreen) {
      return Column(
        children: [
          Row(
            children: [
              _buildMetricCard('Today\'s Sales', '₹${shiftSales.toStringAsFixed(2)}', Icons.payments_outlined, const Color(0xFFD4AF37)),
              const SizedBox(width: 12),
              _buildMetricCard('Active Orders', '$activeCount', Icons.add_shopping_cart_rounded, Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricCard('Completed', '$completedCount', Icons.assignment_turned_in_outlined, Colors.green),
              const SizedBox(width: 12),
              _buildMetricCard('My Tips Today', '₹${shiftTips.toStringAsFixed(2)}', Icons.monetization_on_outlined, const Color(0xFFB59023)),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        _buildMetricCard('Today\'s Sales', '₹${shiftSales.toStringAsFixed(2)}', Icons.payments_outlined, const Color(0xFFD4AF37)),
        const SizedBox(width: 16),
        _buildMetricCard('Active Orders', '$activeCount', Icons.add_shopping_cart_rounded, Colors.blueAccent),
        const SizedBox(width: 16),
        _buildMetricCard('Completed Orders', '$completedCount', Icons.assignment_turned_in_outlined, Colors.green),
        const SizedBox(width: 16),
        _buildMetricCard('My Tips Today', '₹${shiftTips.toStringAsFixed(2)}', Icons.monetization_on_outlined, const Color(0xFFB59023)),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title, 
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value, 
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Interactive Live Tables Grid grouped by Floor
  Widget _buildTablesGrid(BuildContext context, TableProvider tables, {required bool isSmallScreen}) {
    if (tables.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    }

    if (tables.allTables.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.01),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.03)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.table_restaurant_rounded, color: Colors.white.withOpacity(0.1), size: 40),
              const SizedBox(height: 12),
              Text('No floor layout or tables configured.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        shrinkWrap: isSmallScreen,
        physics: isSmallScreen ? const NeverScrollableScrollPhysics() : const ScrollPhysics(),
        itemCount: tables.floors.length,
        itemBuilder: (context, floorIndex) {
          final floor = tables.floors[floorIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.layers_outlined, color: Color(0xFFD4AF37), size: 14),
                    const SizedBox(width: 8),
                    Text(
                      floor.name.toUpperCase(),
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ],
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 130,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.3,
                ),
                itemCount: floor.tables.length,
                itemBuilder: (context, tableIndex) {
                  final table = floor.tables[tableIndex];
                  final isOccupied = table.status == 'occupied';
                  
                  return InkWell(
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/pos',
                        arguments: {'table_id': table.id},
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isOccupied 
                            ? const Color(0xFFD4AF37).withOpacity(0.08) 
                            : Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOccupied 
                              ? const Color(0xFFD4AF37).withOpacity(0.3) 
                              : Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            table.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOccupied ? const Color(0xFFD4AF37) : Colors.green,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOccupied ? 'Occupied' : 'Available',
                                style: TextStyle(
                                  color: isOccupied ? const Color(0xFFD4AF37) : Colors.green,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  // Live Waiter Ongoing Active Orders List
  Widget _buildActiveOrdersList(
    BuildContext context,
    OrderProvider orders,
    TableProvider tables,
    List<MapEntry<String, List<dynamic>>> activeOrders, {
    required bool isSmallScreen,
  }) {
    if (orders.isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator(color: Color(0xFFD4AF37))));
    }

    final listWidget = activeOrders.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, color: Colors.white.withOpacity(0.1), size: 36),
                const SizedBox(height: 8),
                Text('No active orders.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            shrinkWrap: isSmallScreen,
            physics: isSmallScreen ? const ClampingScrollPhysics() : const ScrollPhysics(),
            itemCount: activeOrders.length,
            separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 12),
            itemBuilder: (context, index) {
              final entry = activeOrders[index];
              final String tableKey = entry.key;

              String tableName = tableKey.startsWith('order_') ? 'Takeaway/Delivery' : tableKey;
              final matchTable = tables.allTables.where((t) => t.id == tableKey).firstOrNull;
              if (matchTable != null) {
                tableName = matchTable.name;
              }

              final customerName = orders.orderCustomerNames[tableKey] ?? 'Guest';
              final orderType = orders.orderTypes[tableKey]?.toUpperCase() ?? 'DINE-IN';

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFD4AF37), size: 14),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tableName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                'Cust: $customerName  •  Type: $orderType', 
                                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/pos',
                        arguments: {
                          'table_id': tableKey.startsWith('order_') ? null : tableKey,
                          'id': tableKey.startsWith('order_') ? tableKey.replaceFirst('order_', '') : null,
                          'order_type': orderType.toLowerCase(),
                          'customer_name': customerName,
                        },
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 12),
                    label: const Text('ADD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                  ),
                ],
              );
            },
          );

    if (isSmallScreen) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: listWidget,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: listWidget,
    );
  }

  // Live Kitchen Alerts panel (e.g. food ready warning notifications)
  Widget _buildKitchenAlertsPanel(BuildContext context, List<Map<String, dynamic>> alerts, {required bool isSmallScreen}) {
    final listWidget = alerts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu_rounded, color: Colors.white.withOpacity(0.1), size: 40),
                const SizedBox(height: 12),
                Text('All orders are up to date.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                const SizedBox(height: 4),
                Text('No cooking alerts.', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9)),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            shrinkWrap: isSmallScreen,
            physics: isSmallScreen ? const ClampingScrollPhysics() : const ScrollPhysics(),
            itemCount: alerts.length,
            separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 12),
            itemBuilder: (context, index) {
              final alert = alerts[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.08)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Color(0xFFD4AF37), size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                alert['table_name'] ?? 'Takeaway',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'READY',
                                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${alert['dish_name']}  x${alert['quantity']}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/pos',
                                  arguments: {
                                    'table_id': alert['table_id'].startsWith('order_') ? null : alert['table_id'],
                                    'id': alert['table_id'].startsWith('order_') ? alert['table_id'].replaceFirst('order_', '') : null,
                                  },
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: const Color(0xFFD4AF37).withOpacity(0.08),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: const Text('OPEN POS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );

    if (isSmallScreen) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: listWidget,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: listWidget,
    );
  }
}
