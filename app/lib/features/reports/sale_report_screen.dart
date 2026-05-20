import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../models/restaurant_model.dart';
import '../../services/report_service.dart';

class SaleReportScreen extends StatefulWidget {
  const SaleReportScreen({super.key});

  @override
  State<SaleReportScreen> createState() => _SaleReportScreenState();
}

class _SaleReportScreenState extends State<SaleReportScreen> {
  final ReportService _reportService = ReportService();
  RestaurantModel? _selectedRestaurant;
  String _selectedRange = 'Today';
  bool _isLoading = false;

  double _totalRevenue = 0.0;
  double _revenueChange = 0.0;
  int _totalOrders = 0;
  double _ordersChange = 0.0;
  double _avgOrderValue = 0.0;
  double _avgOrderValueChange = 0.0;

  final List<Map<String, dynamic>> _salesData = [];
  final List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final restoProvider = Provider.of<RestaurantProvider>(context, listen: false);
    if (restoProvider.restaurants.isEmpty) {
      await restoProvider.fetchRestaurants(auth.token!, myRestaurants: true);
    }
  }

  void _fetchSalesReport() async {
    if (_selectedRestaurant == null) return;
    setState(() {
      _isLoading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final data = await _reportService.fetchSalesReport(
      auth.token!,
      _selectedRestaurant!.id,
      _selectedRange,
    );

    if (data != null && mounted) {
      setState(() {
        final summary = data['summary'];
        _totalRevenue = double.tryParse(summary['revenue'].toString()) ?? 0.0;
        _revenueChange = double.tryParse(summary['revenue_change'].toString()) ?? 0.0;
        _totalOrders = int.tryParse(summary['orders'].toString()) ?? 0;
        _ordersChange = double.tryParse(summary['orders_change'].toString()) ?? 0.0;
        _avgOrderValue = double.tryParse(summary['avg_order_value'].toString()) ?? 0.0;
        _avgOrderValueChange = double.tryParse(summary['avg_order_value_change'].toString()) ?? 0.0;

        _salesData.clear();
        if (data['trend'] != null) {
          for (var t in data['trend']) {
            _salesData.add({
              'time': t['label'].toString(),
              'sales': double.tryParse(t['value'].toString()) ?? 0.0,
            });
          }
        }
        if (_salesData.isEmpty) {
          _salesData.addAll([
            {'time': '09 AM', 'sales': 0.0},
            {'time': '12 PM', 'sales': 0.0},
            {'time': '03 PM', 'sales': 0.0},
            {'time': '06 PM', 'sales': 0.0},
            {'time': '09 PM', 'sales': 0.0},
          ]);
        }

        _transactions.clear();
        if (data['recent'] != null) {
          for (var t in data['recent']) {
            final String rawId = t['id'].toString();
            final String shortId = rawId.length > 8 ? rawId.substring(rawId.length - 8) : rawId;
            _transactions.add({
              'id': '#$shortId',
              'customer': t['customer'].toString(),
              'type': t['type'].toString(),
              'payment': t['payment'].toString(),
              'total': '₹${double.tryParse(t['total'].toString())?.toStringAsFixed(2) ?? '0.00'}',
              'time': t['time'].toString(),
            });
          }
        }

        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 600;
    final restoProvider = Provider.of<RestaurantProvider>(context);

    final activeResto = restoProvider.selectedRestaurant ?? (restoProvider.restaurants.isNotEmpty ? restoProvider.restaurants.first : null);
    if (activeResto?.id != _selectedRestaurant?.id) {
      _selectedRestaurant = activeResto;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchSalesReport();
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => _fetchSalesReport(),
        color: const Color(0xFFD4AF37),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(restoProvider),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryRow(isSmall),
                        const SizedBox(height: 24),
                        _buildChartCard(isSmall),
                        const SizedBox(height: 24),
                        _buildTransactionsCard(isSmall),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(RestaurantProvider restoProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWrap = constraints.maxWidth < 600;
        return Flex(
          direction: isWrap ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: isWrap ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('SALES REPORT', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                SizedBox(height: 4),
                Text('Real-Time Restaurant Revenue Insights', style: TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
            if (isWrap) const SizedBox(height: 16),
            Row(
              children: [
                _buildRangeToggle(),
              ],
            )
          ],
        );
      },
    );
  }

  Widget _buildRangeToggle() {
    final ranges = ['Today', 'Weekly', 'Monthly'];
    return Container(
      height: 40,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: ranges.map((r) {
          final isSelected = _selectedRange == r;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedRange = r;
              });
              _fetchSalesReport();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isSelected ? Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)) : null,
              ),
              child: Text(
                r,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryRow(bool isSmall) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 3 : 1);
        double aspect = constraints.maxWidth > 800 ? 1.8 : 1.5;

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: aspect,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard('Total Revenue', '₹${_totalRevenue.toStringAsFixed(2)}', Icons.analytics_rounded, Colors.greenAccent, '${_revenueChange >= 0 ? '+' : ''}${_revenueChange.toStringAsFixed(1)}%'),
            _buildStatCard('Total Orders', '$_totalOrders Orders', Icons.receipt_long_rounded, Colors.blueAccent, '${_ordersChange >= 0 ? '+' : ''}${_ordersChange.toStringAsFixed(1)}%'),
            _buildStatCard('Average Order Value', '₹${_avgOrderValue.toStringAsFixed(2)}', Icons.payments_rounded, const Color(0xFFD4AF37), '${_avgOrderValueChange >= 0 ? '+' : ''}${_avgOrderValueChange.toStringAsFixed(1)}%'),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String growth) {
    final isNegative = growth.startsWith('-');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(icon, color: color.withOpacity(0.8), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                isNegative ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                color: isNegative ? Colors.redAccent : Colors.greenAccent,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                growth,
                style: TextStyle(
                  color: isNegative ? Colors.redAccent : Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              const Text('vs last period', style: TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChartCard(bool isSmall) {
    if (_salesData.isEmpty) {
      return const SizedBox.shrink();
    }
    double maxVal = _salesData.map((d) => d['sales'] as double).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0.0) {
      maxVal = 1.0; // Avoid divide-by-zero
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedRange == 'Today' ? 'REVENUE FLOW (BY HOUR)' : 'REVENUE FLOW (BY DATE)',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _salesData.map((d) {
                final heightFactor = d['sales'] / maxVal;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('₹${(d['sales'] / 1000).toStringAsFixed(1)}K', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      const SizedBox(height: 8),
                      Container(
                        height: (140 * heightFactor).toDouble(),
                        width: isSmall ? 24 : 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              const Color(0xFFD4AF37).withOpacity(0.1),
                              const Color(0xFFD4AF37),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(d['time'], style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsCard(bool isSmall) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('RECENT SALES TRANSACTIONS', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _transactions.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: const [
                      Icon(Icons.receipt_long_rounded, size: 40, color: Colors.white24),
                      SizedBox(height: 12),
                      Text('No transactions found', style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _transactions.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final txn = _transactions[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.receipt_rounded, color: Color(0xFFD4AF37), size: 18),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(txn['customer'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('${txn['id']} • ${txn['time']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(txn['total'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(txn['type'], style: const TextStyle(color: Colors.white60, fontSize: 9)),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(txn['payment'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }
}
