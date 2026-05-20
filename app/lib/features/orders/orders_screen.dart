import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/order_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../models/restaurant_model.dart';
import 'package:intl/intl.dart';
import '../../services/print_service.dart';
import '../../services/pdf_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  RestaurantModel? _selectedRestaurant;
  DateTime? _selectedDate = DateTime.now();
  String? _selectedPaymentMethod;
  String? _selectedOrderType;

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

    if (restoProvider.restaurants.isNotEmpty && mounted) {
      setState(() {
        _selectedRestaurant = restoProvider.selectedRestaurant ?? restoProvider.restaurants.first;
      });
      _fetchOrders();
    }
  }

  void _fetchOrders({int page = 1, bool append = false}) {
    if (!mounted || _selectedRestaurant == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final dateStr = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null;
    Provider.of<OrderProvider>(context, listen: false).fetchAllOrders(
      auth.token!, 
      _selectedRestaurant!.id, 
      date: dateStr, 
      paymentMethod: _selectedPaymentMethod,
      orderType: _selectedOrderType,
      page: page,
      append: append,
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
      _fetchOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 500;
    
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: isSmall ? 16 : 24),
        _buildSummaryRow(),
        SizedBox(height: isSmall ? 16 : 24),
        _buildFiltersRow(),
        SizedBox(height: isSmall ? 20 : 30),
        isSmall ? _buildOrdersList(isSmall: isSmall) : Expanded(child: _buildOrdersList(isSmall: isSmall)),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
        child: isSmall ? SingleChildScrollView(child: content) : content,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text('ORDER HISTORY', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
      ],
    );
  }

  Widget _buildSummaryRow() {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        return Row(
          children: [
            Expanded(child: _buildSummaryCard('Total Orders', provider.totalCount.toString(), Icons.receipt_long_rounded, Colors.blueAccent)),
            const SizedBox(width: 8),
            Expanded(child: _buildSummaryCard('Total Amount', '₹${provider.totalAmount.toStringAsFixed(2)}', Icons.account_balance_wallet_rounded, Colors.greenAccent)),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    final bool isSmall = MediaQuery.of(context).size.width < 500;
    return Container(
      padding: EdgeInsets.all(isSmall ? 8 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isSmall ? 12 : 20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 6 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
            ),
            child: Icon(icon, color: color, size: isSmall ? 14 : 20),
          ),
          SizedBox(width: isSmall ? 8 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title, 
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: isSmall ? 8 : 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isSmall ? 2 : 4),
                Text(
                  value, 
                  style: TextStyle(color: Colors.white, fontSize: isSmall ? 11 : 18, fontWeight: FontWeight.w900, fontFamily: 'Outfit'),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersRow() {
    final restoProvider = Provider.of<RestaurantProvider>(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        
        final filters = [
          // Restaurant Filter
          if (restoProvider.restaurants.length > 1)
            _buildFilterContainer(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<RestaurantModel>(
                  isExpanded: true,
                  value: _selectedRestaurant,
                  dropdownColor: const Color(0xFF16181D),
                  items: restoProvider.restaurants.map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      restoProvider.setSelectedRestaurant(val);
                      setState(() => _selectedRestaurant = val);
                      _fetchOrders();
                    }
                  },
                ),
              ),
            ),
          
          // Date Filter
          _buildFilterContainer(
            child: InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: _selectedDate != null ? const Color(0xFFD4AF37) : Colors.white38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDate != null ? DateFormat('MMM dd, yyyy').format(_selectedDate!) : 'All Dates',
                      style: TextStyle(color: _selectedDate != null ? const Color(0xFFD4AF37) : Colors.white60, fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_selectedDate != null)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedDate = null);
                          _fetchOrders();
                        },
                        child: const Icon(Icons.close, size: 16, color: Color(0xFFD4AF37)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Payment Method Filter
          _buildFilterContainer(
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedPaymentMethod,
                      hint: const Text('All Payments', style: TextStyle(color: Colors.white60, fontSize: 14)),
                      dropdownColor: const Color(0xFF16181D),
                      items: ['cash', 'card', 'upi', 'wallet'].map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 14)),
                      )).toList(),
                      onChanged: (val) {
                        setState(() => _selectedPaymentMethod = val);
                        _fetchOrders();
                      },
                      selectedItemBuilder: (context) => ['cash', 'card', 'upi', 'wallet'].map((method) => 
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            method.toUpperCase(), 
                            style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                        )
                      ).toList(),
                    ),
                  ),
                ),
                if (_selectedPaymentMethod != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedPaymentMethod = null);
                        _fetchOrders();
                      },
                      child: const Icon(Icons.close, size: 16, color: Color(0xFFD4AF37)),
                    ),
                  ),
              ],
            ),
          ),

          // Order Type Filter (Dine-in, Takeaway, Delivery)
          _buildFilterContainer(
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedOrderType,
                      hint: const Text('All Types', style: TextStyle(color: Colors.white60, fontSize: 14)),
                      dropdownColor: const Color(0xFF16181D),
                      items: [
                        {'value': 'dine_in', 'label': 'Dine-in'},
                        {'value': 'takeaway', 'label': 'Takeaway'},
                        {'value': 'delivery', 'label': 'Delivery'},
                      ].map((item) => DropdownMenuItem(
                        value: item['value'] as String,
                        child: Text(item['label'] as String, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      )).toList(),
                      onChanged: (val) {
                        setState(() => _selectedOrderType = val);
                        _fetchOrders();
                      },
                      selectedItemBuilder: (context) => [
                        {'value': 'dine_in', 'label': 'Dine-in'},
                        {'value': 'takeaway', 'label': 'Takeaway'},
                        {'value': 'delivery', 'label': 'Delivery'},
                      ].map((item) => 
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            item['label'] as String, 
                            style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                        )
                      ).toList(),
                    ),
                  ),
                ),
                if (_selectedOrderType != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedOrderType = null);
                        _fetchOrders();
                      },
                      child: const Icon(Icons.close, size: 16, color: Color(0xFFD4AF37)),
                    ),
                  ),
              ],
            ),
          ),
        ];

        if (isNarrow) {
          return Column(
            children: filters.map((f) => Padding(padding: const EdgeInsets.only(bottom: 8), child: f)).toList(),
          );
        }

        return Row(
          children: filters.map((f) => Expanded(child: Padding(padding: EdgeInsets.only(right: f == filters.last ? 0 : 16), child: f))).toList(),
        );
      },
    );
  }

  Widget _buildFilterContainer({required Widget child}) {
    final bool isSmall = MediaQuery.of(context).size.width < 500;
    return Container(
      height: isSmall ? 40 : 48,
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 10 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }

  Widget _buildOrdersList({bool isSmall = false}) {
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.allOrders.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }
        
        if (provider.allOrders.isEmpty) {
          return const Center(child: Text('No orders found.', style: TextStyle(color: Colors.white54)));
        }

        return ListView.separated(
          shrinkWrap: isSmall,
          physics: isSmall ? const NeverScrollableScrollPhysics() : null,
          itemCount: provider.allOrders.length + (provider.hasMore ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            if (index == provider.allOrders.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: provider.isLoading 
                    ? const CircularProgressIndicator(color: Color(0xFFD4AF37))
                    : ElevatedButton(
                        onPressed: () => _fetchOrders(page: provider.currentPage + 1, append: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.05),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Load More'),
                      ),
                ),
              );
            }
            final order = provider.allOrders[index];
            return _buildOrderCard(order);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final status = order['status']?.toString().toUpperCase() ?? 'OPEN';
    final color = status == 'PAID' ? Colors.greenAccent : const Color(0xFFD4AF37);
    
    // Parse date safely
    DateTime? date;
    try {
      if (order['created_at'] != null) {
        date = DateTime.parse(order['created_at'].toString()).toLocal();
      }
    } catch (e) {}
    
    final formattedDate = date != null ? DateFormat('MMM dd, hh:mm a').format(date) : 'N/A';
    final items = order['items'] as List? ?? [];
    final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;
    
    final delivery = double.tryParse(order['delivery_charge']?.toString() ?? '0') ?? 0.0;
    final packing = double.tryParse(order['packing_charge']?.toString() ?? '0') ?? 0.0;
    final service = double.tryParse(order['service_charge']?.toString() ?? '0') ?? 0.0;
    final subtotal = double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0;
    final tax = double.tryParse(order['tax']?.toString() ?? '0') ?? 0.0;
    final discount = double.tryParse(order['discount_amount']?.toString() ?? '0') ?? 0.0;

    // Calculate tax breakup dynamically from the JSON item payload
    Map<String, Map<String, dynamic>> taxBreakup = {};
    for (var i in items) {
      if (i['menu_item'] != null && i['menu_item']['tax_group'] != null) {
        final group = i['menu_item']['tax_group'];
        final isInclusive = group['is_inclusive'] == 1 || group['is_inclusive'] == true;
        final taxes = group['taxes'] as List? ?? [];
        
        final double itemQty = double.tryParse(i['quantity']?.toString() ?? '1') ?? 1.0;
        final double itemPrice = double.tryParse(i['menu_item']['price']?.toString() ?? '0') ?? 0.0;
        final double itemTotal = itemQty * itemPrice;
        
        double totalTaxPercentage = taxes.fold<double>(0.0, (sum, t) => sum + (double.tryParse(t['percentage']?.toString() ?? '0') ?? 0.0));
        
        for (var t in taxes) {
          final taxName = t['name']?.toString() ?? 'Tax';
          final percentage = double.tryParse(t['percentage']?.toString() ?? '0') ?? 0.0;
          
          double taxAmount = (itemTotal / (100 + totalTaxPercentage)) * percentage;
          if (!isInclusive) {
            taxAmount = (itemTotal * percentage) / 100;
          }
          
          // Pro-rate tax based on discount
          if (subtotal > 0 && discount > 0) {
            taxAmount = taxAmount * ((subtotal - discount) / subtotal);
          }
          
          if (!taxBreakup.containsKey(taxName)) {
            taxBreakup[taxName] = {'amount': 0.0, 'isInclusive': isInclusive};
          }
          taxBreakup[taxName]!['amount'] += taxAmount;
        }
      }
    }

    final bool isSmall = MediaQuery.of(context).size.width < 500;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(isSmall ? 16 : 24),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.15)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        order['table'] != null 
                          ? 'Table ${order['table']['name']}' 
                          : '${order['order_type']?.toString().toUpperCase() ?? "DIRECT"}: ${order['customer_name'] ?? "Guest"}',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isSmall ? 14 : 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildSourceBadge(order['source']?.toString()),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: TextStyle(color: const Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: isSmall ? 18 : 20, fontFamily: 'Outfit'),
                  ),
                  _buildOrderActions(order),
                ],
              ),
            ],
          ),
          SizedBox(height: isSmall ? 12 : 16),
          Container(height: 1, color: Colors.white.withOpacity(0.05)),
          SizedBox(height: isSmall ? 12 : 16),
          Text(
            items.map((i) => "${i['quantity']}x ${i['menu_item']?['name'] ?? 'Item'}").join(", "),
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          
          // --- BILLING BREAKDOWN ---
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtotal > 0) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Subtotal', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                ],
                if (discount > 0) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Discount', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text('-₹${discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                ],
                ...taxBreakup.entries.map((entry) {
                  final bool isInclusive = entry.value['isInclusive'];
                  final double amount = entry.value['amount'];
                  if (amount <= 0) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('${entry.key}${isInclusive ? ' (inclusive)' : ''}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  );
                }),
                if (service > 0) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Service Charge', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text('₹${service.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                ],
                if (packing > 0) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Packing Charge', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text('₹${packing.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                ],
                if (delivery > 0) ...[
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Delivery Charge', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    Text('₹${delivery.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                  const SizedBox(height: 4),
                ],
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  height: 1, 
                  color: Colors.white.withOpacity(0.05),
                ),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('GRAND TOTAL', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
                  ),
                ],
              ),
              if (order['payment_method'] != null)
                Row(
                  children: [
                    Icon(Icons.payments_outlined, size: 14, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(width: 6),
                    Text(
                      order['payment_method'].toString().toUpperCase(),
                      style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
            ],
          ),
          if (order['order_type']?.toString().toLowerCase() == 'delivery') ...[
            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.delivery_dining_rounded, color: Color(0xFFD4AF37), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DELIVERY ORDER',
                          style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          order['delivery_status'] != null
                              ? 'Status: ${order['delivery_status'].toString().toUpperCase().replaceAll('_', ' ')}'
                              : 'Status: PENDING',
                          style: TextStyle(
                            color: order['delivery_status'] == 'delivered' ? Colors.greenAccent : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (order['delivery_staff'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, color: Colors.white38, size: 12),
                        const SizedBox(width: 6),
                        Text(
                          order['delivery_staff']['name']?.toString() ?? 'Rider',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                else
                  TextButton.icon(
                    onPressed: () => _showAssignRiderDialog(order),
                    icon: const Icon(Icons.add_rounded, size: 14, color: Color(0xFFD4AF37)),
                    label: const Text('ASSIGN RIDER', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      backgroundColor: const Color(0xFFD4AF37).withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  Widget _buildOrderActions(dynamic order) {
    final bool isOpen = order['status']?.toString().toUpperCase() == 'OPEN';
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded, color: Colors.white38, size: 18),
      color: const Color(0xFF16181D),
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        if (val == 'delete') {
          _confirmDeleteOrder(order);
        } else if (val == 'edit') {
          _editOrder(order);
        } else if (val == 'print') {
          _printBillFromOrder(order);
        } else if (val == 'pdf') {
          _downloadBillPdfFromOrder(order);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'print',
          child: Row(
            children: [
              const Icon(Icons.print_rounded, size: 16, color: Colors.blueAccent),
              const SizedBox(width: 12),
              const Text('Print Bill', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'pdf',
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.greenAccent),
              const SizedBox(width: 12),
              const Text('Download PDF', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit_rounded, size: 16, color: Color(0xFFD4AF37)),
              const SizedBox(width: 12),
              const Text('Edit Order', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
              const SizedBox(width: 12),
              const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDeleteOrder(dynamic order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Order?', style: TextStyle(color: Colors.white)),
        content: const Text('This will permanently remove the order and all its records. Continue?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final provider = Provider.of<OrderProvider>(context, listen: false);
              final success = await provider.deleteOrder(auth.token!, order['id'].toString());
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Order deleted' : 'Failed to delete order'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _editOrder(dynamic order) async {
    final bool isOpen = order['status']?.toString().toUpperCase() == 'OPEN';
    
    if (!isOpen) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<OrderProvider>(context, listen: false);
      
      // Reopen the order on the backend
      final success = await provider.reopenOrder(auth.token!, order['id'].toString());
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to reopen order for editing')));
        return;
      }
    }

    // Navigate to POS and try to select this order
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/pos', (route) => false, arguments: order);
    }
  }

  void _printBillFromOrder(dynamic order) async {
    final restoProvider = Provider.of<RestaurantProvider>(context, listen: false);
    if (restoProvider.restaurants.isEmpty) return;

    final restaurant = restoProvider.restaurants.first;
    final printerIp = restaurant.billPrinterIp;
    
    if (printerIp == null || printerIp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill printer IP not configured!')));
      return;
    }

    final subtotal = double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0;
    final tax = double.tryParse(order['tax']?.toString() ?? '0') ?? 0.0;
    final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;
    final items = order['items'] as List? ?? [];

    final printService = PrintService();
    final success = await printService.printBill(
      printerIp: printerIp,
      restaurantName: restaurant.name,
      tableName: order['table'] != null ? order['table']['name'] : 'DIRECT',
      orderId: order['id'].toString(),
      subtotal: subtotal,
      tax: tax,
      total: total,
      items: items.map((i) => {
        'menu_item': {'name': i['menu_item']?['name'] ?? 'Item'},
        'quantity': int.tryParse(i['quantity']?.toString() ?? '1') ?? 1,
        'price': double.tryParse(i['price']?.toString() ?? '0') ?? 0.0,
      }).toList(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Bill sent to printer!' : 'Failed to print bill!'), backgroundColor: success ? Colors.green : Colors.red),
      );
    }
  }

  void _downloadBillPdfFromOrder(dynamic order) async {
    final restoProvider = Provider.of<RestaurantProvider>(context, listen: false);
    if (restoProvider.restaurants.isEmpty) return;

    final restaurant = restoProvider.restaurants.first;
    final subtotal = double.tryParse(order['subtotal']?.toString() ?? '0') ?? 0.0;
    final tax = double.tryParse(order['tax']?.toString() ?? '0') ?? 0.0;
    final total = double.tryParse(order['total']?.toString() ?? '0') ?? 0.0;
    final deliveryCharge = double.tryParse(order['delivery_charge']?.toString() ?? '0') ?? 0.0;
    final packingCharge = double.tryParse(order['packing_charge']?.toString() ?? '0') ?? 0.0;
    final serviceCharge = double.tryParse(order['service_charge']?.toString() ?? '0') ?? 0.0;
    final discountAmount = double.tryParse(order['discount_amount']?.toString() ?? '0') ?? 0.0;
    final items = order['items'] as List? ?? [];

    Map<String, Map<String, dynamic>> taxBreakup = {};
    for (var i in items) {
      if (i['menu_item'] != null && i['menu_item']['tax_group'] != null) {
        final group = i['menu_item']['tax_group'];
        final isInclusive = group['is_inclusive'] == 1 || group['is_inclusive'] == true;
        final taxes = group['taxes'] as List? ?? [];
        
        final double itemQty = double.tryParse(i['quantity']?.toString() ?? '1') ?? 1.0;
        final double itemPrice = double.tryParse(i['menu_item']['price']?.toString() ?? '0') ?? 0.0;
        final double itemTotal = itemQty * itemPrice;
        
        double totalTaxPercentage = taxes.fold<double>(0.0, (sum, t) => sum + (double.tryParse(t['percentage']?.toString() ?? '0') ?? 0.0));
        
        for (var t in taxes) {
          final taxName = t['name']?.toString() ?? 'Tax';
          final percentage = double.tryParse(t['percentage']?.toString() ?? '0') ?? 0.0;
          
          double taxAmount = (itemTotal / (100 + totalTaxPercentage)) * percentage;
          if (!isInclusive) {
            taxAmount = (itemTotal * percentage) / 100;
          }
          
          if (subtotal > 0 && discountAmount > 0) {
            taxAmount = taxAmount * ((subtotal - discountAmount) / subtotal);
          }
          
          if (!taxBreakup.containsKey(taxName)) {
            taxBreakup[taxName] = {'amount': 0.0, 'isInclusive': isInclusive};
          }
          taxBreakup[taxName]!['amount'] += taxAmount;
        }
      }
    }

    final pdfService = PdfService();
    await pdfService.generateBillPdf(
      restaurantName: restaurant.name,
      tableName: order['table'] != null ? order['table']['name'] : 'DIRECT',
      orderId: order['id'].toString(),
      subtotal: subtotal,
      tax: tax,
      total: total,
      deliveryCharge: deliveryCharge,
      packingCharge: packingCharge,
      serviceCharge: serviceCharge,
      taxBreakup: taxBreakup,
      items: items.map((i) => {
        'menu_item': {'name': i['menu_item']?['name'] ?? 'Item'},
        'quantity': int.tryParse(i['quantity']?.toString() ?? '1') ?? 1,
        'price': double.tryParse(i['price']?.toString() ?? '0') ?? 0.0,
      }).toList(),
      address: restaurant.address,
    );
  }

  Widget _buildSourceBadge(String? source) {
    String label = 'Other';
    Color color = Colors.white38;
    IconData icon = Icons.help_outline;

    switch (source) {
      case 'qr_self':
        label = 'Customer';
        color = Colors.deepPurpleAccent;
        icon = Icons.qr_code_scanner;
        break;
      case 'pos_waiter':
        label = 'Waiter';
        color = Colors.blueAccent;
        icon = Icons.person_outline;
        break;
      case 'pos_counter':
        label = 'Counter';
        color = Colors.orangeAccent;
        icon = Icons.point_of_sale;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  void _showAssignRiderDialog(dynamic order) {
    showDialog(
      context: context,
      builder: (context) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final provider = Provider.of<OrderProvider>(context, listen: false);
        final restoProvider = Provider.of<RestaurantProvider>(context, listen: false);
        final restaurantId = restoProvider.restaurants.isNotEmpty ? restoProvider.restaurants.first.id : '';

        return Dialog(
          backgroundColor: const Color(0xFF16181D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 320,
            child: FutureBuilder<List<dynamic>>(
              future: provider.getDeliveryPartners(auth.token!, restaurantId.toString()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 150,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                    ),
                  );
                }
                
                final partners = snapshot.data ?? [];
                
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ASSIGN RIDER',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a staff partner to dispatch order #${order['id'].toString().substring(0, 6)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    if (partners.isEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline_rounded, color: Colors.white24, size: 36),
                              SizedBox(height: 12),
                              Text(
                                'No Rider Staff Found',
                                style: TextStyle(color: Colors.white38, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Add staff with Delivery Executive role first.',
                                style: TextStyle(color: Colors.white24, fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 250),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: partners.length,
                            separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                            itemBuilder: (context, index) {
                              final partner = partners[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.04),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.person_rounded, color: Colors.white54, size: 16),
                                ),
                                title: Text(
                                  partner['name'] ?? 'Staff Partner',
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  partner['mobile'] ?? 'No number',
                                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
                                onTap: () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  Navigator.pop(context);
                                  final success = await provider.assignDeliveryPartner(
                                    auth.token!,
                                    order['id'].toString(),
                                    restaurantId.toString(),
                                    partner['id'].toString(),
                                  );
                                  
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(success ? 'Delivery partner assigned successfully!' : 'Failed to assign partner'),
                                      backgroundColor: success ? Colors.green : Colors.red,
                                    ),
                                  );
                                  _fetchOrders();
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL', style: TextStyle(color: Colors.white30, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
