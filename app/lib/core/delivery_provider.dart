import 'package:flutter/material.dart';
import '../services/delivery_service.dart';

class DeliveryProvider with ChangeNotifier {
  final DeliveryService _service = DeliveryService();
  bool _isLoading = false;

  List<dynamic> _availableDeliveries = [];
  List<dynamic> _activeDeliveries = [];
  List<dynamic> _deliveredDeliveries = [];
  Map<String, dynamic> _summary = {
    'total_deliveries': 0,
    'total_tips': 0.0,
    'cash_in_hand': 0.0,
    'recent_deliveries': []
  };

  bool get isLoading => _isLoading;
  List<dynamic> get availableDeliveries => _availableDeliveries;
  List<dynamic> get activeDeliveries => _activeDeliveries;
  List<dynamic> get deliveredDeliveries => _deliveredDeliveries;
  Map<String, dynamic> get summary => _summary;

  Future<void> fetchAvailableDeliveries(String token, {String? restaurantId, String? date}) async {
    _isLoading = true;
    notifyListeners();
 
    try {
      final result = await _service.getAvailableDeliveries(token, restaurantId: restaurantId, date: date);
      if (result['status'] == 'success') {
        _availableDeliveries = result['data'] ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching available deliveries: $e");
    }
 
    _isLoading = false;
    notifyListeners();
  }
 
  Future<void> fetchActiveDeliveries(String token, {String? restaurantId, String? date}) async {
    _isLoading = true;
    notifyListeners();
 
    try {
      final result = await _service.getActiveDeliveries(token, restaurantId: restaurantId, date: date);
      if (result['status'] == 'success') {
        _activeDeliveries = result['data'] ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching active deliveries: $e");
    }
 
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchDeliveredDeliveries(String token, {String? restaurantId, String? date}) async {
    _isLoading = true;
    notifyListeners();
 
    try {
      final result = await _service.getDeliveredDeliveries(token, restaurantId: restaurantId, date: date);
      if (result['status'] == 'success') {
        _deliveredDeliveries = result['data'] ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching delivered deliveries: $e");
    }
 
    _isLoading = false;
    notifyListeners();
  }
 
  Future<void> fetchSummary(String token, {String? restaurantId, String? date}) async {
    try {
      final result = await _service.getDeliverySummary(token, restaurantId: restaurantId, date: date);
      if (result['status'] == 'success') {
        _summary = result['data'] ?? {};
      }
    } catch (e) {
      debugPrint("Error fetching delivery stats summary: $e");
    }
    notifyListeners();
  }

  Future<bool> acceptDelivery(String token, String orderId, {String? restaurantId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.acceptDelivery(token, orderId, restaurantId: restaurantId);
      if (result['status'] == 'success') {
        await fetchAvailableDeliveries(token, restaurantId: restaurantId);
        await fetchActiveDeliveries(token, restaurantId: restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error accepting delivery: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateDeliveryStatus(String token, String orderId, String status, {String? restaurantId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.updateDeliveryStatus(token, orderId, status, restaurantId: restaurantId);
      if (result['status'] == 'success') {
        await fetchActiveDeliveries(token, restaurantId: restaurantId);
        await fetchDeliveredDeliveries(token, restaurantId: restaurantId);
        await fetchSummary(token, restaurantId: restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error updating delivery status: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateRiderLocation(String token, String orderId, double latitude, double longitude) async {
    try {
      final result = await _service.updateRiderLocation(token, orderId, latitude, longitude);
      return result['status'] == 'success';
    } catch (e) {
      debugPrint("Error updating rider location: $e");
      return false;
    }
  }

  void reset() {
    _availableDeliveries = [];
    _activeDeliveries = [];
    _deliveredDeliveries = [];
    _summary = {
      'total_deliveries': 0,
      'total_tips': 0.0,
      'cash_in_hand': 0.0,
      'recent_deliveries': []
    };
    _isLoading = false;
    notifyListeners();
  }
}
