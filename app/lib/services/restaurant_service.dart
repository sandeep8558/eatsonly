import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../core/constants.dart';
import '../models/restaurant_model.dart';

class RestaurantService {
  Future<Map<String, dynamic>> getRestaurants(String token, {bool myRestaurants = false}) async {
    try {
      String url = ApiConstants.restaurants;
      if (myRestaurants) {
        url += '?my_restaurants=1';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 402) {
        return {
          'success': false,
          'message': 'Subscription expired. Please renew.',
          'code': 'SUBSCRIPTION_EXPIRED',
        };
      }

      final data = json.decode(response.body);
      
      if (response.statusCode == 200) {
        List<RestaurantModel> restaurants = (data['data'] as List)
            .map((item) => RestaurantModel.fromJson(item))
            .toList();
        
        double radius = (data['delivery_radius_km'] ?? 2.0).toDouble();

        return {
          'success': true, 
          'data': restaurants,
          'delivery_radius_km': radius
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load restaurants',
          'code': data['code'],
        };
      }
    } catch (e) {
      return {
        'success': false, 
        'message': e.toString(),
        'code': 'ERROR'
      };
    }
  }

  Future<Map<String, dynamic>> createRestaurant(String token, String name, String address, {String? slug, List<int>? logoBytes, String? logoName, bool isVeg = true, bool isNonveg = true, bool isJain = false, String? upiId, String? takeawayMenuCardId, String? deliveryMenuCardId, String? taxName, String? taxRegistrationNumber, String? fssaiNumber, double? latitude, double? longitude, bool isDelivery = true, bool isTakeaway = true, bool isDinein = true, String? billPrinterIp, int? billPrinterPort}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConstants.restaurants));
      
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['name'] = name;
      request.fields['address'] = address;
      if (slug != null && slug.isNotEmpty) {
        request.fields['slug'] = slug;
      }
      request.fields['is_veg'] = isVeg ? '1' : '0';
      request.fields['is_nonveg'] = isNonveg ? '1' : '0';
      request.fields['is_jain'] = isJain ? '1' : '0';
      request.fields['is_delivery'] = isDelivery ? '1' : '0';
      request.fields['is_takeaway'] = isTakeaway ? '1' : '0';
      request.fields['is_dinein'] = isDinein ? '1' : '0';
      if (upiId != null) request.fields['upi_id'] = upiId;
      if (takeawayMenuCardId != null) request.fields['takeaway_menu_card_id'] = takeawayMenuCardId;
      if (deliveryMenuCardId != null) request.fields['delivery_menu_card_id'] = deliveryMenuCardId;
      if (taxName != null) request.fields['tax_name'] = taxName;
      if (taxRegistrationNumber != null) request.fields['tax_registration_number'] = taxRegistrationNumber;
      if (fssaiNumber != null) request.fields['fssai_number'] = fssaiNumber;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (billPrinterIp != null) request.fields['bill_printer_ip'] = billPrinterIp;
      if (billPrinterPort != null) request.fields['bill_printer_port'] = billPrinterPort.toString();


      if (logoBytes != null && logoName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'logo',
          logoBytes,
          filename: logoName,
          contentType: MediaType('image', logoName.split('.').last),
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      final data = json.decode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'data': RestaurantModel.fromJson(data['data'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create restaurant'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateRestaurant(String token, String id, String name, String address, {String? slug, List<int>? logoBytes, String? logoName, bool isVeg = true, bool isNonveg = true, bool isJain = false, String? upiId, String? takeawayMenuCardId, String? deliveryMenuCardId, String? taxName, String? taxRegistrationNumber, String? fssaiNumber, double? latitude, double? longitude, bool isDelivery = true, bool isTakeaway = true, bool isDinein = true, String? billPrinterIp, int? billPrinterPort}) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('${ApiConstants.restaurants}/$id'));
      
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      request.fields['_method'] = 'PUT';
      request.fields['name'] = name;
      request.fields['address'] = address;
      if (slug != null && slug.isNotEmpty) {
        request.fields['slug'] = slug;
      }
      request.fields['is_veg'] = isVeg ? '1' : '0';
      request.fields['is_nonveg'] = isNonveg ? '1' : '0';
      request.fields['is_jain'] = isJain ? '1' : '0';
      request.fields['is_delivery'] = isDelivery ? '1' : '0';
      request.fields['is_takeaway'] = isTakeaway ? '1' : '0';
      request.fields['is_dinein'] = isDinein ? '1' : '0';
      if (upiId != null) request.fields['upi_id'] = upiId;
      if (takeawayMenuCardId != null) request.fields['takeaway_menu_card_id'] = takeawayMenuCardId;
      if (deliveryMenuCardId != null) request.fields['delivery_menu_card_id'] = deliveryMenuCardId;
      if (taxName != null) request.fields['tax_name'] = taxName;
      if (taxRegistrationNumber != null) request.fields['tax_registration_number'] = taxRegistrationNumber;
      if (fssaiNumber != null) request.fields['fssai_number'] = fssaiNumber;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
      if (billPrinterIp != null) request.fields['bill_printer_ip'] = billPrinterIp;
      if (billPrinterPort != null) request.fields['bill_printer_port'] = billPrinterPort.toString();


      if (logoBytes != null && logoName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'logo',
          logoBytes,
          filename: logoName,
          contentType: MediaType('image', logoName.split('.').last),
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': RestaurantModel.fromJson(data['data'])};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update restaurant'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteRestaurant(String token, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.restaurants}/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete restaurant'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
