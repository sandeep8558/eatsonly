import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../models/restaurant_model.dart';
import '../../services/report_service.dart';

class MenuMatrixReportScreen extends StatefulWidget {
  const MenuMatrixReportScreen({super.key});

  @override
  State<MenuMatrixReportScreen> createState() => _MenuMatrixReportScreenState();
}

class _MenuMatrixReportScreenState extends State<MenuMatrixReportScreen> {
  final ReportService _reportService = ReportService();
  RestaurantModel? _selectedRestaurant;
  String _selectedRange = 'Today';
  bool _isLoading = false;

  double _avgVolume = 0.0;
  double _avgMargin = 0.0;

  final List<Map<String, dynamic>> _matrixItems = [];
  String _selectedQuadrantTab = 'Stars';

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

  void _fetchMenuMatrix() async {
    if (_selectedRestaurant == null) return;
    setState(() {
      _isLoading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final data = await _reportService.fetchMenuEngineeringReport(
      auth.token!,
      _selectedRestaurant!.id,
      _selectedRange,
    );

    if (data != null && mounted) {
      setState(() {
        _avgVolume = double.tryParse(data['averages']['volume'].toString()) ?? 0.0;
        _avgMargin = double.tryParse(data['averages']['margin'].toString()) ?? 0.0;

        _matrixItems.clear();
        if (data['matrix'] != null) {
          for (var item in data['matrix']) {
            _matrixItems.add({
              'id': item['id'].toString(),
              'name': item['name'].toString(),
              'price': double.tryParse(item['price'].toString()) ?? 0.0,
              'volume': int.tryParse(item['volume'].toString()) ?? 0,
              'margin': double.tryParse(item['margin'].toString()) ?? 0.0,
              'recipe_cost': double.tryParse(item['recipe_cost'].toString()) ?? 0.0,
              'quadrant': item['quadrant'].toString(),
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
        _fetchMenuMatrix();
      });
    }

    // Filter items based on active quadrant tab
    final filteredItems = _matrixItems.where((i) => i['quadrant'] == _selectedQuadrantTab).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => _fetchMenuMatrix(),
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
                        _buildAveragesCard(isSmall),
                        const SizedBox(height: 24),
                        _buildQuadrantSelector(isSmall),
                        const SizedBox(height: 24),
                        _buildQuadrantItemsCard(filteredItems, isSmall),
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
                Text('MENU POPULARITY & PROFITABILITY', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                SizedBox(height: 4),
                Text('BCG Menu Engineering Matrix (Volume vs Profit Margin)', style: TextStyle(color: Colors.white38, fontSize: 12)),
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
              _fetchMenuMatrix();
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

  Widget _buildAveragesCard(bool isSmall) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AVERAGE ITEM VOLUME', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('${_avgVolume.toStringAsFixed(1)} Units', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white10),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AVERAGE GROSS PROFIT MARGIN', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('₹${_avgMargin.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuadrantSelector(bool isSmall) {
    final quadrants = [
      {'name': 'Stars', 'desc': 'High Profit • High Sales', 'color': Colors.greenAccent, 'icon': Icons.star_rounded},
      {'name': 'Plowhorses', 'desc': 'Low Profit • High Sales', 'color': Colors.blueAccent, 'icon': Icons.trending_up_rounded},
      {'name': 'Puzzles', 'desc': 'High Profit • Low Sales', 'color': Colors.purpleAccent, 'icon': Icons.help_outline_rounded},
      {'name': 'Dogs', 'desc': 'Low Profit • Low Sales', 'color': Colors.redAccent, 'icon': Icons.dangerous_rounded},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int count = constraints.maxWidth > 800 ? 4 : (constraints.maxWidth > 500 ? 2 : 1);
        double aspect = constraints.maxWidth > 800 ? 2.0 : 2.5;

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspect,
          physics: const NeverScrollableScrollPhysics(),
          children: quadrants.map((quad) {
            final String name = quad['name'] as String;
            final Color color = quad['color'] as Color;
            final isSelected = _selectedQuadrantTab == name;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedQuadrantTab = name;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? color.withOpacity(0.08) : const Color(0xFF16181D),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? color.withOpacity(0.4) : Colors.white.withOpacity(0.03)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? color : Colors.white38,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Icon(quad['icon'] as IconData, color: isSelected ? color : Colors.white24, size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quad['desc'] as String,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
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

  Widget _buildQuadrantItemsCard(List<Map<String, dynamic>> items, bool isSmall) {
    Color activeColor = Colors.greenAccent;
    if (_selectedQuadrantTab == 'Plowhorses') activeColor = Colors.blueAccent;
    if (_selectedQuadrantTab == 'Puzzles') activeColor = Colors.purpleAccent;
    if (_selectedQuadrantTab == 'Dogs') activeColor = Colors.redAccent;

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
                'QUADRANT MEMBERS: ${_selectedQuadrantTab.toUpperCase()}',
                style: TextStyle(color: activeColor, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${items.length} dishes',
                  style: TextStyle(color: activeColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          items.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 40, color: Colors.white24),
                      const SizedBox(height: 12),
                      Text('No dishes fall into this quadrant during this period', style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final double grossRev = item['price'] * item['volume'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _buildStatBadge('Price: ₹${item['price'].toStringAsFixed(0)}'),
                                    const SizedBox(width: 8),
                                    _buildStatBadge('Cost: ₹${item['recipe_cost'].toStringAsFixed(1)}'),
                                    const SizedBox(width: 8),
                                    _buildStatBadge('Volume: ${item['volume']} sold', color: activeColor.withOpacity(0.1), textCol: activeColor),
                                  ],
                                )
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${item['margin'].toStringAsFixed(2)} margin',
                                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rev: ₹${grossRev.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                              )
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

  Widget _buildStatBadge(String label, {Color? color, Color? textCol}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(color: textCol ?? Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
