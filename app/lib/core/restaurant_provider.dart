import 'package:flutter/material.dart';
import 'auth_provider.dart';
import '../models/restaurant_model.dart';
import '../services/restaurant_service.dart';

class RestaurantProvider with ChangeNotifier {
  List<RestaurantModel> _restaurants = [];
  RestaurantModel? _selectedRestaurant;
  double _deliveryRadiusKm = 2.0; // Default fallback radius (2.0 km)
  bool _isLoading = false;
  String? _errorMessage;
  final RestaurantService _restaurantService = RestaurantService();
  AuthProvider? _auth;

  void updateAuth(AuthProvider auth) {

    _auth = auth;
  }

  bool? _isMyRestaurants;

  List<RestaurantModel> get restaurants => _restaurants;
  RestaurantModel? get selectedRestaurant => _selectedRestaurant;
  double get deliveryRadiusKm => _deliveryRadiusKm;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool? get isMyRestaurants => _isMyRestaurants;

  void setSelectedRestaurant(RestaurantModel? restaurant) {
    _selectedRestaurant = restaurant;
    notifyListeners();
  }

  Future<void> fetchRestaurants(String token, {bool myRestaurants = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _restaurantService.getRestaurants(token, myRestaurants: myRestaurants);

    if (result['success']) {
      _restaurants = result['data'];
      _isMyRestaurants = myRestaurants;
      if (result.containsKey('delivery_radius_km')) {
        _deliveryRadiusKm = result['delivery_radius_km'];
      }
      if (_restaurants.isNotEmpty) {
        if (_selectedRestaurant == null || !_restaurants.any((r) => r.id == _selectedRestaurant!.id)) {
          _selectedRestaurant = _restaurants.first;
        } else {
          _selectedRestaurant = _restaurants.firstWhere((r) => r.id == _selectedRestaurant!.id);
        }
      } else {
        _selectedRestaurant = null;
      }
    } else {
      print('DEBUG: fetchRestaurants failed: ${result['message']} (code: ${result['code']})');
      _errorMessage = result['message'];
      if (result['code'] == 'SUBSCRIPTION_EXPIRED') {
        _auth?.setSubscriptionExpired();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addRestaurant(String token, String name, String address, {String? slug, List<int>? logoBytes, String? logoName, bool isVeg = true, bool isNonveg = true, bool isJain = false, String? upiId, String? takeawayMenuCardId, String? deliveryMenuCardId, String? taxName, String? taxRegistrationNumber, String? fssaiNumber, double? latitude, double? longitude, bool isDelivery = true, bool isTakeaway = true, bool isDinein = true, String? billPrinterIp, int? billPrinterPort}) async {
    _isLoading = true;
    notifyListeners();

    final result = await _restaurantService.createRestaurant(token, name, address, slug: slug, logoBytes: logoBytes, logoName: logoName, isVeg: isVeg, isNonveg: isNonveg, isJain: isJain, upiId: upiId, takeawayMenuCardId: takeawayMenuCardId, deliveryMenuCardId: deliveryMenuCardId, taxName: taxName, taxRegistrationNumber: taxRegistrationNumber, fssaiNumber: fssaiNumber, latitude: latitude, longitude: longitude, isDelivery: isDelivery, isTakeaway: isTakeaway, isDinein: isDinein, billPrinterIp: billPrinterIp, billPrinterPort: billPrinterPort);
    bool success = false;

    if (result['success']) {
      _restaurants.add(result['data']);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> editRestaurant(String token, String id, String name, String address, {String? slug, List<int>? logoBytes, String? logoName, bool isVeg = true, bool isNonveg = true, bool isJain = false, String? upiId, String? takeawayMenuCardId, String? deliveryMenuCardId, String? taxName, String? taxRegistrationNumber, String? fssaiNumber, double? latitude, double? longitude, bool isDelivery = true, bool isTakeaway = true, bool isDinein = true, String? billPrinterIp, int? billPrinterPort}) async {
    _isLoading = true;
    notifyListeners();

    final result = await _restaurantService.updateRestaurant(token, id, name, address, slug: slug, logoBytes: logoBytes, logoName: logoName, isVeg: isVeg, isNonveg: isNonveg, isJain: isJain, upiId: upiId, takeawayMenuCardId: takeawayMenuCardId, deliveryMenuCardId: deliveryMenuCardId, taxName: taxName, taxRegistrationNumber: taxRegistrationNumber, fssaiNumber: fssaiNumber, latitude: latitude, longitude: longitude, isDelivery: isDelivery, isTakeaway: isTakeaway, isDinein: isDinein, billPrinterIp: billPrinterIp, billPrinterPort: billPrinterPort);
    bool success = false;

    if (result['success']) {
      int index = _restaurants.indexWhere((r) => r.id == id);
      if (index != -1) {
        _restaurants[index] = result['data'];
      }
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }


  Future<bool> removeRestaurant(String token, String id) async {
    _isLoading = true;
    notifyListeners();

    final result = await _restaurantService.deleteRestaurant(token, id);
    bool success = false;

    if (result['success']) {
      _restaurants.removeWhere((r) => r.id == id);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  void reset() {
    _restaurants = [];
    _selectedRestaurant = null;
    _deliveryRadiusKm = 2.0;
    _isLoading = false;
    _errorMessage = null;
    _isMyRestaurants = null;
    notifyListeners();
  }
}
