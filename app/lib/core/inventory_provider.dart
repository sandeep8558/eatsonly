import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/inventory_service.dart';

class InventoryProvider with ChangeNotifier {
  List<dynamic> _items = [];
  List<dynamic> _suppliers = [];
  List<dynamic> _purchases = [];
  List<dynamic> _categories = [];
  List<dynamic> _issuances = [];
  List<dynamic> _wastageEntries = [];
  List<dynamic> _stockLedger = [];
  List<dynamic> _stockAudits = [];
  bool _isLoading = false;
  String? _errorMessage;
  final InventoryService _inventoryService = InventoryService();

  // Getters
  List<dynamic> get items => _items;
  List<dynamic> get suppliers => _suppliers;
  List<dynamic> get purchases => _purchases;
  List<dynamic> get categories => _categories;
  List<dynamic> get issuances => _issuances;
  List<dynamic> get wastageEntries => _wastageEntries;
  List<dynamic> get stockLedger => _stockLedger;
  List<dynamic> get stockAudits => _stockAudits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- INVENTORY METHODS ---
  Future<void> fetchInventory(String token, String restaurantId, {bool lowStock = false, String? category, String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.getInventory(
      token, 
      restaurantId, 
      lowStock: lowStock, 
      category: category, 
      search: search
    );

    if (result['success']) {
      _items = result['data'];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addInventoryItem(String token, Map<String, dynamic> itemData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.createInventoryItem(token, itemData);
    bool success = false;

    if (result['success']) {
      _items.add(result['data']);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> editInventoryItem(String token, String id, Map<String, dynamic> itemData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.updateInventoryItem(token, id, itemData);
    bool success = false;

    if (result['success']) {
      int index = _items.indexWhere((i) => i['id'] == id);
      if (index != -1) {
        _items[index] = result['data'];
      }
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> removeInventoryItem(String token, String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.deleteInventoryItem(token, id);
    bool success = false;

    if (result['success']) {
      _items.removeWhere((i) => i['id'] == id);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // --- SUPPLIER METHODS ---
  Future<void> fetchSuppliers(String token, String restaurantId, {String? search}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.getSuppliers(token, restaurantId, search: search);

    if (result['success']) {
      _suppliers = result['data'];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addSupplier(String token, Map<String, dynamic> supplierData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.createSupplier(token, supplierData);
    bool success = false;

    if (result['success']) {
      _suppliers.add(result['data']);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> editSupplier(String token, String id, Map<String, dynamic> supplierData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.updateSupplier(token, id, supplierData);
    bool success = false;

    if (result['success']) {
      int index = _suppliers.indexWhere((s) => s['id'] == id);
      if (index != -1) {
        _suppliers[index] = result['data'];
      }
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> removeSupplier(String token, String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.deleteSupplier(token, id);
    bool success = false;

    if (result['success']) {
      _suppliers.removeWhere((s) => s['id'] == id);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // --- PROCUREMENT/PURCHASES ---
  Future<void> fetchPurchases(String token, String restaurantId, {String? status}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.getPurchases(token, restaurantId, status: status);

    if (result['success']) {
      _purchases = result['data'];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addPurchaseOrder(String token, Map<String, dynamic> poData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.createPurchaseOrder(token, poData);
    bool success = false;

    if (result['success']) {
      _purchases.insert(0, result['data']);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> editPurchaseOrder(String token, String id, Map<String, dynamic> poData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.updatePurchaseOrder(token, id, poData);
    bool success = false;

    if (result['success']) {
      int index = _purchases.indexWhere((po) => po['id'] == id);
      if (index != -1) {
        _purchases[index] = result['data'];
      }
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> removePurchaseOrder(String token, String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.deletePurchaseOrder(token, id);
    bool success = false;

    if (result['success']) {
      _purchases.removeWhere((po) => po['id'] == id);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }


  // --- CATEGORY METHODS ---
  Future<void> fetchCategories(String token, String restaurantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.getInventoryCategories(token, restaurantId);

    if (result['success']) {
      _categories = result['data'];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addCategory(String token, Map<String, dynamic> catData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.createInventoryCategory(token, catData);
    bool success = false;

    if (result['success']) {
      _categories.add(result['data']);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> editCategory(String token, String id, Map<String, dynamic> catData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.updateInventoryCategory(token, id, catData);
    bool success = false;

    if (result['success']) {
      int index = _categories.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        _categories[index] = result['data'];
      }
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> removeCategory(String token, String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.deleteInventoryCategory(token, id);
    bool success = false;

    if (result['success']) {
      _categories.removeWhere((c) => c['id'] == id);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // --- MATERIAL ISSUANCE METHODS ---
  Future<void> fetchMaterialIssuances(String token, String restaurantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.getMaterialIssuances(token, restaurantId);

    if (result['success']) {
      _issuances = result['data'];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> logMaterialIssuance(String token, Map<String, dynamic> issuanceData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.createMaterialIssuance(token, issuanceData);
    bool success = false;

    if (result['success']) {
      _issuances.insert(0, result['data']);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // --- WASTAGE METHODS ---
  Future<void> fetchWastageEntries(String token, String restaurantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.getWastageEntries(token, restaurantId);

    if (result['success']) {
      _wastageEntries = result['data'];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> logWastageEntry(String token, Map<String, dynamic> wastageData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.createWastageEntry(token, wastageData);
    bool success = false;

    if (result['success']) {
      _wastageEntries.insert(0, result['data']);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // --- STOCK LEDGER METHODS ---
  Future<void> fetchStockLedger(String token, String restaurantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.getStockLedger(token, restaurantId);

    if (result['success']) {
      _stockLedger = result['data'];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- STOCK AUDIT METHODS ---
  Future<void> fetchStockAudits(String token, String restaurantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.getStockAudits(token, restaurantId);

    if (result['success']) {
      _stockAudits = result['data'];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitStockAudit(String token, Map<String, dynamic> auditData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _inventoryService.submitStockAudit(token, auditData);
    bool success = false;

    if (result['success']) {
      _stockAudits.insert(0, result['data']);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  @override
  void notifyListeners() {
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        super.notifyListeners();
      });
    } else {
      super.notifyListeners();
    }
  }
}
