import 'tax_model.dart';

class MenuCardModel {
  final String id;
  final String name;
  final bool isActive;
  final bool isLinked;
  final List<MenuCategoryModel> categories;

  MenuCardModel({required this.id, required this.name, required this.isActive, required this.categories, this.isLinked = false});

  factory MenuCardModel.fromJson(Map<String, dynamic> json) {
    return MenuCardModel(
      id: json['id'].toString(),
      name: json['name'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      isLinked: json['is_linked'] == true,
      categories: (json['categories'] as List?)?.map((c) => MenuCategoryModel.fromJson(c)).toList() ?? [],
    );
  }
}

class MenuCategoryModel {
  final String id;
  final String menuCardId;
  final String? kdsStationId;
  final String name;
  final int sortOrder;
  final List<MenuItemModel> items;

  MenuCategoryModel({required this.id, required this.menuCardId, this.kdsStationId, required this.name, required this.sortOrder, required this.items});

  factory MenuCategoryModel.fromJson(Map<String, dynamic> json) {
    return MenuCategoryModel(
      id: json['id'].toString(),
      menuCardId: json['menu_card_id'].toString(),
      kdsStationId: json['kds_station_id']?.toString(),
      name: json['name'],
      sortOrder: json['sort_order'] ?? 0,
      items: (json['items'] as List?)?.map((i) => MenuItemModel.fromJson(i)).toList() ?? [],
    );
  }
}

class MenuItemModel {
  final String id;
  final String menuCategoryId;
  final String? taxGroupId;
  final TaxGroupModel? taxGroup;
  final String name;
  final String? description;
  final double price;
  final String type; // regular, combo
  final bool isVeg;
  final bool isNonveg;
  final bool isJain;
  final String? image;
  final int sortOrder;
  final List<MenuItemComboGroupModel> comboGroups;

  MenuItemModel({
    required this.id, required this.menuCategoryId, this.taxGroupId, this.taxGroup, required this.name, 
    this.description, required this.price, this.type = 'regular', required this.isVeg, 
    required this.isNonveg, required this.isJain, this.image,
    required this.sortOrder,
    this.comboGroups = const [],
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'].toString(),
      menuCategoryId: json['menu_category_id'].toString(),
      taxGroupId: json['tax_group_id']?.toString(),
      taxGroup: json['tax_group'] != null ? TaxGroupModel.fromJson(json['tax_group']) : null,
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      type: json['type'] ?? 'regular',
      isVeg: json['is_veg'] == 1 || json['is_veg'] == true,
      isNonveg: json['is_nonveg'] == 1 || json['is_nonveg'] == true,
      isJain: json['is_jain'] == 1 || json['is_jain'] == true,
      image: json['image'],
      sortOrder: json['sort_order'] ?? 0,
      comboGroups: (json['combo_groups'] as List?)?.map((g) => MenuItemComboGroupModel.fromJson(g)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_category_id': menuCategoryId,
      'tax_group_id': taxGroupId,
      'tax_group': taxGroup?.toJson(),
      'name': name,
      'description': description,
      'price': price,
      'type': type,
      'is_veg': isVeg,
      'is_nonveg': isNonveg,
      'is_jain': isJain,
      'image': image,
      'sort_order': sortOrder,
      'combo_groups': comboGroups.map((g) => g.toJson()).toList(),
    };
  }
}

class MenuItemComboGroupModel {
  final String id;
  final String menuItemId;
  final String name;
  final int minSelections;
  final int maxSelections;
  final bool isRequired;
  final List<MenuItemComboItemModel> comboItems;

  MenuItemComboGroupModel({
    required this.id, required this.menuItemId, required this.name, 
    required this.minSelections, required this.maxSelections, required this.isRequired,
    required this.comboItems
  });

  factory MenuItemComboGroupModel.fromJson(Map<String, dynamic> json) {
    return MenuItemComboGroupModel(
      id: json['id'].toString(),
      menuItemId: json['menu_item_id'].toString(),
      name: json['name'],
      minSelections: json['min_selections'] ?? 1,
      maxSelections: json['max_selections'] ?? 1,
      isRequired: json['is_required'] == 1 || json['is_required'] == true,
      comboItems: (json['combo_items'] as List?)?.map((i) => MenuItemComboItemModel.fromJson(i)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'menu_item_id': menuItemId,
      'name': name,
      'min_selections': minSelections,
      'max_selections': maxSelections,
      'is_required': isRequired,
      'combo_items': comboItems.map((i) => i.toJson()).toList(),
    };
  }
}

class MenuItemComboItemModel {
  final String id;
  final String comboGroupId;
  final String menuItemId;
  final MenuItemModel? menuItem;
  double extraPrice;
  int quantity;
  bool isDefault;


  MenuItemComboItemModel({
    required this.id, required this.comboGroupId, required this.menuItemId, 
    this.menuItem, required this.extraPrice, required this.quantity, required this.isDefault
  });

  factory MenuItemComboItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemComboItemModel(
      id: json['id'].toString(),
      comboGroupId: json['combo_group_id'].toString(),
      menuItemId: json['menu_item_id'].toString(),
      menuItem: json['menu_item'] != null ? MenuItemModel.fromJson(json['menu_item']) : null,
      extraPrice: double.parse(json['extra_price'].toString()),
      quantity: json['quantity'] ?? 1,
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'combo_group_id': comboGroupId,
      'menu_item_id': menuItemId,
      'menu_item': menuItem?.toJson(),
      'extra_price': extraPrice,
      'quantity': quantity,
      'is_default': isDefault,
    };
  }
}

