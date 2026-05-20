import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/staff_model.dart';

class StaffService {
  Future<Map<String, dynamic>> searchUser(String token, String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.staff}/search?query=$query'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'exists': data['exists'], 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Search failed'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getStaff(String token, {String? restaurantId}) async {
    try {
      String url = ApiConstants.staff;
      if (restaurantId != null) {
        url += '?restaurant_id=$restaurantId';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        List<StaffModel> staff = (data['data'] as List)
            .map((item) => StaffModel.fromJson(item))
            .toList();
        return {'success': true, 'data': staff};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load staff',
          'code': data['code'] ?? (response.statusCode == 402 ? 'SUBSCRIPTION_EXPIRED' : null),
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addStaff({
    required String token,
    required String name,
    required String email,
    required String mobile,
    required List<String> roles,
    required String restaurantId,
    String? password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.staff),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'mobile': mobile,
          'roles': roles,
          'restaurant_id': restaurantId,
          'password': password,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to add staff'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateStaff({
    required String token,
    required String userId,
    required String name,
    required List<String> roles,
    required String restaurantId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.staff}/$userId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'name': name,
          'roles': roles,
          'restaurant_id': restaurantId,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update staff'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> removeStaff(String token, String userId, String restaurantId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.staff}/$userId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'restaurant_id': restaurantId,
        }),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to remove staff'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
