import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class RoleService {
  Future<Map<String, dynamic>> getRoles(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.roles),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to load roles'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
