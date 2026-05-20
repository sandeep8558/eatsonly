import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'constants.dart';

class SettingsProvider with ChangeNotifier {
  Map<String, String> _settings = {};
  bool _isLoading = false;

  Map<String, String> get settings => _settings;
  bool get isLoading => _isLoading;

  String get currency => _settings['currency'] ?? 'INR';

  // Takeaway
  bool get takeawayPackingEnabled => _settings['takeaway_packing_enabled'] == 'yes';
  String get takeawayPackingAmount => _settings['takeaway_packing_amount'] ?? '0';
  bool get takeawayServiceEnabled => _settings['takeaway_service_enabled'] == 'yes';
  String get takeawayServiceAmount => _settings['takeaway_service_amount'] ?? '0';

  // Delivery
  bool get deliveryDeliveryEnabled => _settings['delivery_delivery_enabled'] == 'yes';
  String get deliveryDeliveryAmount => _settings['delivery_delivery_amount'] ?? '0';
  bool get deliveryPackingEnabled => _settings['delivery_packing_enabled'] == 'yes';
  String get deliveryPackingAmount => _settings['delivery_packing_amount'] ?? '0';
  bool get deliveryServiceEnabled => _settings['delivery_service_enabled'] == 'yes';
  String get deliveryServiceAmount => _settings['delivery_service_amount'] ?? '0';

  // Dine-in
  bool get dineinPackingEnabled => _settings['dinein_packing_enabled'] == 'yes';
  String get dineinPackingAmount => _settings['dinein_packing_amount'] ?? '0';
  bool get dineinServiceEnabled => _settings['dinein_service_enabled'] == 'yes';
  String get dineinServiceAmount => _settings['dinein_service_amount'] ?? '0';

  // Payment Methods
  bool get codEnabled => _settings['cod_enabled'] != 'no';
  bool get onlinePaymentEnabled => _settings['online_payment_enabled'] != 'no';

  Future<void> fetchSettings(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final Map<String, dynamic> rawSettings = data['settings'] ?? {};
          _settings = rawSettings.map((key, value) => MapEntry(key, value?.toString() ?? ''));
          notifyListeners();
        }
      }
    } catch (e) {
      // Failed to load settings
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSettings(String token, Map<String, String> newSettings) async {
    // Optimistic update
    _settings.addAll(newSettings);
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/settings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'settings': newSettings}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
    } catch (e) {
      debugPrint('Error updating settings: $e');
    }
    return false;
  }
}
