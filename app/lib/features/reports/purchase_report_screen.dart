import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/inventory_provider.dart';
import '../../models/restaurant_model.dart';

class PurchaseReportScreen extends StatefulWidget {
  const PurchaseReportScreen({super.key});

  @override
  State<PurchaseReportScreen> createState() => _PurchaseReportScreenState();
}

class _PurchaseReportScreenState extends State<PurchaseReportScreen> {
  RestaurantModel? _selectedRestaurant;
  final String _selectedRange = 'This Month';

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

  void _refreshPurchases() {
    if (_selectedRestaurant == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);
    invProvider.fetchPurchases(auth.token!, _selectedRestaurant!.id);
    invProvider.fetchSuppliers(auth.token!, _selectedRestaurant!.id);
    invProvider.fetchInventory(auth.token!, _selectedRestaurant!.id);
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 650;
    final restoProvider = Provider.of<RestaurantProvider>(context);
    final invProvider = Provider.of<InventoryProvider>(context);

    final activeResto = restoProvider.selectedRestaurant ?? (restoProvider.restaurants.isNotEmpty ? restoProvider.restaurants.first : null);
    if (activeResto?.id != _selectedRestaurant?.id) {
      _selectedRestaurant = activeResto;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshPurchases();
      });
    }

    // Dynamic calculations from live data
    double totalProcurement = 0.00;
    double pendingInvoices = 0.00;
    for (var po in invProvider.purchases) {
      double amt = double.tryParse(po['total_amount'].toString()) ?? 0.00;
      if (po['status'] != 'cancelled') {
        totalProcurement += amt;
        if (po['status'] == 'pending') {
          pendingInvoices += amt;
        }
      }
    }

    // Dynamic Category division calculations
    Map<String, double> catSum = {};
    double grandCatTotal = 0.00;
    for (var po in invProvider.purchases) {
      if (po['status'] == 'cancelled') continue;
      final List<dynamic> items = po['items'] ?? [];
      for (var item in items) {
        final double qty = double.tryParse(item['quantity'].toString()) ?? 0.00;
        final double price = double.tryParse(item['unit_price'].toString()) ?? 0.00;
        final double lineTotal = qty * price;

        final invItem = item['inventory_item'];
        final String category = invItem != null ? invItem['category'].toString() : 'Uncategorized';

        catSum[category] = (catSum[category] ?? 0.00) + lineTotal;
        grandCatTotal += lineTotal;
      }
    }

    // Standard fallback categories if no items present yet
    final List<Map<String, dynamic>> categoryBreakdown = [];
    final List<Color> colors = [Colors.redAccent, Colors.greenAccent, Colors.blueAccent, Colors.orangeAccent, Colors.purpleAccent, Colors.tealAccent];
    int colorIdx = 0;

    if (catSum.isEmpty) {
      categoryBreakdown.addAll([
        {'category': 'Poultry & Meat', 'amount': 0.0, 'percentage': 0, 'color': Colors.redAccent},
        {'category': 'Fresh Vegetables', 'amount': 0.0, 'percentage': 0, 'color': Colors.greenAccent},
        {'category': 'Dairy Products', 'amount': 0.0, 'percentage': 0, 'color': Colors.blueAccent},
      ]);
    } else {
      catSum.forEach((cat, amt) {
        double pct = grandCatTotal > 0 ? (amt / grandCatTotal) * 100 : 0.0;
        categoryBreakdown.add({
          'category': cat,
          'amount': amt,
          'percentage': pct.round(),
          'color': colors[colorIdx % colors.length]
        });
        colorIdx++;
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => _refreshPurchases(),
        color: const Color(0xFFD4AF37),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isSmall, restoProvider),
              const SizedBox(height: 24),
              invProvider.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryRow(totalProcurement, invProvider.suppliers.length, pendingInvoices),
                        const SizedBox(height: 24),
                        _buildCategoryDistribution(categoryBreakdown),
                        const SizedBox(height: 24),
                        _buildLedgerCard(invProvider.purchases, isSmall),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmall, RestaurantProvider restoProvider) {
    final elements = [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'PURCHASE LEDGER',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Raw Materials, Procurement, and Supplier Ledger Insights',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
      if (isSmall) const SizedBox(height: 16),
      Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => _showAddInvoiceSheet(context),
            icon: const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.black),
            label: const Text('LOG PURCHASE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    ];

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: elements,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: elements,
    );
  }

  Widget _buildSummaryRow(double totalProc, int supplierCount, double pendingAmt) {
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
            _buildStatCard('Total Procurement', '₹${totalProc.toStringAsFixed(2)}', Icons.shopping_bag_rounded, const Color(0xFFD4AF37), '-4.5%'),
            _buildStatCard('Registered Suppliers', '$supplierCount Suppliers', Icons.storefront_rounded, Colors.blueAccent, '+1 New'),
            _buildStatCard('Pending Bills Sum', '₹${pendingAmt.toStringAsFixed(2)}', Icons.pending_actions_rounded, Colors.orangeAccent, 'Pending'),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String growth) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.02),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(height: 4),
          Row(
            children: const [
              Icon(Icons.trending_down_rounded, color: Colors.greenAccent, size: 12),
              SizedBox(width: 4),
              Text('Optimized', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              SizedBox(width: 4),
              Text('this month', style: TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution(List<Map<String, dynamic>> categoryBreakdown) {
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
          const Text('EXPENSE DISTRIBUTION BY CATEGORY', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Column(
            children: categoryBreakdown.map((cat) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: cat['color'],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(cat['category'], style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Row(
                          children: [
                            Text('₹${(cat['amount'] as double).toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 12),
                            Text('${cat['percentage']}%', style: TextStyle(color: cat['color'], fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (cat['percentage'] as int) / 100,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(cat['color']),
                        minHeight: 6,
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildLedgerCard(List<dynamic> purchases, bool isSmall) {
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
          const Text('PROCUREMENT LEDGER', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          purchases.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: const [
                      Icon(Icons.receipt_long_rounded, color: Colors.white24, size: 40),
                      SizedBox(height: 12),
                      Text('No procurement transactions recorded yet', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: purchases.length,
                  separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                  itemBuilder: (context, index) {
                    final po = purchases[index];
                    final bool isPaid = po['status'] == 'paid';
                    final bool isPending = po['status'] == 'pending';

                    // Parse supplier name
                    final String supplierName = po['supplier'] != null ? po['supplier']['name'].toString() : 'Unknown Vendor';

                    // Construct line summary
                    final List<dynamic> items = po['items'] ?? [];
                    List<String> sumList = [];
                    for (var it in items) {
                      final name = it['inventory_item'] != null ? it['inventory_item']['name'] : 'Materials';
                      sumList.add('${it['quantity']}x $name');
                    }
                    final String itemsSummary = sumList.isNotEmpty ? sumList.join(', ') : 'Restock Materials';

                    // Parse and format date
                    String dateStr = '';
                    try {
                      DateTime dt = DateTime.parse(po['order_date'].toString());
                      dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
                    } catch (_) {
                      dateStr = po['order_date'] ?? 'N/A';
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.inventory_2_rounded, color: Colors.blueAccent, size: 18),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        supplierName,
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        itemsSummary,
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text('${po['po_number']} • $dateStr', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('₹${(double.tryParse(po['total_amount'].toString()) ?? 0.00).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? Colors.greenAccent.withOpacity(0.1)
                                          : (isPending ? Colors.orangeAccent.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1)),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      po['status'].toString().toUpperCase(),
                                      style: TextStyle(
                                        color: isPaid ? Colors.greenAccent : (isPending ? Colors.orangeAccent : Colors.redAccent),
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert_rounded, color: Colors.white38, size: 20),
                                color: const Color(0xFF16181D),
                                onSelected: (action) {
                                  if (action == 'edit') {
                                    _showAddInvoiceSheet(context, existingPo: po);
                                  } else if (action == 'delete') {
                                    _confirmDeletePurchase(context, po);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_rounded, color: Colors.white70, size: 16),
                                        SizedBox(width: 8),
                                        Text('Edit Invoice', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                        SizedBox(width: 8),
                                        Text('Delete Record', style: TextStyle(color: Colors.redAccent, fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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

  void _confirmDeletePurchase(BuildContext context, dynamic po) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16181D),
          title: const Text('Delete Invoice', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          content: Text('Are you sure you want to delete purchase order ${po['po_number']}? This will reverse any restock changes in your inventory levels.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                navigator.pop();
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await Provider.of<InventoryProvider>(context, listen: false).removePurchaseOrder(auth.token!, po['id']);
                if (success && mounted) {
                  _refreshPurchases();
                  messenger.showSnackBar(const SnackBar(content: Text('Purchase record deleted successfully!')));
                }
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddInvoiceSheet(BuildContext context, {dynamic existingPo}) {
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);
    if (invProvider.suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please register at least one supplier first!')));
      return;
    }
    if (invProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one inventory material item first!')));
      return;
    }

    String? supplierId = existingPo != null ? (existingPo['supplier_id'] ?? existingPo['supplier']?['id']) : invProvider.suppliers.first['id'];
    String status = existingPo != null ? existingPo['status'] : 'paid';

    // List of active rows: { 'inventory_item_id': String, 'quantity': double, 'unit_price': double, 'unit': String }
    List<Map<String, dynamic>> rows = [];
    if (existingPo != null && existingPo['items'] != null) {
      for (var it in existingPo['items']) {
        rows.add({
          'inventory_item_id': it['inventory_item_id'],
          'quantity': double.tryParse(it['quantity'].toString()) ?? 1.0,
          'unit_price': double.tryParse(it['unit_price'].toString()) ?? 100.0,
          'unit': it['inventory_item'] != null ? it['inventory_item']['unit'] : 'units',
        });
      }
    } else {
      rows.add({
        'inventory_item_id': invProvider.items.first['id'],
        'quantity': 1.0,
        'unit_price': 100.0,
        'unit': invProvider.items.first['unit']
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double invoiceTotal = 0.00;
            for (var row in rows) {
              invoiceTotal += (row['quantity'] as double) * (row['unit_price'] as double);
            }

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(existingPo != null ? 'Edit Purchase Invoice' : 'Log Purchase Order / restock', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Total: ₹${invoiceTotal.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: supplierId,
                      dropdownColor: const Color(0xFF16181D),
                      decoration: const InputDecoration(labelText: 'Supplier', labelStyle: TextStyle(color: Colors.white38)),
                      style: const TextStyle(color: Colors.white),
                      items: invProvider.suppliers.map<DropdownMenuItem<String>>((s) {
                        return DropdownMenuItem<String>(
                          value: s['id'],
                          child: Text(s['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() {
                          supplierId = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      dropdownColor: const Color(0xFF16181D),
                      decoration: const InputDecoration(labelText: 'Payment Status', labelStyle: TextStyle(color: Colors.white38)),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'paid', child: Text('PAID (Restock immediately)')),
                        DropdownMenuItem(value: 'pending', child: Text('PENDING BILL (Restock immediately)')),
                        DropdownMenuItem(value: 'cancelled', child: Text('CANCELLED (Do not restock)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            status = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('LINE ITEMS', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        TextButton.icon(
                          onPressed: () {
                            setModalState(() {
                              rows.add({
                                'inventory_item_id': invProvider.items.first['id'],
                                'quantity': 1.0,
                                'unit_price': 100.0,
                                'unit': invProvider.items.first['unit']
                              });
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFFD4AF37)),
                          label: const Text('ADD ROW', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              children: [
                                DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: row['inventory_item_id'],
                                    dropdownColor: const Color(0xFF16181D),
                                    decoration: const InputDecoration(labelText: 'Material Item', labelStyle: TextStyle(color: Colors.white38)),
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    items: invProvider.items.map<DropdownMenuItem<String>>((it) {
                                      return DropdownMenuItem<String>(
                                        value: it['id'],
                                        child: Text('${it['name']} (${it['unit']})'),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        final matched = invProvider.items.firstWhere((it) => it['id'] == val);
                                        setModalState(() {
                                          row['inventory_item_id'] = val;
                                          row['unit'] = matched['unit'];
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: row['quantity'].toString(),
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        decoration: InputDecoration(labelText: 'Quantity (${row['unit']})', labelStyle: const TextStyle(color: Colors.white38)),
                                        onChanged: (val) {
                                          setModalState(() {
                                            row['quantity'] = double.tryParse(val) ?? 0.0;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        initialValue: row['unit_price'].toString(),
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        decoration: const InputDecoration(labelText: 'Unit Price (₹)', labelStyle: TextStyle(color: Colors.white38)),
                                        onChanged: (val) {
                                          setModalState(() {
                                            row['unit_price'] = double.tryParse(val) ?? 0.0;
                                          });
                                        },
                                      ),
                                    ),
                                    if (rows.length > 1) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                                        onPressed: () {
                                          setModalState(() {
                                            rows.removeAt(index);
                                          });
                                        },
                                      )
                                    ]
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (supplierId == null || rows.isEmpty) return;

                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final bool success;

                          if (existingPo != null) {
                            success = await Provider.of<InventoryProvider>(context, listen: false).editPurchaseOrder(
                              auth.token!,
                              existingPo['id'],
                              {
                                'restaurant_id': _selectedRestaurant!.id,
                                'supplier_id': supplierId,
                                'status': status,
                                'order_date': existingPo['order_date'],
                                'items': rows.map((r) => {
                                  'inventory_item_id': r['inventory_item_id'],
                                  'quantity': r['quantity'],
                                  'unit_price': r['unit_price']
                                }).toList()
                              }
                            );
                          } else {
                            success = await Provider.of<InventoryProvider>(context, listen: false).addPurchaseOrder(
                              auth.token!,
                              {
                                'restaurant_id': _selectedRestaurant!.id,
                                'supplier_id': supplierId,
                                'status': status,
                                'order_date': DateTime.now().toIso8601String(),
                                'items': rows.map((r) => {
                                  'inventory_item_id': r['inventory_item_id'],
                                  'quantity': r['quantity'],
                                  'unit_price': r['unit_price']
                                }).toList()
                              }
                            );
                          }

                          if (success && mounted) {
                            navigator.pop();
                            _refreshPurchases();
                            messenger.showSnackBar(SnackBar(
                              content: Text(existingPo != null ? 'Purchase invoice updated successfully!' : 'Procurement recorded & stocks updated!'),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                        child: Text(existingPo != null ? 'UPDATE INVOICE' : 'SUBMIT PURCHASE INVOICE', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
