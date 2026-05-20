import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final _storage = const FlutterSecureStorage();

  bool _isCustomerMode = false;
  bool get isCustomerMode => _isCustomerMode;

  bool _isSubscriptionBlocked = false;
  bool get isSubscriptionBlocked => !isCustomerMode && (_isSubscriptionBlocked || (_user?.subscription?.isExpired ?? false));

  String? _selectedRole;
  String? get selectedRole => _selectedRole;

  void setCustomerMode(bool value) {
    _isCustomerMode = value;
    notifyListeners();
  }

  Future<void> setSelectedRole(String? role) async {
    _selectedRole = role;
    if (role != null) {
      await _storage.write(key: 'selected_role', value: role);
    } else {
      await _storage.delete(key: 'selected_role');
    }
    notifyListeners();
  }

  Future<void> toggleMode() async {
    _isCustomerMode = !_isCustomerMode;
    if (!_isCustomerMode) {
      _selectedRole = null;
      notifyListeners();
      await _storage.delete(key: 'selected_role');
    } else {
      notifyListeners();
    }
  }

  void _syncDefaultMode() {
    if (_user != null) {
      if (_user!.isOnlyCustomer) {
        _isCustomerMode = true;
        _selectedRole = 'customer';
      } else {
        if (_selectedRole == 'customer') {
          _isCustomerMode = true;
        } else {
          _isCustomerMode = false;
        }
      }
    }
  }

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    setLoading(true);
    final result = await _authService.login(email, password);
    setLoading(false);

    if (result['success']) {
      _token = result['data']['access_token'];
      _user = UserModel.fromJson(result['data']['user']);
      _isSubscriptionBlocked = false;
      _syncDefaultMode();
      await _storage.write(key: 'token', value: _token);
      await _storage.write(key: 'user', value: json.encode(_user!.toJson()));
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> register(Map<String, String> data) async {
    setLoading(true);
    final result = await _authService.register(
      name: data['name']!,
      email: data['email']!,
      mobile: data['mobile']!,
      password: data['password']!,
      passwordConfirmation: data['password_confirmation']!,
    );
    setLoading(false);

    if (result['success']) {
      _token = result['data']['access_token'];
      _user = UserModel.fromJson(result['data']['user']);
      _syncDefaultMode();
      await _storage.write(key: 'token', value: _token);
      await _storage.write(key: 'user', value: json.encode(_user!.toJson()));
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String mobile,
  }) async {
    setLoading(true);
    final result = await _authService.updateProfile(
      token: _token!,
      name: name,
      email: email,
      mobile: mobile,
    );
    setLoading(false);

    if (result['success']) {
      _user = UserModel.fromJson(result['data']['user']);
      await _storage.write(key: 'user', value: json.encode(_user!.toJson()));
      notifyListeners();
    }
    return result;
  }

  Future<Map<String, dynamic>> updatePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    setLoading(true);
    final result = await _authService.updatePassword(
      token: _token!,
      currentPassword: currentPassword,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    setLoading(false);
    return result;
  }

  Future<Map<String, dynamic>> deleteAccount(String password) async {
    if (_token == null) return {'success': false, 'message': 'Authentication required'};
    
    setLoading(true);
    final result = await _authService.deleteAccount(
      token: _token!,
      password: password,
    );
    setLoading(false);

    if (result['success']) {
      await logout();
    }
    return result;
  }

  Future<Map<String, dynamic>> upgradeToRestaurantAdmin() async {
    if (_token == null) return {'success': false, 'message': 'Authentication required'};

    setLoading(true);
    final result = await _authService.upgradeToRestaurantAdmin(token: _token!);
    setLoading(false);

    if (result['success']) {
      _user = UserModel.fromJson(result['data']['user']);
      _syncDefaultMode();
      await _storage.write(key: 'user', value: json.encode(_user!.toJson()));
      notifyListeners();
    }
    return result;
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _selectedRole = null;
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'user');
    await _storage.delete(key: 'selected_role');
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final token = await _storage.read(key: 'token');
    final userData = await _storage.read(key: 'user');
    final savedRole = await _storage.read(key: 'selected_role');
    
    if (token != null && userData != null) {
      _token = token;
      _user = UserModel.fromJson(json.decode(userData));
      _isSubscriptionBlocked = false;
      _selectedRole = savedRole;
      _syncDefaultMode();
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    if (_token == null) return;
    final result = await _authService.getUserProfile(token: _token!);
    if (result['success'] == true) {
      _user = UserModel.fromJson(result['data']);
      _isSubscriptionBlocked = false;
      _syncDefaultMode();
      await _storage.write(key: 'user', value: json.encode(_user!.toJson()));
      notifyListeners();
    }
  }

  void setSubscriptionExpired() {
    if (isCustomerMode) return;
    print('DEBUG: Subscription expired triggered!');
    _isSubscriptionBlocked = true;
    notifyListeners();
  }
}
