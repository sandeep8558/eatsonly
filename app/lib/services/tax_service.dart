import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/tax_model.dart';

class TaxService {
  Future<Map<String, dynamic>> getTaxGroups(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.taxGroups),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        List<TaxGroupModel> groups = (data['data'] as List)
            .map((item) => TaxGroupModel.fromJson(item))
            .toList();
        return {'success': true, 'data': groups};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load tax groups'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createTaxGroup(String token, Map<String, dynamic> taxGroupData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.taxGroups),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(taxGroupData),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 201) {
        return {'success': true, 'data': TaxGroupModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create tax group'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateTaxGroup(String token, String id, Map<String, dynamic> taxGroupData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.taxGroups}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(taxGroupData),
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': TaxGroupModel.fromJson(data['data'])};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update tax group'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteTaxGroup(String token, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.taxGroups}/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete tax group'
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
