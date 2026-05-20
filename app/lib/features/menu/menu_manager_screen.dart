import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/menu_provider.dart';
import '../../core/tax_provider.dart';
import '../../core/kds_station_provider.dart';
import '../../models/menu_model.dart';
import '../../models/tax_model.dart';
import '../../core/constants.dart';
import 'widgets/combo_configuration_dialog.dart';
import 'widgets/recipe_configurator_dialog.dart';


class MenuManagerScreen extends StatefulWidget {
  final String? restaurantId;
  const MenuManagerScreen({super.key, this.restaurantId});

  @override
  State<MenuManagerScreen> createState() => _MenuManagerScreenState();
}

class _MenuManagerScreenState extends State<MenuManagerScreen> {
  String? _selectedMenuCardId;
  final ScrollController _outerScrollController = ScrollController();
  final ScrollController _tabsScrollController = ScrollController();
  String? _loadedRestaurantId;

  @override
  void dispose() {
    _outerScrollController.dispose();
    _tabsScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resto = Provider.of<RestaurantProvider>(context);
    final activeRestaurantId = widget.restaurantId ?? (resto.selectedRestaurant?.id ?? (resto.restaurants.isNotEmpty ? resto.restaurants.first.id : null));
    
    if (activeRestaurantId != _loadedRestaurantId) {
      _loadedRestaurantId = activeRestaurantId;
      _selectedMenuCardId = null; // Reset selection on switch to default to the new restaurant's first menu card
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadMenuCardsForRestaurant(activeRestaurantId);
        }
      });
    }
  }

  void _loadMenuCardsForRestaurant(String? activeRestaurantId) {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      Provider.of<MenuProvider>(context, listen: false).fetchMenuCards(token, restaurantId: activeRestaurantId).then((_) {
        if (mounted) {
          final cards = Provider.of<MenuProvider>(context, listen: false).menuCards;
          if (cards.isNotEmpty && _selectedMenuCardId == null) {
            setState(() {
              _selectedMenuCardId = cards.first.id;
            });
          }
        }
      });
      Provider.of<TaxProvider>(context, listen: false).fetchTaxGroups(token);
      
      if (activeRestaurantId != null) {
        Provider.of<KdsStationProvider>(context, listen: false).fetchStations(token, activeRestaurantId);
      }
    }
  }

  void _showAddMenuCardDialog() {
    final controller = TextEditingController();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final provider = Provider.of<MenuProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('New Menu Card', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Menu Card Name',
            labelStyle: TextStyle(color: Color(0xFFD4AF37)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await provider.createMenuCard(token!, controller.text, restaurantId: widget.restaurantId);
                Navigator.pop(context);
              }
            },
            child: const Text('Create', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  void _showEditMenuCardDialog(MenuCardModel card) {
    final controller = TextEditingController(text: card.name);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final provider = Provider.of<MenuProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Edit Menu Card', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Menu Card Name',
            labelStyle: TextStyle(color: Color(0xFFD4AF37)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirmed = await _showDeleteConfirmDialog('Are you sure you want to delete this menu card and all its contents?');
              if (confirmed) {
                await provider.deleteMenuCard(token!, card.id, restaurantId: widget.restaurantId);
                setState(() => _selectedMenuCardId = null);
                Navigator.pop(context);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await provider.updateMenuCard(token!, card.id, controller.text, restaurantId: widget.restaurantId);
                Navigator.pop(context);
              }
            },
            child: const Text('Update', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  Future<bool> _showDeleteConfirmDialog(String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Confirm Delete', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Color(0xFF94A3B8))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;
  }

  void _showCloneDialog() {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final provider = Provider.of<MenuProvider>(context, listen: false);
    String? sourceId;

    if (_selectedMenuCardId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a target menu card first.')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Clone Menu Content', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select source menu card to clone from:', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: sourceId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1A1A1A),
                    hint: const Text('Select Source', style: TextStyle(color: Colors.white38)),
                    items: provider.menuCards
                        .where((c) => c.id != _selectedMenuCardId)
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, style: const TextStyle(color: Colors.white)),
                            ))
                        .toList(),
                    onChanged: (val) => setDialogState(() => sourceId = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Note: This will append all categories and items from the source card to the current card.',
                style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
            TextButton(
              onPressed: sourceId == null ? null : () async {
                final success = await provider.cloneMenuCard(token!, sourceId!, _selectedMenuCardId!, restaurantId: widget.restaurantId);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu cloned successfully!'), backgroundColor: Colors.green));
                  Navigator.pop(context);
                }
              },
              child: const Text('Clone Now', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final provider = Provider.of<MenuProvider>(context, listen: false);
    String? selectedStationId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Add Category', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                  return await provider.searchCategories(token!, textEditingValue.text);
                },
                displayStringForOption: (option) => option['name'],
                fieldViewBuilder: (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
                  controller.text = fieldTextEditingController.text;
                  fieldTextEditingController.addListener(() {
                    controller.text = fieldTextEditingController.text;
                  });
                  return TextField(
                    controller: fieldTextEditingController,
                    focusNode: focusNode,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                      hintText: 'e.g. Starters, Beverages',
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      color: const Color(0xFF2A2A2A),
                      elevation: 4,
                      child: SizedBox(
                        width: 300,
                        height: 200,
                        child: ListView.builder(
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);
                            return ListTile(
                              title: Text(option['name'], style: const TextStyle(color: Colors.white)),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Consumer<KdsStationProvider>(
                builder: (context, kdsProvider, _) => DropdownButtonFormField<String>(
                  initialValue: selectedStationId,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Route to KDS Station', 
                    labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Station (Default)')),
                    ...kdsProvider.stations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) => setDialogState(() => selectedStationId = val),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty && _selectedMenuCardId != null) {
                  final sortOrder = provider.menuCards.firstWhere((c) => c.id == _selectedMenuCardId).categories.length;
                  await provider.createMenuCategory(token!, _selectedMenuCardId!, controller.text, sortOrder, kdsStationId: selectedStationId, restaurantId: widget.restaurantId);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(MenuCategoryModel category) {
    final controller = TextEditingController(text: category.name);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final provider = Provider.of<MenuProvider>(context, listen: false);
    String? selectedStationId = category.kdsStationId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Edit Category', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                ),
              ),
              const SizedBox(height: 24),
              Consumer<KdsStationProvider>(
                builder: (context, kdsProvider, _) => DropdownButtonFormField<String>(
                  initialValue: kdsProvider.stations.any((s) => s.id == selectedStationId) ? selectedStationId : null,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Route to KDS Station', 
                    labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('No Station (Default)')),
                    ...kdsProvider.stations.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) => setDialogState(() => selectedStationId = val),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirmed = await _showDeleteConfirmDialog('Delete this category and all its items?');
                if (confirmed) {
                  await provider.deleteMenuCategory(token!, category.id, restaurantId: widget.restaurantId);
                  Navigator.pop(context);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await provider.updateMenuCategory(token!, category.id, controller.text, category.sortOrder, kdsStationId: selectedStationId, restaurantId: widget.restaurantId);
                  Navigator.pop(context);
                }
              },
              child: const Text('Update', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMenuItemDialog(MenuItemModel item) {
    final nameController = TextEditingController(text: item.name);
    final priceController = TextEditingController(text: item.price.toString());
    final descController = TextEditingController(text: item.description);
    bool isVeg = item.isVeg;
    bool isNonveg = item.isNonveg;
    bool isJain = item.isJain;
    String? taxGroupId = item.taxGroupId;
    String itemType = item.type;


    bool isGenerating = false;
    XFile? selectedImage;
    final ImagePicker picker = ImagePicker();

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final provider = Provider.of<MenuProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Edit Menu Item', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Item Name',
                      labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(color: Color(0xFFD4AF37)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    children: [
                      TextField(
                        controller: descController,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 10,
                        child: isGenerating 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)))
                          : IconButton(
                              icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
                              onPressed: () async {
                                setDialogState(() => isGenerating = true);
                                final desc = await provider.generateDescription(token!, nameController.text);
                                if (desc != null) descController.text = desc;
                                setDialogState(() => isGenerating = false);
                              },
                              tooltip: 'Generate with AI',
                            ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setDialogState(() => selectedImage = image);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black12,
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb 
                                  ? Image.network(selectedImage!.path, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white24))
                                  : Image.file(File(selectedImage!.path), fit: BoxFit.cover),

                            )
                          : (item.image != null 
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network('${ApiConstants.storageUrl}${item.image}', fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white24)),

                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, color: Color(0xFFD4AF37), size: 32),
                                    SizedBox(height: 8),
                                    Text('Tap to change image', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                  ],
                                )),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: itemType,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1A1A),
                        items: const [
                          DropdownMenuItem(value: 'regular', child: Text('Regular Item', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'combo', child: Text('Combo Item', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (val) => setDialogState(() => itemType = val!),
                      ),
                    ),
                  ),
                  if (itemType == 'combo') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                           showDialog(
                             context: context,
                             builder: (context) => ComboConfigurationDialog(item: item, restaurantId: widget.restaurantId),
                           );
                        },

                        icon: const Icon(Icons.settings_suggest, color: Color(0xFFD4AF37)),
                        label: const Text('Configure Combo Options', style: TextStyle(color: Color(0xFFD4AF37))),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFD4AF37))),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  Consumer<TaxProvider>(
                    builder: (context, taxProvider, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: taxGroupId,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1A1A1A),
                            hint: const Text('Select Tax Group', style: TextStyle(color: Colors.white38)),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('No Tax', style: TextStyle(color: Colors.white)),
                              ),
                              ...taxProvider.taxGroups.map((g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.name, style: const TextStyle(color: Colors.white)),
                              )),
                            ],
                            onChanged: (val) => setDialogState(() => taxGroupId = val),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Veg', style: TextStyle(color: Colors.white, fontSize: 12)),
                          value: isVeg,
                          onChanged: (val) => setDialogState(() => isVeg = val!),
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Non-Veg', style: TextStyle(color: Colors.white, fontSize: 12)),
                          value: isNonveg,
                          onChanged: (val) => setDialogState(() => isNonveg = val!),
                          activeColor: Colors.red,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Jain', style: TextStyle(color: Colors.white, fontSize: 12)),
                          value: isJain,
                          onChanged: (val) => setDialogState(() => isJain = val!),
                          activeColor: Colors.purple,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirmed = await _showDeleteConfirmDialog('Delete this item?');
                if (confirmed) {
                  await provider.deleteMenuItem(token!, item.id, restaurantId: widget.restaurantId);
                  Navigator.pop(context);
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  final price = double.tryParse(priceController.text) ?? 0;
                  await provider.updateMenuItem(
                    token!, item.id, nameController.text, descController.text, 
                    price, isVeg, isNonveg, isJain, item.sortOrder, type: itemType, taxGroupId: taxGroupId, image: selectedImage,
                    restaurantId: widget.restaurantId
                  );

                  Navigator.pop(context);
                }
              },
              child: const Text('Update', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddItemDialog(String categoryId) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descController = TextEditingController();
    bool isVeg = false;
    bool isNonveg = false;
    bool isJain = false;
    String? taxGroupId;

    bool isGenerating = false;
    XFile? selectedImage;
    String? suggestedImageUrl;
    final ImagePicker picker = ImagePicker();

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final provider = Provider.of<MenuProvider>(context, listen: false);

    String itemType = 'regular';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(

          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Add Menu Item', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty) return const Iterable<Map<String, dynamic>>.empty();
                      return await provider.searchMenuItems(token!, textEditingValue.text);
                    },
                    displayStringForOption: (option) => option['name'],
                    onSelected: (option) {
                      setDialogState(() {
                        nameController.text = option['name'] ?? '';
                        descController.text = option['description'] ?? '';
                        isVeg = option['is_veg'] == 1 || option['is_veg'] == true;
                        isNonveg = option['is_nonveg'] == 1 || option['is_nonveg'] == true;
                        isJain = option['is_jain'] == 1 || option['is_jain'] == true;
                        suggestedImageUrl = option['image'];
                      });
                    },
                    fieldViewBuilder: (context, fieldTextEditingController, focusNode, onFieldSubmitted) {
                      // Sync fieldTextEditingController with nameController
                      if (nameController.text != fieldTextEditingController.text && nameController.text.isNotEmpty) {
                         // This is tricky because we don't want to overwrite if user is typing
                      }
                      
                      fieldTextEditingController.addListener(() {
                        nameController.text = fieldTextEditingController.text;
                      });
                      return TextField(
                        controller: fieldTextEditingController,
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Item Name',
                          labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                        ),
                      );
                    },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          color: const Color(0xFF2A2A2A),
                          elevation: 4,
                          child: SizedBox(
                            width: 400,
                            height: 200,
                            child: ListView.builder(
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options.elementAt(index);
                                return ListTile(
                                  title: Text(option['name'], style: const TextStyle(color: Colors.white)),
                                  subtitle: Text(option['description'] ?? '', style: const TextStyle(color: Colors.white38), maxLines: 1),
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                      prefixText: '₹ ',
                      prefixStyle: TextStyle(color: Color(0xFFD4AF37)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: const TextStyle(color: Color(0xFFD4AF37)),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
                      suffixIcon: isGenerating 
                        ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2)))
                        : IconButton(
                            icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
                            tooltip: 'Auto-generate description',
                            onPressed: () async {
                              if (nameController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter an item name first!', style: TextStyle(color: Colors.white))));
                                return;
                              }
                              setDialogState(() => isGenerating = true);
                              final generated = await provider.generateDescription(token!, nameController.text);
                              if (generated != null) {
                                setDialogState(() {
                                  descController.text = generated;
                                  isGenerating = false;
                                });
                              } else {
                                setDialogState(() => isGenerating = false);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate.', style: TextStyle(color: Colors.white)), backgroundColor: Colors.red));
                              }
                            },
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setDialogState(() => selectedImage = image);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.black12,
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb 
                                  ? Image.network(selectedImage!.path, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white24))
                                  : Image.file(File(selectedImage!.path), fit: BoxFit.cover),

                            )
                          : (suggestedImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network('${ApiConstants.storageUrl}$suggestedImageUrl', fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white24)),

                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, color: Color(0xFFD4AF37), size: 32),
                                    SizedBox(height: 8),
                                    Text('Tap to upload image', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                  ],
                                )),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: itemType,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1A1A1A),
                        items: const [
                          DropdownMenuItem(value: 'regular', child: Text('Regular Item', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 'combo', child: Text('Combo Item', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (val) => setDialogState(() => itemType = val!),
                      ),
                    ),
                  ),
                  if (itemType == 'combo') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please save the item first to configure combo options.')));
                        },

                        icon: const Icon(Icons.settings_suggest, color: Color(0xFFD4AF37)),
                        label: const Text('Configure Combo Options', style: TextStyle(color: Color(0xFFD4AF37))),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFD4AF37))),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Consumer<TaxProvider>(

                    builder: (context, taxProvider, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: taxGroupId,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1A1A1A),
                            hint: const Text('Select Tax Group', style: TextStyle(color: Colors.white38)),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('No Tax', style: TextStyle(color: Colors.white)),
                              ),
                              ...taxProvider.taxGroups.map((g) => DropdownMenuItem(
                                value: g.id,
                                child: Text(g.name, style: const TextStyle(color: Colors.white)),
                              )),
                            ],
                            onChanged: (val) => setDialogState(() => taxGroupId = val),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Veg', style: TextStyle(color: Colors.white, fontSize: 12)),
                          value: isVeg,
                          onChanged: (val) => setDialogState(() => isVeg = val!),
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Non-Veg', style: TextStyle(color: Colors.white, fontSize: 12)),
                          value: isNonveg,
                          onChanged: (val) => setDialogState(() => isNonveg = val!),
                          activeColor: Colors.red,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                      Expanded(
                        child: CheckboxListTile(
                          title: const Text('Jain', style: TextStyle(color: Colors.white, fontSize: 12)),
                          value: isJain,
                          onChanged: (val) => setDialogState(() => isJain = val!),
                          activeColor: Colors.purple,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  final price = double.tryParse(priceController.text) ?? 0;
                  // Calculate sort order
                  final cards = provider.menuCards;
                  final card = cards.firstWhere((c) => c.id == _selectedMenuCardId);
                  final cat = card.categories.firstWhere((c) => c.id == categoryId);
                  
                  await provider.createMenuItem(
                    token!, categoryId, nameController.text, descController.text, 
                    price, isVeg, isNonveg, isJain, cat.items.length, type: itemType, taxGroupId: taxGroupId, image: selectedImage,
                    imagePath: suggestedImageUrl,
                    restaurantId: widget.restaurantId
                  );

                  Navigator.pop(context);
                }
              },
              child: const Text('Add Item', style: TextStyle(color: Color(0xFFD4AF37))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.menuCards.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
        }

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  bool isSmall = constraints.maxWidth < 450;
                  return isSmall 
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Menu Manager', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showAddMenuCardDialog,
                              icon: const Icon(Icons.add, color: Colors.black, size: 18),
                              label: const Text('New Menu Card', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
                            ),
                          )
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Menu Manager', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                          ElevatedButton.icon(
                            onPressed: _showAddMenuCardDialog,
                            icon: const Icon(Icons.add, color: Colors.black),
                            label: const Text('New Menu Card', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          )
                        ],
                      );
                },
              ),
              const SizedBox(height: 24),
              if (provider.menuCards.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No Menu Cards found. Create one to start!', style: TextStyle(color: Colors.white54, fontSize: 16)),
                  ),
                )
              else ...[
                // Menu Card Selector Tabs
                SingleChildScrollView(
                  controller: _tabsScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),


                  child: Row(
                    children: [
                      ...provider.menuCards.map((card) {
                        final isSelected = card.id == _selectedMenuCardId;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onSecondaryTap: () => _showEditMenuCardDialog(card),
                            onLongPress: () => _showEditMenuCardDialog(card),
                            child: ChoiceChip(
                              label: Text(card.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) setState(() => _selectedMenuCardId = card.id);
                              },
                              selectedColor: const Color(0xFFD4AF37),
                              labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                              backgroundColor: const Color(0xFF1A1A1A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? const Color(0xFFD4AF37) : Colors.white24)),
                            ),
                          ),
                        );
                      }),
                      IconButton(
                        onPressed: _showCloneDialog,
                        icon: const Icon(Icons.copy_rounded, color: Color(0xFFD4AF37), size: 20),
                        tooltip: 'Clone from another Menu Card',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Categories and Items
                Expanded(
                  child: _buildMenuEditor(provider),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuEditor(MenuProvider provider) {
    if (_selectedMenuCardId == null) return const SizedBox();
    
    final card = provider.menuCards.firstWhere((c) => c.id == _selectedMenuCardId, orElse: () => provider.menuCards.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            bool isSmall = constraints.maxWidth < 450;
            return isSmall 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${card.name} - Categories', style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4AF37), size: 20),
                      label: const Text('Add Category', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12)),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${card.name} - Categories', style: const TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _showAddCategoryDialog,
                      icon: const Icon(Icons.add_circle_outline, color: Color(0xFFD4AF37)),
                      label: const Text('Add Category', style: TextStyle(color: Color(0xFFD4AF37))),
                    ),
                  ],
                );
          },
        ),
        const SizedBox(height: 16),
        if (card.categories.isEmpty)
          const Expanded(child: Center(child: Text('No categories yet. Add one to begin!', style: TextStyle(color: Colors.white38))))
        else
          Expanded(
            child: ReorderableListView.builder(
              scrollController: _outerScrollController,
              physics: const ClampingScrollPhysics(),
              buildDefaultDragHandles: false,


              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex -= 1;
                final categories = List<MenuCategoryModel>.from(card.categories);
                final item = categories.removeAt(oldIndex);
                categories.insert(newIndex, item);
                
                // Update local state first for instant UI response
                provider.updateLocalCategoryOrder(card.id, categories);
                
                _handleCategoryReorder(categories);
              },
              itemCount: card.categories.length,
              itemBuilder: (context, index) {
                final category = card.categories[index];
                return Container(
                  key: ValueKey(category.id),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16181D),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: true,
                      iconColor: const Color(0xFFD4AF37),
                      collapsedIconColor: Colors.white54,
                      leading: ReorderableDragStartListener(
                        index: index,
                        child: const Icon(Icons.drag_indicator, color: Colors.white24, size: 24),
                      ),
                      title: Consumer<KdsStationProvider>(
                        builder: (context, kdsProvider, _) {
                          final station = kdsProvider.stations.where((s) => s.id == category.kdsStationId).firstOrNull;
                          return Row(
                            children: [
                              Expanded(child: Text(category.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                              if (station != null)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    station.name.toUpperCase(),
                                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18, color: Colors.white54),
                                onPressed: () => _showEditCategoryDialog(category),
                              ),
                            ],
                          );
                        },
                      ),
                      children: [
                        const Divider(color: Colors.white10, height: 1),
                        if (category.items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Text('No items in this category.', style: TextStyle(color: Colors.white38)),
                          )
                        else
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final items = List<MenuItemModel>.from(category.items);
                              final item = items.removeAt(oldIndex);
                              items.insert(newIndex, item);

                              // Update local state first for instant UI response
                              provider.updateLocalItemOrder(category.id, items);

                              _handleItemReorder(category.id, items);
                            },
                            itemCount: category.items.length,
                            itemBuilder: (context, itemIndex) {
                              final item = category.items[itemIndex];
                              return ListTile(
                                key: ValueKey(item.id),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ReorderableDragStartListener(
                                      index: itemIndex,
                                      child: const Icon(Icons.drag_indicator, color: Colors.white12, size: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                                      ),
                                      child: item.image != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              '${ApiConstants.storageUrl}${item.image}',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.fastfood, color: Color(0xFFD4AF37), size: 16),
                                            ),
                                          )
                                        : const Icon(Icons.fastfood, color: Color(0xFFD4AF37), size: 16),
                                    ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Flexible(child: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                                    const SizedBox(width: 4),
                                    if (item.isVeg) const Icon(Icons.circle, color: Colors.green, size: 8),
                                    if (item.isNonveg) const Padding(padding: EdgeInsets.only(left: 2), child: Icon(Icons.circle, color: Colors.red, size: 8)),
                                    if (item.isJain) const Padding(padding: EdgeInsets.only(left: 2), child: Icon(Icons.circle, color: Colors.purple, size: 8)),
                                  ],
                                ),
                                subtitle: item.description != null && item.description!.isNotEmpty 
                                  ? Text(item.description!, style: const TextStyle(color: Colors.white54, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis) 
                                  : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.restaurant_menu_rounded, size: 14, color: Color(0xFFD4AF37)),
                                      tooltip: 'Recipe & BOM',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => RecipeConfiguratorDialog(
                                            item: item,
                                            restaurantId: _loadedRestaurantId,
                                          ),
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 14, color: Colors.white54),
                                      onPressed: () => _showEditMenuItemDialog(item),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
                          ),
                          child: TextButton.icon(
                            onPressed: () => _showAddItemDialog(category.id),
                            icon: const Icon(Icons.add, color: Color(0xFFD4AF37), size: 18),
                            label: const Text('Add Item', style: TextStyle(color: Color(0xFFD4AF37))),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _handleCategoryReorder(List<MenuCategoryModel> reorderedCategories) {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final provider = Provider.of<MenuProvider>(context, listen: false);
    
    final orders = reorderedCategories.asMap().entries.map((e) => {
      'id': e.value.id,
      'sort_order': e.key,
    }).toList();

    provider.reorderCategories(token!, orders, restaurantId: widget.restaurantId);
  }

  void _handleItemReorder(String categoryId, List<MenuItemModel> reorderedItems) {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final provider = Provider.of<MenuProvider>(context, listen: false);
    
    final orders = reorderedItems.asMap().entries.map((e) => {
      'id': e.value.id,
      'sort_order': e.key,
    }).toList();

    provider.reorderItems(token!, orders, restaurantId: widget.restaurantId);
  }
}
