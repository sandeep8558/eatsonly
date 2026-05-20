import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/table_provider.dart';
import '../../models/restaurant_model.dart';
import '../../models/table_model.dart';
import '../../core/menu_provider.dart';
import '../../models/menu_model.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants.dart';
import '../../services/pdf_service.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  RestaurantModel? _selectedRestaurant;
  bool _isEditMode = false;
  String _viewType = 'list'; // 'canvas', 'grid', 'list'
  
  // Track dragging positions locally during edit session
  final Map<String, Offset> _dragPositions = {};
  String? _loadedRestaurantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token != null) {
        Provider.of<MenuProvider>(context, listen: false).fetchMenuCards(auth.token!);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resto = Provider.of<RestaurantProvider>(context);
    final activeRestaurantId = resto.selectedRestaurant?.id ?? (resto.restaurants.isNotEmpty ? resto.restaurants.first.id : null);
    
    if (activeRestaurantId != _loadedRestaurantId) {
      _loadedRestaurantId = activeRestaurantId;
      _selectedRestaurant = resto.selectedRestaurant ?? (resto.restaurants.isNotEmpty ? resto.restaurants.first : null);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadFloors();
        }
      });
    }
  }

  void _loadFloors() {
    if (_selectedRestaurant == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<TableProvider>(context, listen: false)
        .fetchFloors(auth.token!, _selectedRestaurant!.id);
  }

  void _showAddFloorDialog() {
    final nameController = TextEditingController();
    String? selectedMenuCardId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Add New Floor/Section', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Name (e.g. Ground Floor)', 
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                ),
              ),
              const SizedBox(height: 24),
              Consumer<MenuProvider>(
                builder: (context, menuProvider, _) {
                  return DropdownButtonFormField<String>(
                    initialValue: selectedMenuCardId,
                    dropdownColor: const Color(0xFF16181D),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Attached Menu Card', 
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                    ),
                    items: menuProvider.menuCards.map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Text(m.name),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedMenuCardId = val),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
              onPressed: () async {
                if (_selectedRestaurant == null) return;
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await Provider.of<TableProvider>(context, listen: false)
                    .createFloor(auth.token!, _selectedRestaurant!.id, nameController.text, menuCardId: selectedMenuCardId);
                if (success && mounted) {
                  Navigator.pop(context);
                  _loadFloors();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageFloorDialog(FloorModel floor) {
    final nameController = TextEditingController(text: floor.name);
    String? selectedMenuCardId = floor.menuCardId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Manage Floor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Floor Name', 
                  labelStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                ),
              ),
              const SizedBox(height: 24),
              Consumer<MenuProvider>(
                builder: (context, menuProvider, _) {
                  return DropdownButtonFormField<String>(
                    initialValue: selectedMenuCardId,
                    dropdownColor: const Color(0xFF16181D),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Attached Menu Card', 
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                    ),
                    items: menuProvider.menuCards.map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Text(m.name),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedMenuCardId = val),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _confirmDeleteFloor(floor),
              child: const Text('Delete Floor', style: TextStyle(color: Colors.redAccent)),
            ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await Provider.of<TableProvider>(context, listen: false)
                    .updateFloor(auth.token!, _selectedRestaurant!.id, floor.id, nameController.text, menuCardId: selectedMenuCardId);
                if (success && mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceBetween,
        ),
      ),
    );
  }

  void _confirmDeleteFloor(FloorModel floor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Floor?', style: TextStyle(color: Colors.white)),
        content: Text('This will delete "${floor.name}" and all tables within it. This cannot be undone.', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final success = await Provider.of<TableProvider>(context, listen: false)
                  .deleteFloor(auth.token!, _selectedRestaurant!.id, floor.id);
              if (success && mounted) {
                Navigator.pop(context); // Pop confirm
                Navigator.pop(context); // Pop manage dialog
                _loadFloors();
              }
            },
            child: const Text('Delete Everything', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showEditTableDialog(TableModel table) {
    final nameController = TextEditingController(text: table.name);
    int capacity = table.capacity;
    String shape = table.shape;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Edit Table', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Table Name', labelStyle: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: capacity,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Capacity', labelStyle: TextStyle(color: Colors.white54)),
                items: [2, 4, 6, 8, 10, 12].map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                onChanged: (val) => setDialogState(() => capacity = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: shape,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Shape', labelStyle: TextStyle(color: Colors.white54)),
                items: ['square', 'round', 'rectangle'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                onChanged: (val) => setDialogState(() => shape = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await Provider.of<TableProvider>(context, listen: false)
                    .updateTable(auth.token!, _selectedRestaurant!.id, table.id, {
                      'name': nameController.text,
                      'capacity': capacity,
                      'shape': shape,
                    });
                if (success && mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteTable(TableModel table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Table?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${table.name}"?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              final success = await Provider.of<TableProvider>(context, listen: false)
                  .deleteTable(auth.token!, _selectedRestaurant!.id, table.id);
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showAddTableDialog(String floorId) {
    final nameController = TextEditingController();
    int capacity = 2;
    String shape = 'square';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Add New Table', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Table Name/Number', labelStyle: TextStyle(color: Colors.white54)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: capacity,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Seating Capacity', labelStyle: TextStyle(color: Colors.white54)),
                items: [2, 4, 6, 8, 10, 12].map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                onChanged: (val) => setDialogState(() => capacity = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: shape,
                dropdownColor: const Color(0xFF1A1A1A),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Shape', labelStyle: TextStyle(color: Colors.white54)),
                items: ['square', 'round', 'rectangle'].map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
                onChanged: (val) => setDialogState(() => shape = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await Provider.of<TableProvider>(context, listen: false)
                    .createTable(auth.token!, _selectedRestaurant!.id, floorId, nameController.text, capacity, shape);
                if (success && mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final restoProvider = Provider.of<RestaurantProvider>(context);
    final tableProvider = Provider.of<TableProvider>(context);

    return DefaultTabController(
      key: ValueKey('${_selectedRestaurant?.id}_${tableProvider.floors.length}'),
      length: tableProvider.floors.isEmpty ? 1 : tableProvider.floors.length,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isNarrow = constraints.maxWidth < 500;
                  
                  Widget restaurantSelector = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TABLE & FLOOR', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(
                        _selectedRestaurant?.name ?? 'No Restaurant Selected',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );

                  Widget toolbar = Row(
                    mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _viewIcon(Icons.grid_view_rounded, 'grid'),
                            _viewIcon(Icons.list_alt_rounded, 'list'),
                            _viewIcon(Icons.layers_outlined, 'canvas'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch.adaptive(
                            value: _isEditMode,
                            onChanged: (val) {
                              setState(() => _isEditMode = val);
                              if (!val) {
                                final auth = Provider.of<AuthProvider>(context, listen: false);
                                tableProvider.saveLayout(auth.token!, _selectedRestaurant!.id, tableProvider.floors.expand((f) => f.tables).toList());
                              }
                            },
                            activeColor: const Color(0xFFD4AF37),
                          ),
                          const Text('Edit', style: TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ],
                  );

                  return isNarrow 
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          restaurantSelector,
                          const SizedBox(height: 16),
                          toolbar,
                        ],
                      )
                    : Row(
                        children: [
                          restaurantSelector,
                          const Spacer(),
                          toolbar,
                        ],
                      );
                },
              ),
            ),
            
            if (tableProvider.isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                ),
              )
            else if (_selectedRestaurant == null)
              const Expanded(
                child: Center(
                  child: Text('No restaurant selected.', style: TextStyle(color: Colors.white54)),
                ),
              )
            else if (tableProvider.floors.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No floors defined for this restaurant.', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _showAddFloorDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Floor'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    Builder(
                      builder: (context) {
                        final controller = DefaultTabController.of(context);
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TabBar(
                                    isScrollable: true,
                                    indicatorColor: const Color(0xFFD4AF37),
                                    labelColor: const Color(0xFFD4AF37),
                                    unselectedLabelColor: Colors.white38,
                                    tabs: tableProvider.floors.map((f) => Tab(text: f.name)).toList(),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_to_photos_rounded, color: Color(0xFFD4AF37), size: 22),
                                  tooltip: 'Add New Floor',
                                  onPressed: _showAddFloorDialog,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white38, size: 22),
                                  tooltip: 'Manage Floor',
                                  onPressed: () {
                                    final currentFloor = tableProvider.floors[controller.index];
                                    _showManageFloorDialog(currentFloor);
                                  },
                                ),
                                const SizedBox(width: 16),
                              ],
                            ),
                            // Current Floor Menu Info
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.menu_book_rounded, size: 14, color: Colors.white.withOpacity(0.3)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'MENU: ',
                                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                  ),
                                  AnimatedBuilder(
                                    animation: controller.animation!,
                                    builder: (context, _) {
                                      final index = controller.index;
                                      final floor = tableProvider.floors[index];
                                      return Text(
                                        (floor.menuCardName ?? 'NOT ASSIGNED').toUpperCase(),
                                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    Expanded(
                      child: TabBarView(
                        children: tableProvider.floors.map((floor) {
                          if (_viewType == 'grid') return _buildFloorGrid(floor);
                          if (_viewType == 'list') return _buildFloorList(floor);
                          return _buildFloorCanvas(floor);
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        floatingActionButton: _selectedRestaurant != null ? Builder(
          builder: (context) => FloatingActionButton(
            backgroundColor: const Color(0xFFD4AF37),
            onPressed: () {
              final tableProvider = Provider.of<TableProvider>(context, listen: false);
              if (tableProvider.floors.isNotEmpty) {
                final controller = DefaultTabController.of(context);
                _showAddTableDialog(tableProvider.floors[controller.index].id);
              } else {
                _showAddFloorDialog();
              }
            },
            child: const Icon(Icons.add, color: Colors.black),
          ),
        ) : null,
      ),
    );
  }

  Widget _viewIcon(IconData icon, String type) {
    final isSelected = _viewType == type;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _viewType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: isSelected ? Colors.black : Colors.white38, size: 18),
        ),
      ),
    );
  }

  Widget _buildFloorGrid(FloorModel floor) {
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: floor.tables.length,
      itemBuilder: (context, index) => _buildTableCard(floor.tables[index]),
    );
  }

  Widget _buildFloorList(FloorModel floor) {
    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: floor.tables.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildTableListItem(floor.tables[index]),
    );
  }

  Widget _buildTableCard(TableModel table) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showTableActions(table),
        child: Container(
          decoration: BoxDecoration(
            color: _getStatusColor(table.status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getStatusColor(table.status).withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                table.shape == 'round' ? Icons.circle_outlined : Icons.crop_square_rounded,
                color: _getStatusColor(table.status),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(table.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('${table.capacity} Seats', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableListItem(TableModel table) {
    return ListTile(
      onTap: () => _showTableActions(table),
      tileColor: Colors.white.withOpacity(0.03),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: _getStatusColor(table.status).withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(table.name, style: TextStyle(color: _getStatusColor(table.status), fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
      title: Text('Table ${table.name}', style: const TextStyle(color: Colors.white)),
      subtitle: Text('${table.capacity} Seating capacity • ${table.shape.toUpperCase()}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(table.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getStatusColor(table.status).withOpacity(0.3)),
        ),
        child: Text(
          table.status.toUpperCase(),
          style: TextStyle(color: _getStatusColor(table.status), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildFloorCanvas(FloorModel floor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Background grid
            Positioned.fill(
              child: CustomPaint(
                painter: GridPainter(),
              ),
            ),
            
            // Tables
            ...floor.tables.map((table) => _buildTableWidget(table, constraints)),
          ],
        );
      },
    );
  }

  Widget _buildTableWidget(TableModel table, BoxConstraints constraints) {
    double width = table.capacity * 15.0 + 40.0;
    double height = width;
    
    if (table.shape == 'rectangle') {
      width = width * 1.6; // Make it wider
    } else if (table.shape == 'round') {
      // Keep it circular (equal width/height)
    }

    return Positioned(
      left: table.xPos,
      top: table.yPos,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onPanUpdate: _isEditMode ? (details) {
            setState(() {
              table.xPos += details.delta.dx;
              table.yPos += details.delta.dy;
              
              // Keep within bounds
              if (table.xPos < 0) table.xPos = 0;
              if (table.yPos < 0) table.yPos = 0;
              if (table.xPos > constraints.maxWidth - width) table.xPos = constraints.maxWidth - width;
              if (table.yPos > constraints.maxHeight - height) table.yPos = constraints.maxHeight - height;
            });
          } : null,
          onTap: !_isEditMode ? () => _showTableActions(table) : null,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: _getStatusColor(table.status).withOpacity(0.2),
              borderRadius: BorderRadius.circular(table.shape == 'round' ? width / 2 : 12),
              border: Border.all(
                color: _getStatusColor(table.status),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(table.status).withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    table.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${table.capacity}p',
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'occupied': return Colors.redAccent;
      case 'reserved': return Colors.orangeAccent;
      case 'cleaning': return Colors.blueAccent;
      default: return Colors.greenAccent;
    }
  }

  void _showTableActions(TableModel table) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Table ${table.name}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _actionTile(Icons.restaurant, 'Take Order', const Color(0xFFD4AF37), () {}),
            _actionTile(Icons.event_seat, 'Mark Occupied', Colors.redAccent, () => _updateStatus(table, 'occupied')),
            _actionTile(Icons.bookmark, 'Reserve', Colors.orangeAccent, () => _updateStatus(table, 'reserved')),
            _actionTile(Icons.cleaning_services, 'Needs Cleaning', Colors.blueAccent, () => _updateStatus(table, 'cleaning')),
            _actionTile(Icons.check_circle, 'Mark Available', Colors.greenAccent, () => _updateStatus(table, 'available')),
            const Divider(color: Colors.white10),
            _actionTile(Icons.edit_outlined, 'Edit Table Details', Colors.white70, () => _showEditTableDialog(table)),
            _actionTile(Icons.qr_code_rounded, 'Generate QR Menu', const Color(0xFFD4AF37), () => _showQRDialog(table)),
            _actionTile(Icons.delete_outline, 'Delete Table', Colors.redAccent, () => _confirmDeleteTable(table)),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _updateStatus(TableModel table, String status) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    await Provider.of<TableProvider>(context, listen: false).updateTableStatus(auth.token!, table.id, status);
  }

  void _showQRDialog(TableModel table) {
    if (_selectedRestaurant == null) return;
    
    // Construct the public menu URL
    final String slug = _selectedRestaurant!.name.toLowerCase().replaceAll(' ', '-'); // Placeholder logic
    // In production, this would use the real restaurant slug from the model
    final String url = "https://eatsonly.com/m/$slug?t=${table.id}";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Table ${table.name} QR Code', style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(url, style: const TextStyle(color: Colors.white24, fontSize: 10), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text('Customers can scan this code to view the digital menu and place self-service orders.', style: TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), foregroundColor: Colors.white),
            onPressed: () {
              final pdfService = PdfService();
              pdfService.generateQrPdf(
                restaurantName: _selectedRestaurant!.name,
                tableName: table.name,
                url: url,
              );
            },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Download PDF'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () {
              // Logic to print QR code via thermal printer
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Printing QR Code...')));
            },
            icon: const Icon(Icons.print),
            label: const Text('Print QR'),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;

    const double spacing = 40.0;

    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
