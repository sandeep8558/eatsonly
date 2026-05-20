import 'package:flutter/material.dart';
import '../services/integration_service.dart';

class IntegrationProvider with ChangeNotifier {
  final IntegrationService _service = IntegrationService();

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? _zomatoCredentials;
  Map<String, dynamic>? _swiggyCredentials;
  List<dynamic> _menuItems = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get zomatoCredentials => _zomatoCredentials;
  Map<String, dynamic>? get swiggyCredentials => _swiggyCredentials;
  List<dynamic> get menuItems => _menuItems;

  Future<void> fetchIntegrations(String token, String restaurantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.getIntegrations(token, restaurantId);

    if (result['success']) {
      final data = result['data'];
      _zomatoCredentials = data['zomato'];
      _swiggyCredentials = data['swiggy'];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveCredentials(String token, Map<String, dynamic> credentialsData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.saveCredentials(token, credentialsData);
    bool success = false;

    if (result['success']) {
      final saved = result['data'];
      if (saved['aggregator'] == 'zomato') {
        _zomatoCredentials = saved;
      } else if (saved['aggregator'] == 'swiggy') {
        _swiggyCredentials = saved;
      }
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<void> fetchMenuMapping(String token, String restaurantId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.getMenuMapping(token, restaurantId);

    if (result['success']) {
      _menuItems = result['data'] ?? [];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> mapItem(String token, Map<String, dynamic> mappingData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _service.mapItem(token, mappingData);
    bool success = false;

    if (result['success']) {
      final savedMapping = result['data'];
      final menuItemId = mappingData['menu_item_id'];
      final aggregator = mappingData['aggregator'];

      // Update the local list state in memory dynamically to prevent jarring reload flashes
      final index = _menuItems.indexWhere((item) => item['id'] == menuItemId);
      if (index != -1) {
        if (aggregator == 'zomato') {
          _menuItems[index]['zomato_mapping'] = savedMapping;
        } else if (aggregator == 'swiggy') {
          _menuItems[index]['swiggy_mapping'] = savedMapping;
        }
      }
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
