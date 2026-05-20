import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class DeliveryService {
  Future<Map<String, dynamic>> getAvailableDeliveries(String token, {String? restaurantId, String? date}) async {
    try {
      final params = <String>[];
      if (restaurantId != null) params.add('restaurant_id=$restaurantId');
      if (date != null) params.add('date=$date');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';
      
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/delivery/orders/available$query'),
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

  Future<Map<String, dynamic>> getActiveDeliveries(String token, {String? restaurantId, String? date}) async {
    try {
      final params = <String>[];
      if (restaurantId != null) params.add('restaurant_id=$restaurantId');
      if (date != null) params.add('date=$date');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/delivery/orders/active$query'),
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

  Future<Map<String, dynamic>> getDeliveredDeliveries(String token, {String? restaurantId, String? date}) async {
    try {
      final params = <String>[];
      if (restaurantId != null) params.add('restaurant_id=$restaurantId');
      if (date != null) params.add('date=$date');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/delivery/orders/delivered$query'),
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

  Future<Map<String, dynamic>> acceptDelivery(String token, String orderId, {String? restaurantId}) async {
    try {
      final query = restaurantId != null ? '?restaurant_id=$restaurantId' : '';
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/delivery/orders/$orderId/accept$query'),
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

  Future<Map<String, dynamic>> updateDeliveryStatus(String token, String orderId, String status, {String? restaurantId}) async {
    try {
      final query = restaurantId != null ? '?restaurant_id=$restaurantId' : '';
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/delivery/orders/$orderId/status$query'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getDeliverySummary(String token, {String? restaurantId, String? date}) async {
    try {
      final params = <String>[];
      if (restaurantId != null) params.add('restaurant_id=$restaurantId');
      if (date != null) params.add('date=$date');
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/delivery/summary$query'),
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

  Future<Map<String, dynamic>> updateRiderLocation(String token, String orderId, double latitude, double longitude) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/delivery/orders/$orderId/location'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }
}
