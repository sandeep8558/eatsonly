import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/customer_model.dart';

class CustomerService {
  Future<List<CustomerModel>> searchCustomers(String token, String query) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/customers?search=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => CustomerModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error searching customers: $e');
      return [];
    }
  }

  Future<CustomerModel?> saveCustomer(String token, Map<String, dynamic> customerData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/customers'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(customerData),
      );

      if (response.statusCode == 200) {
        return CustomerModel.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error saving customer: $e');
      return null;
    }
  }
}
