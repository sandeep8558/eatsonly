import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/settings_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/table_provider.dart';
import '../../core/menu_provider.dart';
import '../../core/order_provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/table_model.dart';
import '../../models/menu_model.dart';
import '../../models/cart_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/cupertino.dart';
import '../../services/print_service.dart';
import 'package:eats_only/core/customer_provider.dart';
import 'package:eats_only/models/customer_model.dart';
import '../../services/pdf_service.dart';
import '../../core/kds_station_provider.dart';
import 'widgets/combo_selection_sheet.dart';



enum OrderType { dineIn, takeaway, delivery }

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  RestaurantModel? _selectedRestaurant;
  TableModel? _selectedTable;
  MenuCategoryModel? _selectedCategory;
  OrderType _selectedOrderType = OrderType.dineIn;
  CustomerModel? _selectedCustomer;
  String? _customerName;
  String? _customerPhone;
  String? _deliveryAddress;
  String? _virtualTableId; // For takeaway/delivery sessions

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    await settingsProvider.fetchSettings(auth.token!);

    final restoProvider = Provider.of<RestaurantProvider>(context, listen: false);
    await restoProvider.fetchRestaurants(auth.token!, myRestaurants: true);

    if (restoProvider.restaurants.isNotEmpty && mounted) {
      setState(() {
        if (args != null && args['restaurant_id'] != null) {
          _selectedRestaurant = restoProvider.restaurants.firstWhere(
            (r) => r.id == args['restaurant_id'].toString(),
            orElse: () => restoProvider.selectedRestaurant ?? restoProvider.restaurants.first,
          );
        } else {
          _selectedRestaurant = restoProvider.selectedRestaurant ?? restoProvider.restaurants.first;
        }
      });
      _loadTablesAndMenu();

      // If editing an existing order
      if (args != null) {
        setState(() {
          final typeStr = args['order_type']?.toString().toLowerCase();
          if (typeStr == 'takeaway') {
            _selectedOrderType = OrderType.takeaway;
            _virtualTableId = 'order_${args['id']}';
          } else if (typeStr == 'delivery') {
            _selectedOrderType = OrderType.delivery;
            _virtualTableId = 'order_${args['id']}';
          } else {
            _selectedOrderType = OrderType.dineIn;
            // For Dine-in, we need to find the table after they load
            if (args['table_id'] != null) {
              _pendingTableId = args['table_id'].toString();
            }
          }
          _customerName = args['customer_name'];
          _customerPhone = args['customer_phone'];
          _deliveryAddress = args['delivery_address'];
        });
      }
    }
  }

  String? _pendingTableId;

  Future<void> _loadTablesAndMenu() async {
    if (_selectedRestaurant == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tableProvider = Provider.of<TableProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    
    await Future.wait([
      tableProvider.fetchFloors(auth.token!, _selectedRestaurant!.id),
      orderProvider.fetchActiveOrders(auth.token!, _selectedRestaurant!.id),
      Provider.of<MenuProvider>(context, listen: false).fetchMenuCards(auth.token!, restaurantId: _selectedRestaurant!.id),
    ]);

    if (_pendingTableId != null && mounted) {
      for (var floor in tableProvider.floors) {
        final table = floor.tables.where((t) => t.id == _pendingTableId).firstOrNull;
        if (table != null) {
          setState(() {
            _selectedTable = table;
            _pendingTableId = null;
          });
          break;
        }
      }
    }
  }

  void _onTableSelected(TableModel table) {
    setState(() {
      _selectedTable = table;
      _selectedCategory = null; // Reset category to force re-selection from floor menu
    });
  }

  void _addToCart(MenuItemModel item) async {
    if (_selectedOrderType == OrderType.dineIn && _selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a table first!')));
      return;
    }

    if (_selectedOrderType != OrderType.dineIn && _virtualTableId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please start a new order (NEW) first!')));
      _showCustomerDetailsDialog();
      return;
    }

    CartItem? customItem;
    if (item.type == 'combo') {
      customItem = await showModalBottomSheet<CartItem>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => ComboSelectionSheet(
          comboItem: item,
          scrollController: scrollController,
        ),

        ),
      );

      if (customItem == null) return; // User cancelled
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final tableId = _selectedOrderType == OrderType.dineIn ? _selectedTable!.id : _virtualTableId!;
    final newKey = await Provider.of<OrderProvider>(context, listen: false).addToCart(
      auth.token!, 
      _selectedRestaurant!.id, 
      tableId, 
      item,
      customItem: customItem,
      orderType: _selectedOrderType == OrderType.dineIn ? 'dine-in' : _selectedOrderType.name,
      customerName: _customerName,
      customerPhone: _customerPhone,
      deliveryAddress: _deliveryAddress,
      customerId: _selectedCustomer?.id,
      source: 'pos_waiter',
    );


    if (newKey != null && _selectedOrderType != OrderType.dineIn) {
      setState(() {
        _virtualTableId = newKey;
      });
    }
  }

  void _updateQuantity(CartItem item, int delta) {
    final tableId = _selectedOrderType == OrderType.dineIn ? _selectedTable?.id : _virtualTableId;
    if (tableId == null || _selectedRestaurant == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<OrderProvider>(context, listen: false).updateQuantity(
      auth.token!, 
      _selectedRestaurant!.id, 
      tableId, 
      item, 
      delta,
      orderType: _selectedOrderType == OrderType.dineIn ? 'dine-in' : _selectedOrderType.name,
      customerName: _customerName,
      customerPhone: _customerPhone,
      deliveryAddress: _deliveryAddress,
      customerId: _selectedCustomer?.id,
      source: 'pos_waiter',
    );
  }

  void _sendKOT(BuildContext context, String? tableId, List<CartItem> order) async {
    if (tableId == null || _selectedRestaurant == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a table or start an order first!')));
      return;
    }

    final unsent = order.where((item) => !item.isSent).toList();
    if (unsent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All items already sent to kitchen!')));
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<OrderProvider>(context, listen: false);

    final response = await provider.submitKOTWithResponse(
      auth.token!, 
      _selectedRestaurant!.id, 
      tableId,
      orderType: _selectedOrderType == OrderType.dineIn ? 'dine-in' : _selectedOrderType.name,
      customerName: _customerName,
      customerPhone: _customerPhone,
      deliveryAddress: _deliveryAddress,
      customerId: _selectedCustomer?.id,
      source: 'pos_waiter',
    );

    final orderData = response?['order'];
    final String? orderId = orderData?['id']?.toString();
    final String? newKey = orderData?['table_id'] ?? (orderId != null ? 'order_$orderId' : null);

    if (newKey != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('KOT Sent to Kitchen!'), backgroundColor: Colors.green));
      
      // Handle Printing
      final kots = response?['kots'] as List? ?? [];
      final printService = PrintService();
      final stationProvider = Provider.of<KdsStationProvider>(context, listen: false);

      for (var kot in kots) {
        final stationId = kot['kds_station_id']?.toString();
        final station = stationProvider.stations.where((s) => s.id == stationId).firstOrNull;
        
        if (station != null && station.printerIp != null) {
          printService.printKOT(
            printerIp: station.printerIp!,
            tableName: kot['order']?['table']?['name'] ?? 'Direct',
            orderId: kot['order_id'].toString(),
            items: kot['items'],
            stationName: station.name,
          );
        }
      }

      if (_selectedOrderType != OrderType.dineIn) {
        setState(() {
          _virtualTableId = newKey;
        });
      }
    } else if (mounted) {

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send KOT!')));
    }
  }

  void _printBill(BuildContext context, String? tableId, List<CartItem> order, double subtotal, double tax, double total, double deliveryCharge, double packingCharge, double serviceCharge, Map<String, Map<String, dynamic>> taxBreakup) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final restoProvider = Provider.of<RestaurantProvider>(context, listen: false);
    
    if (tableId == null || restoProvider.restaurants.isEmpty) return;

    final orderId = orderProvider.getOrderIdForTable(tableId);
    if (orderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please send KOT before printing bill!')));
      return;
    }

    // Use the actual printer IP from restaurant settings
    final printerIp = restoProvider.restaurants.first.billPrinterIp;
    
    if (printerIp == null || printerIp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill printer IP not configured in Restaurant Settings!')));
      return;
    }
    
    final printService = PrintService();

    final success = await printService.printBill(
      printerIp: printerIp,
      restaurantName: restoProvider.restaurants.first.name,
      tableName: tableId.startsWith('order_') ? 'Takeaway' : tableId, // Simple logic for table name
      orderId: orderId,
      subtotal: subtotal,
      tax: tax,
      total: total,
      deliveryCharge: deliveryCharge,
      packingCharge: packingCharge,
      serviceCharge: serviceCharge,
      taxBreakup: taxBreakup,
      items: order.map((item) => {
        'menu_item': {'name': item.menuItem.name},
        'quantity': item.quantity,
        'price': item.menuItem.price,
      }).toList(),
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill sent to printer!'), backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to connect to printer. Check IP!')));
      }
    }
  }

  Future<void> _downloadBillPdf(BuildContext context, String? tableId, List<CartItem> order, double subtotal, double tax, double total, double deliveryCharge, double packingCharge, double serviceCharge, Map<String, Map<String, dynamic>> taxBreakup) async {
    final tableProvider = Provider.of<TableProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (_selectedRestaurant == null) return;
    
    final tableName = tableId != null 
        ? (tableProvider.allTables.firstWhere((t) => t.id == tableId, orElse: () => TableModel(id: '', floorId: '', name: 'Unknown', capacity: 0, shape: 'square', xPos: 0, yPos: 0, status: 'available')).name)
        : 'Counter';
        
    final orderId = tableId != null ? orderProvider.getOrderIdForTable(tableId) : 'NEW';

    final pdfService = PdfService();
    await pdfService.generateBillPdf(
      restaurantName: _selectedRestaurant!.name,
      tableName: tableName,
      orderId: orderId ?? 'NEW',
      subtotal: subtotal,
      tax: tax,
      total: total,
      deliveryCharge: deliveryCharge,
      packingCharge: packingCharge,
      serviceCharge: serviceCharge,
      taxBreakup: taxBreakup,
      items: order.map((i) => {
        'menu_item': {'name': i.menuItem.name},
        'quantity': i.quantity,
        'price': i.menuItem.price,
      }).toList(),
      address: _selectedRestaurant!.address,
    );
  }

  Future<void> _downloadKotPdf(BuildContext context, String? tableId, List<CartItem> order) async {
    final tableProvider = Provider.of<TableProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final menuProvider = Provider.of<MenuProvider>(context, listen: false);
    final kdsProvider = Provider.of<KdsStationProvider>(context, listen: false);
    
    final tableName = tableId != null 
        ? (tableProvider.allTables.firstWhere((t) => t.id == tableId, orElse: () => TableModel(id: '', floorId: '', name: 'Unknown', capacity: 0, shape: 'square', xPos: 0, yPos: 0, status: 'available')).name)
        : 'Counter';
        
    final orderId = tableId != null ? orderProvider.getOrderIdForTable(tableId) : 'NEW';

    // Map categories to stations
    final categoryToStation = <String, String?>{};
    for (var card in menuProvider.menuCards) {
      for (var cat in card.categories) {
        categoryToStation[cat.id] = cat.kdsStationId;
      }
    }

    // Map station IDs to Names
    final stationIdToName = <String, String>{};
    for (var station in kdsProvider.stations) {
      stationIdToName[station.id] = station.name;
    }

    // Group items by station
    final stationGroups = <String?, List<CartItem>>{};
    for (var item in order) {
      final stationId = categoryToStation[item.menuItem.menuCategoryId];
      if (!stationGroups.containsKey(stationId)) {
        stationGroups[stationId] = [];
      }
      stationGroups[stationId]!.add(item);
    }

    // Prepare station groups for PDF
    final stationGroupsData = <Map<String, dynamic>>[];
    for (var entry in stationGroups.entries) {
      final stationId = entry.key;
      final stationItems = entry.value;
      final stationName = stationId != null ? (stationIdToName[stationId] ?? 'Main') : 'Main';

      stationGroupsData.add({
        'name': stationName,
        'items': stationItems.map((i) => {
          'menu_item': {'name': i.menuItem.name},
          'quantity': i.quantity,
          'notes': i.notes,
          'children': i.children.map((c) => {'menu_item': {'name': c.menuItem.name}}).toList(),
        }).toList(),
      });
    }

    // Generate single PDF with multiple pages
    if (stationGroupsData.isNotEmpty) {
      final pdfService = PdfService();
      await pdfService.generateKotPdf(
        tableName: tableName,
        orderId: orderId ?? 'NEW',
        stationGroups: stationGroupsData,
      );
    }
  }

  void _showTransferDialog(BuildContext context, String currentTableId) {
    final tableProvider = Provider.of<TableProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final orderId = orderProvider.getOrderIdForTable(currentTableId);
    if (orderId == null) return;

    // Filter available tables (not current one and status is available)
    final availableTables = tableProvider.allTables.where((t) => t.id != currentTableId && t.status == 'available').toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16181D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Transfer Table', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: availableTables.isEmpty 
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No available tables found!', style: TextStyle(color: Colors.white60), textAlign: TextAlign.center),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: availableTables.length,
                itemBuilder: (context, index) {
                  final table = availableTables[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(table.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Capacity: ${table.capacity}', style: const TextStyle(color: Colors.white38)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFD4AF37)),
                    onTap: () async {
                      final success = await orderProvider.transferOrder(auth.token!, _selectedRestaurant!.id, orderId, table.id);
                      if (success && mounted) {
                        Navigator.pop(context);
                        setState(() {
                          _selectedTable = table;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transferred to ${table.name}'), backgroundColor: Colors.green));
                      }
                    },
                  );
                },
              ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
        ],
      ),
    );
  }

  void _showMergeDialog(BuildContext context, String currentTableId) {
    final tableProvider = Provider.of<TableProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final sourceOrderId = orderProvider.getOrderIdForTable(currentTableId);
    if (sourceOrderId == null) return;

    // Filter busy tables (tables with active orders, not including the current one)
    final busyTables = tableProvider.allTables.where((t) => t.id != currentTableId && orderProvider.getOrderIdForTable(t.id) != null).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16181D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Merge Table', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: busyTables.isEmpty 
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('No other active tables found!', style: TextStyle(color: Colors.white60), textAlign: TextAlign.center),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: busyTables.length,
                itemBuilder: (context, index) {
                  final table = busyTables[index];
                  final targetOrderId = orderProvider.getOrderIdForTable(table.id);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(table.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Merge current items into ${table.name}', style: const TextStyle(color: Colors.white38)),
                    trailing: const Icon(Icons.merge_type, color: Color(0xFFD4AF37)),
                    onTap: () async {
                      if (targetOrderId == null) return;
                      final success = await orderProvider.mergeOrder(auth.token!, _selectedRestaurant!.id, sourceOrderId, targetOrderId);
                      if (success && mounted) {
                        Navigator.pop(context);
                        setState(() {
                          _selectedTable = null; // Current table is now empty
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Merged into ${table.name}'), backgroundColor: Colors.green));
                      }
                    },
                  );
                },
              ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
        ],
      ),
    );
  }

  void _showDiscountDialog() {
    final provider = Provider.of<OrderProvider>(context, listen: false);
    final tableId = _selectedOrderType == OrderType.dineIn ? _selectedTable?.id : _virtualTableId;
    if (tableId == null) return;

    final currentType = provider.getOrderDiscountType(tableId);
    final currentAmount = provider.getOrderDiscountAmount(tableId);
    final currentPercentage = provider.getOrderDiscountPercentage(tableId);
    final currentReason = provider.getOrderDiscountReason(tableId);

    final amountController = TextEditingController(text: currentType == 'fixed' ? currentAmount.toStringAsFixed(0) : '');
    final percentController = TextEditingController(text: currentType == 'percentage' ? currentPercentage.toStringAsFixed(0) : '');
    final reasonController = TextEditingController(text: currentReason ?? '');
    String selectedType = currentType ?? 'percentage';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF16181D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Apply Discount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => selectedType = 'percentage'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == 'percentage' ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text('% Percentage', style: TextStyle(color: selectedType == 'percentage' ? Colors.black : Colors.white, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => setDialogState(() => selectedType = 'fixed'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selectedType == 'fixed' ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(child: Text('₹ Fixed Amount', style: TextStyle(color: selectedType == 'fixed' ? Colors.black : Colors.white, fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: selectedType == 'percentage' ? percentController : amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: selectedType == 'percentage' ? '0%' : '₹0',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Reason (e.g. Birthday, Happy Hour)',
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                provider.setDiscount(tableId, type: null, amount: 0, percentage: 0, reason: null);
                Navigator.pop(context);
              },
              child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0;
                final percent = double.tryParse(percentController.text) ?? 0;
                provider.setDiscount(
                  tableId,
                  type: selectedType,
                  amount: selectedType == 'fixed' ? amount : 0,
                  percentage: selectedType == 'percentage' ? percent : 0,
                  reason: reasonController.text,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Apply Discount'),
            ),
          ],
        ),
      ),
    );
  }



  void _showNotesDialog(CartItem item) {
    final controller = TextEditingController(text: item.notes);
    showDialog(

      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Note for ${item.menuItem.name}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'e.g. Extra spicy, No onions...',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                item.notes = controller.text;
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetailsDialog() {
    final nameController = TextEditingController(text: _customerName);
    final phoneController = TextEditingController(text: _customerPhone);
    final addressController = TextEditingController(text: _deliveryAddress);


    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(_selectedOrderType == OrderType.takeaway ? 'Takeaway Details' : 'Delivery Details', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Customer Name', Icons.person_outline),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
            ),
            if (_selectedOrderType == OrderType.delivery) ...[
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration('Delivery Address', Icons.map_outlined),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () {
              setState(() {
                _customerName = nameController.text;
                _customerPhone = phoneController.text;
                _deliveryAddress = addressController.text;
                _virtualTableId = 'virtual_${_selectedOrderType.name}_${DateTime.now().millisecondsSinceEpoch}';
              });
              Navigator.pop(context);
            },
            child: const Text('Start Order'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 18),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 900;
        
        return Container(
          color: const Color(0xFF0F1115),
          child: SafeArea(
            child: Scaffold(
              backgroundColor: const Color(0xFF0F1115),
              body: Column(
                children: [
                  _buildHeader(isMobile),
                  if (isMobile) 
                    _buildMobileLayout()
                  else
                    _buildDesktopLayout(),
                ],
              ),
              bottomNavigationBar: isMobile ? _buildMobileCartBar() : null,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF16181D),
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: _buildTableSelector(),
          ),
          Expanded(
            child: _buildMenuBrowser(isMobile: false),
          ),
          Container(
            width: 350,
            decoration: BoxDecoration(
              color: const Color(0xFF16181D),
              border: Border(left: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: _buildOrderPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Expanded(
      child: Column(
        children: [
          // Menu Browser (Rest of the space)
          Expanded(
            child: _buildMenuBrowser(isMobile: true),
          ),
          // Bottom Selector
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF16181D),
              border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: _selectedOrderType == OrderType.dineIn 
                ? _buildMobileTableSelector() 
                : _buildMobileDirectOrderSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTypeButton(OrderType type, String label, IconData icon, bool isMobile) {
    final isSelected = _selectedOrderType == type;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedOrderType = type;
            _selectedTable = null;
            _virtualTableId = null;
            _customerName = null;
            _customerPhone = null;
            _deliveryAddress = null;
            _selectedCategory = null;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 6 : 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white38),
              if (label.isNotEmpty) const SizedBox(width: 8),
              if (label.isNotEmpty)
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  onPressed: () {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    if (auth.user?.isWaiter == true) {
                      Navigator.of(context).pushReplacementNamed('/dashboard');
                    } else {
                      Navigator.of(context).pushReplacementNamed('/orders');
                    }
                  },
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.point_of_sale_rounded, color: Color(0xFFD4AF37), size: 18),
                  const SizedBox(width: 8),
                  const Text('EatsOnly POS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
                if (_selectedRestaurant != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.storefront_rounded, color: Colors.white38, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _buildRestaurantSelector(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildOrderTypeButton(OrderType.dineIn, isMobile ? '' : 'DINE-IN', Icons.restaurant_rounded, isMobile),
                _buildOrderTypeButton(OrderType.takeaway, isMobile ? '' : 'TAKEAWAY', Icons.shopping_bag_rounded, isMobile),
                _buildOrderTypeButton(OrderType.delivery, isMobile ? '' : 'DELIVERY', Icons.delivery_dining_rounded, isMobile),
              ],
            ),
          ),

          if (!isMobile)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  const Text('Online', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRestaurantSelector() {
    final restoProvider = Provider.of<RestaurantProvider>(context);
    return DropdownButtonHideUnderline(
      child: DropdownButton<RestaurantModel>(
        isExpanded: true,
        value: _selectedRestaurant,
        dropdownColor: const Color(0xFF16181D),
        items: restoProvider.restaurants.map((r) => DropdownMenuItem(
          value: r,
          child: Text(
            r.name, 
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        )).toList(),
        onChanged: (val) {
          if (val != null) {
            restoProvider.setSelectedRestaurant(val);
            setState(() {
              _selectedRestaurant = val;
              _selectedTable = null; // Clear table on restaurant change
            });
            _loadTablesAndMenu();
          }
        },
      ),
    );
  }

  Widget _buildMobileTableSelector() {
    final tableProvider = Provider.of<TableProvider>(context);
    if (tableProvider.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: tableProvider.floors.length,
      itemBuilder: (context, floorIndex) {
        final floor = tableProvider.floors[floorIndex];
        
        return Container(
          margin: const EdgeInsets.only(right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tables Row for this floor
              Row(
                children: floor.tables.map((table) {
                  final isSelected = _selectedTable?.id == table.id;
                  final hasOrder = Provider.of<OrderProvider>(context).getOrderForTable(table.id).isNotEmpty;
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => _onTableSelected(table),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFD4AF37) : (hasOrder ? Colors.redAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05)),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : (hasOrder ? Colors.redAccent : Colors.white10)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              table.shape == 'round' ? Icons.circle_outlined : Icons.crop_square_rounded,
                              size: 16,
                              color: isSelected ? Colors.black : (hasOrder ? Colors.redAccent : Colors.white38),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              table.name,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              // Horizontal Strap
              Container(
                height: 16,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                ),
                child: Center(
                  child: Text(
                    floor.name.toUpperCase(),
                    style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableSelector() {
    final tableProvider = Provider.of<TableProvider>(context);
    if (_selectedOrderType != OrderType.dineIn) {
      return Column(
        children: [
          const SizedBox(height: 20),
          IconButton(
            onPressed: _showCustomerDetailsDialog,
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4AF37), size: 32),
          ),
          const Text('NEW', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, orderProvider, _) {
                final directOrders = orderProvider.activeOrders.keys.where((key) {
                  final type = orderProvider.orderTypes[key];
                  if (type == null) return false;
                  
                  // Normalize both to compare (e.g. dine-in vs dineIn)
                  String normType = type.toLowerCase().replaceAll('-', '');
                  String normCurrent = _selectedOrderType.name.toLowerCase().replaceAll('-', '');
                  return normType == normCurrent;
                }).toList();

                if (directOrders.isEmpty) {
                  return const Center(child: Text('NONE', style: TextStyle(color: Colors.white12, fontSize: 10)));
                }

                return ListView.builder(
                  itemCount: directOrders.length,
                  itemBuilder: (context, index) {
                    final key = directOrders[index];
                    final name = orderProvider.orderCustomerNames[key] ?? 'Guest';
                    final isSelected = _virtualTableId == key;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _virtualTableId = key;
                          _customerName = name;
                          // In a real app we'd also store/fetch phone/address
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.white10),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.person_outline, color: isSelected ? Colors.black : const Color(0xFFD4AF37), size: 16),
                            const SizedBox(height: 4),
                            Text(
                              name.toUpperCase(),
                              style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    }
    if (tableProvider.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text('TABLES', style: TextStyle(color: Colors.white38, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: tableProvider.floors.length,
            itemBuilder: (context, i) {
              final floor = tableProvider.floors[i];
              return LayoutBuilder(
                builder: (context, constraints) {
                  bool isSmall = constraints.maxWidth < 100;
                  
                  if (isSmall) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Horizontal Strap (Compact)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.1)),
                            ),
                            child: Center(
                              child: Text(
                                floor.name.toUpperCase(),
                                style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 7, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Tables Grid
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: floor.tables.length,
                            itemBuilder: (context, index) => _buildTableItem(floor.tables[index]),
                          ),
                        ],
                      ),
                    );
                  }

                  // Vertical Strap (Normal Desktop)
                  final double itemHeight = 72.0;
                  final double totalHeight = (floor.tables.length * itemHeight) + ((floor.tables.length - 1).clamp(0, 100) * 8.0);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: totalHeight,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                          ),
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: Text(
                                  floor.name.toUpperCase(),
                                  style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 8, letterSpacing: 0.5),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: floor.tables.length,
                            itemBuilder: (context, index) => _buildTableItem(floor.tables[index]),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTableItem(TableModel table) {
    final isSelected = _selectedTable?.id == table.id;
    final hasOrder = Provider.of<OrderProvider>(context).getOrderForTable(table.id).isNotEmpty;

    return InkWell(
      onTap: () => _onTableSelected(table),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : (hasOrder ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : (hasOrder ? Colors.redAccent : Colors.white10)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              table.shape == 'round' ? Icons.circle_outlined : Icons.crop_square_rounded,
              size: 18,
              color: isSelected ? Colors.black : (hasOrder ? Colors.redAccent : Colors.white38),
            ),
            const SizedBox(height: 4),
            Text(
              table.name,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuBrowser({required bool isMobile}) {
    final menuProvider = Provider.of<MenuProvider>(context);
    final tableProvider = Provider.of<TableProvider>(context);

    // Determine which menu card to use
    List<MenuCardModel> activeMenuCards = [];
    String emptyMessage = "Please select a table to load menu";

    if (_selectedOrderType == OrderType.dineIn) {
      if (_selectedTable != null) {
        final floor = tableProvider.floors.firstWhere((f) => f.id == _selectedTable!.floorId);
        activeMenuCards = menuProvider.menuCards.where((c) => c.id == floor.menuCardId).toList();
        emptyMessage = 'No menu card attached to ${floor.name}';
      }
    } else if (_selectedOrderType == OrderType.takeaway) {
      activeMenuCards = menuProvider.menuCards.where((c) => c.id == _selectedRestaurant?.takeawayMenuCardId).toList();
      emptyMessage = 'No Takeaway menu card assigned in settings';
    } else if (_selectedOrderType == OrderType.delivery) {
      activeMenuCards = menuProvider.menuCards.where((c) => c.id == _selectedRestaurant?.deliveryMenuCardId).toList();
      emptyMessage = 'No Delivery menu card assigned in settings';
    }

    if (activeMenuCards.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, color: Colors.white.withOpacity(0.1), size: 64),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final floorMenu = activeMenuCards; // Alias for existing code below
    
    final allCategories = floorMenu.first.categories;
    if (allCategories.isEmpty) return const Center(child: Text('Menu is empty.', style: TextStyle(color: Colors.white54)));
    
    // Ensure we have a selected category if none is set
    final currentCategory = _selectedCategory ?? allCategories.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 90,
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menu Card Name Label
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: Row(
                  children: [
                    Icon(Icons.menu_book_rounded, size: 12, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(width: 8),
                    Text(
                      'LOADED MENU: ',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                    Text(
                      floorMenu.first.name.toUpperCase(),
                      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: allCategories.length,
                  itemBuilder: (context, index) {
                    final cat = allCategories[index];
                    final isSelected = currentCategory.id == cat.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        selectedColor: const Color(0xFFD4AF37),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.bold),
                        onSelected: (val) { if (val) setState(() => _selectedCategory = cat); },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 4,
              childAspectRatio: isMobile ? 4.5 : 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: currentCategory.items.length,
            itemBuilder: (context, index) => _buildMenuItemCard(currentCategory.items[index], isMobile),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(MenuItemModel item, bool isMobile) {
    if (isMobile) {
      return InkWell(
        onTap: () => _addToCart(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              // Small Image at left
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.restaurant, color: Colors.white.withOpacity(0.1), size: 24),
                ),
              ),
              const SizedBox(width: 16),
              // Name and Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${item.price.toStringAsFixed(2)}',
                      style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ],
                ),
              ),
              // Add Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Color(0xFFD4AF37), size: 20),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _addToCart(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                child: Center(child: Icon(Icons.restaurant, color: Colors.white.withOpacity(0.1), size: 40)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text('₹${item.price.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileCartBar() {
    final tableId = _selectedOrderType == OrderType.dineIn ? _selectedTable?.id : _virtualTableId;
    if (tableId == null) return const SizedBox.shrink();
    
    final order = Provider.of<OrderProvider>(context).getOrderForTable(tableId);
    if (order.isEmpty) return const SizedBox.shrink();

    double total = order.fold(0.0, (sum, item) => sum + item.totalWithTax);
    final displayName = _selectedOrderType == OrderType.dineIn 
        ? _selectedTable!.name 
        : (_customerName ?? 'Direct Order');

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${order.length} items for $displayName', style: const TextStyle(color: Colors.white54, fontSize: 10)),
              Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () => _showMobileCart(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('VIEW CART', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMobileCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: _buildOrderPanel(onRefresh: () => setModalState(() {})),
          );
        },
      ),
    );
  }

  Widget _buildItemStatusBadge(String? status) {
    final cleanStatus = (status ?? 'placed').toLowerCase();
    Color bgColor;
    Color textColor;
    String text;

    switch (cleanStatus) {
      case 'placed':
        bgColor = Colors.blue.withOpacity(0.15);
        textColor = Colors.blueAccent;
        text = 'PLACED';
        break;
      case 'preparing':
      case 'cooking':
        bgColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orangeAccent;
        text = 'PREPARING';
        break;
      case 'ready':
        bgColor = Colors.green.withOpacity(0.15);
        textColor = Colors.greenAccent;
        text = 'READY';
        break;
      case 'served':
        bgColor = Colors.teal.withOpacity(0.15);
        textColor = Colors.tealAccent;
        text = 'SERVED';
        break;
      default:
        bgColor = Colors.blueGrey.withOpacity(0.15);
        textColor = Colors.blueGrey;
        text = cleanStatus.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildOrderPanel({VoidCallback? onRefresh}) {
    final provider = Provider.of<OrderProvider>(context);
    final tableId = _selectedOrderType == OrderType.dineIn ? _selectedTable?.id : _virtualTableId;
    final order = tableId != null ? provider.getOrderForTable(tableId) : <CartItem>[];
    
    String title = "CURRENT ORDER";
    String? subtitle;

    if (_selectedOrderType == OrderType.dineIn && _selectedTable != null) {
      subtitle = _selectedTable!.name;
    } else if (_selectedOrderType != OrderType.dineIn && _customerName != null) {
      title = _selectedOrderType.name.toUpperCase();
      subtitle = _customerName;
    } else {
      subtitle = "Select a table";
    }

    double subtotal = order.fold(0.0, (sum, item) => sum + item.total);
    
    final discountAmount = tableId != null ? provider.getOrderDiscountAmount(tableId) : 0.0;
    final discountPercentage = tableId != null ? provider.getOrderDiscountPercentage(tableId) : 0.0;
    final discountType = tableId != null ? provider.getOrderDiscountType(tableId) : null;
    final discountReason = tableId != null ? provider.getOrderDiscountReason(tableId) : null;

    double calculatedDiscount = 0;
    if (discountType == 'fixed') {
      calculatedDiscount = discountAmount;
    } else if (discountType == 'percentage') {
      calculatedDiscount = subtotal * (discountPercentage / 100);
    }
    
    // Total Tax should be calculated based on whether it's inclusive or exclusive
    double totalTax = 0;
    double exclusiveTax = 0;
    
    for (var item in order) {
      if (item.menuItem.taxGroup?.isInclusive ?? true) {
        // Tax is already in subtotal, we just track it for display
        totalTax += item.taxAmount;
      } else {
        // Exclusive tax needs to be added to grand total
        exclusiveTax += item.taxAmount;
        totalTax += item.taxAmount;
      }
    }
    
    // Pro-rate tax based on discount (Tax on discounted price)
    if (subtotal > 0 && calculatedDiscount > 0) {
      totalTax = totalTax * ((subtotal - calculatedDiscount) / subtotal);
      exclusiveTax = exclusiveTax * ((subtotal - calculatedDiscount) / subtotal);
    }

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    double deliveryCharge = 0;
    double packingCharge = 0;
    double serviceChargePercent = 0;

    if (_selectedOrderType == OrderType.dineIn) {
      if (settingsProvider.dineinPackingEnabled) packingCharge = double.tryParse(settingsProvider.dineinPackingAmount) ?? 0;
      if (settingsProvider.dineinServiceEnabled) serviceChargePercent = double.tryParse(settingsProvider.dineinServiceAmount) ?? 0;
    } else if (_selectedOrderType == OrderType.takeaway) {
      if (settingsProvider.takeawayPackingEnabled) packingCharge = double.tryParse(settingsProvider.takeawayPackingAmount) ?? 0;
      if (settingsProvider.takeawayServiceEnabled) serviceChargePercent = double.tryParse(settingsProvider.takeawayServiceAmount) ?? 0;
    } else if (_selectedOrderType == OrderType.delivery) {
      if (settingsProvider.deliveryDeliveryEnabled) deliveryCharge = double.tryParse(settingsProvider.deliveryDeliveryAmount) ?? 0;
      if (settingsProvider.deliveryPackingEnabled) packingCharge = double.tryParse(settingsProvider.deliveryPackingAmount) ?? 0;
      if (settingsProvider.deliveryServiceEnabled) serviceChargePercent = double.tryParse(settingsProvider.deliveryServiceAmount) ?? 0;
    }
    
    double serviceCharge = (subtotal - calculatedDiscount) * (serviceChargePercent / 100);

    // Grand Total: (Subtotal - Discount) + Exclusive Tax + Charges
    double grandTotal = (subtotal - calculatedDiscount) + exclusiveTax + deliveryCharge + packingCharge + serviceCharge;
    final alreadyPaid = tableId != null ? provider.getOrderPaidAmount(tableId) : 0.0;

    // Calculate tax breakup
    Map<String, Map<String, dynamic>> taxBreakup = {};
    for (var item in order) {
      if (item.menuItem.taxGroup != null) {
        final group = item.menuItem.taxGroup!;
        double totalPercentage = group.taxes.fold(0, (sum, t) => sum + t.percentage);
        
        for (var tax in group.taxes) {
          double taxAmount = 0;
          if (group.isInclusive) {
            taxAmount = item.total * (tax.percentage / (100 + totalPercentage));
          } else {
            taxAmount = item.total * (tax.percentage / 100);
          }

          // Apply discount scaling to tax breakup item
          if (subtotal > 0 && calculatedDiscount > 0) {
            taxAmount = taxAmount * ((subtotal - calculatedDiscount) / subtotal);
          }

          String key = "${tax.name} (${tax.percentage}%)";
          if (!taxBreakup.containsKey(key)) {
            taxBreakup[key] = {'amount': 0.0, 'isInclusive': group.isInclusive};
          }
          taxBreakup[key]!['amount'] += taxAmount;
        }
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  Text(subtitle ?? "", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Spacer(),
              // Customer Selection Button
              InkWell(
                onTap: _showCustomerSelectionSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _selectedCustomer != null ? const Color(0xFFD4AF37).withOpacity(0.3) : Colors.white10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _selectedCustomer != null ? Icons.person : Icons.person_add_outlined,
                        color: _selectedCustomer != null ? const Color(0xFFD4AF37) : Colors.white38,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _customerName ?? 'Guest',
                            style: TextStyle(
                              color: _selectedCustomer != null ? Colors.white : Colors.white38,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_customerPhone != null)
                            Text(
                              _customerPhone!,
                              style: const TextStyle(color: Colors.white24, fontSize: 9),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white12, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white38),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    setState(() {
                      _selectedTable = null;
                      _virtualTableId = null;
                      _customerName = null;
                      _customerPhone = null;
                      _deliveryAddress = null;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: order.isEmpty ? const Center(child: Text('Order is empty', style: TextStyle(color: Colors.white54))) : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: order.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final item = order[index];
              return Dismissible(
                key: Key('item_${item.menuItem.id}_$index'),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Colors.redAccent.withOpacity(0.8),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (direction) {
                  // Completely remove item
                  _updateQuantity(item, -item.quantity);
                  if (onRefresh != null) onRefresh();
                },
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              onTap: () {
                                _updateQuantity(item, 1);
                                if (onRefresh != null) onRefresh();
                              },
                              child: const SizedBox(
                                height: 32,
                                width: 36,
                                child: Center(child: Icon(Icons.add, color: Colors.white, size: 14)),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                              onTap: () {
                                _updateQuantity(item, -1);
                                if (onRefresh != null) onRefresh();
                              },
                              child: const SizedBox(
                                height: 32,
                                width: 36,
                                child: Center(child: Icon(Icons.remove, color: Colors.white, size: 14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(
                        children: [
                          Expanded(child: Text(item.menuItem.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                          if (!item.isSent) ...[
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: Icon(Icons.note_add_outlined, size: 14, color: item.notes != null ? const Color(0xFFD4AF37) : Colors.white24),
                              onPressed: () => _showNotesDialog(item),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: const Text('NEW', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ] else ...[
                            const SizedBox(width: 4),
                            _buildItemStatusBadge(item.status),
                          ],
                        ],
                      ),
                      if (item.notes != null && item.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Note: ${item.notes}',
                            style: const TextStyle(color: Colors.orangeAccent, fontSize: 10, fontStyle: FontStyle.italic),
                          ),
                        ),
                      if (item.children.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: item.children.map((child) => Text(
                              '• ${child.menuItem.name}${child.menuItem.price > 0 ? " (+₹${child.menuItem.price.toStringAsFixed(0)})" : ""}',
                              style: const TextStyle(color: Colors.white38, fontSize: 10),
                            )).toList(),
                          ),
                        ),
                      Text('₹${item.menuItem.price}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ])),


                    Text('₹${item.total.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.black26, border: Border(top: BorderSide(color: Colors.white10))),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Subtotal', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Row(
                children: [
                  if (calculatedDiscount == 0)
                    TextButton.icon(
                      onPressed: _showDiscountDialog,
                      icon: const Icon(Icons.add_circle_outline, size: 14, color: Color(0xFFD4AF37)),
                      label: const Text('Add Discount', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11)),
                      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: Size.zero),
                    ),
                  const SizedBox(width: 8),
                  Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ]),
            if (calculatedDiscount > 0) ...[
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(
                  children: [
                    const Text('Discount', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                    if (discountReason != null && discountReason.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text('($discountReason)', style: const TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic)),
                      ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _showDiscountDialog,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.edit, size: 10, color: Colors.white60),
                      ),
                    ),
                  ],
                ),
                Text('-₹${calculatedDiscount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
            ],
            const SizedBox(height: 8),
            if (serviceCharge > 0)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Service Charge', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('₹${serviceCharge.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Packing Charge', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('₹${packingCharge.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Delivery Charge', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('₹${deliveryCharge.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
            ]),
            const SizedBox(height: 8),
            ...taxBreakup.entries.map((entry) {
              final bool isInclusive = entry.value['isInclusive'];
              final double amount = entry.value['amount'];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${entry.key}${isInclusive ? ' (incl)' : ''}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  Text('₹${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              );
            }),
            if (taxBreakup.isEmpty)
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Tax', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('₹${totalTax.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
              ]),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.white10, height: 1),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Grand Total', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text('₹${grandTotal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.w900)),
            ]),
            if (alreadyPaid > 0) ...[
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Already Paid', style: TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                Text('₹${alreadyPaid.toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Balance Due', style: TextStyle(color: Colors.orangeAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                Text('₹${(grandTotal - alreadyPaid).toStringAsFixed(2)}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.w900)),
              ]),
            ],
            const SizedBox(height: 20),
            const SizedBox(height: 16),
            Column(
              children: [
                // Row 1: Primary Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _sendKOT(context, tableId, order),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D2D2D),
                          foregroundColor: const Color(0xFFD4AF37),
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('SEND KOT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: order.isEmpty ? null : () {
                          final orderProvider = Provider.of<OrderProvider>(context, listen: false);
                          final currentTableId = _selectedOrderType == OrderType.dineIn ? _selectedTable?.id : _virtualTableId;
                          if (currentTableId == null) return;
                          
                          final orderId = orderProvider.getOrderIdForTable(currentTableId);
                          if (orderId != null) {
                            _showPaymentSelector(context, orderId, grandTotal);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please send KOT first!')));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 2,
                        ),
                        child: const Text('PAY & BILL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Row 2: Secondary Tools (Centered)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.assignment_rounded, color: Colors.white70, size: 20),
                        tooltip: 'Download KOT PDF',
                        onPressed: order.isEmpty ? null : () => _downloadKotPdf(context, tableId, order),
                      ),
                      Container(width: 1, height: 20, color: Colors.white10),
                      IconButton(
                        icon: const Icon(Icons.print_rounded, color: Colors.white70, size: 20),
                        tooltip: 'Print Bill',
                        onPressed: order.isEmpty ? null : () => _printBill(context, tableId, order, subtotal, totalTax, grandTotal, deliveryCharge, packingCharge, serviceCharge, taxBreakup),
                      ),
                      Container(width: 1, height: 20, color: Colors.white10),
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white70, size: 20),
                        tooltip: 'Download Bill PDF',
                        onPressed: order.isEmpty ? null : () => _downloadBillPdf(context, tableId, order, subtotal, totalTax, grandTotal, deliveryCharge, packingCharge, serviceCharge, taxBreakup),
                      ),
                      if (_selectedOrderType == OrderType.dineIn && tableId != null && order.isNotEmpty) ...[
                        Container(width: 1, height: 20, color: Colors.white10),
                        IconButton(
                          icon: const Icon(Icons.move_up_rounded, color: Color(0xFFD4AF37), size: 20),
                          tooltip: 'Transfer Table',
                          onPressed: () => _showTransferDialog(context, tableId),
                        ),
                        Container(width: 1, height: 20, color: Colors.white10),
                        IconButton(
                          icon: const Icon(Icons.merge_type_rounded, color: Color(0xFFD4AF37), size: 20),
                          tooltip: 'Merge Table',
                          onPressed: () => _showMergeDialog(context, tableId),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

          ]),
        ),
      ],
    );
  }

  void _showPaymentSelector(BuildContext context, String orderId, double total) {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final tableId = _selectedOrderType == OrderType.dineIn ? _selectedTable?.id : _virtualTableId;
    final alreadyPaid = tableId != null ? orderProvider.getOrderPaidAmount(tableId) : 0.0;
    final payments = tableId != null ? orderProvider.getOrderPayments(tableId) : [];
    final remaining = total - alreadyPaid;

    final TextEditingController amountController = TextEditingController(text: remaining.toStringAsFixed(2));
    final TextEditingController tipController = TextEditingController(text: '0');
    double tipAmount = 0;
    String tipType = 'flat'; // 'flat' or 'percent'
    double tipPercent = 0;
    bool isPartial = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16181D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Calculate tip value
          double calculatedTip = 0;
          if (tipType == 'percent') {
            calculatedTip = remaining * (tipPercent / 100);
          } else {
            calculatedTip = double.tryParse(tipController.text) ?? 0;
          }
          tipAmount = calculatedTip;

          final grandTotalWithTip = remaining + tipAmount;

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SETTLE PAYMENT',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (alreadyPaid > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order Total', style: TextStyle(color: Colors.white60, fontSize: 13)),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'PAYMENT HISTORY',
                        style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...payments.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.greenAccent.withOpacity(0.5), size: 12),
                              const SizedBox(width: 6),
                              Text(
                                p['payment_method'].toString().toUpperCase(),
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          Text(
                            '₹${double.tryParse(p['amount'].toString())?.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )),
                    const Divider(color: Colors.white10, height: 20),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Remaining Balance', style: TextStyle(color: Colors.white60, fontSize: 14)),
                      Text(
                        '₹${remaining.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tip Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ADD TIP',
                          style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildTipButton(setModalState, '0%', 0, tipPercent, tipType == 'percent', (val) {
                              tipType = 'percent';
                              tipPercent = val;
                              tipController.text = '0';
                            }),
                            const SizedBox(width: 8),
                            _buildTipButton(setModalState, '10%', 10, tipPercent, tipType == 'percent', (val) {
                              tipType = 'percent';
                              tipPercent = val;
                              tipController.text = '0';
                            }),
                            const SizedBox(width: 8),
                            _buildTipButton(setModalState, '15%', 15, tipPercent, tipType == 'percent', (val) {
                              tipType = 'percent';
                              tipPercent = val;
                              tipController.text = '0';
                            }),
                            const SizedBox(width: 8),
                            _buildTipButton(setModalState, '20%', 20, tipPercent, tipType == 'percent', (val) {
                              tipType = 'percent';
                              tipPercent = val;
                              tipController.text = '0';
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: tipController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Custom Tip',
                                  labelStyle: const TextStyle(color: Colors.white38),
                                  prefixText: '₹ ',
                                  prefixStyle: const TextStyle(color: Color(0xFFD4AF37)),
                                  isDense: true,
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.white10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onTap: () {
                                  setModalState(() {
                                    tipType = 'flat';
                                    tipPercent = -1; // Deselect percentage buttons
                                  });
                                },
                                onChanged: (val) => setModalState(() {}),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL TO PAY', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '₹${grandTotalWithTip.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    title: const Text('Split / Partial Payment', style: TextStyle(color: Colors.white, fontSize: 14)),
                    value: isPartial,
                    onChanged: (val) => setModalState(() => isPartial = val ?? false),
                    contentPadding: EdgeInsets.zero,
                    activeColor: const Color(0xFFD4AF37),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (isPartial) ...[
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (val) {
                        setModalState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: 'Amount to Pay (Partial)',
                        labelStyle: const TextStyle(color: Colors.white38),
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(color: Color(0xFFD4AF37)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.white10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    'CHOOSE PAYMENT METHOD',
                    style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.2,
                    children: [
                      _buildPaymentMethodItem(
                        context,
                        'Cash',
                        Icons.payments_rounded,
                        orderId,
                        customAmount: double.tryParse(amountController.text),
                        tipAmount: tipAmount,
                      ),
                      _buildPaymentMethodItem(
                        context,
                        'Card',
                        Icons.credit_card_rounded,
                        orderId,
                        customAmount: double.tryParse(amountController.text),
                        tipAmount: tipAmount,
                      ),
                      _buildPaymentMethodItem(
                        context,
                        'UPI',
                        Icons.qr_code_scanner_rounded,
                        orderId,
                        isUPI: true,
                        total: grandTotalWithTip,
                        customAmount: double.tryParse(amountController.text),
                        tipAmount: tipAmount,
                      ),
                      _buildPaymentMethodItem(
                        context,
                        'Wallet',
                        Icons.account_balance_wallet_rounded,
                        orderId,
                        customAmount: double.tryParse(amountController.text),
                        tipAmount: tipAmount,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipButton(Function setModalState, String label, double value, double currentPercent, bool isPercentType, Function(double) onSelected) {
    final bool isSelected = isPercentType && currentPercent == value;
    return Expanded(
      child: InkWell(
        onTap: () => setModalState(() => onSelected(value)),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.white10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem(BuildContext context, String name, IconData icon, String orderId, {bool isUPI = false, double? total, double? customAmount, double? tipAmount}) {
    return InkWell(
      onTap: () {
        if (isUPI) {
          _showUPIDialog(context, orderId, total!, amountPaid: customAmount, tipAmount: tipAmount);
        } else {
          _processPayment(context, orderId, name, amountPaid: customAmount, tipAmount: tipAmount);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFD4AF37), size: 24),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _showUPIDialog(BuildContext context, String orderId, double total, {double? amountPaid, double? tipAmount}) {
    try {
      final double displayAmount = amountPaid ?? total;
      final String upiId = _selectedRestaurant?.upiId ?? "restaurant@okaxis";
      final String encodedName = Uri.encodeComponent(_selectedRestaurant?.name ?? "EatsOnly");
      final upiUri = 'upi://pay?pa=$upiId&pn=$encodedName&am=${displayAmount.toStringAsFixed(2)}&cu=INR';
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF16181D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('UPI PAYMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: QrImageView(
                    data: upiUri,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Scan this QR with any UPI app', style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(upiId, style: const TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              Text('₹${displayAmount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 28, fontWeight: FontWeight.w900)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog
                _processPayment(context, orderId, 'UPI', amountPaid: amountPaid, tipAmount: tipAmount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CONFIRM PAYMENT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('QR Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating QR: $e')));
    }
  }

  void _processPayment(BuildContext context, String orderId, String method, {double? amountPaid, double? tipAmount}) async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final tableId = _selectedOrderType == OrderType.dineIn ? _selectedTable?.id : _virtualTableId;
    if (tableId == null) return;

    final order = orderProvider.getOrderForTable(tableId);
    final subtotal = order.fold(0.0, (sum, item) => sum + item.total);
    
    final discountAmount = orderProvider.getOrderDiscountAmount(tableId);
    final discountPercentage = orderProvider.getOrderDiscountPercentage(tableId);
    final discountType = orderProvider.getOrderDiscountType(tableId);
    final discountReason = orderProvider.getOrderDiscountReason(tableId);

    double calculatedDiscount = 0;
    if (discountType == 'fixed') {
      calculatedDiscount = discountAmount;
    } else if (discountType == 'percentage') {
      calculatedDiscount = subtotal * (discountPercentage / 100);
    }
    
    double totalTax = 0;
    double exclusiveTax = 0;
    
    for (var item in order) {
      if (item.menuItem.taxGroup?.isInclusive ?? true) {
        totalTax += item.taxAmount;
      } else {
        exclusiveTax += item.taxAmount;
        totalTax += item.taxAmount;
      }
    }
    
    if (subtotal > 0 && calculatedDiscount > 0) {
      totalTax = totalTax * ((subtotal - calculatedDiscount) / subtotal);
      exclusiveTax = exclusiveTax * ((subtotal - calculatedDiscount) / subtotal);
    }

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    double deliveryCharge = 0;
    double packingCharge = 0;
    double serviceChargePercent = 0;

    if (_selectedOrderType == OrderType.dineIn) {
      if (settingsProvider.dineinPackingEnabled) packingCharge = double.tryParse(settingsProvider.dineinPackingAmount) ?? 0;
      if (settingsProvider.dineinServiceEnabled) serviceChargePercent = double.tryParse(settingsProvider.dineinServiceAmount) ?? 0;
    } else if (_selectedOrderType == OrderType.takeaway) {
      if (settingsProvider.takeawayPackingEnabled) packingCharge = double.tryParse(settingsProvider.takeawayPackingAmount) ?? 0;
      if (settingsProvider.takeawayServiceEnabled) serviceChargePercent = double.tryParse(settingsProvider.takeawayServiceAmount) ?? 0;
    } else if (_selectedOrderType == OrderType.delivery) {
      if (settingsProvider.deliveryDeliveryEnabled) deliveryCharge = double.tryParse(settingsProvider.deliveryDeliveryAmount) ?? 0;
      if (settingsProvider.deliveryPackingEnabled) packingCharge = double.tryParse(settingsProvider.deliveryPackingAmount) ?? 0;
      if (settingsProvider.deliveryServiceEnabled) serviceChargePercent = double.tryParse(settingsProvider.deliveryServiceAmount) ?? 0;
    }
    
    double serviceCharge = (subtotal - calculatedDiscount) * (serviceChargePercent / 100);

    final grandTotal = (subtotal - calculatedDiscount) + exclusiveTax + deliveryCharge + packingCharge + serviceCharge;

    final response = await orderProvider.generateBill(
      auth.token!, 
      orderId, 
      method,
      discountAmount: calculatedDiscount,
      discountPercentage: discountPercentage,
      discountType: discountType,
      discountReason: discountReason,
      subtotal: subtotal,
      tax: totalTax,
      total: grandTotal,
      amountPaid: amountPaid ?? grandTotal,
      tipAmount: tipAmount,
      deliveryCharge: deliveryCharge,
      packingCharge: packingCharge,
      serviceCharge: serviceCharge,
    );
    
    if (response != null && response['status'] == 'success' && mounted) {
      final updatedOrder = response['data'];
      final String finalStatus = updatedOrder['status'];
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(finalStatus == 'completed' 
          ? 'Order fully paid via $method!' 
          : 'Partial payment of ₹${(amountPaid ?? grandTotal).toStringAsFixed(2)} recorded!'),
        backgroundColor: finalStatus == 'completed' ? Colors.green : Colors.blue,
      ));
      
      // Refresh to see remaining balance if not fully paid
      await orderProvider.fetchActiveOrders(auth.token!, _selectedRestaurant!.id);
      
      if (finalStatus == 'completed' || _selectedOrderType == OrderType.delivery || _selectedOrderType == OrderType.takeaway) {
        orderProvider.clearOrder(tableId);
      
        setState(() {
          _selectedTable = null;
          _virtualTableId = null;
          _customerName = null;
          _customerPhone = null;
          _deliveryAddress = null;
        });

        Navigator.of(context).pop(); // Close bottom sheet
      } else {
        // If still open (partial payment), just close the selector to show remaining
        Navigator.of(context).pop();
      }
    } else if (response != null && response['status'] == 'error') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment failed: ${response['message']}'), backgroundColor: Colors.red));
    }
  }

  Widget _buildMobileDirectOrderSelector() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, _) {
        final directOrders = orderProvider.activeOrders.keys.where((key) {
          final type = orderProvider.orderTypes[key];
          if (type == null) return false;
          String normType = type.toLowerCase().replaceAll('-', '');
          String normCurrent = _selectedOrderType.name.toLowerCase().replaceAll('-', '');
          return normType == normCurrent;
        }).toList();

        return ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(16),
          children: [
            // NEW Button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _showCustomerDetailsDialog,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.black),
                      Text('NEW', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Active Orders
            ...directOrders.map((key) {
              final isSelected = _virtualTableId == key;
              final customerName = orderProvider.orderCustomerNames[key] ?? 'Guest';
              
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _virtualTableId = key;
                      _customerName = orderProvider.orderCustomerNames[key];
                    });
                  },
                  child: Container(
                    width: 70,
                    height: 60,
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.2) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? const Color(0xFFD4AF37) : Colors.white10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person_outline, color: Colors.white38, size: 16),
                        const SizedBox(height: 4),
                        Text(
                          customerName,
                          style: TextStyle(color: isSelected ? const Color(0xFFD4AF37) : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _showCustomerSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF16181D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CUSTOMER MANAGEMENT', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                    const SizedBox(height: 8),
                    const Text('Select or Add Customer', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    TextField(
                      onChanged: (val) {
                        Provider.of<CustomerProvider>(context, listen: false).searchCustomers(
                          Provider.of<AuthProvider>(context, listen: false).token!,
                          val,
                        );
                      },
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by phone or name...',
                        hintStyle: const TextStyle(color: Colors.white24),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFD4AF37)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<CustomerProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                    
                    if (provider.searchResults.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_outlined, size: 64, color: Colors.white.withOpacity(0.1)),
                            const SizedBox(height: 16),
                            const Text('No customers found', style: TextStyle(color: Colors.white38)),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                              onPressed: _showAddCustomerDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Add New Customer'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: provider.searchResults.length,
                      separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05)),
                      itemBuilder: (context, index) {
                        final customer = provider.searchResults[index];
                        return ListTile(
                          onTap: () {
                            setState(() {
                              _selectedCustomer = customer;
                              _customerName = customer.name;
                              _customerPhone = customer.phone;
                            });
                            Navigator.pop(context);
                          },
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
                            child: Text(customer.name[0], style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                          ),
                          title: Text(customer.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(customer.phone, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white12, size: 14),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddCustomerDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('New Customer', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Full Name', Icons.person_outline),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Phone Number', Icons.phone_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final provider = Provider.of<CustomerProvider>(context, listen: false);
              final customer = await provider.saveCustomer(auth.token!, nameController.text, phoneController.text);
              if (customer != null && mounted) {
                setState(() {
                  _selectedCustomer = customer;
                  _customerName = customer.name;
                  _customerPhone = customer.phone;
                });
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close sheet
              }
            },
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }
}
