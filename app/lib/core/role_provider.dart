import 'package:flutter/material.dart';
import '../services/role_service.dart';

class RoleProvider with ChangeNotifier {
  List<Map<String, dynamic>> _roles = [];
  bool _isLoading = false;
  final RoleService _roleService = RoleService();

  List<Map<String, dynamic>> get roles => _roles;
  bool get isLoading => _isLoading;

  Future<void> fetchRoles(String token) async {
    if (_roles.isNotEmpty) return; // Only fetch once

    _isLoading = true;
    notifyListeners();

    final result = await _roleService.getRoles(token);
    if (result['success']) {
      _roles = List<Map<String, dynamic>>.from(result['data']);
    }

    _isLoading = false;
    notifyListeners();
  }
}
