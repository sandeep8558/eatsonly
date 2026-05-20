import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class ReportService {
  Future<Map<String, dynamic>?> fetchTipReport(String token, String restaurantId, {String? startDate, String? endDate, String? waiterId}) async {
    try {
      String url = '${ApiConstants.baseUrl}/reports/tips?restaurant_id=$restaurantId';
      if (startDate != null) url += '&start_date=$startDate';
      if (endDate != null) url += '&end_date=$endDate';
      if (waiterId != null) url += '&waiter_id=$waiterId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching tip report: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchSalesReport(String token, String restaurantId, String range) async {
    try {
      final String url = '${ApiConstants.baseUrl}/reports/sales?restaurant_id=$restaurantId&range=$range';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching sales report: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchLeakageReport(String token, String restaurantId, String range) async {
    try {
      final String url = '${ApiConstants.baseUrl}/reports/leakage?restaurant_id=$restaurantId&range=$range';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching leakage report: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchMenuEngineeringReport(String token, String restaurantId, String range) async {
    try {
      final String url = '${ApiConstants.baseUrl}/reports/menu-engineering?restaurant_id=$restaurantId&range=$range';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error fetching menu engineering report: $e');
      return null;
    }
  }
}
