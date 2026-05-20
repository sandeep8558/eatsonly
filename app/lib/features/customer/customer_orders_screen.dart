import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../services/order_service.dart';
import '../../models/restaurant_model.dart';
import 'restaurant_menu_screen.dart';

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});

  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  final OrderService _orderService = OrderService();
  
  final List<dynamic> _activeOrders = [];
  final List<dynamic> _pastOrders = [];
  
  int _currentPage = 1;
  bool _hasMore = false;
  bool _isLoadingActive = false;
  bool _isLoadingHistory = false;
  Timer? _refreshTimer;

  Razorpay? _razorpay;
  String? _activePayingOrderId;
  String? _activePayingToken;
  double _activePayingTotal = 0.0;

  @override
  void initState() {
    super.initState();
    
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
    _startLiveTrackingRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _razorpay?.clear();
    }
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final orderId = _activePayingOrderId;
    final token = _activePayingToken;
    final total = _activePayingTotal;
    if (orderId == null || token == null) return;

    // Record the payment on the backend then show success
    _orderService.generateBill(
      token,
      orderId,
      'ONLINE',
      amountPaid: total,
      subtotal: total,
      tax: 0,
      total: total,
    ).then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment Successful! Order is now being prepared.')),
        );
        _loadOrders(); // Refresh lists
      }
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Transaction cancelled"}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void _startNativeRazorpayCheckout(String token, String orderId, double total, String userName, String userPhone) {
    _activePayingOrderId = orderId;
    _activePayingToken = token;
    _activePayingTotal = total;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: Card(
            color: Color(0xFF0C0C0C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              side: BorderSide(color: Color(0xFFD4AF37), width: 0.5),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  SizedBox(height: 16),
                  Text(
                    'Opening Razorpay...',
                    style: TextStyle(color: Colors.white70, fontSize: 13, decoration: TextDecoration.none),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    _orderService.initiateRazorpayPayment(token, orderId).then((data) {
      if (mounted) Navigator.pop(context);

      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to initialize payment. Please try again.')),
          );
        }
        return;
      }

      final String? rzpKey = data['razorpay_key'];
      final String? rzpOrderId = data['razorpay_order_id'];
      final int? amount = data['amount'];

      if (rzpKey == null || rzpOrderId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid payment configuration from server.')),
          );
        }
        return;
      }

      try {
        _razorpay?.open({
          'key': rzpKey,
          'order_id': rzpOrderId,
          'amount': amount ?? (total * 100).toInt(),
          'currency': 'INR',
          'name': 'EatsOnly',
          'description': 'Order #${orderId.substring(0, 8).toUpperCase()}',
          'prefill': {
            'name': userName,
            'contact': userPhone,
          },
          'image': '${ApiConstants.baseUrl.replaceAll("/api", "")}/logo.png',
          'theme': {'color': '#D4AF37'},
          'timeout': 300,
        });
      } catch (e) {
        debugPrint('Razorpay open error: $e');
      }
    }).catchError((err) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $err')),
        );
      }
    });
  }

  void _startLiveTrackingRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) return;
      
      if (_activeOrders.isNotEmpty) {
        _loadActiveOrdersOnly();
      }
    });
  }

  Future<void> _loadActiveOrdersOnly() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    try {
      final active = await _orderService.fetchActiveOrders(token, 'all');
      if (mounted) {
        final wasNotEmpty = _activeOrders.isNotEmpty;
        final isNowEmptyOrReduced = active.length < _activeOrders.length;
        
        if (wasNotEmpty && isNowEmptyOrReduced) {
          // Robustly reload the entire dashboard to seamlessly populate Order History!
          _loadOrders();
        } else {
          setState(() {
            _activeOrders.clear();
            _activeOrders.addAll(active);
          });
        }
      }
    } catch (e) {
      debugPrint("Live tracking active order fetch error: $e");
    }
  }

  Future<void> _loadOrders() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    setState(() {
      _isLoadingActive = true;
      _isLoadingHistory = true;
    });

    try {
      // 1. Fetch active orders from central master registry
      final active = await _orderService.fetchActiveOrders(token, 'all');
      
      // 2. Fetch past orders from central master registry (Page 1)
      final historyData = await _orderService.fetchAllOrders(token, 'all', page: 1, perPage: 5);

      if (mounted) {
        setState(() {
          _activeOrders.clear();
          _activeOrders.addAll(active);
          
          _pastOrders.clear();
          _pastOrders.addAll(historyData['orders']);
          
          _currentPage = historyData['current_page'];
          _hasMore = _currentPage < historyData['last_page'];
          
          _isLoadingActive = false;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingActive = false;
          _isLoadingHistory = false;
        });
      }
    }
  }

  Future<void> _loadMorePastOrders() async {
    if (_isLoadingHistory || !_hasMore) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final historyData = await _orderService.fetchAllOrders(token, 'all', page: nextPage, perPage: 5);

      if (mounted) {
        setState(() {
          _pastOrders.addAll(historyData['orders']);
          _currentPage = historyData['current_page'];
          _hasMore = _currentPage < historyData['last_page'];
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null) return 'Recent';
    try {
      final dt = DateTime.parse(rawDate);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
    } catch (_) {
      return 'Recent';
    }
  }

  double _getStatusProgress(String? status) {
    final s = (status ?? 'open').toLowerCase();
    if (s == 'completed' || s == 'delivered' || s == 'paid') return 1.0;
    if (s == 'on the way' || s == 'ready') return 0.75;
    if (s == 'preparing' || s == 'cooking') return 0.5;
    return 0.25; // open, placed, pending
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: const Color(0xFFD4AF37),
      backgroundColor: const Color(0xFF16181D),
      onRefresh: _loadOrders,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // Active Orders Section (Always fully shown)
            if (_isLoadingActive && _activeOrders.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                ),
              ),
            ] else if (_activeOrders.isNotEmpty) ...[
              const Text('ACTIVE ORDERS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              ..._activeOrders.map((order) {
                final displayId = (order['tenant_order_id'] ?? '').toString();
                final orderIdShort = displayId.length > 5 ? displayId.substring(0, 5).toUpperCase() : displayId;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: _buildActiveOrderCard(
                    context,
                    orderId: '#EO-$orderIdShort',
                    orderIdRaw: order['tenant_order_id'].toString(),
                    totalRaw: double.tryParse(order['total']?.toString() ?? '0') ?? 0.0,
                    restaurantName: order['restaurant_name'] ?? 'Restaurant',
                    status: order['status'] ?? 'open',
                    statusProgress: _getStatusProgress(order['status']),
                    items: order['items_summary'] ?? '',
                    total: '₹${double.tryParse(order['total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}',
                    riderLatitude: double.tryParse(order['rider_latitude']?.toString() ?? ''),
                    riderLongitude: double.tryParse(order['rider_longitude']?.toString() ?? ''),
                    deliveryLatitude: double.tryParse(order['delivery_latitude']?.toString() ?? ''),
                    deliveryLongitude: double.tryParse(order['delivery_longitude']?.toString() ?? ''),
                    orderType: order['order_type']?.toString(),
                    restaurantData: order['restaurant'] as Map<String, dynamic>?,
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Past Orders Section
            Text('ORDER HISTORY', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 16),

            if (_isLoadingHistory && _pastOrders.isEmpty) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                ),
              ),
            ] else if (_pastOrders.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48.0),
                  child: Column(
                    children: [
                      Icon(Icons.history_rounded, size: 48, color: Colors.white.withOpacity(0.1)),
                      const SizedBox(height: 16),
                      Text('No order history yet.', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ..._pastOrders.map((order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildPastOrderCard(
                    context,
                    order,
                  ),
                );
              }),
            ],

            // Load More Button
            if (_hasMore) ...[
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoadingHistory ? null : _loadMorePastOrders,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: const Color(0xFFD4AF37),
                      disabledBackgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoadingHistory
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.expand_more_rounded, size: 20),
                              SizedBox(width: 8),
                              Text('LOAD MORE ORDERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderCard(BuildContext context, {
    required String orderId,
    required String orderIdRaw,
    required double totalRaw,
    required String restaurantName,
    required String status,
    required double statusProgress,
    required String items,
    required String total,
    double? riderLatitude,
    double? riderLongitude,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? orderType,
    Map<String, dynamic>? restaurantData,
  }) {
    final normalizedType = (orderType ?? 'delivery').toString().toLowerCase().replaceAll('-', '_');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurantName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Order ID: $orderId', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(items, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Paid:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 12)),
              Text(total, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator(context, 'Placed', true),
              _buildStepIndicator(context, 'Cooking', statusProgress >= 0.5),
              if (normalizedType == 'takeaway') ...[
                _buildStepIndicator(context, 'Ready', statusProgress >= 0.75),
                _buildStepIndicator(context, 'Collected', statusProgress >= 1.0),
              ] else ...[
                _buildStepIndicator(context, 'On the Way', statusProgress >= 0.75),
                _buildStepIndicator(context, 'Arrived', statusProgress >= 1.0),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: statusProgress,
              backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              color: const Color(0xFFD4AF37),
              minHeight: 6,
            ),
          ),
          
          // 1. Embed Live Interactive Map ONLY when order type is delivery and dispatched
          if (normalizedType == 'delivery' && (statusProgress >= 0.75 || status == 'on the way')) ...[
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                // Determine locations
                final double rLat = riderLatitude ?? 18.5204;
                final double rLng = riderLongitude ?? 73.8567;
                
                // If customer address coordinates are null, place the customer 400 meters away for a perfect simulated routing line!
                final double dLat = deliveryLatitude ?? (rLat + 0.0035);
                final double dLng = deliveryLongitude ?? (rLng + 0.0035);
                final double latDiff = (rLat - dLat).abs();
                final double lngDiff = (rLng - dLng).abs();
                final double maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

                return Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: FlutterMap(
                      key: ValueKey('${orderId}_${rLat}_${rLng}_${dLat}_$dLng'),
                      options: maxDiff < 0.0001
                          ? MapOptions(
                              initialCenter: LatLng(rLat, rLng),
                              initialZoom: 15.5,
                            )
                          : MapOptions(
                              initialCameraFit: CameraFit.bounds(
                                bounds: LatLngBounds.fromPoints([
                                  LatLng(rLat, rLng),
                                  LatLng(dLat, dLng),
                                ]),
                                padding: const EdgeInsets.all(50.0),
                              ),
                            ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.eatsonly.app',
                        ),
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: [
                                LatLng(rLat, rLng),
                                LatLng(dLat, dLng),
                              ],
                              color: Colors.blueAccent,
                              strokeWidth: 4.0,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            // Rider Marker
                            Marker(
                              point: LatLng(rLat, rLng),
                              width: 38,
                              height: 38,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.delivery_dining_rounded,
                                  color: Colors.black,
                                  size: 20,
                                ),
                              ),
                            ),
                            // Destination Marker
                            Marker(
                              point: LatLng(dLat, dLng),
                              width: 38,
                              height: 38,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.home_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      riderLatitude != null ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
                      color: const Color(0xFFD4AF37),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'LIVE DELIVERY TRACKING',
                          style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          riderLatitude != null
                              ? 'Rider is bringing your delicious meal!'
                              : 'Waiting for rider to start GPS live tracking...',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        if (riderLatitude != null && riderLongitude != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Location: ${riderLatitude.toStringAsFixed(5)}, ${riderLongitude.toStringAsFixed(5)}',
                            style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: riderLatitude != null ? Colors.green : Colors.amber,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 2. Embed Navigate storefront button panel ONLY when order type is takeaway
          if (normalizedType == 'takeaway') ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final double? rLat = double.tryParse(restaurantData?['latitude']?.toString() ?? '');
                  final double? rLng = double.tryParse(restaurantData?['longitude']?.toString() ?? '');
                  final String addr = restaurantData?['address']?.toString() ?? restaurantName;
                  _openDirectionsInGoogleMaps(rLat != null && rLng != null ? '$rLat,$rLng' : addr);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('NAVIGATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],

          // 3. Embed Pay Now button panel ONLY when order status is pending_payment
          if (status.toLowerCase() == 'pending_payment') ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.payment_rounded,
                              color: Color(0xFFD4AF37),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'PAYMENT PENDING',
                              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Complete payment to send order to kitchen',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final token = authProvider.token;
                      final userName = authProvider.user?.name ?? 'Customer';
                      final userPhone = authProvider.user?.mobile ?? '';
                      if (token != null) {
                        _startNativeRazorpayCheckout(token, orderIdRaw, totalRaw, userName, userPhone);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    icon: const Icon(Icons.credit_card_rounded, size: 16),
                    label: const Text('PAY NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

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

  Widget _buildStepIndicator(BuildContext context, String label, bool isCompleted) {
    return Column(
      children: [
        Icon(
          isCompleted ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
          color: isCompleted ? const Color(0xFFD4AF37) : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
          size: 18,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: isCompleted ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontSize: 10,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPastOrderCard(BuildContext context, Map<String, dynamic> order) {
    final displayId = (order['tenant_order_id'] ?? '').toString();
    final orderIdShort = displayId.length > 5 ? displayId.substring(0, 5).toUpperCase() : displayId;
    final orderId = '#EO-$orderIdShort';
    final restaurantName = order['restaurant_name'] ?? 'Restaurant';
    final date = _formatDate(order['created_at']);
    final items = order['items_summary'] ?? '';
    final total = '₹${double.tryParse(order['total']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}';
    final status = order['status'] ?? 'completed';
    final isCancelled = status.toLowerCase() == 'cancelled';
    final restaurantData = order['restaurant'] as Map<String, dynamic>?;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurantName, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('$orderId • $date', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCancelled ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: isCancelled ? Colors.red : Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(items, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13)),
          const SizedBox(height: 12),
          Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(total, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14)),
              OutlinedButton(
                onPressed: () {
                  if (restaurantData != null) {
                    final restaurant = RestaurantModel.fromJson(restaurantData);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantMenuScreen(restaurant: restaurant),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Restaurant details not available for this order.')),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Reorder', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
