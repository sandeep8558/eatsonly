import 'package:flutter/foundation.dart';
import '../models/kds_station_model.dart';
import '../services/kds_station_service.dart';

class KdsStationProvider with ChangeNotifier {
  final KdsStationService _service = KdsStationService();
  List<KdsStationModel> _stations = [];
  bool _isLoading = false;

  List<KdsStationModel> get stations => _stations;
  bool get isLoading => _isLoading;

  Future<void> fetchStations(String token, String restaurantId) async {
    _isLoading = true;
    notifyListeners();
    _stations = await _service.fetchStations(token, restaurantId);
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addStation(String token, String restaurantId, String name) async {
    final station = await _service.createStation(token, restaurantId, name);
    if (station != null) {
      _stations.add(station);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateStation(String token, String id, Map<String, dynamic> data) async {
    final updated = await _service.updateStation(token, id, data);
    if (updated != null) {
      final index = _stations.indexWhere((s) => s.id == id);
      if (index != -1) {
        _stations[index] = updated;
        notifyListeners();
      }
      return true;
    }
    return false;
  }
  Future<bool> deleteStation(String token, String id) async {
    final success = await _service.deleteStation(token, id);
    if (success) {
      _stations.removeWhere((s) => s.id == id);
      notifyListeners();
    }
    return success;
  }

  void reset() {
    _stations = [];
    _isLoading = false;
    notifyListeners();
  }
}

