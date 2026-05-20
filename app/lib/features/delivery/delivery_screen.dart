import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/delivery_provider.dart';
import '../../core/order_provider.dart';
import '../../models/restaurant_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RestaurantModel? _selectedRestaurant;
  Timer? _locationTimer;
  DateTime? _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initRestaurantAndLoad();
    });
    _startLocationTracking();
  }

  void _startLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) return;
      final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token == null) return;

      // Find any active order with status 'on_the_way' or 'picked_up'
      final dispatchedOrders = deliveryProvider.activeDeliveries
          .where((d) => d['delivery_status'] == 'on_the_way' || d['delivery_status'] == 'picked_up')
          .toList();
      if (dispatchedOrders.isEmpty) return;

      try {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          return;
        }

        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );

        for (var order in dispatchedOrders) {
          await deliveryProvider.updateRiderLocation(
            auth.token!,
            order['id'].toString(),
            position.latitude,
            position.longitude,
          );
        }
      } catch (e) {
        debugPrint("Rider live location tracking error: $e");
      }
    });
  }

  void _initRestaurantAndLoad() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final restoProvider = Provider.of<RestaurantProvider>(context, listen: false);
    if (restoProvider.restaurants.isEmpty) {
      await restoProvider.fetchRestaurants(auth.token!, myRestaurants: true);
    }
    if (restoProvider.restaurants.isNotEmpty && mounted) {
      setState(() {
        _selectedRestaurant = restoProvider.selectedRestaurant ?? restoProvider.restaurants.first;
      });
      _loadDeliveryFeeds();
    }
  }

  void _loadDeliveryFeeds() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);
    final restaurantId = _selectedRestaurant?.id ?? '';
    final dateStr = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null;

    deliveryProvider.fetchActiveDeliveries(auth.token!, restaurantId: restaurantId, date: dateStr);
    deliveryProvider.fetchAvailableDeliveries(auth.token!, restaurantId: restaurantId, date: dateStr);
    deliveryProvider.fetchDeliveredDeliveries(auth.token!, restaurantId: restaurantId, date: dateStr);
    deliveryProvider.fetchSummary(auth.token!, restaurantId: restaurantId, date: dateStr);
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  // Settle Order payment modal dialog
  void _showCollectPaymentDialog(dynamic order) {
    String selectedMethod = 'cash';
    final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF16181D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COLLECT CASH / PAYMENT',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Collect payment for order #${order['id'].toString().substring(0, 6)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'AMOUNT TO COLLECT',
                            style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Outfit',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'SELECT PAYMENT MODE',
                      style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPaymentMethodOption(
                            label: 'Cash',
                            value: 'cash',
                            selectedValue: selectedMethod,
                            icon: Icons.payments_outlined,
                            onTap: () => setDialogState(() => selectedMethod = 'cash'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPaymentMethodOption(
                            label: 'UPI',
                            value: 'upi',
                            selectedValue: selectedMethod,
                            icon: Icons.qr_code_rounded,
                            onTap: () => setDialogState(() => selectedMethod = 'upi'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildPaymentMethodOption(
                            label: 'Card',
                            value: 'card',
                            selectedValue: selectedMethod,
                            icon: Icons.credit_card_rounded,
                            onTap: () => setDialogState(() => selectedMethod = 'card'),
                          ),
                        ),
                      ],
                    ),
                    if (selectedMethod == 'upi') ...[
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          width: 170,
                          height: 170,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: "upi://pay?pa=${_selectedRestaurant?.upiId ?? 'eatsonly@paytm'}&pn=${Uri.encodeComponent(_selectedRestaurant?.name ?? 'Eats Only')}&am=${total.toStringAsFixed(2)}&cu=INR",
                            version: QrVersions.auto,
                            size: 150.0,
                            gapless: false,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'UPI ID: ${_selectedRestaurant?.upiId ?? "eatsonly@paytm"}',
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Scan with GPay, PhonePe, Paytm or any UPI App to Pay',
                              style: TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL', style: TextStyle(color: Colors.white30, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD4AF37),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                           onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                            final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);

                            Navigator.pop(context);
                            
                            // Call API to record payment and complete bill
                            final result = await orderProvider.generateBill(
                              auth.token!,
                              order['id'].toString(),
                              selectedMethod,
                              amountPaid: total,
                            );

                            // Auto-deliver upon cash/UPI/card payment settlement during active delivery
                            if (result != null) {
                              await deliveryProvider.updateDeliveryStatus(
                                auth.token!,
                                order['id'].toString(),
                                'delivered',
                                restaurantId: _selectedRestaurant?.id,
                              );
                            }

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(result != null ? 'Payment Settle & Order Delivered Successfully!' : 'Failed to record payment'),
                                backgroundColor: result != null ? Colors.green : Colors.red,
                              ),
                            );
                            _loadDeliveryFeeds();
                          },
                          child: const Text('MARK PAID & SETTLE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPaymentMethodOption({
    required String label,
    required String value,
    required String selectedValue,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedValue == value;
    final Color activeColor = const Color(0xFFD4AF37);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.08) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? activeColor : Colors.white38, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Open maps with address directions
  void _openDirectionsInGoogleMaps(String address) async {
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch Maps url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open navigation directions on Google Maps.')),
        );
      }
    }
  }

  // Call customer on phone
  void _callCustomerPhone(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        throw 'Could not dial number';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call to $phone.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 500;
    final restoProvider = Provider.of<RestaurantProvider>(context);

    // Dynamic restaurant synchronization from sidebar
    final activeResto = restoProvider.selectedRestaurant ?? (restoProvider.restaurants.isNotEmpty ? restoProvider.restaurants.first : null);
    if (activeResto?.id != _selectedRestaurant?.id) {
      _selectedRestaurant = activeResto;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadDeliveryFeeds();
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildMetricsGrid(),
            const SizedBox(height: 24),
            _buildTabBar(),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDeliveriesTab(),
                  _buildAvailableDeliveriesTab(),
                  _buildDeliveredOrdersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2023),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadDeliveryFeeds();
    }
  }

  Widget _buildDateFilter() {
    final bool isSmall = MediaQuery.of(context).size.width < 500;
    return Container(
      height: isSmall ? 36 : 42,
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: InkWell(
        onTap: _selectDate,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded, size: 13, color: _selectedDate != null ? const Color(0xFFD4AF37) : Colors.white38),
            const SizedBox(width: 6),
            Text(
              _selectedDate != null ? DateFormat('MMM dd, yyyy').format(_selectedDate!) : 'All Dates',
              style: TextStyle(color: _selectedDate != null ? const Color(0xFFD4AF37) : Colors.white60, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(width: 6),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = null);
                    _loadDeliveryFeeds();
                  },
                  child: const Icon(Icons.close, size: 13, color: Color(0xFFD4AF37)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool isSmall = MediaQuery.of(context).size.width < 500;
    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DELIVERY CENTER', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
              _buildDateFilter(),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Manage outgoing shipments & assignments', style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('DELIVERY CENTER', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
              SizedBox(height: 4),
              Text('Manage outgoing shipments & assignments', style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _buildDateFilter(),
      ],
    );
  }  Widget _buildMetricsGrid() {
    return Consumer<DeliveryProvider>(
      builder: (context, provider, _) {
        final summary = provider.summary;
        final totalDeliveries = summary['total_deliveries']?.toString() ?? '0';
        final totalTips = summary['total_tips'] != null ? '₹${double.parse(summary['total_tips'].toString()).toStringAsFixed(2)}' : '₹0.00';
        final cashInHand = summary['cash_in_hand'] != null ? '₹${double.parse(summary['cash_in_hand'].toString()).toStringAsFixed(2)}' : '₹0.00';
 
        final bool isSmall = MediaQuery.of(context).size.width < 500;

        if (isSmall) {
          return SizedBox(
            height: 70,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              children: [
                SizedBox(
                  width: 140,
                  child: _buildMetricCard('Total Deliveries', totalDeliveries, Icons.task_alt_rounded, Colors.greenAccent, isSmall: true),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 145,
                  child: _buildMetricCard('Tips Earned Today', totalTips, Icons.payments_rounded, const Color(0xFFD4AF37), isSmall: true),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 165,
                  child: _buildMetricCard('Cash Collected / Hand', cashInHand, Icons.wallet_rounded, Colors.blueAccent, isSmall: true),
                ),
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
            double aspect = constraints.maxWidth > 900 ? 1.8 : 1.4;

            return GridView.count(
              shrinkWrap: true,
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 12,
              childAspectRatio: aspect,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard('Total Deliveries', totalDeliveries, Icons.task_alt_rounded, Colors.greenAccent),
                _buildMetricCard('Tips Earned Today', totalTips, Icons.payments_rounded, const Color(0xFFD4AF37)),
                _buildMetricCard('Cash Collected / Hand', cashInHand, Icons.wallet_rounded, Colors.blueAccent),
              ],
            );
          },
        );
      },
    );
  }
 
  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {bool isSmall = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 12 : 16, vertical: isSmall ? 10 : 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.white38, fontSize: isSmall ? 10 : 11, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color.withOpacity(0.8), size: isSmall ? 14 : 16),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(color: color, fontSize: isSmall ? 18 : 24, fontWeight: FontWeight.w900, fontFamily: 'Outfit'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final bool isSmall = MediaQuery.of(context).size.width < 500;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: isSmall,
        tabAlignment: isSmall ? TabAlignment.start : null,
        labelPadding: isSmall ? const EdgeInsets.symmetric(horizontal: 16) : null,
        indicator: BoxDecoration(
          color: const Color(0xFFD4AF37).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'My Assigned Active'),
          Tab(text: 'Available Deliveries'),
          Tab(text: 'Delivered Orders'),
        ],
      ),
    );
  }

  Widget _buildDeliveriesTab() {
    return Consumer<DeliveryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }

        final active = provider.activeDeliveries;
        if (active.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delivery_dining_rounded, color: Colors.white12, size: 48),
                SizedBox(height: 12),
                Text('No active assignments.', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Go to Available Deliveries to claim orders.', style: TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: active.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final d = active[index];
            return _buildDeliveryCard(d, isAssigned: true);
          },
        );
      },
    );
  }

  Widget _buildAvailableDeliveriesTab() {
    return Consumer<DeliveryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }

        final available = provider.availableDeliveries;
        if (available.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.thumb_up_alt_rounded, color: Colors.white12, size: 48),
                SizedBox(height: 12),
                Text('All caught up!', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('No available orders pending rider assignment.', style: TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: available.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final d = available[index];
            return _buildDeliveryCard(d, isAssigned: false);
          },
        );
      },
    );
  }

  Widget _buildDeliveredOrdersTab() {
    return Consumer<DeliveryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }

        final delivered = provider.deliveredDeliveries;
        if (delivered.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline_rounded, color: Colors.white12, size: 48),
                SizedBox(height: 12),
                Text('No delivered orders.', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Completed orders will appear here.', style: TextStyle(color: Colors.white24, fontSize: 11)),
              ],
            ),
          );
        }

        return ListView.separated(
          itemCount: delivered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final d = delivered[index];
            return _buildDeliveryCard(d, isAssigned: true);
          },
        );
      },
    );
  }

  Widget _buildDeliveryCard(dynamic d, {required bool isAssigned}) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);

    final String orderId = d['id']?.toString() ?? 'N/A';
    final total = double.tryParse(d['total']?.toString() ?? '0') ?? 0.0;
    
    // Check payment status (paid or completed)
    final bool isPaid = d['status']?.toString().toLowerCase() == 'completed' || d['status']?.toString().toLowerCase() == 'paid';
    final String deliveryStatus = d['delivery_status']?.toString().toLowerCase() ?? 'pending';

    // Parse date safely
    DateTime? date;
    try {
      if (d['created_at'] != null) {
        date = DateTime.parse(d['created_at'].toString()).toLocal();
      }
    } catch (e) {}
    final formattedDate = date != null ? DateFormat('hh:mm a').format(date) : 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('#${orderId.substring(0, 6).toUpperCase()}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(formattedDate, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  ),
                ],
              ),
              _buildDeliveryStatusBadge(deliveryStatus),
            ],
          ),
          const SizedBox(height: 16),
          
          // Customer details Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('CUSTOMER', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(d['customer_name'] ?? 'Guest Customer', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              if (d['customer_phone'] != null)
                IconButton(
                  icon: const Icon(Icons.phone_rounded, color: Colors.greenAccent, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.greenAccent.withOpacity(0.08),
                    padding: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _callCustomerPhone(d['customer_phone'].toString()),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Address details Row
          const Text('DELIVERY ADDRESS', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFFD4AF37), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  d['delivery_address'] ?? 'No delivery address provided.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Google maps navigation button
          if (d['delivery_address'] != null) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.navigation_rounded, size: 14, color: Colors.black),
              label: const Text('GET DIRECTIONS (MAPS)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onPressed: () => _openDirectionsInGoogleMaps(d['delivery_address'].toString()),
            ),
            const SizedBox(height: 20),
          ],

          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 16),
          
          // Payment & Collect Cash Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ORDER AMOUNT', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isPaid || d['payment_method']?.toString().toLowerCase() == 'online') ? Colors.greenAccent.withOpacity(0.08) : Colors.redAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isPaid ? 'PAID' : (d['payment_method']?.toString().toLowerCase() == 'online' ? 'PAID ONLINE' : 'UNPAID'),
                          style: TextStyle(
                            color: (isPaid || d['payment_method']?.toString().toLowerCase() == 'online') ? Colors.greenAccent : Colors.redAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!isPaid && isAssigned && d['payment_method']?.toString().toLowerCase() != 'online')
                ElevatedButton.icon(
                  icon: const Icon(Icons.payments_rounded, size: 12, color: Colors.black),
                  label: const Text('COLLECT CASH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _showCollectPaymentDialog(d),
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Action triggers: Self-assign OR Update Sequential Deliveries Status
          if (!isAssigned) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.black),
                label: const Text('ACCEPT DELIVERY / SELF-ASSIGN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  final success = await deliveryProvider.acceptDelivery(
                    auth.token!,
                    d['id'].toString(),
                    restaurantId: _selectedRestaurant?.id,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Delivery accepted and assigned to you!' : 'Failed to assign delivery'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                    _loadDeliveryFeeds();
                  }
                },
              ),
            ),
          ] else ...[
            // Status Transition Stepper & Button
            _buildTransitionButton(d, deliveryStatus, isPaid),
          ],
        ],
      ),
    );
  }

  Widget _buildTransitionButton(dynamic d, String deliveryStatus, bool isPaid) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final deliveryProvider = Provider.of<DeliveryProvider>(context, listen: false);

    String actionLabel = '';
    String nextStatus = '';
    Color buttonColor = const Color(0xFFD4AF37);

    switch (deliveryStatus) {
      case 'assigned':
        actionLabel = 'MARK AS ORDER PICKED';
        nextStatus = 'picked_up';
        break;
      case 'picked_up':
        actionLabel = 'MARK AS ON THE WAY';
        nextStatus = 'on_the_way';
        break;
      case 'on_the_way':
        actionLabel = 'MARK AS DELIVERED';
        nextStatus = 'delivered';
        buttonColor = Colors.greenAccent;
        break;
      default:
        actionLabel = 'COMPLETED';
        nextStatus = '';
    }

    if (nextStatus.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
            SizedBox(width: 8),
            Text(
              'ORDER DELIVERED SUCCESSFULLY',
              style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Horizontal mini progress stepper indicators
        Row(
          children: [
            _buildStepIndicator('Assigned', true),
            _buildStepConnector(deliveryStatus != 'assigned'),
            _buildStepIndicator('Picked Up', deliveryStatus != 'assigned'),
            _buildStepConnector(deliveryStatus == 'on_the_way' || deliveryStatus == 'delivered'),
            _buildStepIndicator('On the way', deliveryStatus == 'on_the_way' || deliveryStatus == 'delivered'),
            _buildStepConnector(deliveryStatus == 'delivered'),
            _buildStepIndicator('Delivered', deliveryStatus == 'delivered'),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              if (nextStatus == 'delivered' && !isPaid && d['payment_method']?.toString().toLowerCase() != 'online') {
                // Instantly pop up the payment collection dialog (Cash/UPI/Card) for seamless single-action flow
                _showCollectPaymentDialog(d);
                return;
              }

              final success = await deliveryProvider.updateDeliveryStatus(
                auth.token!,
                d['id'].toString(),
                nextStatus,
                restaurantId: _selectedRestaurant?.id,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Delivery status updated!' : 'Failed to update status'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
                _loadDeliveryFeeds();
              }
            },
            child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(String label, bool isActive) {
    final activeColor = const Color(0xFFD4AF37);
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.white10,
              shape: BoxShape.circle,
              boxShadow: isActive ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 4)] : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: isActive ? Colors.white70 : Colors.white24, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(
      width: 16,
      height: 1.5,
      color: isActive ? const Color(0xFFD4AF37) : Colors.white10,
    );
  }

  Widget _buildDeliveryStatusBadge(String status) {
    Color color = Colors.amberAccent;
    switch (status) {
      case 'assigned':
        color = Colors.blueAccent;
        break;
      case 'picked_up':
        color = Colors.orangeAccent;
        break;
      case 'on_the_way':
        color = Colors.yellowAccent;
        break;
      case 'delivered':
        color = Colors.greenAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
