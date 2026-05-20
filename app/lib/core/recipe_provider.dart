import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/recipe_service.dart';

class RecipeProvider with ChangeNotifier {
  List<dynamic> _recipeItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  final RecipeService _recipeService = RecipeService();

  // Getters
  List<dynamic> get recipeItems => _recipeItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchRecipe(String token, String restaurantId, String menuItemId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _recipeService.getRecipe(token, restaurantId, menuItemId);

    if (result['success']) {
      _recipeItems = result['data'];
    } else {
      _errorMessage = result['message'];
      _recipeItems = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveRecipe(
    String token, 
    String restaurantId, 
    String menuItemId, 
    List<Map<String, dynamic>> ingredients
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _recipeService.saveRecipe(token, restaurantId, menuItemId, ingredients);
    bool success = false;

    if (result['success']) {
      _recipeItems = result['data'];
      success = true;
    } else {
      _errorMessage = result['message'];
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  @override
  void notifyListeners() {
    if (WidgetsBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        super.notifyListeners();
      });
    } else {
      super.notifyListeners();
    }
  }
}
