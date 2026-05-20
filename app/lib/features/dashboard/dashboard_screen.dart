import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/order_provider.dart';
import '../../services/order_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboardStats();
    });
  }

  Future<void> _fetchDashboardStats() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token != null) {
      final orderService = OrderService();
      final stats = await orderService.fetchDashboardStats(auth.token!, 'all');
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final restoProvider = Provider.of<RestaurantProvider>(context);
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Responsive Header
            LayoutBuilder(
              builder: (context, constraints) {
                bool isNarrow = constraints.maxWidth < 400;
                return isNarrow 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildUserGreeting(auth),
                        const SizedBox(height: 16),
                        _buildBadge(context, auth),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildUserGreeting(auth)),
                        const SizedBox(width: 16),
                        _buildBadge(context, auth),
                      ],
                    );
              },
            ),
            const SizedBox(height: 40),
            
            // QUICK STATS SECTION
            const Text(
              'QUICK OVERVIEW',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                // Calculate item width based on screen width
                final double spacing = 16.0;
                final bool isMobile = constraints.maxWidth < 500;
                final int crossAxisCount = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 3 : 2);
                final double itemWidth = (constraints.maxWidth - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                final double highlightItemWidth = isMobile ? constraints.maxWidth : itemWidth;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: highlightItemWidth,
                      child: _buildStatCard(
                        'Total Outlets',
                        restoProvider.isLoading ? '...' : restoProvider.restaurants.length.toString(),
                        Icons.storefront,
                        const Color(0xFFD4AF37),
                      ),
                    ),
                    SizedBox(
                      width: highlightItemWidth,
                      child: _buildStatCard(
                        'Today\'s Sale',
                        _isLoadingStats ? '...' : '₹${_stats?['total_sales']?.toStringAsFixed(2) ?? '0.00'}',
                        Icons.currency_rupee,
                        Colors.greenAccent,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatCard(
                        'Total Orders',
                        _isLoadingStats ? '...' : '${_stats?['total_orders'] ?? 0}',
                        Icons.receipt_long,
                        Colors.blueAccent,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatCard(
                        'Delivery',
                        _isLoadingStats ? '...' : '${_stats?['delivery_orders'] ?? 0}',
                        Icons.delivery_dining,
                        Colors.orangeAccent,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatCard(
                        'Takeaway',
                        _isLoadingStats ? '...' : '${_stats?['takeaway_orders'] ?? 0}',
                        Icons.takeout_dining,
                        Colors.purpleAccent,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatCard(
                        'Dine-in',
                        _isLoadingStats ? '...' : '${_stats?['dine_in_orders'] ?? 0}',
                        Icons.restaurant,
                        Colors.pinkAccent,
                      ),
                    ),
                  ],
                );
              },
            ),
            
            const SizedBox(height: 40),
            
            // NAVIGATION SECTION
            const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            _buildActionCard(
              context,
              'Manage Restaurants',
              'View and edit your outlet details',
              Icons.restaurant,
              () {
                Navigator.of(context).pushNamedAndRemoveUntil('/restaurants', (route) => false);
              },
            ),
            const SizedBox(height: 16),
            _buildActionCard(
              context,
              'Staff Directory',
              'Manage your restaurant employees',
              Icons.people,
              () {
                Navigator.of(context).pushNamedAndRemoveUntil('/staff', (route) => false);
              },
            ),
            const SizedBox(height: 32), // Extra space at bottom
          ],
        ),
      ),
    );
  }

  Widget _buildUserGreeting(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back,',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          auth.user?.name ?? 'Admin',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 28,
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildBadge(BuildContext context, AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
          ),
          child: const Text(
            'RESTAURANT ADMIN',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        if (auth.user?.hasMultipleDashboards == true) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).setSelectedRole(null);
              Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
            },
            icon: const Icon(Icons.swap_horiz_rounded, size: 16, color: Color(0xFFD4AF37)),
            label: const Text('SWITCH ROLE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: const Color(0xFFD4AF37), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }
}
