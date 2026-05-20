import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class InventoryService {
  // --- INVENTORY ---
  Future<Map<String, dynamic>> getInventory(String token, String restaurantId, {bool lowStock = false, String? category, String? search}) async {
    try {
      String url = '${ApiConstants.inventory}?restaurant_id=$restaurantId';
      if (lowStock) url += '&low_stock=true';
      if (category != null && category.isNotEmpty) url += '&category=${Uri.encodeComponent(category)}';
      if (search != null && search.isNotEmpty) url += '&search=${Uri.encodeComponent(search)}';

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
        return {'success': false, 'message': data['message'] ?? 'Failed to load inventory items'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createInventoryItem(String token, Map<String, dynamic> itemData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.inventory),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(itemData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create inventory item'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateInventoryItem(String token, String id, Map<String, dynamic> itemData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.inventory}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(itemData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update inventory item'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteInventoryItem(String token, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.inventory}/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete inventory item'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- SUPPLIERS ---
  Future<Map<String, dynamic>> getSuppliers(String token, String restaurantId, {String? search}) async {
    try {
      String url = '${ApiConstants.suppliers}?restaurant_id=$restaurantId';
      if (search != null && search.isNotEmpty) url += '&search=${Uri.encodeComponent(search)}';

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
        return {'success': false, 'message': data['message'] ?? 'Failed to load suppliers'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createSupplier(String token, Map<String, dynamic> supplierData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.suppliers),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(supplierData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create supplier'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateSupplier(String token, String id, Map<String, dynamic> supplierData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.suppliers}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(supplierData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update supplier'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteSupplier(String token, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.suppliers}/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete supplier'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- PURCHASES (PROCUREMENT) ---
  Future<Map<String, dynamic>> getPurchases(String token, String restaurantId, {String? status}) async {
    try {
      String url = '${ApiConstants.purchases}?restaurant_id=$restaurantId';
      if (status != null && status.isNotEmpty) url += '&status=$status';

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
        return {'success': false, 'message': data['message'] ?? 'Failed to load purchase orders'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createPurchaseOrder(String token, Map<String, dynamic> poData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.purchases),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(poData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to log purchase order'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }  Future<Map<String, dynamic>> updatePurchaseOrder(String token, String id, Map<String, dynamic> poData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.purchases}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(poData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update purchase order'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deletePurchaseOrder(String token, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.purchases}/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to delete purchase order'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // --- INVENTORY CATEGORIES ---
  Future<Map<String, dynamic>> getInventoryCategories(String token, String restaurantId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.inventoryCategories}?restaurant_id=$restaurantId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to load categories'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createInventoryCategory(String token, Map<String, dynamic> catData) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConstants.inventoryCategories),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(catData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to create category'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateInventoryCategory(String token, String id, Map<String, dynamic> catData) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.inventoryCategories}/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(catData),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Failed to update category'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteInventoryCategory(String token, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConstants.inventoryCategories}/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = json.decode(response.body);
 
       if (response.statusCode == 200) {
         return {'success': true};
       } else {
         return {'success': false, 'message': data['message'] ?? 'Failed to delete category'};
       }
     } catch (e) {
       return {'success': false, 'message': e.toString()};
     }
   }

   // --- MATERIAL ISSUANCES ---
   Future<Map<String, dynamic>> getMaterialIssuances(String token, String restaurantId) async {
     try {
       final url = '${ApiConstants.issuances}?restaurant_id=$restaurantId';
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
         return {'success': false, 'message': data['message'] ?? 'Failed to load material issuances'};
       }
     } catch (e) {
       return {'success': false, 'message': e.toString()};
     }
   }

   Future<Map<String, dynamic>> createMaterialIssuance(String token, Map<String, dynamic> issuanceData) async {
     try {
       final response = await http.post(
         Uri.parse(ApiConstants.issuances),
         headers: {
           'Content-Type': 'application/json',
           'Accept': 'application/json',
           'Authorization': 'Bearer $token',
         },
         body: json.encode(issuanceData),
       );

       final data = json.decode(response.body);

       if (response.statusCode == 200 || response.statusCode == 201) {
         return {'success': true, 'data': data['data']};
       } else {
         return {'success': false, 'message': data['message'] ?? 'Failed to log material issuance'};
       }
     } catch (e) {
       return {'success': false, 'message': e.toString()};
     }
   }

   // --- WASTAGE MANAGEMENT ---
   Future<Map<String, dynamic>> getWastageEntries(String token, String restaurantId) async {
     try {
       final url = '${ApiConstants.wastage}?restaurant_id=$restaurantId';
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
         return {'success': false, 'message': data['message'] ?? 'Failed to load wastage entries'};
       }
     } catch (e) {
       return {'success': false, 'message': e.toString()};
     }
   }

   Future<Map<String, dynamic>> createWastageEntry(String token, Map<String, dynamic> wastageData) async {
     try {
       final response = await http.post(
         Uri.parse(ApiConstants.wastage),
         headers: {
           'Content-Type': 'application/json',
           'Accept': 'application/json',
           'Authorization': 'Bearer $token',
         },
         body: json.encode(wastageData),
       );

       final data = json.decode(response.body);

       if (response.statusCode == 200 || response.statusCode == 201) {
         return {'success': true, 'data': data['data']};
       } else {
         return {'success': false, 'message': data['message'] ?? 'Failed to log wastage entry'};
       }
     } catch (e) {
       return {'success': false, 'message': e.toString()};
     }
   }

   // --- STOCK LEDGER ---
   Future<Map<String, dynamic>> getStockLedger(String token, String restaurantId) async {
     try {
       final url = '${ApiConstants.stockLedger}?restaurant_id=$restaurantId';
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
         return {'success': false, 'message': data['message'] ?? 'Failed to load stock ledger'};
       }
      } catch (e) {
        return {'success': false, 'message': e.toString()};
      }
    }

    // --- STOCK AUDITS ---
    Future<Map<String, dynamic>> getStockAudits(String token, String restaurantId) async {
      try {
        final url = '${ApiConstants.stockAudits}?restaurant_id=$restaurantId';
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
          return {'success': false, 'message': data['message'] ?? 'Failed to load stock audits'};
        }
      } catch (e) {
        return {'success': false, 'message': e.toString()};
      }
    }

    Future<Map<String, dynamic>> submitStockAudit(String token, Map<String, dynamic> auditData) async {
      try {
        final response = await http.post(
          Uri.parse(ApiConstants.stockAudits),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: json.encode(auditData),
        );

        final data = json.decode(response.body);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return {'success': true, 'data': data['data']};
        } else {
          return {'success': false, 'message': data['message'] ?? 'Failed to submit stock audit'};
        }
      } catch (e) {
        return {'success': false, 'message': e.toString()};
      }
    }
}
