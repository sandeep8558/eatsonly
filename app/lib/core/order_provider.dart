import 'package:flutter/foundation.dart';
import 'auth_provider.dart';
import '../services/order_service.dart';
import '../models/cart_model.dart';
import '../models/menu_model.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  AuthProvider? _auth;

  void updateAuth(AuthProvider auth) {
    _auth = auth;
  }

  // Table ID -> List of CartItems
  Map<String, List<CartItem>> _activeOrders = {};
  Map<String, List<CartItem>> get activeOrders => _activeOrders;
  Map<String, String> get orderCustomerNames => _orderCustomerNames;
  Map<String, String> get orderTypes => _orderTypes;

  List<dynamic> _allOrders = [];
  List<dynamic> get allOrders => _allOrders;

  // Table ID -> Order ID (from DB)
  Map<String, String> _tableOrderIds = {};
  Map<String, String> _orderCustomerNames = {};
  Map<String, String?> _orderCustomerIds = {};
  Map<String, String> _orderTypes = {};
  Map<String, String?> _orderSources = {};
  
  Map<String, double> _orderDiscountAmounts = {};
  Map<String, double> _orderDiscountPercentages = {};
  Map<String, String?> _orderDiscountTypes = {};
  Map<String, String?> _orderDiscountReasons = {};
  Map<String, double> _orderPaidAmounts = {};
  Map<String, List<dynamic>> _orderPayments = {};

  double getOrderDiscountAmount(String tableId) => _orderDiscountAmounts[tableId] ?? 0;
  double getOrderDiscountPercentage(String tableId) => _orderDiscountPercentages[tableId] ?? 0;
  String? getOrderDiscountType(String tableId) => _orderDiscountTypes[tableId];
  String? getOrderDiscountReason(String tableId) => _orderDiscountReasons[tableId];
  double getOrderPaidAmount(String tableId) => _orderPaidAmounts[tableId] ?? 0;
  List<dynamic> getOrderPayments(String tableId) => _orderPayments[tableId] ?? [];

  void setDiscount(String tableId, {double amount = 0, double percentage = 0, String? type, String? reason}) {
    _orderDiscountAmounts[tableId] = amount;
    _orderDiscountPercentages[tableId] = percentage;
    _orderDiscountTypes[tableId] = type;
    _orderDiscountReasons[tableId] = reason;
    notifyListeners();
  }

  OrderProvider() {
    // Initial fetch happens from PosScreen since we need restaurantId
  }

  Future<void> fetchActiveOrders(String token, String restaurantId) async {
    _isLoading = true;
    notifyListeners();

    final dynamic ordersData = await _orderService.fetchActiveOrders(token, restaurantId);
    
    if (ordersData is Map && ordersData['code'] == 'SUBSCRIPTION_EXPIRED') {
      _auth?.setSubscriptionExpired();
      _isLoading = false;
      notifyListeners();
      return;
    }

    _activeOrders = {};
    _tableOrderIds = {};
    if (ordersData is List) {
      for (var order in ordersData) {
        final String orderKey = order['table_id'] ?? 'order_${order['id']}';
        _tableOrderIds[orderKey] = order['id'].toString();
        
        final List<CartItem> allCartItems = [];
        final Map<String, List<dynamic>> childrenMap = {};

        for (var i in order['items']) {
          final menuItem = MenuItemModel.fromJson(i['menu_item']);
          final int qty = i['quantity'] is int ? i['quantity'] : int.parse(i['quantity'].toString());
          final String itemId = i['id'].toString();
          final String? parentId = i['parent_order_item_id']?.toString();

          if (parentId == null) {
            allCartItems.add(CartItem(
              menuItem: menuItem, 
              quantity: qty, 
              notes: i['notes'], 
              isSent: true,
              children: [],
            ));
          } else {
            if (!childrenMap.containsKey(parentId)) {
              childrenMap[parentId] = [];
            }
            childrenMap[parentId]!.add(i);
          }
        }

        final List<CartItem> topLevelItems = [];
        final Map<String, CartItem> idToCartItem = {};

        for (var i in order['items']) {
          if (i['parent_order_item_id'] == null) {
            final menuItem = MenuItemModel.fromJson(i['menu_item']);
            final int qty = i['quantity'] is int ? i['quantity'] : int.parse(i['quantity'].toString());
            final ci = CartItem(
              menuItem: menuItem, 
              quantity: qty, 
              notes: i['notes'], 
              isSent: true,
              status: i['status']?.toString(),
            );
            topLevelItems.add(ci);
            idToCartItem[i['id'].toString()] = ci;
          }
        }

        for (var i in order['items']) {
          if (i['parent_order_item_id'] != null) {
            final parentId = i['parent_order_item_id'].toString();
            if (idToCartItem.containsKey(parentId)) {
              final menuItem = MenuItemModel.fromJson(i['menu_item']);
              final int qty = i['quantity'] is int ? i['quantity'] : int.parse(i['quantity'].toString());
              final childCi = CartItem(
                menuItem: menuItem, 
                quantity: qty, 
                notes: i['notes'], 
                isSent: true,
                status: i['status']?.toString(),
                comboGroupId: i['combo_group_id']?.toString(),
              );
              idToCartItem[parentId]!.children.add(childCi);
            }
          }
        }

        _activeOrders[orderKey] = topLevelItems;
        _orderCustomerNames[orderKey] = order['customer_name'] ?? 'Guest';
        _orderCustomerIds[orderKey] = order['customer_id']?.toString();
        _orderTypes[orderKey] = order['order_type'] ?? 'dine-in';
        _orderSources[orderKey] = order['source'];

        _orderDiscountAmounts[orderKey] = double.tryParse(order['discount_amount']?.toString() ?? '0') ?? 0.0;
        _orderDiscountPercentages[orderKey] = double.tryParse(order['discount_percentage']?.toString() ?? '0') ?? 0.0;
        _orderDiscountTypes[orderKey] = order['discount_type'];
        _orderDiscountReasons[orderKey] = order['discount_reason'];

        final payments = order['payments'] as List?;
        _orderPayments[orderKey] = payments ?? [];
        _orderPaidAmounts[orderKey] = payments?.fold(0.0, (sum, p) => sum! + (double.tryParse(p['amount'].toString()) ?? 0.0)) ?? 0.0;
      }
    }
    
    _isLoading = false;
    notifyListeners();
  }

  int _currentPage = 1;
  int _lastPage = 1;
  int _totalCount = 0;
  double _totalAmount = 0.0;

  int get currentPage => _currentPage;
  int get lastPage => _lastPage;
  int get totalCount => _totalCount;
  double get totalAmount => _totalAmount;
  bool get hasMore => _currentPage < _lastPage;

  Future<void> fetchAllOrders(String token, String restaurantId, {String? date, String? paymentMethod, String? orderType, int page = 1, bool append = false}) async {
    if (page == 1) {
      _isLoading = true;
      if (!append) _allOrders = [];
      notifyListeners();
    }

    final result = await _orderService.fetchAllOrders(token, restaurantId, date: date, paymentMethod: paymentMethod, orderType: orderType, page: page);
    
    if (append) {
      _allOrders.addAll(result['orders']);
    } else {
      _allOrders = result['orders'];
    }

    _currentPage = result['current_page'];
    _lastPage = result['last_page'];
    _totalCount = result['total_count'];
    _totalAmount = double.tryParse(result['total_amount'].toString()) ?? 0.0;

    _isLoading = false;
    notifyListeners();
  }

  List<CartItem> getOrderForTable(String tableId) {
    return _activeOrders[tableId] ?? [];
  }

  String? getOrderIdForTable(String tableId) {
    return _tableOrderIds[tableId];
  }

  Future<String?> addToCart(String token, String restaurantId, String? tableId, MenuItemModel item, {CartItem? customItem, String? orderType, String? customerName, String? customerPhone, String? deliveryAddress, String? customerId, String? source}) async {
    if (tableId == null) return null;
    // Optimistic update
    final order = _activeOrders[tableId] ?? [];

    if (customItem != null) {
      // For customized items (combos), we usually don't merge them as easily because selections might differ
      // But if they are identical, we could merge. For now, let's just add as new line item.
      order.add(customItem);
    } else {
      final existingIndex = order.indexWhere((ci) => ci.menuItem.id == item.id && !ci.isSent && ci.children.isEmpty);
      
      if (existingIndex >= 0) {
        order[existingIndex].quantity++;
      } else {
        order.add(CartItem(menuItem: item, isSent: false));
      }
    }
    
    _activeOrders[tableId] = order;
    notifyListeners();
    return null;
  }


  String? getOrderCustomerId(String tableId) => _orderCustomerIds[tableId];
  String? getOrderSource(String tableId) => _orderSources[tableId];

  Future<Map<String, dynamic>?> submitKOTWithResponse(String token, String restaurantId, String tableId, {String? orderType, String? customerName, String? customerPhone, String? deliveryAddress, String? customerId, String? source}) async {
    final order = _activeOrders[tableId] ?? [];
    final unsentItems = order.where((item) => !item.isSent).toList();
    
    if (unsentItems.isEmpty) return null;

    final existingOrderId = _tableOrderIds[tableId];
    
    final List<Map<String, dynamic>> itemsToSync = [];
    
    for (var item in unsentItems) {
      final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}_${unsentItems.indexOf(item)}';
      
      itemsToSync.add({
        'temp_id': tempId,
        'menu_item_id': item.menuItem.id,
        'quantity': item.quantity,
        'price': item.menuItem.price,
        'notes': item.notes,
      });

      // Add children
      for (var child in item.children) {
        itemsToSync.add({
          'parent_temp_id': tempId,
          'combo_group_id': child.comboGroupId,
          'menu_item_id': child.menuItem.id,
          'quantity': child.quantity,
          'price': child.menuItem.price,
          'notes': child.notes,
        });
      }
    }

    final data = await _orderService.sendKOT(
      token, 
      restaurantId, 
      tableId, 
      itemsToSync, 
      orderType: orderType, 
      customerName: customerName, 
      customerPhone: customerPhone, 
      deliveryAddress: deliveryAddress, 
      orderId: existingOrderId,
      customerId: customerId,
      source: source ?? 'pos_waiter'
    );


    if (data != null && data['order'] != null) {
      final String orderId = data['order']['id'].toString();
      final String newKey = data['order']['table_id'] ?? 'order_$orderId';
      
      _tableOrderIds[newKey] = orderId;
      
      // Mark items as sent
      for (var item in unsentItems) {
        item.isSent = true;
      }
      
      _activeOrders[newKey] = _activeOrders[tableId] ?? [];
      _orderCustomerNames[newKey] = data['order']['customer_name'] ?? customerName ?? 'Guest';
      _orderCustomerIds[newKey] = data['order']['customer_id']?.toString() ?? customerId;
      _orderTypes[newKey] = data['order']['order_type'] ?? orderType ?? 'dine-in';
      _orderSources[newKey] = data['order']['source'] ?? source ?? 'pos_waiter';
      
      if (newKey != tableId) {
        _activeOrders.remove(tableId);
        _tableOrderIds.remove(tableId);
      }
      
      notifyListeners();
      return data;
    }
    return null;
  }


  Future<void> updateQuantity(String token, String restaurantId, String? tableId, CartItem item, int delta, {String? orderType, String? customerName, String? customerPhone, String? deliveryAddress, String? customerId, String? source}) async {
    if (tableId == null) return;
    // Optimistic update
    item.quantity += delta;
    if (item.quantity <= 0) {
      _activeOrders[tableId]?.remove(item);
    }
    notifyListeners();

    // Sync with backend immediately (Real-time update)
    final existingOrderId = _tableOrderIds[tableId];
    if (delta > 0) {
      final data = await _orderService.sendKOT(token, restaurantId, tableId, [
        {
          'menu_item_id': item.menuItem.id,
          'quantity': delta,
          'price': item.menuItem.price,
        }
      ], orderType: orderType, customerName: customerName, customerPhone: customerPhone, deliveryAddress: deliveryAddress, orderId: existingOrderId, customerId: customerId, source: source);
      
      if (data != null && data['order'] != null) {
        final String orderId = data['order']['id'].toString();
        final String newKey = data['order']['table_id'] ?? 'order_$orderId';
        _tableOrderIds[newKey] = orderId;
      }
    } else {
      // Delta is negative (removing/decreasing)
      for (int i = 0; i < delta.abs(); i++) {
        await _orderService.removeItem(token, restaurantId, tableId, item.menuItem.id, orderId: existingOrderId);
      }
    }
  }

  void clearOrder(String tableId) {
    _activeOrders.remove(tableId);
    _tableOrderIds.remove(tableId);
    notifyListeners();
  }

  Future<bool> sendKOT(String token, String restaurantId, String tableId, List<Map<String, dynamic>> items) async {
    _isLoading = true;
    notifyListeners();

    final data = await _orderService.sendKOT(token, restaurantId, tableId, items);

    if (data != null && data['order'] != null) {
      _tableOrderIds[tableId] = data['order']['id'].toString();
    }

    _isLoading = false;
    notifyListeners();
    return data != null;
  }

  Future<Map<String, dynamic>?> generateBill(String token, String orderId, String paymentMethod, {double discountAmount = 0, double discountPercentage = 0, String? discountType, String? discountReason, double? subtotal, double? tax, double? total, double? amountPaid, double? tipAmount, double deliveryCharge = 0, double packingCharge = 0, double serviceCharge = 0}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _orderService.generateBillResponse(
        token, 
        orderId, 
        paymentMethod, 
        discountAmount: discountAmount, 
        discountPercentage: discountPercentage, 
        discountType: discountType, 
        discountReason: discountReason, 
        subtotal: subtotal, 
        tax: tax, 
        total: total,
        amountPaid: amountPaid,
        tipAmount: tipAmount,
        deliveryCharge: deliveryCharge,
        packingCharge: packingCharge,
        serviceCharge: serviceCharge,
      );

      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  Future<bool> reopenOrder(String token, String orderId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _orderService.reopenOrder(token, orderId);
    if (success) {
      final index = _allOrders.indexWhere((o) => o['id'].toString() == orderId);
      if (index != -1) {
        _allOrders[index]['status'] = 'open';
        _allOrders[index]['payment_method'] = null;
      }
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteOrder(String token, String orderId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _orderService.deleteOrder(token, orderId);
    if (success) {
      _allOrders.removeWhere((o) => o['id'].toString() == orderId);
      _totalCount--;
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> transferOrder(String token, String restaurantId, String orderId, String targetTableId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _orderService.transferOrder(token, orderId, targetTableId);
    if (success) {
      await fetchActiveOrders(token, restaurantId);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> mergeOrder(String token, String restaurantId, String sourceOrderId, String targetOrderId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _orderService.mergeOrder(token, sourceOrderId, targetOrderId);
    if (success) {
      await fetchActiveOrders(token, restaurantId);
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<List<dynamic>> getDeliveryPartners(String token, String restaurantId) async {
    return await _orderService.getDeliveryPartners(token, restaurantId);
  }

  Future<bool> assignDeliveryPartner(String token, String orderId, String restaurantId, String deliveryStaffId) async {
    _isLoading = true;
    notifyListeners();

    final success = await _orderService.assignDeliveryPartner(token, orderId, restaurantId, deliveryStaffId);

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateDeliveryStatus(String token, String orderId, String restaurantId, String status) async {
    _isLoading = true;
    notifyListeners();

    final success = await _orderService.updateDeliveryStatus(token, orderId, restaurantId, status);

    _isLoading = false;
    notifyListeners();
    return success;
  }

  void reset() {
    _activeOrders = {};
    _allOrders = [];
    _tableOrderIds = {};
    _orderCustomerNames = {};
    _orderCustomerIds = {};
    _orderTypes = {};
    _orderSources = {};
    _orderDiscountAmounts = {};
    _orderDiscountPercentages = {};
    _orderDiscountTypes = {};
    _orderDiscountReasons = {};
    _orderPaidAmounts = {};
    _orderPayments = {};
    _isLoading = false;
    notifyListeners();
  }
}
