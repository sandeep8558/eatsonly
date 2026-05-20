import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class TableService {
  Future<Map<String, dynamic>> getFloors(String token, String restaurantId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/floors?restaurant_id=$restaurantId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> storeFloor(String token, String restaurantId, String name, {String? menuCardId}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/floors'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'restaurant_id': restaurantId, 'name': name, 'menu_card_id': menuCardId}),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> storeTable(String token, String floorId, String name, int capacity, String shape) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tables'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        'floor_id': floorId,
        'name': name,
        'capacity': capacity,
        'shape': shape,
      }),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> updateFloor(String token, String floorId, String name, {String? menuCardId}) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/floors/$floorId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'menu_card_id': menuCardId}),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> deleteFloor(String token, String floorId) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/floors/$floorId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> updateTable(String token, String tableId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/tables/$tableId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> deleteTable(String token, String tableId) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/tables/$tableId'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> updateTableStatus(String token, String tableId, String status) async {
    return updateTable(token, tableId, {'status': status});
  }

  Future<Map<String, dynamic>> saveLayout(String token, List<Map<String, dynamic>> layoutData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/tables/layout'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'tables': layoutData}),
    );
    return json.decode(response.body);
  }
}
