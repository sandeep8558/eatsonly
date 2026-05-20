import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/kds_station_model.dart';

class KdsStationService {
  Future<List<KdsStationModel>> fetchStations(String token, String restaurantId) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.baseUrl}/kds-stations?restaurant_id=$restaurantId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body)['data'];
      return data.map((item) => KdsStationModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<KdsStationModel?> createStation(String token, String restaurantId, String name) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/kds-stations'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'restaurant_id': restaurantId,
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
      return KdsStationModel.fromJson(json.decode(response.body)['data']);
    }
    return null;
  }

  Future<bool> deleteStation(String token, String id) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/kds-stations/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    return response.statusCode == 200;
  }

  Future<KdsStationModel?> updateStation(String token, String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.baseUrl}/kds-stations/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      return KdsStationModel.fromJson(json.decode(response.body)['data']);
    }
    return null;
  }
}

