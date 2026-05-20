import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class KotService {
  Future<List<dynamic>> fetchKots(String token, String restaurantId, {String? kdsStationId}) async {
    try {
      String url = '${ApiConstants.baseUrl}/kots?restaurant_id=$restaurantId';
      if (kdsStationId != null) url += '&kds_station_id=$kdsStationId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return data['data'];
      }
      return [];
    } catch (e) {
      print('Error fetching KOTs: $e');
      return [];
    }
  }

  Future<bool> updateKotStatus(String token, String kotId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/kots/$kotId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status}),
      );

      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print('Error updating KOT status: $e');
      return false;
    }
  }
}
