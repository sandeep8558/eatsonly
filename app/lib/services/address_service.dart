import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class AddressModel {
  final int id;
  final String label;
  final String address;
  final double latitude;
  final double longitude;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      label: json['label'] ?? 'Home',
      address: json['address'] ?? '',
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
    );
  }
}

class AddressService {
  Future<List<AddressModel>> fetchAddresses(String token) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.addresses),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return (data['data'] as List)
              .map((item) => AddressModel.fromJson(item))
              .toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<AddressModel?> createAddress(String token, String address, double lat, double lng, {String? label, bool isDefault = false}) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.addresses),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'address': address,
          'latitude': lat,
          'longitude': lng,
          'label': label ?? 'Home',
          'is_default': isDefault,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 211 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AddressModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<AddressModel?> updateAddress(String token, int id, String address, double lat, double lng, {String? label, bool isDefault = false}) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.addresses}/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'address': address,
          'latitude': lat,
          'longitude': lng,
          'label': label ?? 'Home',
          'is_default': isDefault,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return AddressModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteAddress(String token, int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.addresses}/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setDefaultAddress(String token, int id) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.addresses}/$id/default'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
