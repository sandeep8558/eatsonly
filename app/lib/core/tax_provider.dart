import 'package:flutter/material.dart';
import '../models/tax_model.dart';
import '../services/tax_service.dart';

class TaxProvider with ChangeNotifier {
  List<TaxGroupModel> _taxGroups = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TaxService _taxService = TaxService();

  List<TaxGroupModel> get taxGroups => _taxGroups;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTaxGroups(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _taxService.getTaxGroups(token);

    if (result['success']) {
      _taxGroups = result['data'];
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addTaxGroup(String token, Map<String, dynamic> taxGroupData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _taxService.createTaxGroup(token, taxGroupData);
    bool success = false;

    if (result['success']) {
      _taxGroups.add(result['data']);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> editTaxGroup(String token, String id, Map<String, dynamic> taxGroupData) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _taxService.updateTaxGroup(token, id, taxGroupData);
    bool success = false;

    if (result['success']) {
      int index = _taxGroups.indexWhere((g) => g.id == id);
      if (index != -1) {
        _taxGroups[index] = result['data'];
      }
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> removeTaxGroup(String token, String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _taxService.deleteTaxGroup(token, id);
    bool success = false;

    if (result['success']) {
      _taxGroups.removeWhere((g) => g.id == id);
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
  
  Future<bool> toggleTaxGroupStatus(String token, TaxGroupModel group) async {
    final updatedData = {
      'name': group.name,
      'is_active': !group.isActive,
      'is_inclusive': group.isInclusive,
      'taxes': group.taxes.map((t) => t.toJson()).toList(),
    };
    
    return await editTaxGroup(token, group.id, updatedData);
  }
}
