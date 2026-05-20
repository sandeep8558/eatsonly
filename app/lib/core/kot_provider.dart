import 'package:flutter/material.dart';
import '../services/kot_service.dart';

class KotProvider extends ChangeNotifier {
  final KotService _kotService = KotService();
  List<dynamic> _activeKots = [];
  bool _isLoading = false;

  List<dynamic> get activeKots => _activeKots;
  bool get isLoading => _isLoading;

  Future<void> fetchActiveKots(String token, String restaurantId, {String? kdsStationId}) async {
    if (_activeKots.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }


    _activeKots = await _kotService.fetchKots(token, restaurantId, kdsStationId: kdsStationId);

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateStatus(String token, String kotId, String status) async {
    final success = await _kotService.updateKotStatus(token, kotId, status);
    if (success) {
      // Remove or update locally
      if (status == 'completed' || status == 'cancelled') {
        _activeKots.removeWhere((k) => k['id'].toString() == kotId);
      } else {
        final index = _activeKots.indexWhere((k) => k['id'].toString() == kotId);
        if (index != -1) {
          _activeKots[index]['status'] = status;
        }
      }
      notifyListeners();
    }
    return success;
  }
}
