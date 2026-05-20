import 'package:flutter/material.dart';
import '../services/table_service.dart';
import '../models/table_model.dart';

class TableProvider extends ChangeNotifier {
  final TableService _tableService = TableService();
  bool _isLoading = false;
  List<FloorModel> _floors = [];

  bool get isLoading => _isLoading;
  List<FloorModel> get floors => _floors;
  List<TableModel> get allTables => _floors.expand((f) => f.tables).toList();


  Future<void> fetchFloors(String token, String restaurantId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _tableService.getFloors(token, restaurantId);
      if (result['status'] == 'success') {
        _floors = (result['data'] as List).map((f) => FloorModel.fromJson(f)).toList();
      }
    } catch (e) {
      debugPrint("Error fetching floors: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createFloor(String token, String restaurantId, String name, {String? menuCardId}) async {
    try {
      final result = await _tableService.storeFloor(token, restaurantId, name, menuCardId: menuCardId);
      if (result['status'] == 'success') {
        await fetchFloors(token, restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error creating floor: $e");
    }
    return false;
  }

  Future<bool> updateFloor(String token, String restaurantId, String floorId, String name, {String? menuCardId}) async {
    try {
      final result = await _tableService.updateFloor(token, floorId, name, menuCardId: menuCardId);
      if (result['status'] == 'success') {
        await fetchFloors(token, restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error updating floor: $e");
    }
    return false;
  }

  Future<bool> deleteFloor(String token, String restaurantId, String floorId) async {
    try {
      final result = await _tableService.deleteFloor(token, floorId);
      if (result['status'] == 'success') {
        await fetchFloors(token, restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting floor: $e");
    }
    return false;
  }

  Future<bool> createTable(String token, String restaurantId, String floorId, String name, int capacity, String shape) async {
    try {
      final result = await _tableService.storeTable(token, floorId, name, capacity, shape);
      if (result['status'] == 'success') {
        await fetchFloors(token, restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error creating table: $e");
    }
    return false;
  }

  Future<bool> updateTable(String token, String restaurantId, String tableId, Map<String, dynamic> data) async {
    try {
      final result = await _tableService.updateTable(token, tableId, data);
      if (result['status'] == 'success') {
        await fetchFloors(token, restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error updating table: $e");
    }
    return false;
  }

  Future<bool> deleteTable(String token, String restaurantId, String tableId) async {
    try {
      final result = await _tableService.deleteTable(token, tableId);
      if (result['status'] == 'success') {
        await fetchFloors(token, restaurantId);
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting table: $e");
    }
    return false;
  }

  Future<bool> updateTableStatus(String token, String tableId, String status) async {
    try {
      final result = await _tableService.updateTableStatus(token, tableId, status);
      if (result['status'] == 'success') {
        // Find and update locally to be fast
        for (var floor in _floors) {
          for (var table in floor.tables) {
            if (table.id == tableId) {
              table.status = status;
              notifyListeners();
              return true;
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error updating status: $e");
    }
    return false;
  }

  Future<bool> saveLayout(String token, String restaurantId, List<TableModel> tables) async {
    try {
      final layoutData = tables.map((t) => {
        'id': t.id,
        'x_pos': t.xPos,
        'y_pos': t.yPos,
      }).toList();
      
      final result = await _tableService.saveLayout(token, layoutData);
      if (result['status'] == 'success') {
        return true;
      }
    } catch (e) {
      debugPrint("Error saving layout: $e");
    }
    return false;
  }

  void reset() {
    _floors = [];
    _isLoading = false;
    notifyListeners();
  }
}
