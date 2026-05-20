import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../models/restaurant_model.dart';
import '../../services/report_service.dart';

class LeakageReportScreen extends StatefulWidget {
  const LeakageReportScreen({super.key});

  @override
  State<LeakageReportScreen> createState() => _LeakageReportScreenState();
}

class _LeakageReportScreenState extends State<LeakageReportScreen> {
  final ReportService _reportService = ReportService();
  RestaurantModel? _selectedRestaurant;
  String _selectedRange = 'Today';
  bool _isLoading = false;

  double _totalWastageCost = 0.0;
  double _totalAuditLoss = 0.0;
  double _totalFinancialLoss = 0.0;

  final List<Map<String, dynamic>> _byReason = [];
  final List<Map<String, dynamic>> _topWasted = [];
  final List<Map<String, dynamic>> _trend = [];

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

  void _fetchLeakageReport() async {
    if (_selectedRestaurant == null) return;
    setState(() {
      _isLoading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final data = await _reportService.fetchLeakageReport(
      auth.token!,
      _selectedRestaurant!.id,
      _selectedRange,
    );

    if (data != null && mounted) {
      setState(() {
        final summary = data['summary'];
        _totalWastageCost = double.tryParse(summary['total_wastage_cost'].toString()) ?? 0.0;
        _totalAuditLoss = double.tryParse(summary['total_audit_loss'].toString()) ?? 0.0;
        _totalFinancialLoss = double.tryParse(summary['total_financial_loss'].toString()) ?? 0.0;

        _byReason.clear();
        if (data['by_reason'] != null) {
          for (var item in data['by_reason']) {
            _byReason.add({
              'reason': item['reason'].toString(),
              'cost': double.tryParse(item['cost'].toString()) ?? 0.0,
            });
          }
        }

        _topWasted.clear();
        if (data['top_wasted'] != null) {
          for (var item in data['top_wasted']) {
            _topWasted.add({
              'name': item['name'].toString(),
              'qty': double.tryParse(item['qty'].toString()) ?? 0.0,
              'unit': item['unit'].toString(),
              'cost': double.tryParse(item['cost'].toString()) ?? 0.0,
            });
          }
        }

        _trend.clear();
        if (data['trend'] != null) {
          for (var item in data['trend']) {
            _trend.add({
              'label': item['label'].toString(),
              'wastage': double.tryParse(item['wastage'].toString()) ?? 0.0,
              'audit': double.tryParse(item['audit'].toString()) ?? 0.0,
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
        _fetchLeakageReport();
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => _fetchLeakageReport(),
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
                        _buildSummaryCards(isSmall),
                        const SizedBox(height: 24),
                        _buildTrendCard(isSmall),
                        const SizedBox(height: 24),
                        _buildBottomRow(isSmall),
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
                Text('WASTAGE & LEAKAGE REPORT', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                SizedBox(height: 4),
                Text('Monetary Loss and Shrinkage Cost Analysis', style: TextStyle(color: Colors.white38, fontSize: 12)),
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
              _fetchLeakageReport();
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

  Widget _buildSummaryCards(bool isSmall) {
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
            _buildStatCard('Total Financial Loss', '₹${_totalFinancialLoss.toStringAsFixed(2)}', Icons.gavel_rounded, Colors.redAccent, 'Overall Leakage'),
            _buildStatCard('Raw Wastage Spoilage', '₹${_totalWastageCost.toStringAsFixed(2)}', Icons.delete_outline_rounded, Colors.orangeAccent, 'Direct Spoilage'),
            _buildStatCard('Audit Shrinkage Loss', '₹${_totalAuditLoss.toStringAsFixed(2)}', Icons.fact_check_rounded, Colors.amberAccent, 'Theft / Variances'),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.01),
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
              const Icon(Icons.info_outline_rounded, color: Colors.white24, size: 12),
              const SizedBox(width: 4),
              Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTrendCard(bool isSmall) {
    if (_trend.isEmpty) return const SizedBox.shrink();

    double maxVal = 0.0;
    for (var d in _trend) {
      double sum = (d['wastage'] as double) + (d['audit'] as double);
      if (sum > maxVal) maxVal = sum;
    }
    if (maxVal == 0.0) maxVal = 1.0;

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
          const Text('LEAKAGE FLOW (WASTAGE + SHRINKAGE OVER TIME)', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _trend.map((d) {
                final double wasteVal = d['wastage'];
                final double auditVal = d['audit'];
                final double totalVal = wasteVal + auditVal;
                final double heightFactor = totalVal / maxVal;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('₹${(totalVal / 1000).toStringAsFixed(1)}K', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      const SizedBox(height: 8),
                      Container(
                        height: (140 * heightFactor).toDouble(),
                        width: isSmall ? 20 : 34,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                        child: Column(
                          children: [
                            if (auditVal > 0)
                              Expanded(
                                flex: (auditVal * 10).round() + 1,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.amberAccent,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                                  ),
                                ),
                              ),
                            if (wasteVal > 0)
                              Expanded(
                                flex: (wasteVal * 10).round() + 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orangeAccent,
                                    borderRadius: auditVal == 0 ? const BorderRadius.vertical(top: Radius.circular(6)) : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(d['label'], style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.orangeAccent, 'Wastage Cost'),
              const SizedBox(width: 24),
              _buildLegend(Colors.amberAccent, 'Audit Discrepancies'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Widget _buildBottomRow(bool isSmall) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildTopWastedCard()),
              const SizedBox(width: 24),
              Expanded(flex: 2, child: _buildReasonsCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildTopWastedCard(),
              const SizedBox(height: 24),
              _buildReasonsCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildTopWastedCard() {
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
          const Text('TOP 5 HIGHEST COST WASTAGE ITEMS', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _topWasted.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No wastage entries found in this period', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _topWasted.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final item = _topWasted[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Wasted Volume: ${item['qty'].toStringAsFixed(1)} ${item['unit']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            ],
                          ),
                          Text(
                            '₹${item['cost'].toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _buildReasonsCard() {
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
          const Text('WASTAGE BREAKDOWN BY REASON', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _byReason.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text('No categorized wastage found', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                )
              : Column(
                  children: _byReason.map((reason) {
                    final double cost = reason['cost'];
                    final double ratio = _totalWastageCost > 0 ? cost / _totalWastageCost : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(reason['reason'], style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('₹${cost.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 6,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
        ],
      ),
    );
  }
}
