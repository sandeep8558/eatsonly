import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/inventory_provider.dart';
import '../../core/staff_provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/staff_model.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  RestaurantModel? _selectedRestaurant;
  String _selectedCategory = 'All';
  bool _filterLowStock = false;
  String _activeTab = 'Stock'; // 'Stock', 'Ledger', 'Issuances', 'Wastage'
  final TextEditingController _searchController = TextEditingController();

  List<String> get _categories {
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);
    return ['All', ...invProvider.categories.map((c) => c['name'].toString())];
  }

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

  void _loadTabSpecificData() {
    if (_selectedRestaurant == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);

    if (_activeTab == 'Stock') {
      _refreshInventory();
    } else if (_activeTab == 'Ledger') {
      invProvider.fetchStockLedger(auth.token!, _selectedRestaurant!.id);
    } else if (_activeTab == 'Issuances') {
      invProvider.fetchMaterialIssuances(auth.token!, _selectedRestaurant!.id);
      // Fetch staff members to receive materials
      final staffProvider = Provider.of<StaffProvider>(context, listen: false);
      staffProvider.fetchStaff(auth.token!, restaurantId: _selectedRestaurant!.id);
    } else if (_activeTab == 'Wastage') {
      invProvider.fetchWastageEntries(auth.token!, _selectedRestaurant!.id);
    } else if (_activeTab == 'Audits') {
      invProvider.fetchStockAudits(auth.token!, _selectedRestaurant!.id);
      invProvider.fetchInventory(auth.token!, _selectedRestaurant!.id);
    }
  }

  void _refreshInventory() {
    if (_selectedRestaurant == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);
    invProvider.fetchInventory(
      auth.token!,
      _selectedRestaurant!.id,
      lowStock: _filterLowStock,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      search: _searchController.text,
    );
    invProvider.fetchSuppliers(auth.token!, _selectedRestaurant!.id);
    invProvider.fetchCategories(auth.token!, _selectedRestaurant!.id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _loadTabSpecificData();
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => _loadTabSpecificData(),
        color: const Color(0xFFD4AF37),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(restoProvider, isSmall),
              const SizedBox(height: 20),
              _buildSubTabs(isSmall),
              const SizedBox(height: 24),
              _buildTabBody(invProvider, isSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(RestaurantProvider restoProvider, bool isSmall) {
    final elements = [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'STOCK INVENTORY',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Real-time Ingredient Stock levels & safety triggers',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
      if (isSmall) const SizedBox(height: 16),
      Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => _showAddItemSheet(context),
            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.black),
            label: const Text('ADD MATERIAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
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

  Widget _buildControls(bool isSmall) {
    final searchField = Expanded(
      flex: isSmall ? 1 : 2,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => _refreshInventory(),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search stock items or SKU...',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
          fillColor: const Color(0xFF16181D),
          filled: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );

    final alertSwitch = InkWell(
      onTap: () {
        setState(() {
          _filterLowStock = !_filterLowStock;
        });
        _refreshInventory();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _filterLowStock ? const Color(0xFFD4AF37).withOpacity(0.12) : const Color(0xFF16181D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _filterLowStock ? const Color(0xFFD4AF37).withOpacity(0.3) : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _filterLowStock ? Icons.warning_amber_rounded : Icons.warning_amber_rounded,
              color: _filterLowStock ? const Color(0xFFD4AF37) : Colors.white38,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Low Stock Alerts',
              style: TextStyle(
                color: _filterLowStock ? const Color(0xFFD4AF37) : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );

    if (isSmall) {
      return Column(
        children: [
          Row(children: [searchField]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              alertSwitch,
              TextButton.icon(
                onPressed: () => _showAddSupplierSheet(context),
                icon: const Icon(Icons.person_add_rounded, size: 16, color: Color(0xFFD4AF37)),
                label: const Text('ADD SUPPLIER', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.03), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
              ),
            ],
          )
        ],
      );
    }

    return Row(
      children: [
        searchField,
        const SizedBox(width: 16),
        alertSwitch,
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showAddSupplierSheet(context),
          icon: const Icon(Icons.person_add_rounded, size: 16, color: Colors.white70),
          label: const Text('ADD SUPPLIER', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.05),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                        _refreshInventory();
                      }
                    },
                    backgroundColor: const Color(0xFF16181D),
                    selectedColor: const Color(0xFFD4AF37),
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Tooltip(
          message: 'Manage Categories',
          child: InkWell(
            onTap: () => _showManageCategoriesSheet(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF16181D),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.edit_rounded, color: Color(0xFFD4AF37), size: 14),
                  SizedBox(width: 6),
                  Text('CATEGORIES', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryGrid(InventoryProvider provider, bool isSmall) {
    if (provider.items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: const [
            Icon(Icons.inventory_2_rounded, size: 48, color: Colors.white24),
            SizedBox(height: 16),
            Text('No inventory items found', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Click "Add Material" to record your restaurant raw ingredients.', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isSmall ? 1.8 : 1.4,
          ),
          itemBuilder: (context, index) {
            final item = provider.items[index];
            final double qty = double.tryParse(item['quantity'].toString()) ?? 0.00;
            final double threshold = double.tryParse(item['min_threshold'].toString()) ?? 5.00;
            final bool isLowStock = qty <= threshold;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16181D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLowStock ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              item['category'].toString().toUpperCase(),
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['name'],
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (item['sku'] != null && item['sku'].toString().isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text('SKU: ${item['sku']}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isLowStock ? Colors.redAccent.withOpacity(0.12) : Colors.greenAccent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isLowStock ? 'LOW STOCK' : 'IN STOCK',
                          style: TextStyle(
                            color: isLowStock ? Colors.redAccent : Colors.greenAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item['storage_location'] == 'Cold Storage'
                                  ? Icons.ac_unit_rounded
                                  : (item['storage_location'] == 'Freezer Storage'
                                      ? Icons.kitchen_rounded
                                      : Icons.wb_sunny_rounded),
                              color: item['storage_location'] == 'Cold Storage'
                                  ? Colors.lightBlueAccent
                                  : (item['storage_location'] == 'Freezer Storage'
                                      ? Colors.blueAccent
                                      : Colors.orangeAccent),
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              (item['storage_location'] ?? 'Dry Storage').toString().toUpperCase(),
                              style: const TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      if (item['expiry_date'] != null) () {
                        final dateStr = item['expiry_date'].toString();
                        final expiry = DateTime.tryParse(dateStr);
                        if (expiry == null) return const SizedBox.shrink();
                        final isExpired = expiry.isBefore(DateTime.now());
                        final isNearExpiry = expiry.isBefore(DateTime.now().add(const Duration(days: 7)));
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isExpired 
                              ? Colors.redAccent.withOpacity(0.12)
                              : (isNearExpiry ? Colors.orangeAccent.withOpacity(0.1) : Colors.white.withOpacity(0.03)),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isExpired 
                                ? Colors.redAccent.withOpacity(0.2)
                                : (isNearExpiry ? Colors.orangeAccent.withOpacity(0.2) : Colors.white.withOpacity(0.05))
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.hourglass_empty_rounded, 
                                color: isExpired 
                                  ? Colors.redAccent 
                                  : (isNearExpiry ? Colors.orangeAccent : Colors.white38), 
                                size: 10
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "EXP: ${expiry.day}/${expiry.month}/${expiry.year}",
                                style: TextStyle(
                                  color: isExpired 
                                    ? Colors.redAccent 
                                    : (isNearExpiry ? Colors.orangeAccent : Colors.white54), 
                                  fontSize: 8, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                        );
                      }(),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CURRENT STOCK', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text(
                            '$qty ${item['unit']}',
                            style: TextStyle(
                              color: isLowStock ? Colors.redAccent : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Colors.white38, size: 18),
                            onPressed: () => _showEditItemSheet(context, item),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            onPressed: () => _confirmDelete(context, item),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddItemSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final qtyCtrl = TextEditingController(text: '0');
    final unitCtrl = TextEditingController(text: 'kg');
    final thresholdCtrl = TextEditingController(text: '5');
    final costCtrl = TextEditingController(text: '0');
    String category = _categories[1]; // default first non-all category
    String storageLocation = 'Dry Storage';
    DateTime? expiryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    const Text('Add New Material / Ingredient', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      dropdownColor: const Color(0xFF16181D),
                      decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: Colors.white38)),
                      style: const TextStyle(color: Colors.white),
                      items: _categories.skip(1).map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            category = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Ingredient Name (e.g., Tomato)', labelStyle: TextStyle(color: Colors.white38)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: skuCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'SKU or Barcode (Optional)', labelStyle: TextStyle(color: Colors.white38)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Initial Quantity', labelStyle: TextStyle(color: Colors.white38)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Unit (e.g. kg, L, pcs)', labelStyle: TextStyle(color: Colors.white38)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: thresholdCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Safety Threshold', labelStyle: TextStyle(color: Colors.white38)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Cost Per Unit (₹)', labelStyle: TextStyle(color: Colors.white38)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: storageLocation,
                            dropdownColor: const Color(0xFF16181D),
                            decoration: const InputDecoration(labelText: 'Storage Standard', labelStyle: TextStyle(color: Colors.white38)),
                            style: const TextStyle(color: Colors.white),
                            items: ['Dry Storage', 'Cold Storage', 'Freezer Storage'].map((loc) {
                              return DropdownMenuItem(value: loc, child: Text(loc));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  storageLocation = val;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
                              if (selected != null) {
                                setModalState(() {
                                  expiryDate = selected;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Expiry Date',
                                labelStyle: const TextStyle(color: Colors.white38),
                                suffixIcon: expiryDate != null 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                                      onPressed: () {
                                        setModalState(() {
                                          expiryDate = null;
                                        });
                                      },
                                    )
                                  : const Icon(Icons.calendar_today_rounded, color: Colors.white38, size: 16),
                              ),
                              child: Text(
                                expiryDate != null 
                                  ? "${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}"
                                  : 'No Expiry',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameCtrl.text.isEmpty || unitCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all mandatory fields')));
                            return;
                          }

                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final success = await Provider.of<InventoryProvider>(context, listen: false).addInventoryItem(
                            auth.token!,
                            {
                              'restaurant_id': _selectedRestaurant!.id,
                              'name': nameCtrl.text,
                              'sku': skuCtrl.text,
                              'category': category,
                              'quantity': double.tryParse(qtyCtrl.text) ?? 0.0,
                              'unit': unitCtrl.text,
                              'min_threshold': double.tryParse(thresholdCtrl.text) ?? 5.0,
                              'cost_per_unit': double.tryParse(costCtrl.text) ?? 0.0,
                              'storage_location': storageLocation,
                              'expiry_date': expiryDate != null ? expiryDate!.toIso8601String().split('T')[0] : null,
                            }
                          );

                          if (success && mounted) {
                            navigator.pop();
                            _refreshInventory();
                            messenger.showSnackBar(const SnackBar(content: Text('Material added successfully')));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                        child: const Text('SAVE MATERIAL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  void _showEditItemSheet(BuildContext context, dynamic item) {
    final nameCtrl = TextEditingController(text: item['name']);
    final skuCtrl = TextEditingController(text: item['sku'] ?? '');
    final qtyCtrl = TextEditingController(text: item['quantity'].toString());
    final unitCtrl = TextEditingController(text: item['unit']);
    final thresholdCtrl = TextEditingController(text: item['min_threshold'].toString());
    final costCtrl = TextEditingController(text: item['cost_per_unit'].toString());
    String category = item['category'];
    String storageLocation = item['storage_location'] ?? 'Dry Storage';
    DateTime? expiryDate = item['expiry_date'] != null ? DateTime.tryParse(item['expiry_date']) : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                    const Text('Edit Material Details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      dropdownColor: const Color(0xFF16181D),
                      decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: Colors.white38)),
                      style: const TextStyle(color: Colors.white),
                      items: _categories.skip(1).map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            category = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Ingredient Name', labelStyle: TextStyle(color: Colors.white38)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: skuCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'SKU or Barcode', labelStyle: TextStyle(color: Colors.white38)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Quantity', labelStyle: TextStyle(color: Colors.white38)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Unit', labelStyle: TextStyle(color: Colors.white38)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: thresholdCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Safety Threshold', labelStyle: TextStyle(color: Colors.white38)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: costCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Cost Per Unit (₹)', labelStyle: TextStyle(color: Colors.white38)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: storageLocation,
                            dropdownColor: const Color(0xFF16181D),
                            decoration: const InputDecoration(labelText: 'Storage Standard', labelStyle: TextStyle(color: Colors.white38)),
                            style: const TextStyle(color: Colors.white),
                            items: ['Dry Storage', 'Cold Storage', 'Freezer Storage'].map((loc) {
                              return DropdownMenuItem(value: loc, child: Text(loc));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  storageLocation = val;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final selected = await showDatePicker(
                                context: context,
                                initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
                              if (selected != null) {
                                setModalState(() {
                                  expiryDate = selected;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Expiry Date',
                                labelStyle: const TextStyle(color: Colors.white38),
                                suffixIcon: expiryDate != null 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, color: Colors.white38, size: 16),
                                      onPressed: () {
                                        setModalState(() {
                                          expiryDate = null;
                                        });
                                      },
                                    )
                                  : const Icon(Icons.calendar_today_rounded, color: Colors.white38, size: 16),
                              ),
                              child: Text(
                                expiryDate != null 
                                  ? "${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}"
                                  : 'No Expiry',
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final auth = Provider.of<AuthProvider>(context, listen: false);
                          final success = await Provider.of<InventoryProvider>(context, listen: false).editInventoryItem(
                            auth.token!,
                            item['id'],
                            {
                              'name': nameCtrl.text,
                              'sku': skuCtrl.text,
                              'category': category,
                              'quantity': double.tryParse(qtyCtrl.text) ?? 0.0,
                              'unit': unitCtrl.text,
                              'min_threshold': double.tryParse(thresholdCtrl.text) ?? 5.0,
                              'cost_per_unit': double.tryParse(costCtrl.text) ?? 0.0,
                              'storage_location': storageLocation,
                              'expiry_date': expiryDate != null ? expiryDate!.toIso8601String().split('T')[0] : null,
                            }
                          );

                          if (success && mounted) {
                            navigator.pop();
                            _refreshInventory();
                            messenger.showSnackBar(const SnackBar(content: Text('Material updated successfully')));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                        child: const Text('UPDATE DETAILS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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

  void _confirmDelete(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16181D),
          title: Text('Delete ${item['name']}?', style: const TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to remove this raw material? All stock logs will be permanently deleted.', style: TextStyle(color: Colors.white60)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
            TextButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await Provider.of<InventoryProvider>(context, listen: false).removeInventoryItem(
                  auth.token!,
                  item['id']
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  _refreshInventory();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material removed successfully')));
                }
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showAddSupplierSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
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
                const Text('Register New Supply Supplier', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Supplier Company Name', labelStyle: TextStyle(color: Colors.white38)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: personCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Contact Person Name', labelStyle: TextStyle(color: Colors.white38)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Mobile Phone', labelStyle: TextStyle(color: Colors.white38)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(color: Colors.white38)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Business Address', labelStyle: TextStyle(color: Colors.white38)),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company name is required')));
                        return;
                      }

                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final success = await Provider.of<InventoryProvider>(context, listen: false).addSupplier(
                        auth.token!,
                        {
                          'restaurant_id': _selectedRestaurant!.id,
                          'name': nameCtrl.text,
                          'contact_person': personCtrl.text,
                          'phone': phoneCtrl.text,
                          'email': emailCtrl.text,
                          'address': addressCtrl.text,
                        }
                      );

                      if (success && mounted) {
                        Navigator.pop(context);
                        _refreshInventory();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier registered successfully')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                    child: const Text('REGISTER SUPPLIER', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManageCategoriesSheet(BuildContext context) {
    final newCatCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final auth = Provider.of<AuthProvider>(context);
            final invProvider = Provider.of<InventoryProvider>(context);

            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manage Material Categories',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create, edit, or delete categories. Deleting a category will set its items to "Uncategorized".',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newCatCtrl,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Enter new category name...',
                            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                            fillColor: Colors.black.withOpacity(0.15),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          if (newCatCtrl.text.isEmpty) return;
                          final success = await invProvider.addCategory(
                            auth.token!,
                            {
                              'restaurant_id': _selectedRestaurant!.id,
                              'name': newCatCtrl.text.trim(),
                            },
                          );
                          if (success) {
                            newCatCtrl.clear();
                            setSheetState(() {});
                            _refreshInventory();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Category added successfully')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(invProvider.errorMessage ?? 'Failed to add category')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        child: const Text('ADD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                    child: invProvider.categories.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Text('No custom categories registered.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: invProvider.categories.length,
                            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, index) {
                              final cat = invProvider.categories[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  cat['name'],
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: Colors.white38, size: 18),
                                      onPressed: () => _showRenameCategoryDialog(context, cat, setSheetState),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                      onPressed: () => _confirmDeleteCategory(context, cat, setSheetState),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRenameCategoryDialog(BuildContext context, dynamic cat, StateSetter setSheetState) {
    final renameCtrl = TextEditingController(text: cat['name']);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16181D),
          title: const Text('Rename Category', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: renameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Category Name',
              labelStyle: TextStyle(color: Colors.white38),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () async {
                if (renameCtrl.text.isEmpty) return;
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final invProvider = Provider.of<InventoryProvider>(context, listen: false);

                final success = await invProvider.editCategory(
                  auth.token!,
                  cat['id'],
                  {'name': renameCtrl.text.trim()},
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  setSheetState(() {});
                  _refreshInventory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category renamed successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(invProvider.errorMessage ?? 'Failed to rename category')),
                  );
                }
              },
              child: const Text('SAVE', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCategory(BuildContext context, dynamic cat, StateSetter setSheetState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16181D),
          title: Text('Delete "${cat['name']}"?', style: const TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to delete this category? Any raw materials currently under this category will be set to "Uncategorized".',
            style: TextStyle(color: Colors.white60, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final invProvider = Provider.of<InventoryProvider>(context, listen: false);

                final success = await invProvider.removeCategory(auth.token!, cat['id']);

                if (success && mounted) {
                  Navigator.pop(context);
                  setSheetState(() {});
                  _refreshInventory();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Category deleted successfully')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(invProvider.errorMessage ?? 'Failed to delete category')),
                  );
                }
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // --- TAB SEGMENTED CONTROL ---
  Widget _buildSubTabs(bool isSmall) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF16181D),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabButton('Stock', Icons.storage_rounded),
            _buildTabButton('Ledger', Icons.receipt_long_rounded),
            _buildTabButton('Issuances', Icons.local_shipping_rounded),
            _buildTabButton('Wastage', Icons.delete_sweep_rounded),
            _buildTabButton('Audits', Icons.fact_check_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tabName, IconData icon) {
    final isSelected = _activeTab == tabName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabName;
        });
        _loadTabSpecificData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.black : Colors.white60),
            const SizedBox(width: 8),
            Text(
              tabName,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- DYNAMIC TAB ROUTER ---
  Widget _buildTabBody(InventoryProvider invProvider, bool isSmall) {
    if (invProvider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    switch (_activeTab) {
      case 'Ledger':
        return _buildLedgerTab(invProvider, isSmall);
      case 'Issuances':
        return _buildIssuancesTab(invProvider, isSmall);
      case 'Wastage':
        return _buildWastageTab(invProvider, isSmall);
      case 'Audits':
        return _buildAuditsTab(invProvider, isSmall);
      case 'Stock':
      default:
        return _buildStockTab(invProvider, isSmall);
    }
  }

  // --- STOCK VIEW TAB ---
  Widget _buildStockTab(InventoryProvider invProvider, bool isSmall) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildControls(isSmall),
        const SizedBox(height: 24),
        _buildCategoryChips(),
        const SizedBox(height: 24),
        _buildInventoryGrid(invProvider, isSmall),
      ],
    );
  }

  // --- STOCK LEDGER VIEW TAB ---
  Widget _buildLedgerTab(InventoryProvider invProvider, bool isSmall) {
    final ledger = invProvider.stockLedger;

    if (ledger.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Text('No ledger entries recorded.', style: TextStyle(color: Colors.white38)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: ledger.length,
      separatorBuilder: (context, idx) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final entry = ledger[idx];
        final item = entry['inventory_item'] ?? {};
        final qty = double.tryParse((entry['quantity'] ?? 0).toString()) ?? 0.0;
        final cost = double.tryParse((entry['cost_per_unit'] ?? 0).toString()) ?? 0.0;
        final date = DateTime.parse(entry['created_at']).toLocal();
        final formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

        final isNegative = qty < 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16181D),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isNegative ? Colors.redAccent.withOpacity(0.1) : Colors.greenAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isNegative ? Icons.south_west_rounded : Icons.north_east_rounded,
                  color: isNegative ? Colors.redAccent : Colors.greenAccent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'] ?? 'Unknown Item',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type: ${entry['transaction_type'].toString().toUpperCase()} | $formattedDate',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isNegative ? "" : "+"}${qty.toStringAsFixed(2)} ${entry['unit']}',
                    style: TextStyle(
                      color: isNegative ? Colors.redAccent : Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cost: ₹${(qty.abs() * cost).toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- MATERIAL ISSUANCES VIEW TAB ---
  Widget _buildIssuancesTab(InventoryProvider invProvider, bool isSmall) {
    final issuances = invProvider.issuances;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'STORE TO KITCHEN DISPATCHES',
              style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            ElevatedButton.icon(
              onPressed: () => _showMaterialIssuanceDialog(context),
              icon: const Icon(Icons.add_rounded, size: 16, color: Colors.black),
              label: const Text('NEW DISPATCH', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        issuances.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Text('No material dispatches logged.', style: TextStyle(color: Colors.white38)),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: issuances.length,
                separatorBuilder: (context, idx) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final log = issuances[idx];
                  final items = log['items'] as List<dynamic>? ?? [];
                  final issuer = log['issuer']?['name'] ?? 'Storekeeper';
                  final receiver = log['receiver']?['name'] ?? 'Chef';
                  final date = DateTime.parse(log['created_at']).toLocal();
                  final formattedDate = '${date.day}/${date.month}/${date.year}';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16181D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                log['department'] ?? 'Kitchen',
                                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(formattedDate, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.arrow_forward_rounded, color: Colors.greenAccent, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'Dispatched by: $issuer | Received by: $receiver',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                        if (log['notes'] != null && log['notes'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text('Notes: ${log['notes']}', style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic)),
                        ],
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),
                        Column(
                          children: items.map((it) {
                            final raw = it['inventory_item'] ?? {};
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(raw['name'] ?? 'Unknown Ingredient', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  Text('${it['quantity']} ${it['unit']}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // --- WASTAGE LOGS VIEW TAB ---
  Widget _buildWastageTab(InventoryProvider invProvider, bool isSmall) {
    final wastage = invProvider.wastageEntries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'MATERIAL WASTAGE LOGS',
              style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            ElevatedButton.icon(
              onPressed: () => _showLogWastageDialog(context),
              icon: const Icon(Icons.add_rounded, size: 16, color: Colors.black),
              label: const Text('LOG WASTAGE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        wastage.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Text('No wastage logs recorded.', style: TextStyle(color: Colors.white38)),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wastage.length,
                separatorBuilder: (context, idx) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final log = wastage[idx];
                  final raw = log['inventory_item'] ?? {};
                  final user = log['user']?['name'] ?? 'Auditor';
                  final date = DateTime.parse(log['created_at']).toLocal();
                  final formattedDate = '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16181D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                raw['name'] ?? 'Unknown Item',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reason: ${log['reason'].toString().toUpperCase()}',
                                style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text('Logged by $user | $formattedDate', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              if (log['notes'] != null && log['notes'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Notes: ${log['notes']}', style: const TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic)),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '-${log['quantity']} ${log['unit']}',
                          style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // --- LOG WASTAGE ENTRY DIALOG ---
  void _showLogWastageDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);

    dynamic selectedItem;
    final qtyCtrl = TextEditingController();
    String reason = 'spoilage';
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Log Material Wastage', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  // Item Selector
                  const Text('Select Raw Material', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<dynamic>(
                        value: selectedItem,
                        dropdownColor: const Color(0xFF16181D),
                        hint: const Text('Choose material...', style: TextStyle(color: Colors.white38, fontSize: 13)),
                        isExpanded: true,
                        items: invProvider.items.map((it) {
                          return DropdownMenuItem(
                            value: it,
                            child: Text(it['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setSheetState(() {
                            selectedItem = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      // Quantity
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Wasted Quantity', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: qtyCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: '0.00',
                                suffixText: selectedItem?['unit'] ?? '',
                                suffixStyle: const TextStyle(color: Color(0xFFD4AF37)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Reason
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Reason', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: reason,
                                  dropdownColor: const Color(0xFF16181D),
                                  isExpanded: true,
                                  items: ['spoilage', 'overproduction', 'cooking_loss', 'expired', 'theft'].map((val) {
                                    return DropdownMenuItem(
                                      value: val,
                                      child: Text(val.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() {
                                        reason = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  const Text('Incident Notes', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. cold storage compressor failure...',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedItem == null || qtyCtrl.text.isEmpty) return;

                        final success = await invProvider.logWastageEntry(auth.token!, {
                          'restaurant_id': _selectedRestaurant!.id,
                          'inventory_item_id': selectedItem['id'],
                          'quantity': double.tryParse(qtyCtrl.text) ?? 0.0,
                          'unit': selectedItem['unit'],
                          'reason': reason,
                          'notes': notesCtrl.text.trim(),
                        });

                        if (success && mounted) {
                          Navigator.pop(context);
                          _loadTabSpecificData();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wastage entry logged and stock updated successfully')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(invProvider.errorMessage ?? 'Failed to log wastage')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('SUBMIT WASTAGE REPORT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- NEW STORE-TO-KITCHEN DISPATCH DIALOG ---
  void _showMaterialIssuanceDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);

    StaffModel? selectedReceiver;
    String department = 'Main Kitchen';
    final notesCtrl = TextEditingController();

    // Stateful inner list of items being dispatched
    List<Map<String, dynamic>> selectedItems = [];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Store to Kitchen Dispatch', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      // Received By Staff
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Receiver (Staff)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<StaffModel>(
                                  value: selectedReceiver,
                                  dropdownColor: const Color(0xFF16181D),
                                  hint: const Text('Select staff...', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                  isExpanded: true,
                                  items: staffProvider.staffList.map((st) {
                                    return DropdownMenuItem<StaffModel>(
                                      value: st,
                                      child: Text(st.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    setSheetState(() {
                                      selectedReceiver = val;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Department
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Target Kitchen Section', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: department,
                                  dropdownColor: const Color(0xFF16181D),
                                  isExpanded: true,
                                  items: ['Main Kitchen', 'Bar', 'Bakery', 'Pastry'].map((val) {
                                    return DropdownMenuItem(
                                      value: val,
                                      child: Text(val, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setSheetState(() {
                                        department = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dispatch Items list builder
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Dispatch Line Items', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      TextButton.icon(
                        onPressed: () {
                          // Spawn quick item adder inside dialog
                          _showAddIssuanceItemDialog(context, invProvider, (addedItem) {
                            setSheetState(() {
                              selectedItems.add(addedItem);
                            });
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFFD4AF37)),
                        label: const Text('ADD LINE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  selectedItems.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text('No dispatch items added yet.', style: TextStyle(color: Colors.white24, fontSize: 12)),
                          ),
                        )
                      : ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 180),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: selectedItems.length,
                            separatorBuilder: (context, idx) => const Divider(color: Colors.white10, height: 1),
                            itemBuilder: (context, idx) {
                              final it = selectedItems[idx];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(it['name'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                subtitle: Text('Qty: ${it['quantity']} ${it['unit']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  onPressed: () {
                                    setSheetState(() {
                                      selectedItems.removeAt(idx);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 16),

                  // Dispatch Notes
                  const Text('Dispatch Notes', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'e.g. morning kitchen shift raw stock dispatch...',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedReceiver == null || selectedItems.isEmpty) return;

                        final success = await invProvider.logMaterialIssuance(auth.token!, {
                          'restaurant_id': _selectedRestaurant!.id,
                          'received_by': selectedReceiver!.id,
                          'department': department,
                          'notes': notesCtrl.text.trim(),
                          'items': selectedItems.map((it) => {
                            'inventory_item_id': it['inventory_item_id'],
                            'quantity': it['quantity'],
                            'unit': it['unit'],
                          }).toList(),
                        });

                        if (success && mounted) {
                          Navigator.pop(context);
                          _loadTabSpecificData();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material dispatch logged and central stock levels updated successfully')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(invProvider.errorMessage ?? 'Failed to complete dispatch')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('DISPATCH MATERIALS TO KITCHEN', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- SUB-ADDER FOR INDIVIDUAL ISSUANCE ITEM ---
  void _showAddIssuanceItemDialog(BuildContext context, InventoryProvider invProvider, Function(Map<String, dynamic>) onAdded) {
    dynamic chosenItem;
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF16181D),
              title: const Text('Add Dispatch Line', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Material', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<dynamic>(
                        value: chosenItem,
                        dropdownColor: const Color(0xFF16181D),
                        hint: const Text('Choose...', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        isExpanded: true,
                        items: invProvider.items.map((it) {
                          return DropdownMenuItem(
                            value: it,
                            child: Text(it['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            chosenItem = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Dispatch Quantity', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      suffixText: chosenItem?['unit'] ?? '',
                      suffixStyle: const TextStyle(color: Color(0xFFD4AF37)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
                ),
                TextButton(
                  onPressed: () {
                    if (chosenItem == null || qtyCtrl.text.isEmpty) return;
                    onAdded({
                      'inventory_item_id': chosenItem['id'],
                      'name': chosenItem['name'],
                      'quantity': double.tryParse(qtyCtrl.text) ?? 0.0,
                      'unit': chosenItem['unit'],
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('ADD LINE', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
  // --- STOCK AUDITS VIEW TAB ---
  Widget _buildAuditsTab(InventoryProvider invProvider, bool isSmall) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Physical Stock Audits', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () => _showAuditDialog(context),
                icon: const Icon(Icons.add_task_rounded, size: 16, color: Colors.black),
                label: const Text('PERFORM AUDIT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 16),
        invProvider.stockAudits.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text('No physical audits performed yet.', style: TextStyle(color: Colors.white24, fontSize: 14)),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: invProvider.stockAudits.length,
                separatorBuilder: (context, idx) => const SizedBox(height: 16),
                itemBuilder: (context, idx) {
                  final audit = invProvider.stockAudits[idx];
                  final dateStr = audit['audit_date'] ?? audit['created_at'];
                  DateTime? date;
                  if (dateStr != null) {
                    date = DateTime.tryParse(dateStr.toString());
                  }
                  final formattedDate = date != null ? "${date.toLocal().day}/${date.toLocal().month}/${date.toLocal().year}" : 'N/A';
                  final auditor = audit['auditor']?['name'] ?? 'System';
                  final items = audit['items'] as List<dynamic>? ?? [];
                  final auditIdRaw = audit['id']?.toString() ?? '';
                  final auditId = auditIdRaw.length >= 8 ? auditIdRaw.substring(0, 8) : auditIdRaw;

                  return Container(
                    padding: const EdgeInsets.all(16),
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
                            Text('Audit ID: $auditId', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text((audit['status'] ?? 'submitted').toString().toUpperCase(), style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('Performed by $auditor on $formattedDate', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        const SizedBox(height: 12),
                        const Divider(color: Colors.white10, height: 1),
                        const SizedBox(height: 12),
                        const Text('Variances Noticed:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...items.where((it) {
                          final variance = double.tryParse((it['variance'] ?? 0).toString()) ?? 0.0;
                          return variance != 0.0;
                        }).map((it) {
                          final variance = double.tryParse((it['variance'] ?? 0).toString()) ?? 0.0;
                          final isLoss = variance < 0;
                          final varColor = isLoss ? Colors.redAccent : Colors.greenAccent;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(it['inventory_item']?['name'] ?? 'Unknown Item', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                Text(
                                  '${variance > 0 ? '+' : ''}$variance ${it['inventory_item']?['unit'] ?? ''}',
                                  style: TextStyle(color: varColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (items.where((it) {
                          final variance = double.tryParse((it['variance'] ?? 0).toString()) ?? 0.0;
                          return variance != 0.0;
                        }).isEmpty)
                          const Text('No variances found during this audit. Stock was perfect.', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  // --- NEW STOCK AUDIT DIALOG ---
  void _showAuditDialog(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final invProvider = Provider.of<InventoryProvider>(context, listen: false);

    // Filter to only trackable items or low stock (for now, all items)
    final List<dynamic> auditItems = List.from(invProvider.items);
    final Map<String, TextEditingController> qtyControllers = {};

    for (var item in auditItems) {
      final itemId = item['id']?.toString();
      if (itemId != null) {
        qtyControllers[itemId] = TextEditingController(
          text: (item['quantity'] ?? 0.0).toString(),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16181D),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Perform Physical Audit', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Enter the actual physical quantities you observe in the store. Any variance will be automatically recorded as an adjustment.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 20),

                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: auditItems.length,
                      separatorBuilder: (context, idx) => const Divider(color: Colors.white10, height: 1),
                      itemBuilder: (context, idx) {
                        final item = auditItems[idx];
                        final itemId = item['id']?.toString() ?? '';
                        final sysQty = double.tryParse((item['quantity'] ?? 0.0).toString()) ?? 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'] ?? 'Unknown Item', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text('System Qty: $sysQty ${item['unit'] ?? ''}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: qtyControllers[itemId] ?? TextEditingController(text: sysQty.toString()),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    suffixText: item['unit'] ?? '',
                                    suffixStyle: const TextStyle(color: Colors.white54, fontSize: 11),
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final List<Map<String, dynamic>> itemsPayload = [];
                        for (var item in auditItems) {
                          final itemId = item['id']?.toString();
                          if (itemId == null) continue;

                          final controller = qtyControllers[itemId];
                          final physQty = controller != null ? (double.tryParse(controller.text) ?? 0.0) : 0.0;
                          
                          itemsPayload.add({
                            'inventory_item_id': itemId,
                            'physical_qty': physQty,
                          });
                        }

                        if (itemsPayload.isEmpty) return;

                        final success = await invProvider.submitStockAudit(auth.token!, {
                          'restaurant_id': _selectedRestaurant!.id,
                          'audit_date': DateTime.now().toIso8601String().split('T')[0],
                          'items': itemsPayload,
                        });

                        if (success && mounted) {
                          Navigator.pop(context);
                          _loadTabSpecificData();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audit completed and stock updated.')));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(invProvider.errorMessage ?? 'Audit failed')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('SUBMIT PHYSICAL AUDIT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
