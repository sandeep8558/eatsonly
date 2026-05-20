import 'package:flutter/material.dart';
import '../../../models/menu_model.dart';
import '../../../models/cart_model.dart';

class ComboSelectionSheet extends StatefulWidget {
  final MenuItemModel comboItem;
  final ScrollController? scrollController;

  const ComboSelectionSheet({super.key, required this.comboItem, this.scrollController});

  @override
  State<ComboSelectionSheet> createState() => _ComboSelectionSheetState();
}

class _ComboSelectionSheetState extends State<ComboSelectionSheet> {
  // Group ID -> List of Selected Items
  final Map<String, List<MenuItemComboItemModel>> _selections = {};

  @override
  void initState() {
    super.initState();
    // Initialize default selections
    for (var group in widget.comboItem.comboGroups) {
      _selections[group.id] = group.comboItems.where((i) => i.isDefault).toList();
    }
  }

  bool _isGroupValid(MenuItemComboGroupModel group) {
    final selections = _selections[group.id] ?? [];
    return selections.length >= group.minSelections && selections.length <= group.maxSelections;
  }

  bool _isAllValid() {
    return widget.comboItem.comboGroups.every((g) => !g.isRequired || _isGroupValid(g));
  }

  void _toggleSelection(MenuItemComboGroupModel group, MenuItemComboItemModel item) {
    setState(() {
      final current = _selections[group.id] ?? [];
      final alreadySelected = current.any((i) => i.id == item.id);

      if (alreadySelected) {
        current.removeWhere((i) => i.id == item.id);
      } else {
        if (group.maxSelections == 1) {
          current.clear();
          current.add(item);
        } else if (current.length < group.maxSelections) {
          current.add(item);
        }
      }
      _selections[group.id] = current;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1115),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.comboItem.name,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.comboItem.description ?? 'Customize your combo',
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                  ),
                  child: Text(
                    '₹${widget.comboItem.price.toStringAsFixed(0)}',
                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white10, height: 1),

          // Content
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              itemCount: widget.comboItem.comboGroups.length,
              itemBuilder: (context, index) {
                final group = widget.comboItem.comboGroups[index];
                final isValid = _isGroupValid(group);
                final currentSelections = _selections[group.id] ?? [];

                return Container(
                  margin: const EdgeInsets.only(bottom: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name.toUpperCase(),
                                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Select ${group.minSelections == group.maxSelections ? group.minSelections : "${group.minSelections} to ${group.maxSelections}"} item(s)',
                                style: TextStyle(color: isValid ? Colors.white38 : Colors.redAccent, fontSize: 12),
                              ),
                            ],
                          ),
                          if (group.isRequired)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('REQUIRED', style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...group.comboItems.map((item) {
                        final isSelected = currentSelections.any((i) => i.id == item.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _toggleSelection(group, item),
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.05) : Colors.white.withOpacity(0.03),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFD4AF37).withOpacity(0.3) : Colors.white.withOpacity(0.05),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.restaurant, color: Colors.white24, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.menuItem?.name ?? 'Unknown Item',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        if (item.extraPrice > 0)
                                          Text(
                                            '+₹${item.extraPrice.toStringAsFixed(0)}',
                                            style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFD4AF37) : Colors.white24,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              color: const Color(0xFF16181D),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 40, offset: const Offset(0, -10)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Bundle Price', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      Text(
                        '₹${_calculateTotal().toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                ElevatedButton(
                  onPressed: _isAllValid() ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    disabledBackgroundColor: Colors.white10,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _isAllValid() ? 'Add to Cart' : 'Incomplete',
                        style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotal() {
    double total = widget.comboItem.price;
    _selections.forEach((groupId, items) {
      for (var item in items) {
        total += (item.extraPrice * item.quantity);
      }
    });
    return total;
  }

  void _submit() {
    final List<CartItem> children = [];
    _selections.forEach((groupId, items) {
      for (var item in items) {
        if (item.menuItem != null) {
          children.add(CartItem(
            menuItem: item.menuItem!.copyWith(price: item.extraPrice),
            quantity: item.quantity,
            comboGroupId: groupId,
          ));
        }
      }
    });

    Navigator.pop(context, CartItem(
      menuItem: widget.comboItem,
      children: children,
    ));
  }
}

extension MenuItemModelExtension on MenuItemModel {
  MenuItemModel copyWith({double? price}) {
    return MenuItemModel(
      id: id,
      menuCategoryId: menuCategoryId,
      name: name,
      price: price ?? this.price,
      isVeg: isVeg,
      isNonveg: isNonveg,
      isJain: isJain,
      sortOrder: sortOrder,
      description: description,
      image: image,
      taxGroupId: taxGroupId,
      taxGroup: taxGroup,
      type: type,
      comboGroups: comboGroups,
    );
  }
}
