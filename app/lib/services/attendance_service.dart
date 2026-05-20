import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class AttendanceService {
  Future<Map<String, dynamic>> getStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/attendance/status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> clockIn(String token, String restaurantId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/attendance/clock-in'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'restaurant_id': restaurantId}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> clockOut(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/attendance/clock-out'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/attendance/history'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
