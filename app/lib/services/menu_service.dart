import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';

class MenuService {
  Future<Map<String, dynamic>> generateDescription(String token, String name) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/menu/generate-description'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'name': name}),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> searchMasterCategories(String token, String query) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/menu/suggestions/categories?query=$query'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> searchMasterMenus(String token, String query) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/menu/suggestions/items?query=$query'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> getMenuCards(String token, {String? restaurantId}) async {
    String url = '${ApiConstants.baseUrl}/menu/cards';
    if (restaurantId != null) url += '?restaurant_id=$restaurantId';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    final data = json.decode(response.body);
    if (response.statusCode == 402) {
      data['code'] = 'SUBSCRIPTION_EXPIRED';
    }
    return data;
  }

  Future<Map<String, dynamic>> storeMenuCard(String token, String name, {String? restaurantId}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/menu/cards'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'restaurant_id': restaurantId}),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> storeMenuCategory(String token, String menuCardId, String name, int sortOrder, {String? kdsStationId}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/menu/categories'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        'menu_card_id': menuCardId, 
        'name': name, 
        'sort_order': sortOrder,
        'kds_station_id': kdsStationId
      }),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> updateMenuCard(String token, String id, String name, {String? restaurantId}) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/menu/cards/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'restaurant_id': restaurantId}),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> deleteMenuCard(String token, String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/menu/cards/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> updateMenuCategory(String token, String id, String name, int sortOrder, {String? kdsStationId}) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/menu/categories/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({
        'name': name, 
        'sort_order': sortOrder,
        'kds_station_id': kdsStationId
      }),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> deleteMenuCategory(String token, String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/menu/categories/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> storeMenuItem(String token, String categoryId, String name, String? description, double price, bool isVeg, bool isNonveg, bool isJain, int sortOrder, {String? type, String? taxGroupId, XFile? image, String? imagePath}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/menu/items'));
    request.headers.addAll({'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    
    request.fields['menu_category_id'] = categoryId;
    if (taxGroupId != null) request.fields['tax_group_id'] = taxGroupId;
    request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['is_veg'] = isVeg ? '1' : '0';
    request.fields['is_nonveg'] = isNonveg ? '1' : '0';
    request.fields['is_jain'] = isJain ? '1' : '0';
    request.fields['sort_order'] = sortOrder.toString();
    if (type != null) request.fields['type'] = type;
    if (imagePath != null) request.fields['image_path'] = imagePath;

    if (image != null) {
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    return json.decode(responseBody);
  }

  Future<Map<String, dynamic>> updateMenuItem(String token, String id, String name, String? description, double price, bool isVeg, bool isNonveg, bool isJain, int sortOrder, {String? type, String? taxGroupId, XFile? image}) async {
    final request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.baseUrl}/menu/items/$id'));
    request.headers.addAll({'Accept': 'application/json', 'Authorization': 'Bearer $token'});
    
    request.fields['name'] = name;
    if (taxGroupId != null) request.fields['tax_group_id'] = taxGroupId;
    if (description != null) request.fields['description'] = description;
    request.fields['price'] = price.toString();
    request.fields['is_veg'] = isVeg ? '1' : '0';
    request.fields['is_nonveg'] = isNonveg ? '1' : '0';
    request.fields['is_jain'] = isJain ? '1' : '0';
    request.fields['sort_order'] = sortOrder.toString();
    if (type != null) request.fields['type'] = type;

    if (image != null) {
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    return json.decode(responseBody);
  }


  Future<Map<String, dynamic>> deleteMenuItem(String token, String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/menu/items/$id'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> reorderCategories(String token, List<Map<String, dynamic>> orders) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/menu/categories/reorder'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'orders': orders}),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> reorderItems(String token, List<Map<String, dynamic>> orders) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/menu/items/reorder'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'orders': orders}),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> cloneMenuCard(String token, String sourceCardId, String targetCardId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/menu/cards/clone'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'source_card_id': sourceCardId, 'target_card_id': targetCardId}),
    );
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> saveComboGroups(String token, String itemId, List<Map<String, dynamic>> groups) async {

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/menu/items/$itemId/combo-groups'),
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'groups': groups}),
    );
    return json.decode(response.body);
  }

}
