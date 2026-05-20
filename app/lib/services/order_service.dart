import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class OrderService {
  Future<Map<String, dynamic>?> sendKOT(String token, String restaurantId, String? tableId, List<Map<String, dynamic>> items, {String? orderType, String? customerName, String? customerPhone, String? deliveryAddress, String? orderId, String? customerId, String? source, String? paymentMethod}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/orders/kot'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'restaurant_id': restaurantId,
          'table_id': tableId,
          'order_id': orderId,
          'order_type': orderType,
          'customer_id': customerId,
          'source': source,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'delivery_address': deliveryAddress,
          'items': items,
          'payment_method': paymentMethod,
        }),
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return data['data'];
      }
      return null;
    } catch (e) {
      print('Error sending KOT: $e');
      return null;
    }
  }

  Future<bool> removeItem(String token, String restaurantId, String tableId, String menuItemId, {String? orderId}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/orders/remove-item'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'restaurant_id': restaurantId,
          'table_id': tableId,
          'menu_item_id': menuItemId,
          'order_id': orderId,
        }),
      );

      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print('Error removing item: $e');
      return false;
    }
  }

  Future<dynamic> fetchActiveOrders(String token, String restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/orders/active?restaurant_id=$restaurantId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return data['data'];
      }
      if (response.statusCode == 402) {
        return {'code': 'SUBSCRIPTION_EXPIRED'};
      }
      throw Exception(data['message'] ?? 'Failed to fetch active orders');
    } catch (e) {
      print('Error fetching active orders: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchAllOrders(String token, String restaurantId, {String? date, String? paymentMethod, String? orderType, int page = 1, int perPage = 5}) async {
    try {
      String url = '${ApiConstants.baseUrl}/orders?restaurant_id=$restaurantId&page=$page&per_page=$perPage';
      if (date != null) url += '&date=$date';
      if (paymentMethod != null) url += '&payment_method=$paymentMethod';
      if (orderType != null) url += '&order_type=$orderType';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return {
          'orders': data['data']['data'],
          'current_page': data['data']['current_page'],
          'last_page': data['data']['last_page'],
          'total_count': data['summary']['total_count'],
          'total_amount': data['summary']['total_amount'],
        };
      }
      throw Exception(data['message'] ?? 'Failed to fetch all orders');
    } catch (e) {
      print('Error fetching all orders: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchDashboardStats(String token, String restaurantId, {String? date}) async {
    try {
      String url = '${ApiConstants.baseUrl}/orders/stats?restaurant_id=$restaurantId';
      if (date != null) {
        url += '&date=$date';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success') {
          return decoded['data'];
        }
      }
      return {};
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {};
    }
  }

  Future<bool> generateBill(String token, String orderId, String paymentMethod, {double discountAmount = 0, double discountPercentage = 0, String? discountType, String? discountReason, double? subtotal, double? tax, double? total, double? amountPaid, double? tipAmount, double deliveryCharge = 0, double packingCharge = 0, double serviceCharge = 0}) async {
    final response = await generateBillResponse(token, orderId, paymentMethod, discountAmount: discountAmount, discountPercentage: discountPercentage, discountType: discountType, discountReason: discountReason, subtotal: subtotal, tax: tax, total: total, amountPaid: amountPaid, tipAmount: tipAmount, deliveryCharge: deliveryCharge, packingCharge: packingCharge, serviceCharge: serviceCharge);
    return response != null && response['status'] == 'success';
  }

  Future<Map<String, dynamic>?> generateBillResponse(String token, String orderId, String paymentMethod, {double discountAmount = 0, double discountPercentage = 0, String? discountType, String? discountReason, double? subtotal, double? tax, double? total, double? amountPaid, double? tipAmount, double deliveryCharge = 0, double packingCharge = 0, double serviceCharge = 0}) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/bill'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'payment_method': paymentMethod,
          'discount_amount': discountAmount,
          'discount_percentage': discountPercentage,
          'discount_type': discountType,
          'discount_reason': discountReason,
          'subtotal': subtotal,
          'tax': tax,
          'total': total,
          'amount_paid': amountPaid,
          'tip_amount': tipAmount,
          'delivery_charge': deliveryCharge,
          'packing_charge': packingCharge,
          'service_charge': serviceCharge,
        }),
      );

      return json.decode(response.body);
    } catch (e) {
      print('Error generating bill response: $e');
      return null;
    }
  }
  Future<bool> reopenOrder(String token, String orderId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/reopen'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print('Error reopening order: $e');
      return false;
    }
  }

  Future<bool> deleteOrder(String token, String orderId) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.baseUrl}/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print('Error deleting order: $e');
      return false;
    }
  }

  Future<bool> transferOrder(String token, String orderId, String targetTableId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/orders/transfer'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'order_id': orderId,
          'target_table_id': targetTableId,
        }),
      );

      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print('Error transferring order: $e');
      return false;
    }
  }

  Future<bool> mergeOrder(String token, String sourceOrderId, String targetOrderId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/orders/merge'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'source_order_id': sourceOrderId,
          'target_order_id': targetOrderId,
        }),
      );

      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print('Error merging order: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> initiateRazorpayPayment(String token, String orderId) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/razorpay-initiate'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = json.decode(response.body);
    if (data['status'] == 'success') {
      return data['data'];
    }
    throw Exception(data['message'] ?? 'Failed to initialize payment');
  }

  Future<List<dynamic>> getDeliveryPartners(String token, String restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/orders/delivery-partners?restaurant_id=$restaurantId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      print('Error fetching delivery partners: $e');
      return [];
    }
  }

  Future<bool> assignDeliveryPartner(String token, String orderId, String restaurantId, String deliveryStaffId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/orders/$orderId/assign-delivery'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'restaurant_id': restaurantId,
          'delivery_staff_id': deliveryStaffId,
        }),
      );

      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print('Error assigning delivery partner: $e');
      return false;
    }
  }

  Future<bool> updateDeliveryStatus(String token, String orderId, String restaurantId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/delivery/orders/$orderId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'restaurant_id': restaurantId,
          'status': status,
        }),
      );

      final data = json.decode(response.body);
      return data['status'] == 'success';
    } catch (e) {
      print('Error updating delivery status: $e');
      return false;
    }
  }
}
