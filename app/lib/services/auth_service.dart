import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String mobile,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.register),
      headers: {'Accept': 'application/json'},
      body: {
        'name': name,
        'email': email,
        'mobile': mobile,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String name,
    required String email,
    required String mobile,
  }) async {
    final response = await http.put(
      Uri.parse(ApiConstants.profile),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'name': name,
        'email': email,
        'mobile': mobile,
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updatePassword({
    required String token,
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConstants.profile}/password'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> deleteAccount({
    required String token,
    required String password,
  }) async {
    final response = await http.delete(
      Uri.parse(ApiConstants.profile),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: {
        'password': password,
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse(ApiConstants.forgotPassword),
      headers: {'Accept': 'application/json'},
      body: {'email': email},
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.resetPassword),
      headers: {'Accept': 'application/json'},
      body: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> upgradeToRestaurantAdmin({required String token}) async {
    final response = await http.post(
      Uri.parse(ApiConstants.upgrade),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getUserProfile({required String token}) async {
    final response = await http.get(
      Uri.parse(ApiConstants.userProfile),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final data = json.decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': data};
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Something went wrong',
        'code': data['code'],
        'errors': data['errors']
      };
    }
  }
}
