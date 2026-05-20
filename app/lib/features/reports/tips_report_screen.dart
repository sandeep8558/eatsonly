import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../services/report_service.dart';
import 'package:intl/intl.dart';

class TipsReportScreen extends StatefulWidget {
  const TipsReportScreen({super.key});

  @override
  State<TipsReportScreen> createState() => _TipsReportScreenState();
}

class _TipsReportScreenState extends State<TipsReportScreen> {
  final ReportService _reportService = ReportService();
  bool _isLoading = true;
  Map<String, dynamic>? _reportData;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _loadedRestaurantId;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final restaurant = Provider.of<RestaurantProvider>(context, listen: false);
    
    if (restaurant.restaurants.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    final activeRestaurantId = restaurant.selectedRestaurant?.id ?? restaurant.restaurants.first.id;

    final data = await _reportService.fetchTipReport(
      auth.token!,
      activeRestaurantId.toString(),
      startDate: DateFormat('yyyy-MM-dd').format(_startDate),
      endDate: DateFormat('yyyy-MM-dd').format(_endDate),
    );

    setState(() {
      _reportData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = Provider.of<RestaurantProvider>(context);
    final activeRestaurantId = restaurant.selectedRestaurant?.id ?? (restaurant.restaurants.isNotEmpty ? restaurant.restaurants.first.id : null);

    if (activeRestaurantId != null && activeRestaurantId != _loadedRestaurantId) {
      _loadedRestaurantId = activeRestaurantId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadReport();
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))))
            else if (_reportData == null)
              const Expanded(child: Center(child: Text('Failed to load report data', style: TextStyle(color: Colors.white54))))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSummaryCards(),
                      const SizedBox(height: 32),
                      _buildBreakdownSections(),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 16,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tip Management',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            const SizedBox(height: 4),
            Text(
              'Tracking staff incentives and tip performance',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildDateButton('Start', _startDate, (date) {
              setState(() => _startDate = date);
              _loadReport();
            }),
            _buildDateButton('End', _endDate, (date) {
              setState(() => _endDate = date);
              _loadReport();
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildDateButton(String label, DateTime date, Function(DateTime) onSelected) {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (selected != null) onSelected(selected);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Text(
              '$label: ',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.calendar_today_rounded, color: Color(0xFFD4AF37), size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final summary = _reportData!['summary'];
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isNarrow = constraints.maxWidth < 600;
        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            SizedBox(
              width: isNarrow ? double.infinity : (constraints.maxWidth - 48) / 3,
              child: _buildStatCard(
                'Total Tips',
                '₹${summary['total_tips'].toStringAsFixed(2)}',
                Icons.payments_rounded,
                const Color(0xFFD4AF37),
              ),
            ),
            SizedBox(
              width: isNarrow ? double.infinity : (constraints.maxWidth - 48) / 3,
              child: _buildStatCard(
                'Orders with Tips',
                summary['order_count'].toString(),
                Icons.receipt_long_rounded,
                Colors.blue,
              ),
            ),
            SizedBox(
              width: isNarrow ? double.infinity : (constraints.maxWidth - 48) / 3,
              child: _buildStatCard(
                'Avg. Tip/Order',
                '₹${summary['average_tip'].toStringAsFixed(2)}',
                Icons.trending_up_rounded,
                Colors.green,
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSections() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isNarrow = constraints.maxWidth < 800;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildStaffPerformance(),
              const SizedBox(height: 32),
              _buildDateTrend(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildStaffPerformance()),
            const SizedBox(width: 32),
            Expanded(flex: 1, child: _buildDateTrend()),
          ],
        );
      }
    );
  }

  Widget _buildStaffPerformance() {
    final List<dynamic> byWaiter = _reportData!['by_waiter'];
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Staff Performance',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  _buildTableHeader('Staff Member'),
                  _buildTableHeader('Orders'),
                  _buildTableHeader('Total Tips'),
                ],
              ),
              ...byWaiter.map((w) => TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
                          child: Text(w['waiter_name'][0].toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Text(w['waiter_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(w['order_count'].toString(), style: const TextStyle(color: Colors.white70)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text('₹${w['total_tips'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              )),
            ],
          ),
          if (byWaiter.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('No tip data available for this period', style: TextStyle(color: Colors.white24))),
            ),
        ],
      ),
    );
  }

  Widget _buildDateTrend() {
    final List<dynamic> byDate = _reportData!['by_date'];
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Trend',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...byDate.take(7).map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE').format(DateTime.parse(d['date'])), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(DateFormat('MMM dd').format(DateTime.parse(d['date'])), style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                  ],
                ),
                Text('₹${d['total_tips'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ],
            ),
          )),
          if (byDate.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('No trend data', style: TextStyle(color: Colors.white24))),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
      ),
    );
  }
}
