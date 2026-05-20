import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/constants.dart';
import '../../models/restaurant_model.dart';
import '../../services/pdf_service.dart';

class CaExportsScreen extends StatefulWidget {
  const CaExportsScreen({super.key});

  @override
  State<CaExportsScreen> createState() => _CaExportsScreenState();
}

class _CaExportsScreenState extends State<CaExportsScreen> {
  RestaurantModel? _selectedRestaurant;
  String _selectedReportType = 'sales'; // 'sales', 'purchases', 'wastage'
  String _selectedPeriodType = 'month'; // 'month', 'range'

  // Month selection state
  String? _selectedMonth; // format 'YYYY-MM'
  final List<Map<String, String>> _availableMonths = [];

  // Date range state
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _initMonths();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initMonths() {
    // Generate the last 12 months dynamically starting from the current month
    final now = DateTime.now();
    for (int i = 0; i < 12; i++) {
      final date = DateTime(now.year, now.month - i, 1);
      final value = DateFormat('yyyy-MM').format(date);
      final label = DateFormat('MMMM yyyy').format(date);
      _availableMonths.add({'value': value, 'label': label});
    }
    _selectedMonth = _availableMonths.first['value'];
  }

  void _initData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final restoProvider = Provider.of<RestaurantProvider>(context, listen: false);
    if (restoProvider.restaurants.isEmpty) {
      await restoProvider.fetchRestaurants(auth.token!, myRestaurants: true);
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Color(0xFF16181D),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFD4AF37),
              onPrimary: Colors.black,
              surface: Color(0xFF16181D),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _triggerDownload() async {
    if (_selectedRestaurant == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Build URL parameters
    String url = '${ApiConstants.baseUrl}/reports/download?restaurant_id=${_selectedRestaurant!.id}&type=$_selectedReportType&token=${authProvider.token}';

    if (_selectedPeriodType == 'month') {
      if (_selectedMonth == null) return;
      url += '&month=$_selectedMonth';
    } else {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both start and end dates', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Color(0xFFD4AF37),
          ),
        );
        return;
      }
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);
      url += '&start_date=$startStr&end_date=$endStr';
    }

    try {
      final Uri uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to initiate download: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _triggerPdfGeneration() async {
    if (_selectedRestaurant == null) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Build URL parameters for JSON fetch
    String url = '${ApiConstants.baseUrl}/reports/download?restaurant_id=${_selectedRestaurant!.id}&type=$_selectedReportType&format=json';

    if (_selectedPeriodType == 'month') {
      if (_selectedMonth == null) return;
      url += '&month=$_selectedMonth';
    } else {
      if (_startDate == null || _endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select both start and end dates', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Color(0xFFD4AF37),
          ),
        );
        return;
      }
      final startStr = DateFormat('yyyy-MM-dd').format(_startDate!);
      final endStr = DateFormat('yyyy-MM-dd').format(_endDate!);
      url += '&start_date=$startStr&end_date=$endStr';
    }

    // Show processing indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
      ),
    );

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${authProvider.token}',
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading

      if (response.statusCode == 200) {
        final parsed = json.decode(response.body);
        final List<dynamic> records = parsed['data'] ?? [];

        if (records.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No transactions found for the selected period.', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Color(0xFFD4AF37),
            ),
          );
          return;
        }

        // Generate and preview PDF natively
        final pdfService = PdfService();
        final periodTitle = _selectedPeriodType == 'month'
            ? (_availableMonths.firstWhere((m) => m['value'] == _selectedMonth)['label'] ?? _selectedMonth!)
            : '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}';

        await pdfService.generateAccountingReportPdf(
          restaurantName: _selectedRestaurant!.name,
          reportType: _selectedReportType,
          periodTitle: periodTitle,
          records: records,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load transaction details (Error: ${response.statusCode})'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Ensure dismissed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error preparing ledger PDF: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 600;
    final restoProvider = Provider.of<RestaurantProvider>(context);

    final activeResto = restoProvider.selectedRestaurant ?? (restoProvider.restaurants.isNotEmpty ? restoProvider.restaurants.first : null);
    if (activeResto?.id != _selectedRestaurant?.id) {
      _selectedRestaurant = activeResto;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 28),
            _buildFormCard(isSmall),
            const SizedBox(height: 24),
            _buildGuidanceCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('CA EXPORTS & TAX DOCUMENTATION', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
        SizedBox(height: 4),
        Text('Download accounting-ready CSV files directly compatible with Tally, Zoho Books, and Excel.', style: TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _buildFormCard(bool isSmall) {
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
          const Text('1. SELECT REPORT CATEGORY', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildReportTypeGrid(isSmall),
          const SizedBox(height: 32),
          const Text('2. SELECT EXPORT PERIOD', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildPeriodTypeToggle(),
          const SizedBox(height: 20),
          _selectedPeriodType == 'month' ? _buildMonthSelector() : _buildDateRangeSelector(isSmall),
          const SizedBox(height: 40),
          LayoutBuilder(
            builder: (context, bConstraints) {
              final isButtonsWrap = bConstraints.maxWidth < 600;
              final buttons = [
                Expanded(
                  flex: isButtonsWrap ? 0 : 1,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _selectedRestaurant == null ? null : _triggerDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFFD4AF37),
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                        ),
                      ),
                      icon: const Icon(Icons.table_chart_rounded, size: 18),
                      label: const Text('DOWNLOAD CSV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ),
                if (isButtonsWrap) const SizedBox(height: 12) else const SizedBox(width: 16),
                Expanded(
                  flex: isButtonsWrap ? 0 : 1,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _selectedRestaurant == null ? null : _triggerPdfGeneration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                      label: const Text('PREVIEW & PRINT PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ),
              ];

              return Flex(
                direction: isButtonsWrap ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: isButtonsWrap ? CrossAxisAlignment.stretch : CrossAxisAlignment.center,
                children: buttons,
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildReportTypeGrid(bool isSmall) {
    final types = [
      {
        'id': 'sales',
        'title': 'Sales & Revenue',
        'desc': 'Invoices, CGST, SGST splits, discounts & payment channels.',
        'icon': Icons.trending_up_rounded
      },
      {
        'id': 'purchases',
        'title': 'Procurements & Bills',
        'desc': 'Supplier purchases, ordered inventories & total spends.',
        'icon': Icons.shopping_bag_rounded
      },
      {
        'id': 'wastage',
        'title': 'Wastage & Spoilage',
        'desc': 'Logged ingredient spillage losses with audit variance cost.',
        'icon': Icons.delete_sweep_rounded
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int count = constraints.maxWidth > 800 ? 3 : 1;
        double aspect = constraints.maxWidth > 800 ? 1.6 : 4.0;

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspect,
          physics: const NeverScrollableScrollPhysics(),
          children: types.map((t) {
            final isSelected = _selectedReportType == t['id'];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedReportType = t['id'] as String;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.4) : Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.1) : Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(t['icon'] as IconData, color: isSelected ? const Color(0xFFD4AF37) : Colors.white30, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(t['title'] as String, style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(t['desc'] as String, style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPeriodTypeToggle() {
    return Row(
      children: [
        _buildToggleOption('month', 'Month-wise Selection', Icons.calendar_month_rounded),
        const SizedBox(width: 16),
        _buildToggleOption('range', 'Custom Date Range', Icons.date_range_rounded),
      ],
    );
  }

  Widget _buildToggleOption(String value, String label, IconData icon) {
    final isSelected = _selectedPeriodType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriodType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.3) : Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFD4AF37) : Colors.white38, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          dropdownColor: const Color(0xFF16181D),
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFD4AF37)),
          onChanged: (val) {
            setState(() {
              _selectedMonth = val;
            });
          },
          items: _availableMonths.map((m) {
            return DropdownMenuItem<String>(
              value: m['value'],
              child: Text(m['label']!),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(bool isSmall) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWrap = constraints.maxWidth < 500;
        return Flex(
          direction: isWrap ? Axis.vertical : Axis.horizontal,
          children: [
            Expanded(
              flex: isWrap ? 0 : 1,
              child: InkWell(
                onTap: () => _selectStartDate(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _startDate == null ? 'Select Start Date' : DateFormat('yyyy-MM-dd').format(_startDate!),
                        style: TextStyle(color: _startDate == null ? Colors.white24 : Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.calendar_today, size: 14, color: Color(0xFFD4AF37)),
                    ],
                  ),
                ),
              ),
            ),
            if (isWrap) const SizedBox(height: 12) else const SizedBox(width: 16),
            Expanded(
              flex: isWrap ? 0 : 1,
              child: InkWell(
                onTap: () => _selectEndDate(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _endDate == null ? 'Select End Date' : DateFormat('yyyy-MM-dd').format(_endDate!),
                        style: TextStyle(color: _endDate == null ? Colors.white24 : Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.calendar_today, size: 14, color: Color(0xFFD4AF37)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGuidanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD4AF37).withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded, color: Color(0xFFD4AF37), size: 16),
              SizedBox(width: 8),
              Text('CHARTERED ACCOUNTANT COMPLIANCE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '• Sales reports are formatted as fully-structured general ledger worksheets, splitting CGST and SGST values cleanly for tax compliance.\n'
            '• Purchase spreadsheets represent detailed invoices from inventory suppliers, ideal for claiming Input Tax Credit (ITC).\n'
            '• Spoilage & Wastage lists enable accurate asset write-offs and deduction reporting.',
            style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.6),
          ),
        ],
      ),
    );
  }
}
