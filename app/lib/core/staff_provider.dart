import 'package:flutter/material.dart';
import 'auth_provider.dart';
import '../models/staff_model.dart';
import '../services/staff_service.dart';

class StaffProvider with ChangeNotifier {
  List<StaffModel> _staffList = [];
  bool _isLoading = false;
  String? _errorMessage;
  final StaffService _staffService = StaffService();
  AuthProvider? _auth;

  void updateAuth(AuthProvider auth) {
    _auth = auth;
  }

  List<StaffModel> get staffList => _staffList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchStaff(String token, {String? restaurantId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _staffService.getStaff(token, restaurantId: restaurantId);

    if (result['success']) {
      _staffList = result['data'];
    } else {
      print('DEBUG: fetchStaff failed: ${result['message']} (code: ${result['code']})');
      _errorMessage = result['message'];
      if (result['code'] == 'SUBSCRIPTION_EXPIRED') {
        _auth?.setSubscriptionExpired();
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> checkUserExists(String token, String query) async {
    return await _staffService.searchUser(token, query);
  }

  Future<bool> addStaff({
    required String token,
    required String name,
    required String email,
    required String mobile,
    required List<String> roles,
    required String restaurantId,
    String? password,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _staffService.addStaff(
      token: token,
      name: name,
      email: email,
      mobile: mobile,
      roles: roles,
      restaurantId: restaurantId,
      password: password,
    );

    _isLoading = false;
    if (result['success']) {
      await fetchStaff(token); // Refresh list
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStaff({
    required String token,
    required String userId,
    required String name,
    required List<String> roles,
    required String restaurantId,
  }) async {
    _isLoading = true;
    notifyListeners();

    final result = await _staffService.updateStaff(
      token: token,
      userId: userId,
      name: name,
      roles: roles,
      restaurantId: restaurantId,
    );

    _isLoading = false;
    if (result['success']) {
      await fetchStaff(token); // Refresh list
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeStaff(String token, String userId, String restaurantId) async {
    _isLoading = true;
    notifyListeners();

    final result = await _staffService.removeStaff(token, userId, restaurantId);

    _isLoading = false;
    if (result['success']) {
      _staffList.removeWhere((s) => s.id == userId && s.restaurantId == restaurantId);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _staffList = [];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
