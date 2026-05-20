import 'package:flutter/foundation.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';
import '../services/address_service.dart';

class CustomerProvider with ChangeNotifier {
  final CustomerService _customerService = CustomerService();
  final AddressService _addressService = AddressService();
  
  List<CustomerModel> _searchResults = [];
  List<CustomerModel> get searchResults => _searchResults;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Active / Selected Customer Location Coordinate & Text State
  String? _currentAddress = "123 MG Road, Bangalore";
  double? _customerLatitude = 12.9716;  // Default coordinate (Bangalore Center)
  double? _customerLongitude = 77.5946;

  bool _hasInitiallySetLocation = false;
  bool get hasInitiallySetLocation => _hasInitiallySetLocation;

  // Active Order Flow State
  String _orderType = 'delivery'; // 'delivery', 'takeaway', 'dine_in'
  String get orderType => _orderType;

  String? _activeTableId;
  String? get activeTableId => _activeTableId;

  String? _activeTableName;
  String? get activeTableName => _activeTableName;

  String? _activeRestaurantId;
  String? get activeRestaurantId => _activeRestaurantId;

  String? _activeRestaurantName;
  String? get activeRestaurantName => _activeRestaurantName;

  void setOrderType(String type) {
    _orderType = type;
    if (type == 'delivery') {
      _activeTableId = null;
      _activeTableName = null;
    }
    notifyListeners();
  }

  void setActiveTable(String? tableId, String? tableName, String? restaurantId, String? restaurantName) {
    _activeTableId = tableId;
    _activeTableName = tableName;
    _activeRestaurantId = restaurantId;
    _activeRestaurantName = restaurantName;
    notifyListeners();
  }

  void clearActiveTable() {
    _activeTableId = null;
    _activeTableName = null;
    notifyListeners();
  }

  void setHasInitiallySetLocation(bool val) {
    _hasInitiallySetLocation = val;
    notifyListeners();
  }

  void reset() {
    _hasInitiallySetLocation = false;
    _currentAddress = "123 MG Road, Bangalore";
    _customerLatitude = 12.9716;
    _customerLongitude = 77.5946;
    _apiAddresses = [];
    notifyListeners();
  }

  // Legacy Offline List fallback
  final List<String> _savedAddresses = [
    "Home: 123 MG Road, Bangalore",
    "Office: Phoenix Marketcity, Whitefield",
  ];

  // API Database Addresses
  List<AddressModel> _apiAddresses = [];

  String get currentAddress => _currentAddress ?? "No location selected";
  double? get customerLatitude => _customerLatitude;
  double? get customerLongitude => _customerLongitude;
  List<String> get savedAddresses => _savedAddresses;
  List<AddressModel> get apiAddresses => _apiAddresses;

  void setCurrentLocation(double lat, double lng, {String? address}) {
    _customerLatitude = lat;
    _customerLongitude = lng;
    _currentAddress = address ?? "GPS Coordinates: [${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}]";
    notifyListeners();
  }

  // --- LOCAL OFFLINE HELPERS (FALLBACK) ---
  void addSavedAddress(String address) {
    _savedAddresses.add(address);
    _currentAddress = address;
    _customerLatitude = 12.9716 + (_savedAddresses.length * 0.015);
    _customerLongitude = 77.5946 + (_savedAddresses.length * 0.012);
    notifyListeners();
  }

  void selectSavedAddress(String address) {
    _currentAddress = address;
    int index = _savedAddresses.indexOf(address);
    if (index != -1) {
      _customerLatitude = 12.9716 + (index * 0.015);
      _customerLongitude = 77.5946 + (index * 0.012);
    }
    notifyListeners();
  }

  void deleteAddress(String address) {
    _savedAddresses.remove(address);
    if (_currentAddress == address) {
      _currentAddress = _savedAddresses.isNotEmpty ? _savedAddresses.first : "No location selected";
      _customerLatitude = _savedAddresses.isNotEmpty ? 12.9716 : null;
      _customerLongitude = _savedAddresses.isNotEmpty ? 77.5946 : null;
    }
    notifyListeners();
  }

  void updateAddress(String oldAddress, String newAddress) {
    int index = _savedAddresses.indexOf(oldAddress);
    if (index != -1) {
      _savedAddresses[index] = newAddress;
      if (_currentAddress == oldAddress) {
        _currentAddress = newAddress;
      }
      notifyListeners();
    }
  }


  // --- REMOTE DATABASE (API) HELPERS ---
  Future<void> fetchAddresses(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      _apiAddresses = await _addressService.fetchAddresses(token);
      
      // Auto-select the default or first address if available
      if (_apiAddresses.isNotEmpty) {
        AddressModel? def;
        for (var a in _apiAddresses) {
          if (a.isDefault) {
            def = a;
            break;
          }
        }
        def ??= _apiAddresses.first;

        _currentAddress = "${def.label}: ${def.address}";
        _customerLatitude = def.latitude;
        _customerLongitude = def.longitude;
      }
    } catch (e) {
      debugPrint("Error fetching addresses: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addAddress(String token, String address, double lat, double lng, {String? label, bool isDefault = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newAddr = await _addressService.createAddress(token, address, lat, lng, label: label, isDefault: isDefault);
      if (newAddr != null) {
        await fetchAddresses(token);
      }
    } catch (e) {
      debugPrint("Error adding address: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> editAddress(String token, int id, String address, double lat, double lng, {String? label, bool isDefault = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updated = await _addressService.updateAddress(token, id, address, lat, lng, label: label, isDefault: isDefault);
      if (updated != null) {
        await fetchAddresses(token);
      }
    } catch (e) {
      debugPrint("Error updating address: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> removeAddress(String token, int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _addressService.deleteAddress(token, id);
      if (success) {
        await fetchAddresses(token);
      }
    } catch (e) {
      debugPrint("Error removing address: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> selectAddress(String token, AddressModel address) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _addressService.setDefaultAddress(token, address.id);
      if (success) {
        _currentAddress = "${address.label}: ${address.address}";
        _customerLatitude = address.latitude;
        _customerLongitude = address.longitude;
        await fetchAddresses(token);
      }
    } catch (e) {
      debugPrint("Error setting default address: $e");
    }

    _isLoading = false;
    notifyListeners();
  }


  // --- POS CUSTOMER CRUD ---
  Future<void> searchCustomers(String token, String query) async {
    if (query.length < 3) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _searchResults = await _customerService.searchCustomers(token, query);
    
    _isLoading = false;
    notifyListeners();
  }

  Future<CustomerModel?> saveCustomer(String token, String name, String phone, {String? email}) async {
    _isLoading = true;
    notifyListeners();

    final customer = await _customerService.saveCustomer(token, {
      'name': name,
      'mobile': phone,
      'email': email,
    });

    _isLoading = false;
    notifyListeners();
    return customer;
  }
  
  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }
}
