import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/menu_model.dart';
import '../../../core/auth_provider.dart';
import '../../../core/inventory_provider.dart';
import '../../../core/recipe_provider.dart';

class RecipeConfiguratorDialog extends StatefulWidget {
  final MenuItemModel item;
  final String? restaurantId;

  const RecipeConfiguratorDialog({super.key, required this.item, this.restaurantId});

  @override
  State<RecipeConfiguratorDialog> createState() => _RecipeConfiguratorDialogState();
}

class _RecipeConfiguratorDialogState extends State<RecipeConfiguratorDialog> {
  List<Map<String, dynamic>> _ingredients = [];
  bool _isSaving = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  String _standardizeUnit(String unit) {
    final lower = unit.toLowerCase().trim();
    if (lower == 'kg' || lower == 'g') return lower;
    if (lower == 'l' || lower == 'liters' || lower == 'liter' || lower == 'litre' || lower == 'litres') return 'L';
    if (lower == 'ml') return 'ml';
    return unit;
  }

  List<String> _getAvailableConsumptionUnits(String? inventoryUnit) {
    if (inventoryUnit == null) return ['unit'];
    final unitLower = inventoryUnit.toLowerCase().trim();
    if (unitLower == 'kg' || unitLower == 'g') {
      return ['g', 'kg'];
    } else if (unitLower == 'l' || unitLower == 'ml' || unitLower == 'liters' || unitLower == 'liter' || unitLower == 'litre' || unitLower == 'litres') {
      return ['ml', 'L'];
    } else {
      final list = <String>[inventoryUnit];
      if (unitLower != 'unit') {
        list.add('unit');
      }
      return list.toSet().toList();
    }
  }

  double calculateIngredientCost(Map<String, dynamic> ing) {
    final qty = ing['quantity_needed'] as double;
    final costPerInvUnit = ing['cost_per_unit'] as double;
    final consumptionUnit = (ing['consumption_unit'] as String).toLowerCase().trim();
    final inventoryUnit = (ing['inventory_unit'] as String? ?? ing['consumption_unit'] as String).toLowerCase().trim();

    if (consumptionUnit == inventoryUnit) {
      return qty * costPerInvUnit;
    }

    // Weight conversions
    if (inventoryUnit == 'kg' && consumptionUnit == 'g') {
      return qty * (costPerInvUnit / 1000.0);
    }
    if (inventoryUnit == 'g' && consumptionUnit == 'kg') {
      return qty * (costPerInvUnit * 1000.0);
    }

    // Liquid volume conversions
    if ((inventoryUnit == 'l' || inventoryUnit == 'liters' || inventoryUnit == 'liter' || inventoryUnit == 'litre') && consumptionUnit == 'ml') {
      return qty * (costPerInvUnit / 1000.0);
    }
    if (inventoryUnit == 'ml' && (consumptionUnit == 'l' || consumptionUnit == 'liters' || consumptionUnit == 'liter' || consumptionUnit == 'litre')) {
      return qty * (costPerInvUnit * 1000.0);
    }

    // Default fallback
    return qty * costPerInvUnit;
  }

  Future<void> _loadData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);

    try {
      await Future.wait([
        inventoryProvider.fetchInventory(token!, widget.restaurantId ?? ''),
        recipeProvider.fetchRecipe(token, widget.restaurantId ?? '', widget.item.id),
      ]);

      if (mounted) {
        setState(() {
          _ingredients = recipeProvider.recipeItems.map((item) {
            final invItem = item['inventory_item'];
            final rawInvUnit = invItem != null ? invItem['unit'].toString() : 'unit';
            final rawConsUnit = item['consumption_unit'] ?? rawInvUnit;
            final invUnit = _standardizeUnit(rawInvUnit);
            final consUnit = _standardizeUnit(rawConsUnit.toString());
            return {
              'inventory_item_id': item['inventory_item_id'],
              'name': invItem != null ? invItem['name'] : 'Unknown Item',
              'quantity_needed': double.tryParse(item['quantity_needed'].toString()) ?? 0.0,
              'consumption_unit': consUnit,
              'cost_per_unit': double.tryParse((invItem != null ? invItem['cost_per_unit'] : 0.0).toString()) ?? 0.0,
              'inventory_unit': invUnit,
            };
          }).toList();
          _isLoadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  void _addIngredient(dynamic rawItem) {
    // Check if item is already added
    final exists = _ingredients.any((ing) => ing['inventory_item_id'] == rawItem['id']);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingredient already added to recipe!'), backgroundColor: Colors.amber),
      );
      return;
    }

    final rawUnit = rawItem['unit'] != null ? rawItem['unit'].toString() : 'unit';
    final standardizedUnit = _standardizeUnit(rawUnit);

    setState(() {
      _ingredients.add({
        'inventory_item_id': rawItem['id'],
        'name': rawItem['name'] ?? 'Ingredient',
        'quantity_needed': 1.0,
        'consumption_unit': standardizedUnit,
        'cost_per_unit': double.tryParse(rawItem['cost_per_unit'].toString()) ?? 0.0,
        'inventory_unit': standardizedUnit,
      });
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _saveRecipe() async {
    setState(() => _isSaving = true);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final recipeProvider = Provider.of<RecipeProvider>(context, listen: false);

    // Format list for backend payload
    final payload = _ingredients.map((ing) => {
      'inventory_item_id': ing['inventory_item_id'],
      'quantity_needed': ing['quantity_needed'],
      'consumption_unit': ing['consumption_unit'],
    }).toList();

    final success = await recipeProvider.saveRecipe(
      token!, 
      widget.restaurantId ?? '', 
      widget.item.id, 
      payload
    );

    setState(() => _isSaving = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recipe & BOM saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(recipeProvider.errorMessage ?? 'Failed to save recipe'), backgroundColor: Colors.red),
        );
      }
    }
  }

  double get totalFoodCost {
    return _ingredients.fold(0.0, (sum, ing) {
      return sum + calculateIngredientCost(ing);
    });
  }

  double get foodCostPercentage {
    if (widget.item.price <= 0) return 0.0;
    return (totalFoodCost / widget.item.price) * 100;
  }

  Color get _percentageColor {
    final pct = foodCostPercentage;
    if (pct < 30.0) return Colors.greenAccent;
    if (pct <= 45.0) return Colors.amberAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final rawMaterials = inventoryProvider.items;

    return AlertDialog(
      backgroundColor: const Color(0xFF16181D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.05))),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Recipe & Bill of Materials (BOM)',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Colors.white38),
          ),
        ],
      ),
      content: SizedBox(
        width: 650,
        height: 550,
        child: _isLoadingData
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
            : Column(
                children: [
                  // Real-time Theoretical Costing dashboard card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selling Price', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('₹${widget.item.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Food Cost', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            const SizedBox(height: 4),
                            Text('₹${totalFoodCost.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Theoretical Cost %', style: TextStyle(color: Colors.white38, fontSize: 11)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _percentageColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _percentageColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${foodCostPercentage.toStringAsFixed(1)}%',
                                style: TextStyle(color: _percentageColor, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search & Add ingredient bar
                  Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) return const Iterable.empty();
                      return rawMaterials.where((item) {
                        final name = (item['name'] ?? '').toString().toLowerCase();
                        return name.contains(textEditingValue.text.toLowerCase());
                      }).map((item) => item as Map<String, dynamic>);
                    },
                    displayStringForOption: (option) => option['name'] ?? '',
                    onSelected: (option) => _addIngredient(option),
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search raw material to add...',
                          hintStyle: const TextStyle(color: Colors.white24),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFD4AF37), size: 18),
                          filled: true,
                          fillColor: Colors.black26,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: const Color(0xFF23252C),
                          elevation: 4,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 580,
                            constraints: const BoxConstraints(maxHeight: 250),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: options.length,
                              itemBuilder: (context, idx) {
                                final opt = options.elementAt(idx);
                                final price = double.tryParse((opt['cost_per_unit'] ?? 0.0).toString()) ?? 0.0;
                                return ListTile(
                                  title: Text(opt['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  subtitle: Text('Unit: ${opt['unit']} | Cost: ₹${price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                                  onTap: () => onSelected(opt),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Header labels for ingredients list
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Expanded(flex: 4, child: Text('RAW INGREDIENT', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))),
                        const Expanded(flex: 2, child: Text('QTY', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))),
                        const Expanded(flex: 2, child: Text('UNIT', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold))),
                        const Expanded(flex: 2, child: Text('COST', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Scrollable recipe item builders
                  Expanded(
                    child: _ingredients.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restaurant_menu_rounded, color: Colors.white10, size: 48),
                                const SizedBox(height: 12),
                                Text('No ingredients defined yet for this dish.', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
                                Text('Select ingredients from search bar above to configure.', style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _ingredients.length,
                            itemBuilder: (context, index) {
                              final ing = _ingredients[index];
                              final cost = calculateIngredientCost(ing);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.01),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white.withOpacity(0.03)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        ing['name'],
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        initialValue: ing['quantity_needed'].toString(),
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        style: const TextStyle(color: Colors.white, fontSize: 13),
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                                        ),
                                        onChanged: (val) {
                                          final dVal = double.tryParse(val) ?? 0.0;
                                          setState(() {
                                            ing['quantity_needed'] = dVal;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: _getAvailableConsumptionUnits(ing['inventory_unit']).contains(ing['consumption_unit'])
                                              ? ing['consumption_unit']
                                              : _getAvailableConsumptionUnits(ing['inventory_unit']).first,
                                          dropdownColor: const Color(0xFF1A1A1A),
                                          style: const TextStyle(color: Colors.white, fontSize: 12),
                                          isDense: true,
                                          items: _getAvailableConsumptionUnits(ing['inventory_unit'])
                                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                                              .toList(),
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() {
                                                ing['consumption_unit'] = val;
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '₹${cost.toStringAsFixed(2)}',
                                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    IconButton(
                                      onPressed: () => _removeIngredient(index),
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: (_isSaving || _isLoadingData) ? null : _saveRecipe,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isSaving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Text('Save Recipe', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
