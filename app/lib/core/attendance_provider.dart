import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _service = AttendanceService();
  bool _isLoading = false;
  bool _isClockedIn = false;
  Map<String, dynamic>? _activeAttendance;
  List<dynamic> _history = [];

  bool get isLoading => _isLoading;
  bool get isClockedIn => _isClockedIn;
  Map<String, dynamic>? get activeAttendance => _activeAttendance;
  List<dynamic> get history => _history;

  Future<void> fetchStatus(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.getStatus(token);
      if (result['status'] == 'success') {
        _isClockedIn = result['is_clocked_in'];
        _activeAttendance = result['attendance'];
      }
    } catch (e) {
      debugPrint("Error fetching attendance status: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> clockIn(String token, String restaurantId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.clockIn(token, restaurantId);
      if (result['status'] == 'success') {
        await fetchStatus(token);
        return true;
      }
    } catch (e) {
      debugPrint("Error clocking in: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> clockOut(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _service.clockOut(token);
      if (result['status'] == 'success') {
        await fetchStatus(token);
        return true;
      }
    } catch (e) {
      debugPrint("Error clocking out: $e");
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> fetchHistory(String token) async {
    try {
      final result = await _service.getHistory(token);
      if (result['status'] == 'success') {
        _history = result['data'];
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error fetching attendance history: $e");
    }
  }
}
