import 'package:flutter/material.dart';
import 'auth_provider.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import '../services/menu_service.dart';
import '../models/menu_model.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _menuService = MenuService();
  bool _isLoading = false;
  List<MenuCardModel> _menuCards = [];
  AuthProvider? _auth;

  void updateAuth(AuthProvider auth) {
    _auth = auth;
  }

  bool get isLoading => _isLoading;
  List<MenuCardModel> get menuCards => _menuCards;

  Future<void> fetchMenuCards(String token, {String? restaurantId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _menuService.getMenuCards(token, restaurantId: restaurantId);
      if (result['status'] == 'success') {
        _menuCards = (result['data'] as List).map((c) => MenuCardModel.fromJson(c)).toList();
      } else if (result['code'] == 'SUBSCRIPTION_EXPIRED') {
        _auth?.setSubscriptionExpired();
      }
    } catch (e) {
      debugPrint("Error fetching menu cards: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createMenuCard(String token, String name, {String? restaurantId}) async {
    try {
      final result = await _menuService.storeMenuCard(token, name);
      if (result['status'] == 'success') {
        await fetchMenuCards(token, restaurantId: restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error creating menu card: $e");
    }
    return false;
  }

  Future<bool> updateMenuCard(String token, String id, String name, {String? restaurantId}) async {
    try {
      final result = await _menuService.updateMenuCard(token, id, name);
      if (result['status'] == 'success') {
        await fetchMenuCards(token, restaurantId: restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error updating menu card: $e");
    }
    return false;
  }

  Future<bool> deleteMenuCard(String token, String id, {String? restaurantId}) async {
    try {
      final result = await _menuService.deleteMenuCard(token, id);
      if (result['status'] == 'success') {
        await fetchMenuCards(token, restaurantId: restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting menu card: $e");
    }
    return false;
  }

  Future<bool> createMenuCategory(String token, String menuCardId, String name, int sortOrder, {String? kdsStationId, String? restaurantId}) async {
    try {
      final result = await _menuService.storeMenuCategory(token, menuCardId, name, sortOrder, kdsStationId: kdsStationId);
      if (result['status'] == 'success') {
        await fetchMenuCards(token, restaurantId: restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error creating category: $e");
    }
    return false;
  }

  Future<bool> updateMenuCategory(String token, String id, String name, int sortOrder, {String? kdsStationId, String? restaurantId}) async {
    try {
      final result = await _menuService.updateMenuCategory(token, id, name, sortOrder, kdsStationId: kdsStationId);
      if (result['status'] == 'success') {
        await fetchMenuCards(token, restaurantId: restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error updating category: $e");
    }
    return false;
  }

  Future<bool> deleteMenuCategory(String token, String id, {String? restaurantId}) async {
    try {
      final result = await _menuService.deleteMenuCategory(token, id);
      if (result['status'] == 'success') {
        await fetchMenuCards(token, restaurantId: restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting category: $e");
    }
    return false;
  }

  Future<bool> createMenuItem(String token, String categoryId, String name, String? description, double price, bool isVeg, bool isNonveg, bool isJain, int sortOrder, {String? type, String? taxGroupId, XFile? image, String? imagePath, String? restaurantId}) async {
    try {
      final result = await _menuService.storeMenuItem(token, categoryId, name, description, price, isVeg, isNonveg, isJain, sortOrder, type: type, taxGroupId: taxGroupId, image: image, imagePath: imagePath);
      if (result['status'] == 'success') {
        await fetchMenuCards(token, restaurantId: restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error creating menu item: $e");
    }
    return false;
  }

  Future<bool> updateMenuItem(String token, String id, String name, String? description, double price, bool isVeg, bool isNonveg, bool isJain, int sortOrder, {String? type, String? taxGroupId, XFile? image, String? restaurantId}) async {
    try {
      final result = await _menuService.updateMenuItem(token, id, name, description, price, isVeg, isNonveg, isJain, sortOrder, type: type, taxGroupId: taxGroupId, image: image);
      if (result['status'] == 'success') {
        await fetchMenuCards(token, restaurantId: restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error updating menu item: $e");
    }
    return false;
  }


  Future<bool> deleteMenuItem(String token, String id, {String? restaurantId}) async {
    try {
      final result = await _menuService.deleteMenuItem(token, id);
      if (result['status'] == 'success') {
        await fetchMenuCards(token, restaurantId: restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting menu item: $e");
    }
    return false;
  }


  Future<String?> generateDescription(String token, String name) async {
    if (name.isEmpty) return null;
    try {
      final result = await _menuService.generateDescription(token, name);
      if (result['status'] == 'success') {
        return result['data'];
      }
    } catch (e) {
      debugPrint("Error generating description: $e");
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> searchCategories(String token, String query) async {
    if (query.isEmpty) return [];
    try {
      final result = await _menuService.searchMasterCategories(token, query);
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchMenuItems(String token, String query) async {
    if (query.isEmpty) return [];
    try {
      final result = await _menuService.searchMasterMenus(token, query);
      return List<Map<String, dynamic>>.from(result['data'] ?? []);
    } catch (e) {
      return [];
    }
  }

  Future<bool> reorderCategories(String token, List<Map<String, dynamic>> orders, {String? restaurantId}) async {
    final oldCards = List<MenuCardModel>.from(_menuCards);
    try {
      final result = await _menuService.reorderCategories(token, orders);
      if (result['status'] == 'success') {
        return true;
      }
    } catch (e) {
      _menuCards = oldCards;
      notifyListeners();
      debugPrint("Error reordering categories: $e");
    }
    return false;
  }

  Future<bool> reorderItems(String token, List<Map<String, dynamic>> orders, {String? restaurantId}) async {
    final oldCards = List<MenuCardModel>.from(_menuCards);
    try {
      final result = await _menuService.reorderItems(token, orders);
      if (result['status'] == 'success') {
        return true;
      }
    } catch (e) {
      _menuCards = oldCards;
      notifyListeners();
      debugPrint("Error reordering items: $e");
    }
    return false;
  }

  void updateLocalCategoryOrder(String cardId, List<MenuCategoryModel> newCategories) {
    final index = _menuCards.indexWhere((c) => c.id == cardId);
    if (index != -1) {
      _menuCards[index] = MenuCardModel(
        id: _menuCards[index].id,
        name: _menuCards[index].name,
        isActive: _menuCards[index].isActive,
        isLinked: _menuCards[index].isLinked,
        categories: newCategories,
      );
      notifyListeners();
    }
  }

  void updateLocalItemOrder(String categoryId, List<MenuItemModel> newItems) {
    for (int i = 0; i < _menuCards.length; i++) {
      final catIndex = _menuCards[i].categories.indexWhere((c) => c.id == categoryId);
      if (catIndex != -1) {
        final newCategories = List<MenuCategoryModel>.from(_menuCards[i].categories);
        newCategories[catIndex] = MenuCategoryModel(
          id: newCategories[catIndex].id,
          menuCardId: newCategories[catIndex].menuCardId,
          name: newCategories[catIndex].name,
          sortOrder: newCategories[catIndex].sortOrder,
          kdsStationId: newCategories[catIndex].kdsStationId,
          items: newItems,
        );
        
        _menuCards[i] = MenuCardModel(
          id: _menuCards[i].id,
          name: _menuCards[i].name,
          isActive: _menuCards[i].isActive,
          isLinked: _menuCards[i].isLinked,
          categories: newCategories,
        );
        notifyListeners();
        break;
      }
    }
  }

  Future<bool> cloneMenuCard(String token, String sourceCardId, String targetCardId, {String? restaurantId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _menuService.cloneMenuCard(token, sourceCardId, targetCardId);
      if (result['status'] == 'success') {
        await fetchMenuCards(token, restaurantId: restaurantId);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error cloning menu card: $e");
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> saveComboGroups(String token, String itemId, List<Map<String, dynamic>> groups, {String? restaurantId}) async {
    try {
      final result = await _menuService.saveComboGroups(token, itemId, groups);
      if (result['status'] == 'success') {
        await fetchMenuCards(token, restaurantId: restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error saving combo groups: $e");
    }
    return false;
  }

  void reset() {
    _menuCards = [];
    _isLoading = false;
    notifyListeners();
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


