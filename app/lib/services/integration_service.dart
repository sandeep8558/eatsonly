import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class IntegrationService {
  Future<Map<String, dynamic>> getIntegrations(String token, String restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.integrations}?restaurant_id=$restaurantId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load integration states'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> saveCredentials(String token, Map<String, dynamic> credentialsData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.integrationsCredentials),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(credentialsData),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to save integration settings'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMenuMapping(String token, String restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.integrationsMenu}?restaurant_id=$restaurantId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load menu mappings'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> mapItem(String token, Map<String, dynamic> mappingData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.integrationsMapItem),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(mappingData),
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update item mapping'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
