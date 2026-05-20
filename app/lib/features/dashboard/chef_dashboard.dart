import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/kot_provider.dart';
import '../../core/widgets/attendance_header.dart';

class ChefDashboard extends StatefulWidget {
  const ChefDashboard({super.key});

  @override
  State<ChefDashboard> createState() => _ChefDashboardState();
}

class _ChefDashboardState extends State<ChefDashboard> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshKots();
    });
  }

  Future<void> _refreshKots() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final resto = Provider.of<RestaurantProvider>(context, listen: false);
    final kotProvider = Provider.of<KotProvider>(context, listen: false);

    if (auth.token == null) return;

    try {
      await resto.fetchRestaurants(auth.token!, myRestaurants: true);
      if (resto.selectedRestaurant != null) {
        final restaurantId = resto.selectedRestaurant!.id;
        await kotProvider.fetchActiveKots(auth.token!, restaurantId);
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

  Future<void> _completeKot(String kotId) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final kotProvider = Provider.of<KotProvider>(context, listen: false);
    if (auth.token == null) return;

    final success = await kotProvider.updateStatus(auth.token!, kotId, 'completed');
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ticket marked as COMPLETED successfully.', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Color(0xFFD4AF37),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final resto = Provider.of<RestaurantProvider>(context);
    final kotProvider = Provider.of<KotProvider>(context);

    final selectedResto = resto.selectedRestaurant;
    final activeKots = kotProvider.activeKots;

    // Calculate real live stats
    int activeTicketsCount = activeKots.length;
    int itemsToPrepare = 0;
    int urgentTickets = 0;

    final now = DateTime.now();
    for (var kot in activeKots) {
      final items = kot['items'] as List? ?? [];
      for (var item in items) {
        itemsToPrepare += int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      }

      try {
        final createdAtStr = kot['created_at']?.toString();
        if (createdAtStr != null) {
          final createdAt = DateTime.parse(createdAtStr.contains('Z') ? createdAtStr : '${createdAtStr}Z').toLocal();
          final difference = now.difference(createdAt).inMinutes;
          if (difference >= 15) {
            urgentTickets++;
          }
        }
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refreshKots,
        color: const Color(0xFFD4AF37),
        backgroundColor: const Color(0xFF16181D),
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
                        selectedResto != null ? selectedResto.name.toUpperCase() : 'KITCHEN TICKETS',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Chef Workspace',
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
                        onPressed: _refreshKots,
                        tooltip: 'Refresh Tickets',
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
                      Icon(Icons.kitchen_outlined, color: Colors.white24, size: 48),
                      SizedBox(height: 16),
                      Text(
                        'No Restaurant Context Selected',
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Please select a restaurant outlet from the left sidebar to load live kitchen ticket queues.',
                        style: TextStyle(color: Colors.white30, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Overview Stats Row
                const Text(
                  'KITCHEN QUEUE SUMMARY',
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
                    _buildStatCard('Active Tickets', '$activeTicketsCount', Icons.receipt_long_rounded, Colors.orangeAccent),
                    const SizedBox(width: 16),
                    _buildStatCard('Pending Items', '$itemsToPrepare', Icons.restaurant_menu_rounded, const Color(0xFFD4AF37)),
                    const SizedBox(width: 16),
                    _buildStatCard('Urgent Tickets', '$urgentTickets', Icons.warning_amber_rounded, Colors.redAccent),
                  ],
                ),
              ],
              const SizedBox(height: 40),

              // Active Tickets Feed List Header
              const Text(
                'LIVE WORK CUE',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Feed Queue
              Expanded(
                child: activeKots.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.done_all_rounded, color: Colors.white24, size: 44),
                            const SizedBox(height: 12),
                            Text(
                              'All tickets prepared!',
                              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                            ),
                            Text(
                              'New orders sent from the POS will appear here.',
                              style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: activeKots.length,
                        physics: const BouncingScrollPhysics(),
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final kot = activeKots[index];
                          final String orderId = kot['order_id']?.toString() ?? '';
                          final String tableLabel = kot['order']?['table']?['name'] ?? 'Direct';
                          
                          // Parse elapsed minutes
                          int minutesElapsed = 0;
                          try {
                            final createdAtStr = kot['created_at']?.toString();
                            if (createdAtStr != null) {
                              final createdAt = DateTime.parse(createdAtStr.contains('Z') ? createdAtStr : '${createdAtStr}Z').toLocal();
                              minutesElapsed = now.difference(createdAt).inMinutes;
                            }
                          } catch (_) {}

                          // Build concise list of items in the KOT
                          final items = kot['items'] as List? ?? [];
                          final String itemsSummary = items.map((i) {
                            final qty = i['quantity'] ?? '1';
                            final name = i['menu_item']?['name'] ?? 'Unknown';
                            return '${qty}x $name';
                          }).join(', ');

                          final bool isUrgent = minutesElapsed >= 15;

                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.03),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isUrgent ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: (isUrgent ? Colors.red : const Color(0xFFD4AF37)).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '${minutesElapsed}m',
                                    style: TextStyle(
                                      color: isUrgent ? Colors.redAccent : const Color(0xFFD4AF37),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Table $tableLabel - Order #${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        itemsSummary,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 13,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _completeKot(kot['id'].toString()),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isUrgent ? Colors.redAccent : Colors.teal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                  ),
                                  child: const Text('Complete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
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
}
