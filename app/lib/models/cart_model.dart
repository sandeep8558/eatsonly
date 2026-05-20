import 'menu_model.dart';

class CartItem {
  final MenuItemModel menuItem;
  int quantity;
  String? notes;
  bool isSent;
  final String? status;
  final List<CartItem> children;
  final String? comboGroupId;

  CartItem({
    required this.menuItem, 
    this.quantity = 1, 
    this.notes, 
    this.isSent = false,
    this.status,
    List<CartItem>? children,
    this.comboGroupId,
  }) : children = children ?? [];


  double get baseTotal => menuItem.price * quantity;
  
  double get childrenExtraTotal {
    return children.fold(0.0, (sum, child) => sum + (child.menuItem.price * child.quantity));
  }

  double get total => baseTotal + (childrenExtraTotal * quantity);

  double get taxAmount {
    if (menuItem.taxGroup == null || menuItem.taxGroup!.taxes.isEmpty) return 0.0;
    
    double totalTaxPercentage = menuItem.taxGroup!.taxes.fold(0, (sum, t) => sum + t.percentage);
    
    if (menuItem.taxGroup!.isInclusive) {
      // Inclusive: Tax = Price - (Price / (1 + TaxRate))
      return total * (totalTaxPercentage / (100 + totalTaxPercentage));
    } else {
      // Exclusive: Tax = Price * TaxRate
      return total * (totalTaxPercentage / 100);
    }
  }

  double get totalWithTax {
    if (menuItem.taxGroup == null || menuItem.taxGroup!.isInclusive) {
      return total;
    } else {
      return total + taxAmount;
    }
  }

  Map<String, dynamic> toJson() => {
    'menuItem': menuItem.toJson(),
    'quantity': quantity,
    'notes': notes,
    'isSent': isSent,
    'status': status,
    'children': children.map((c) => c.toJson()).toList(),
    'comboGroupId': comboGroupId,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    menuItem: MenuItemModel.fromJson(json['menuItem']),
    quantity: json['quantity'],
    notes: json['notes'],
    isSent: json['isSent'] ?? false,
    status: json['status'],
    children: (json['children'] as List?)?.map((c) => CartItem.fromJson(c)).toList() ?? [],
    comboGroupId: json['comboGroupId'],
  );
}

