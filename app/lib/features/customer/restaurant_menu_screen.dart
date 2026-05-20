import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/menu_model.dart';
import '../../models/cart_model.dart';
import '../../core/auth_provider.dart';
import '../../core/customer_provider.dart';
import '../../core/settings_provider.dart';
import '../../core/menu_provider.dart';
import '../../services/order_service.dart';
import '../../services/address_service.dart';
import '../../core/constants.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/widgets/main_layout.dart';
import 'customer_addresses_screen.dart';

class RestaurantMenuScreen extends StatefulWidget {
  final RestaurantModel restaurant;

  const RestaurantMenuScreen({super.key, required this.restaurant});

  @override
  State<RestaurantMenuScreen> createState() => _RestaurantMenuScreenState();
}

class _RestaurantMenuScreenState extends State<RestaurantMenuScreen> {
  final OrderService _orderService = OrderService();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _categoryKeys = {};
  String? _selectedCategoryId; // null means 'Show All'
  final List<CartItem> _cart = [];
  bool _menuLoaded = false;
  Razorpay? _razorpay;
  String? _activePayingOrderId;
  String? _activePayingToken;

  @override
  void initState() {
    super.initState();
    _loadMenu();

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _razorpay?.clear();
    }
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final orderId = _activePayingOrderId;
    final token = _activePayingToken;
    if (orderId == null || token == null) return;

    // Record the payment on the backend then show success
    _orderService.generateBill(
      token,
      orderId,
      'ONLINE',
      amountPaid: _cartTotal,
      subtotal: _cartSubtotal,
      tax: _cartTax,
      total: _cartTotal,
    ).then((_) {
      if (mounted) {
        _showOrderCompletedSuccessDialog(orderId, 'Paid via Razorpay');
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

  void _startNativeRazorpayCheckout(String token, String orderId, String userName, String userPhone) {
    if (kIsWeb) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
            title: Row(
              children: [
                const Icon(Icons.payment_rounded, color: Color(0xFFD4AF37)),
                const SizedBox(width: 12),
                Text('Online Payments', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            content: Text(
              'Online card/UPI checkouts are only supported on our native mobile apps. Please select "Cash on Delivery" to proceed on the Web!',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13, height: 1.45),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
      return;
    }

    _activePayingOrderId = orderId;
    _activePayingToken = token;

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
          'order_id': rzpOrderId,          // Razorpay Order ID: order_XXXXX
          'amount': amount ?? (_cartTotal * 100).toInt(),
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

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollToCategory(String categoryId) {
    final key = _categoryKeys[categoryId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadMenu() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token != null) {
        await Provider.of<MenuProvider>(context, listen: false)
            .fetchMenuCards(auth.token!, restaurantId: widget.restaurant.id);
      }
      if (mounted) {
        setState(() {
          _menuLoaded = true;
        });
      }
    });
  }

  // Get active menu card based on user preference (selected delivery menu card)
  MenuCardModel? _getDeliveryMenuCard(List<MenuCardModel> cards) {
    if (cards.isEmpty) return null;
    if (widget.restaurant.deliveryMenuCardId != null) {
      final found = cards.firstWhere(
        (card) => card.id == widget.restaurant.deliveryMenuCardId,
        orElse: () => cards.first,
      );
      return found;
    }
    return cards.first;
  }

  void _addToCart(MenuItemModel item) {
    setState(() {
      final existingIndex = _cart.indexWhere((ci) => ci.menuItem.id == item.id);
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity++;
      } else {
        _cart.add(CartItem(menuItem: item, quantity: 1));
      }
    });
  }

  void _removeFromCart(MenuItemModel item) {
    setState(() {
      final existingIndex = _cart.indexWhere((ci) => ci.menuItem.id == item.id);
      if (existingIndex >= 0) {
        if (_cart[existingIndex].quantity > 1) {
          _cart[existingIndex].quantity--;
        } else {
          _cart.removeAt(existingIndex);
        }
      }
    });
  }

  int _getItemCount(String itemId) {
    final existingIndex = _cart.indexWhere((ci) => ci.menuItem.id == itemId);
    return existingIndex >= 0 ? _cart[existingIndex].quantity : 0;
  }

  double get _cartSubtotal => _cart.fold(0.0, (sum, ci) => sum + ci.total);

  double get _cartTax {
    double totalTax = 0.0;
    for (var ci in _cart) {
      if (ci.menuItem.taxGroup != null && !ci.menuItem.taxGroup!.isInclusive) {
        totalTax += ci.taxAmount;
      }
    }
    return totalTax;
  }

  double get _inclusiveTax {
    double totalTax = 0.0;
    for (var ci in _cart) {
      if (ci.menuItem.taxGroup != null && ci.menuItem.taxGroup!.isInclusive) {
        totalTax += ci.taxAmount;
      }
    }
    return totalTax;
  }

  Map<String, Map<String, dynamic>> get _taxBreakup {
    Map<String, Map<String, dynamic>> breakup = {};
    for (var ci in _cart) {
      if (ci.menuItem.taxGroup != null) {
        double totalTaxPercentage = ci.menuItem.taxGroup!.taxes.fold(0.0, (sum, t) => sum + t.percentage);
        for (var tax in ci.menuItem.taxGroup!.taxes) {
          double taxAmount = (ci.total / (100 + totalTaxPercentage)) * tax.percentage;
          if (!ci.menuItem.taxGroup!.isInclusive) {
            taxAmount = (ci.total * tax.percentage) / 100;
          }
          
          if (!breakup.containsKey(tax.name)) {
            breakup[tax.name] = {
              'amount': 0.0,
              'isInclusive': ci.menuItem.taxGroup!.isInclusive,
            };
          }
          breakup[tax.name]!['amount'] += taxAmount;
        }
      }
    }
    return breakup;
  }

  double get _deliveryFee {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    if (customerProvider.orderType == 'delivery' && settingsProvider.deliveryDeliveryEnabled) {
      return double.tryParse(settingsProvider.deliveryDeliveryAmount) ?? 0.0;
    }
    return 0.0;
  }

  double get _packingCharge {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    if (customerProvider.orderType == 'dine-in' && settingsProvider.dineinPackingEnabled) {
      return double.tryParse(settingsProvider.dineinPackingAmount) ?? 0.0;
    } else if (customerProvider.orderType == 'takeaway' && settingsProvider.takeawayPackingEnabled) {
      return double.tryParse(settingsProvider.takeawayPackingAmount) ?? 0.0;
    } else if (customerProvider.orderType == 'delivery' && settingsProvider.deliveryPackingEnabled) {
      return double.tryParse(settingsProvider.deliveryPackingAmount) ?? 0.0;
    }
    return 0.0;
  }

  double get _serviceCharge {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    double serviceChargePercent = 0.0;
    if (customerProvider.orderType == 'dine-in' && settingsProvider.dineinServiceEnabled) {
      serviceChargePercent = double.tryParse(settingsProvider.dineinServiceAmount) ?? 0.0;
    } else if (customerProvider.orderType == 'takeaway' && settingsProvider.takeawayServiceEnabled) {
      serviceChargePercent = double.tryParse(settingsProvider.takeawayServiceAmount) ?? 0.0;
    } else if (customerProvider.orderType == 'delivery' && settingsProvider.deliveryServiceEnabled) {
      serviceChargePercent = double.tryParse(settingsProvider.deliveryServiceAmount) ?? 0.0;
    }
    return _cartSubtotal * (serviceChargePercent / 100);
  }

  double get _cartTotal => _cartSubtotal + _cartTax + _deliveryFee + _packingCharge + _serviceCharge;

  // Categories Floating Shortcut Sheet
  void _openCategoriesFABSheet(List<MenuCategoryModel> categories) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'EXPLORE MENU',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), height: 1),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length + 1,
                  itemBuilder: (context, idx) {
                    final isAll = idx == 0;
                    final catName = isAll ? 'Show All Items' : categories[idx - 1].name;
                    final catId = isAll ? null : categories[idx - 1].id;
                    final isSelected = _selectedCategoryId == catId;

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        catName,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF37), size: 18)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCategoryId = catId;
                        });
                        Navigator.pop(context);
                        if (isAll) {
                          _scrollToTop();
                        } else {
                          _scrollToCategory(catId!);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Complete checkout & placing order platform
  void _openCheckoutSheet() {
    if (_cart.isEmpty) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    String paymentMethod = settings.codEnabled ? 'COD' : 'ONLINE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0C0C0C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            final auth = Provider.of<AuthProvider>(context);
            final customerProvider = Provider.of<CustomerProvider>(context);
            final settings = Provider.of<SettingsProvider>(context);

            final apiAddresses = customerProvider.apiAddresses;
            // Default select first address if any exists, but matching active location
            AddressModel? selectedAddress;
            if (apiAddresses.isNotEmpty) {
              selectedAddress = apiAddresses.firstWhere(
                (a) => (customerProvider.customerLatitude == a.latitude && customerProvider.customerLongitude == a.longitude) || customerProvider.currentAddress.contains(a.address),
                orElse: () => apiAddresses.firstWhere((a) => a.isDefault, orElse: () => apiAddresses.first),
              );
            }

            final isDeliveryMode = customerProvider.orderType == 'delivery';
            final isDineInMode = customerProvider.orderType == 'dine_in';
            
            bool isModeAllowed = true;
            if (customerProvider.orderType == 'delivery') {
              isModeAllowed = widget.restaurant.isDelivery;
            } else if (customerProvider.orderType == 'takeaway') {
              isModeAllowed = widget.restaurant.isTakeaway;
            } else if (customerProvider.orderType == 'dine_in') {
              isModeAllowed = widget.restaurant.isDinein;
            }

            bool isAllowedToCheckout = true;
            if (isDeliveryMode) {
              isAllowedToCheckout = selectedAddress != null && isModeAllowed;
            } else if (isDineInMode) {
              isAllowedToCheckout = customerProvider.activeTableId != null && 
                                    customerProvider.activeRestaurantId == widget.restaurant.id &&
                                    isModeAllowed;
            } else {
              isAllowedToCheckout = isModeAllowed;
            }

            return Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Center bar indicator
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR BASKET', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 4),
                          Text(widget.restaurant.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), shape: BoxShape.circle),
                          child: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), height: 1),
                  const SizedBox(height: 16),

                  // Cart Items Scroll
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.22),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _cart.length,
                      itemBuilder: (context, idx) {
                        final ci = _cart[idx];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              _buildVegIndicator(ci.menuItem.isVeg, ci.menuItem.isNonveg, size: 12),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ci.menuItem.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text('₹${ci.menuItem.price.toStringAsFixed(2)} x ${ci.quantity}', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      _removeFromCart(ci.menuItem);
                                      setSheetState(() {});
                                      setState(() {});
                                      if (_cart.isEmpty) Navigator.pop(context);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.remove_rounded, color: Color(0xFFD4AF37), size: 14),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('${ci.quantity}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () {
                                      _addToCart(ci.menuItem);
                                      setSheetState(() {});
                                      setState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.add_rounded, color: Color(0xFFD4AF37), size: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Text('₹${ci.total.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 16),

                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 16),



                  // Delivery Address Selector (Delivery Only)
                  if (isDeliveryMode) ...[
                    const Text('DELIVERY ADDRESS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFD4AF37),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (selectedAddress != null && selectedAddress.label.toLowerCase() == 'home')
                                ? Icons.home_rounded
                                : (selectedAddress != null && selectedAddress.label.toLowerCase() == 'office')
                                    ? Icons.work_rounded
                                    : Icons.location_on_rounded,
                            color: const Color(0xFFD4AF37),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  selectedAddress != null
                                      ? selectedAddress.label.toUpperCase()
                                      : 'SELECTED DELIVERY LOCATION',
                                  style: const TextStyle(
                                    color: Color(0xFFD4AF37),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  selectedAddress != null
                                      ? selectedAddress.address
                                      : customerProvider.currentAddress,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (selectedAddress == null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 18),
                                const SizedBox(width: 8),
                                const Text(
                                  'ADDRESS NOT SAVED',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'To place orders, you must save your delivery address to your account. This secures accurate routing and tenant-specific database synchronization.',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12, height: 1.4),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 42,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.add_location_alt_rounded, size: 16, color: Colors.black),
                                label: const Text('SAVE ADDRESS TO ACCOUNT', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4AF37),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.pop(context); // Close checkout sheet
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MainLayout(
                                        activePage: 'Addresses',
                                        child: CustomerAddressesScreen(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  // Payment Mode Choice
                  const Text('PAYMENT MODE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (settings.codEnabled)
                        Expanded(
                          child: GestureDetector(
                            onTap: !isAllowedToCheckout ? null : () {
                              setSheetState(() {
                                paymentMethod = 'COD';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !isAllowedToCheckout
                                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.01)
                                    : (paymentMethod == 'COD' ? const Color(0xFFD4AF37).withOpacity(0.12) : Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: !isAllowedToCheckout
                                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.1)
                                      : (paymentMethod == 'COD' ? const Color(0xFFD4AF37) : Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.money_rounded,
                                    color: !isAllowedToCheckout
                                        ? Colors.white38
                                        : (paymentMethod == 'COD' ? const Color(0xFFD4AF37) : Colors.white60),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    customerProvider.orderType == 'dine_in' ? 'Pay at Counter' : 'Cash On Delivery',
                                    style: TextStyle(
                                      color: !isAllowedToCheckout
                                          ? Colors.white38
                                          : (paymentMethod == 'COD' ? const Color(0xFFD4AF37) : Colors.white),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (settings.codEnabled && settings.onlinePaymentEnabled)
                        const SizedBox(width: 12),
                      if (settings.onlinePaymentEnabled)
                        Expanded(
                          child: GestureDetector(
                            onTap: !isAllowedToCheckout ? null : () {
                              setSheetState(() {
                                paymentMethod = 'ONLINE';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !isAllowedToCheckout
                                    ? Colors.white.withOpacity(0.01)
                                    : (paymentMethod == 'ONLINE' ? const Color(0xFFD4AF37).withOpacity(0.12) : Colors.white.withOpacity(0.03)),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: !isAllowedToCheckout
                                      ? Colors.white.withOpacity(0.05)
                                      : (paymentMethod == 'ONLINE' ? const Color(0xFFD4AF37) : Colors.white30),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_rounded,
                                    color: !isAllowedToCheckout
                                        ? Colors.white38
                                        : (paymentMethod == 'ONLINE' ? const Color(0xFFD4AF37) : Colors.white60),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Pay via UPI / Card',
                                    style: TextStyle(
                                      color: !isAllowedToCheckout
                                          ? Colors.white38
                                          : (paymentMethod == 'ONLINE' ? const Color(0xFFD4AF37) : Colors.white),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 16),

                  // Calculations
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal', style: TextStyle(color: Colors.white38, fontSize: 13)),
                      Text('₹${_cartSubtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._taxBreakup.entries.map((entry) {
                    final bool isInclusive = entry.value['isInclusive'];
                    final double amount = entry.value['amount'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${entry.key}${isInclusive ? ' (inclusive)' : ''}', style: const TextStyle(color: Colors.white38, fontSize: 13)),
                          Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    );
                  }),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Service Charge', style: TextStyle(color: Colors.white38, fontSize: 13)),
                      Text('₹${_serviceCharge.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Packing Charge', style: TextStyle(color: Colors.white38, fontSize: 13)),
                      Text('₹${_packingCharge.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Delivery Partner Fee', style: TextStyle(color: Colors.white38, fontSize: 13)),
                      Text('₹${_deliveryFee.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GRAND TOTAL', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                      Text('₹${_cartTotal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // PLACE ORDER SUBMITTER
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: !isAllowedToCheckout ? null : () {
                        if (paymentMethod == 'ONLINE' && kIsWeb) {
                          _showOnlinePaymentWebWarning();
                          return;
                        }
                        Navigator.pop(context); // Close checkout
                        _processOrderFlow(
                          token: auth.token!,
                          selectedAddress: isDeliveryMode ? (selectedAddress?.address ?? customerProvider.currentAddress) : 'Dine-In/Takeaway Order',
                          paymentMethod: paymentMethod,
                          userId: auth.user!.id,
                          userName: auth.user!.name,
                          userPhone: auth.user!.mobile,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !isAllowedToCheckout ? Colors.white.withOpacity(0.05) : const Color(0xFFD4AF37),
                        foregroundColor: !isAllowedToCheckout ? Colors.white24 : Colors.black,
                        disabledBackgroundColor: Colors.white.withOpacity(0.05),
                        disabledForegroundColor: Colors.white24,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: !isAllowedToCheckout ? Colors.white24 : Colors.black,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            !isModeAllowed
                                ? '${customerProvider.orderType.toUpperCase()} NOT SUPPORTED'
                                : (!isAllowedToCheckout 
                                    ? (isDeliveryMode 
                                        ? 'SAVE ADDRESS TO CONTINUE' 
                                        : (customerProvider.activeTableId == null 
                                            ? 'SCAN TABLE QR TO ORDER' 
                                            : 'TABLE FROM DIFFERENT RESTO')) 
                                    : 'PROCEED & PLACE ORDER'),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
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

  void _showOnlinePaymentWebWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16181D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.05))),
          title: const Row(
            children: [
              Icon(Icons.payment_rounded, color: Color(0xFFD4AF37)),
              SizedBox(width: 12),
              Text('Online Payments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            'Online card/UPI checkouts are only supported on our native mobile apps. Please select "Cash on Delivery" to proceed on the Web!',
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.45),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Handle the Order Transmission Flow + Mock Payment animations
  Future<void> _processOrderFlow({
    required String token,
    required String selectedAddress,
    required String paymentMethod,
    required String userId,
    required String userName,
    required String userPhone,
  }) async {
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    // 1. Show processing modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Dialog(
          backgroundColor: Color(0xFF121212),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFFD4AF37)),
                SizedBox(height: 24),
                Text('TRANSMITTING ORDER', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                SizedBox(height: 8),
                Text('Securing connection to restaurant...', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Uploading basket items to tenant database.', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );

    // Prepare Items KOT payload structure
    final List<Map<String, dynamic>> itemsList = _cart.map((ci) {
      return {
        'menu_item_id': ci.menuItem.id,
        'quantity': ci.quantity,
        'price': ci.menuItem.price,
      };
    }).toList();

    final activeType = customerProvider.orderType.toUpperCase(); // 'DELIVERY', 'TAKEAWAY', 'DINE_IN'
    final tableId = activeType == 'DINE_IN' ? customerProvider.activeTableId : null;
    final sourceVal = activeType == 'DELIVERY' ? 'customer_app_delivery' : (activeType == 'TAKEAWAY' ? 'customer_app_takeaway' : 'customer_app_dinein');

    // 2. Execute KOT order submission
    final orderData = await _orderService.sendKOT(
      token,
      widget.restaurant.id,
      tableId, 
      itemsList,
      orderType: activeType,
      customerName: userName,
      customerPhone: userPhone,
      deliveryAddress: activeType == 'DELIVERY' ? selectedAddress : null,
      customerId: userId,
      source: sourceVal,
      paymentMethod: paymentMethod,
    );

    if (!mounted) return;
    Navigator.pop(context); // Close Processing dialog

    if (orderData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to transmit order details. Please try again.')),
      );
      return;
    }

    final String orderId = orderData['order']['id'].toString();

    // If Payment method is ONLINE, launch native Razorpay mobile SDK checkout
    if (paymentMethod == 'ONLINE') {
      _startNativeRazorpayCheckout(token, orderId, userName, userPhone);
    } else {
      // Cash on delivery directly finishes
      _showOrderCompletedSuccessDialog(orderId, 'Cash On Delivery');
    }
  }



  // Stunning Success animations overlay
  void _showOrderCompletedSuccessDialog(String orderId, String paymentType) {
    setState(() {
      _cart.clear(); // Empty basket locally
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF101010),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars_rounded, color: Color(0xFFD4AF37), size: 48),
              ),
              const SizedBox(height: 24),
              const Text('Order Placed Successfully!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Your order is dispatched to the kitchen.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order ID', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        Text('#${orderId.substring(0, 8).toUpperCase()}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Mode', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        Text(paymentType, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close Dialog
                    Navigator.of(context).pushNamedAndRemoveUntil('/customer/orders', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('GO TO MY ORDERS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVegIndicator(bool isVeg, bool isNonVeg, {double size = 14}) {
    final color = isVeg ? Colors.green : Colors.red;
    final shape = isVeg ? BoxShape.circle : BoxShape.rectangle;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: isVeg ? null : BorderRadius.circular(2),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: shape,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final activeCard = _getDeliveryMenuCard(menuProvider.menuCards);
    final categories = activeCard?.categories ?? [];

    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: _menuLoaded && categories.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _openCategoriesFABSheet(categories),
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
              label: const Text('MENU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
            )
          : null,
      bottomNavigationBar: _cart.isNotEmpty
          ? Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: SafeArea(
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_cart.length} ITEM${_cart.length > 1 ? 'S' : ''} ADDED',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '₹${_cartSubtotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _openCheckoutSheet(),
                        child: Row(
                          children: const [
                            Text(
                              'VIEW CART',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.shopping_cart_checkout_rounded, color: Colors.black, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Restaurant Appbar Banner
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.restaurant.logo != null && widget.restaurant.logo!.isNotEmpty)
                    Image.network(
                      ApiConstants.storageUrl + widget.restaurant.logo!,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: const Color(0xFF161616),
                      child: const Icon(Icons.storefront_rounded, color: Colors.white12, size: 60),
                    ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.transparent, Colors.black],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Restaurant Header description block
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.restaurant.name,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.restaurant.address ?? 'No address listed',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFFD4AF37), size: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white10, height: 1),
                ],
              ),
            ),
          ),

          // Shimmer/Skeleton or Loaded Food List items
          if (!_menuLoaded)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                ),
              ),
            )
          else if (categories.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24.0),
                child: Column(
                  children: [
                    const Icon(Icons.no_meals_rounded, color: Colors.white24, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'No Delivery Menu Available',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'This restaurant tenant hasn\'t linked any menu card for home delivery services.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            for (var cat in categories) ...[
              // Category Title Header with anchor key
              SliverToBoxAdapter(
                key: _categoryKeys.putIfAbsent(cat.id, () => GlobalKey()),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Category Items List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = cat.items[index];
                      final count = _getItemCount(item.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.01),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.03)),
                        ),
                        child: Row(
                          children: [
                            // Item Image
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.02),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: (item.image != null && item.image!.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        ApiConstants.storageUrl + item.image!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => const Icon(Icons.fastfood_rounded, color: Colors.white12),
                                      ),
                                    )
                                  : const Icon(Icons.fastfood_rounded, color: Colors.white12),
                            ),
                            const SizedBox(width: 16),

                            // Item Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      _buildVegIndicator(item.isVeg, item.isNonveg),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  if (item.description != null && item.description!.isNotEmpty)
                                    Text(
                                      item.description!,
                                      style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '₹${item.price.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Action button add/subtract
                            if (count == 0)
                              SizedBox(
                                height: 36,
                                width: 76,
                                child: TextButton(
                                  onPressed: () => _addToCart(item),
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
                                    side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('ADD', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.w900)),
                                ),
                              )
                            else
                              Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _removeFromCart(item),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                                        child: Icon(Icons.remove_rounded, color: Colors.black, size: 14),
                                      ),
                                    ),
                                    Text('$count', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
                                    GestureDetector(
                                      onTap: () => _addToCart(item),
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                                        child: Icon(Icons.add_rounded, color: Colors.black, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                    childCount: cat.items.length,
                  ),
                ),
              ),
            ],
            // Extra bottom spacer for elegant scrolling and FAB padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        ],
      ),
    );
  }
}
