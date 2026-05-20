import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/menu_model.dart';
import '../../../core/menu_provider.dart';
import '../../../core/auth_provider.dart';

class ComboConfigurationDialog extends StatefulWidget {
  final MenuItemModel item;
  final String? restaurantId;

  const ComboConfigurationDialog({super.key, required this.item, this.restaurantId});

  @override
  State<ComboConfigurationDialog> createState() => _ComboConfigurationDialogState();
}

class _ComboConfigurationDialogState extends State<ComboConfigurationDialog> {
  late List<MenuItemComboGroupModel> _groups;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Clone groups to avoid direct mutation of model
    _groups = widget.item.comboGroups.map((g) => MenuItemComboGroupModel(
      id: g.id,
      menuItemId: g.menuItemId,
      name: g.name,
      minSelections: g.minSelections,
      maxSelections: g.maxSelections,
      isRequired: g.isRequired,
      comboItems: g.comboItems.map((i) => MenuItemComboItemModel(
        id: i.id,
        comboGroupId: i.comboGroupId,
        menuItemId: i.menuItemId,
        menuItem: i.menuItem,
        extraPrice: i.extraPrice,
        quantity: i.quantity,
        isDefault: i.isDefault,
      )).toList(),
    )).toList();
  }

  void _addGroup() {
    setState(() {
      _groups.add(MenuItemComboGroupModel(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        menuItemId: widget.item.id,
        name: 'New Group',
        minSelections: 1,
        maxSelections: 1,
        isRequired: true,
        comboItems: [],
      ));
    });
  }

  void _removeGroup(int index) {
    setState(() {
      _groups.removeAt(index);
    });
  }

  void _addItemToGroup(int groupIndex, MenuItemModel menuItem) {
    setState(() {
      _groups[groupIndex].comboItems.add(MenuItemComboItemModel(
        id: 'new_item_${DateTime.now().millisecondsSinceEpoch}',
        comboGroupId: _groups[groupIndex].id,
        menuItemId: menuItem.id,
        menuItem: menuItem,
        extraPrice: 0,
        quantity: 1,
        isDefault: false,
      ));
    });
  }

  void _save() async {
    setState(() => _isSaving = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final provider = Provider.of<MenuProvider>(context, listen: false);

    // Prepare data for backend
    final data = _groups.map((g) => {
      'name': g.name,
      'min_selections': g.minSelections,
      'max_selections': g.maxSelections,
      'is_required': g.isRequired,
      'items': g.comboItems.map((i) => {
        'menu_item_id': i.menuItemId,
        'extra_price': i.extraPrice,
        'quantity': i.quantity,
        'is_default': i.isDefault,
      }).toList(),
    }).toList();

    await provider.saveComboGroups(token!, widget.item.id, data, restaurantId: widget.restaurantId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Combo configuration saved!')));
      Navigator.pop(context);
    }

  }

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Configure Combo', style: TextStyle(color: Colors.white)),
          IconButton(onPressed: _addGroup, icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37)), tooltip: 'Add Group'),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 500,
        child: _groups.isEmpty 
          ? const Center(child: Text('No groups added yet.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              controller: _scrollController,
              itemCount: _groups.length,
              itemBuilder: (context, index) => _buildGroupItem(index),
            ),
      ),

      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
            : const Text('Save Configuration', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildGroupItem(int index) {
    final group = _groups[index];
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: group.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(labelText: 'Group Name', labelStyle: TextStyle(color: Color(0xFFD4AF37))),
                    onChanged: (val) => _groups[index] = MenuItemComboGroupModel(
                      id: group.id, menuItemId: group.menuItemId, name: val, 
                      minSelections: group.minSelections, maxSelections: group.maxSelections, 
                      isRequired: group.isRequired, comboItems: group.comboItems
                    ),
                  ),
                ),
                IconButton(onPressed: () => _removeGroup(index), icon: const Icon(Icons.delete, color: Colors.red, size: 20)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: group.minSelections.toString(),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Min Select', labelStyle: TextStyle(color: Colors.white38)),
                    onChanged: (val) => _groups[index] = MenuItemComboGroupModel(
                      id: group.id, menuItemId: group.menuItemId, name: group.name, 
                      minSelections: int.tryParse(val) ?? 1, maxSelections: group.maxSelections, 
                      isRequired: group.isRequired, comboItems: group.comboItems
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: group.maxSelections.toString(),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: const InputDecoration(labelText: 'Max Select', labelStyle: TextStyle(color: Colors.white38)),
                    onChanged: (val) => _groups[index] = MenuItemComboGroupModel(
                      id: group.id, menuItemId: group.menuItemId, name: group.name, 
                      minSelections: group.minSelections, maxSelections: int.tryParse(val) ?? 1, 
                      isRequired: group.isRequired, comboItems: group.comboItems
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    const Text('Required', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    Switch(
                      value: group.isRequired,
                      onChanged: (val) => setState(() {
                        _groups[index] = MenuItemComboGroupModel(
                          id: group.id, menuItemId: group.menuItemId, name: group.name, 
                          minSelections: group.minSelections, maxSelections: group.maxSelections, 
                          isRequired: val, comboItems: group.comboItems
                        );
                      }),
                      activeThumbColor: const Color(0xFFD4AF37),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32, color: Colors.white10),
            const Text('Items', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...group.comboItems.asMap().entries.map((entry) {
              final itemIndex = entry.key;
              final comboItem = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(comboItem.menuItem?.name ?? 'Unknown', style: const TextStyle(color: Colors.white, fontSize: 12))),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        initialValue: comboItem.extraPrice.toString(),
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        decoration: const InputDecoration(prefixText: '+₹', labelText: 'Extra', labelStyle: TextStyle(fontSize: 10)),
                        onChanged: (val) => comboItem.extraPrice = double.tryParse(val) ?? 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => setState(() => group.comboItems.removeAt(itemIndex)),
                      icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                    ),
                  ],
                ),
              );
            }),
            TextButton.icon(
              onPressed: () => _showItemPicker(index),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Item', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFD4AF37)),
            ),
          ],
        ),
      ),
    );
  }

  void _showItemPicker(int groupIndex) {
    final provider = Provider.of<MenuProvider>(context, listen: false);
    // Flatten all items from all cards
    final allItems = provider.menuCards.expand((c) => c.categories.expand((cat) => cat.items)).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A2A),
        title: const Text('Pick Menu Item', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 400,
          height: 400,
          child: ListView.builder(
            controller: ScrollController(), // Temporary controller for the dialog list
            itemCount: allItems.length,
            itemBuilder: (context, index) {

              final item = allItems[index];
              return ListTile(
                title: Text(item.name, style: const TextStyle(color: Colors.white)),
                subtitle: Text('₹${item.price}', style: const TextStyle(color: Colors.white38)),
                onTap: () {
                  _addItemToGroup(groupIndex, item);
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}


