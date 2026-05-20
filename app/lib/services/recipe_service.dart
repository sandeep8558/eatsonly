import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class RecipeService {
  Future<Map<String, dynamic>> getRecipe(String token, String restaurantId, String menuItemId) async {
    try {
      final url = '${ApiConstants.recipes}?restaurant_id=$restaurantId&menu_item_id=$menuItemId';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to load recipe'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> saveRecipe(
    String token, 
    String restaurantId, 
    String menuItemId, 
    List<Map<String, dynamic>> ingredients
  ) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.recipes),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'restaurant_id': restaurantId,
          'menu_item_id': menuItemId,
          'ingredients': ingredients,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to save recipe'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
