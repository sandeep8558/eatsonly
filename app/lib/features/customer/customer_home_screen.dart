import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/customer_provider.dart';
import '../../models/restaurant_model.dart';
import '../../core/widgets/main_layout.dart';
import '../customer/customer_addresses_screen.dart';
import 'restaurant_menu_screen.dart';
import '../../services/address_service.dart';
import '../../core/constants.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = 10;
  bool _isLoadingMore = false;
  String? _previousAddress;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRestaurantsAndAddresses();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_isLoadingMore) return;

    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);

    final double? cLat = customerProvider.customerLatitude;
    final double? cLng = customerProvider.customerLongitude;

    int totalCount = 0;
    for (var r in restaurantProvider.restaurants) {
      if (cLat != null && cLng != null && r.latitude != null && r.longitude != null) {
        double distance = Geolocator.distanceBetween(cLat, cLng, r.latitude!, r.longitude!) / 1000.0;
        if (distance <= restaurantProvider.deliveryRadiusKm) {
          totalCount++;
        }
      }
    }

    if (_visibleCount < totalCount) {
      setState(() {
        _isLoadingMore = true;
      });

      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _visibleCount += 10;
            _isLoadingMore = false;
          });
        }
      });
    }
  }

  Future<void> _fetchRestaurantsAndAddresses() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token == null) return;

    final restaurantProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);

    // 1. Fetch restaurants and addresses from API
    await restaurantProvider.fetchRestaurants(auth.token!);
    await customerProvider.fetchAddresses(auth.token!);

    // ONLY perform the auto-detection override on first-time login
    if (customerProvider.hasInitiallySetLocation) {

      return;
    }

    // Mark as initialized so they can freely switch coordinates / addresses later without automatic override
    customerProvider.setHasInitiallySetLocation(true);

    // 2. Fetch current physical GPS coordinates
    Position? currentPosition;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      debugPrint("Failed to automatically acquire current GPS coordinate: $e");
    }

    // 3. Resolve starting default address based on saved addresses or geo location
    if (customerProvider.apiAddresses.isNotEmpty) {
      if (currentPosition != null) {
        // Find nearest saved address to the physical GPS coordinate
        AddressModel nearestAddress = customerProvider.apiAddresses.first;
        double minDistance = double.infinity;

        for (var addr in customerProvider.apiAddresses) {
          double dist = Geolocator.distanceBetween(
            currentPosition.latitude,
            currentPosition.longitude,
            addr.latitude,
            addr.longitude,
          );
          if (dist < minDistance) {
            minDistance = dist;
            nearestAddress = addr;
          }
        }

        customerProvider.setCurrentLocation(
          nearestAddress.latitude,
          nearestAddress.longitude,
          address: "${nearestAddress.label}: ${nearestAddress.address}",
        );
      } else {
        // No physical location could be acquired (disabled/denied) -> Fallback to the default/first saved address
        final firstAddr = customerProvider.apiAddresses.first;
        customerProvider.setCurrentLocation(
          firstAddr.latitude,
          firstAddr.longitude,
          address: "${firstAddr.label}: ${firstAddr.address}",
        );
      }
    } else {
      // No saved addresses in the account -> Set physical GPS position if acquired, else default to Bangalore center
      if (currentPosition != null) {
        String gpsAddress = "GPS Coordinates: [${currentPosition.latitude.toStringAsFixed(5)}, ${currentPosition.longitude.toStringAsFixed(5)}]";
        customerProvider.setCurrentLocation(
          currentPosition.latitude,
          currentPosition.longitude,
          address: gpsAddress,
        );
      } else {
        // Default coordinate placeholder as fallback
        customerProvider.setCurrentLocation(
          12.9716,
          77.5946,
          address: "123 MG Road, Bangalore",
        );
      }
    }
  }

  Future<void> _detectGPSLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS Location service is disabled on this device.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is denied.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    try {
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint("Failed to get high accuracy position: $e. Trying last known position...");
        position = await Geolocator.getLastKnownPosition();
        if (position == null) {
          debugPrint("Last known position was null. Trying medium accuracy...");
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
        }
      }

      if (position == null) {
        throw Exception("Could not determine location.");
      }

      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      
      String gpsAddress = "GPS Coordinates: [${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}]";
      customerProvider.setCurrentLocation(position.latitude, position.longitude, address: gpsAddress);
      
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current GPS position loaded! Sorted closest restaurants.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to obtain GPS position: $e')),
      );
    }
  }

  void _showQrScannerSheet() {
    final TextEditingController urlController = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Center Bar Indicator
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFD4AF37), size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('SCAN RESTAURANT OR TABLE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        const SizedBox(height: 4),
                        Text('EatsOnly Native QR Parser', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), height: 1),
              const SizedBox(height: 20),
              
              // Animated Mock Scanner
              SizedBox(
                height: 180,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: MobileScanner(
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final String? code = barcode.rawValue;
                        if (code != null) {
                          debugPrint('Barcode found! $code');
                          _parseAndRouteQR(code);
                          break; // Only parse the first one found
                        }
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('PASTE OR ENTER COPIED QR CODE LINK', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              
              TextField(
                controller: urlController,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: 'e.g., https://eatsonly.com/m/kings-foodland?t=table-id',
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.02),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFD4AF37)),
                    onPressed: () => _parseAndRouteQR(urlController.text.trim()),
                  ),
                ),
                onSubmitted: (val) => _parseAndRouteQR(val.trim()),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _parseAndRouteQR(String content) {
    if (content.isEmpty) return;

    // Dismiss scanner modal
    Navigator.pop(context);

    try {
      final Uri uri = Uri.parse(content);
      final String? tableId = uri.queryParameters['t'];

      // Extract slug from URL, like '/m/kings-foodland' -> 'kings-foodland'
      String? slug;
      final segments = uri.pathSegments;
      final mIndex = segments.indexOf('m');
      if (mIndex != -1 && mIndex < segments.length - 1) {
        slug = segments[mIndex + 1];
      } else if (segments.isNotEmpty) {
        slug = segments.last;
      }

      if (slug == null) {
        final match = RegExp(r'/m/([^?/]+)').firstMatch(content);
        if (match != null) {
          slug = match.group(1);
        }
      }

      final restoProvider = Provider.of<RestaurantProvider>(context, listen: false);
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);

      RestaurantModel? foundResto;
      for (var r in restoProvider.restaurants) {
        if (r.slug == slug || r.id == slug || r.name.toLowerCase().replaceAll(' ', '-') == slug) {
          foundResto = r;
          break;
        }
      }

      // Fallback match
      if (foundResto == null && restoProvider.restaurants.isNotEmpty) {
        foundResto = restoProvider.restaurants.firstWhere(
          (r) => r.slug.contains(slug ?? '') || (slug ?? '').contains(r.slug),
          orElse: () => restoProvider.restaurants.first,
        );
      }

      if (foundResto == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find a restaurant matching that QR code.')),
        );
        return;
      }

      if (tableId != null) {
        customerProvider.setOrderType('dine_in');
        customerProvider.setActiveTable(tableId, 'Table ${tableId.substring(0, 4).toUpperCase()}', foundResto.id, foundResto.name);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Dine-In locked on Table: ${tableId.substring(0, 4).toUpperCase()} at ${foundResto.name}!'),
            backgroundColor: const Color(0xFFD4AF37),
          ),
        );
      } else {
        customerProvider.setOrderType('takeaway');
        customerProvider.setActiveTable(null, null, foundResto.id, foundResto.name);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Takeaway registered for ${foundResto.name}!'),
            backgroundColor: const Color(0xFFD4AF37),
          ),
        );
      }

      // Instantly open the native menu inside the app
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RestaurantMenuScreen(restaurant: foundResto!),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error parsing scanned QR link: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  Widget _buildOrderTypeTab(
    BuildContext context, {
    required String type,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final isSelected = customerProvider.orderType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          customerProvider.setOrderType(type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor.withOpacity(0.3) : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 16),
              const SizedBox(width: 4),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final restaurantProvider = Provider.of<RestaurantProvider>(context);
    final customerProvider = Provider.of<CustomerProvider>(context);

    final double? cLat = customerProvider.customerLatitude;
    final double? cLng = customerProvider.customerLongitude;

    List<Map<String, dynamic>> structuredRestaurants = [];

    for (var r in restaurantProvider.restaurants) {
      double? distance;
      if (cLat != null && cLng != null && r.latitude != null && r.longitude != null) {
        distance = Geolocator.distanceBetween(cLat, cLng, r.latitude!, r.longitude!) / 1000.0;
      }
      
      if (distance != null && distance <= restaurantProvider.deliveryRadiusKm) {
        structuredRestaurants.add({
          'restaurant': r,
          'distance': distance,
        });
      }
    }

    structuredRestaurants.sort((a, b) {
      if (a['distance'] == null && b['distance'] == null) return 0;
      if (a['distance'] == null) return 1;
      if (b['distance'] == null) return -1;
      return (a['distance'] as double).compareTo(b['distance'] as double);
    });

    final currentAddr = customerProvider.currentAddress;
    if (_previousAddress != currentAddr) {
      _previousAddress = currentAddr;
      _visibleCount = 10;
    }

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Order Type Selector Tabs
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                _buildOrderTypeTab(
                  context,
                  type: 'delivery',
                  label: 'Delivery',
                  icon: Icons.moped_rounded,
                  activeColor: const Color(0xFFD4AF37),
                ),
                _buildOrderTypeTab(
                  context,
                  type: 'takeaway',
                  label: 'Takeaway',
                  icon: Icons.shopping_bag_rounded,
                  activeColor: const Color(0xFFD4AF37),
                ),
                _buildOrderTypeTab(
                  context,
                  type: 'dine_in',
                  label: 'Dine-In',
                  icon: Icons.restaurant_rounded,
                  activeColor: const Color(0xFFD4AF37),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Render Delivery Section
          if (customerProvider.orderType == 'delivery') ...[
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainLayout(
                          activePage: 'Addresses',
                          child: const CustomerAddressesScreen(),
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFFD4AF37), size: 14),
                            const SizedBox(width: 6),
                            const Text('DELIVERING TO', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customerProvider.currentAddress,
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    cLat != null && cLng != null 
                                        ? 'GPS Coordinates: [${cLat.toStringAsFixed(4)}, ${cLng.toStringAsFixed(4)}]'
                                        : 'Location coordinate not specified',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Render Takeaway Header Card
          if (customerProvider.orderType == 'takeaway') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withOpacity(0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TAKEAWAY PRE-ORDERS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  Text('Choose a kitchen below to place a pre-order, or scan a restaurant QR code directly at the checkout counter.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12, height: 1.5)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black),
                      label: const Text('SCAN COUNTER QR CODE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showQrScannerSheet,
                    ),
                  )
                ],
              ),
            ),
          ],

          // Render Dine-In Card
          if (customerProvider.orderType == 'dine_in') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: customerProvider.activeTableId != null ? const Color(0xFFD4AF37).withOpacity(0.03) : Colors.white.withOpacity(0.01),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: customerProvider.activeTableId != null ? const Color(0xFFD4AF37).withOpacity(0.2) : Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('DINE-IN SERVICES', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  if (customerProvider.activeTableId != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.restaurant_rounded, color: Color(0xFFD4AF37), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(customerProvider.activeTableName ?? 'Active Table', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('At: ${customerProvider.activeRestaurantName ?? 'Restaurant'}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: _showQrScannerSheet,
                            child: const Text('Change Table / Scan QR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onPressed: () {
                              // Re-open active menu
                              final found = restaurantProvider.restaurants.firstWhere(
                                (r) => r.id == customerProvider.activeRestaurantId,
                                orElse: () => restaurantProvider.restaurants.first,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RestaurantMenuScreen(restaurant: found),
                                ),
                              );
                            },
                            child: const Text('OPEN MENU & ORDER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        )
                      ],
                    )
                  ] else ...[
                    Text('To view menus and place digital self-service orders from your table, you must scan your table\'s physical QR code.', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12, height: 1.5)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.black, size: 20),
                        label: const Text('SCAN PHYSICAL TABLE QR', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showQrScannerSheet,
                      ),
                    )
                  ]
                ],
              ),
            ),
          ],
          
          if (customerProvider.orderType != 'dine_in') ...[
            const SizedBox(height: 32),

            // Nearby Restaurants Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NEARBY RESTAURANTS',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                if (restaurantProvider.isLoading)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37))),
              ],
            ),
            const SizedBox(height: 16),

            if (structuredRestaurants.isEmpty)
              Container(
                padding: const EdgeInsets.all(40),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.01),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.store_outlined, color: Colors.white24, size: 48),
                    const SizedBox(height: 16),
                    Text('No restaurants available within ${restaurantProvider.deliveryRadiusKm.toStringAsFixed(1)}km of your location.', style: const TextStyle(color: Colors.white38, fontSize: 14)),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: structuredRestaurants.length > _visibleCount 
                    ? _visibleCount 
                    : structuredRestaurants.length,
                itemBuilder: (context, index) {
                  final item = structuredRestaurants[index];
                  final RestaurantModel r = item['restaurant'];
                  final double? distance = item['distance'];

                  return InkWell(
                    onTap: () {
                      final orderType = customerProvider.orderType;
                      bool isAllowed = true;
                      String modeName = '';
                      
                      if (orderType == 'delivery') {
                        isAllowed = r.isDelivery;
                        modeName = 'Delivery';
                      } else if (orderType == 'takeaway') {
                        isAllowed = r.isTakeaway;
                        modeName = 'Takeaway';
                      } else if (orderType == 'dine_in') {
                        isAllowed = r.isDinein;
                        modeName = 'Dine-In';
                      }
                      
                      if (!isAllowed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${r.name} does not offer $modeName services.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RestaurantMenuScreen(restaurant: r),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.1)),
                                ),
                                child: (r.logo != null && r.logo!.isNotEmpty)
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.network(
                                          ApiConstants.storageUrl + r.logo!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Icon(
                                            Icons.storefront_rounded,
                                            color: const Color(0xFFD4AF37).withOpacity(0.7),
                                            size: 30,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.storefront_rounded,
                                        color: const Color(0xFFD4AF37).withOpacity(0.7),
                                        size: 30,
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: _buildDietaryBadge(r),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD4AF37).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.directions_rounded, size: 12, color: Color(0xFFD4AF37)),
                                              const SizedBox(width: 4),
                                              Text(
                                                distance != null 
                                                    ? '${distance.toStringAsFixed(1)} km'
                                                    : 'N/A km',
                                                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      r.name,
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      r.address ?? 'No address provided',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1), height: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _buildServiceBadge('DELIVERY', r.isDelivery),
                              const SizedBox(width: 8),
                              _buildServiceBadge('TAKEAWAY', r.isTakeaway),
                              const SizedBox(width: 8),
                              _buildServiceBadge('DINE-IN', r.isDinein),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (_isLoadingMore)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Loading more nearby kitchens...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceBadge(String name, bool isEnabled) {
    IconData iconData;
    if (name == 'DELIVERY') {
      iconData = Icons.moped_rounded;
    } else if (name == 'TAKEAWAY') {
      iconData = Icons.shopping_bag_rounded;
    } else {
      iconData = Icons.restaurant_rounded;
    }

    return Container(
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFFD4AF37).withOpacity(0.08) : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEnabled ? const Color(0xFFD4AF37).withOpacity(0.2) : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1.2,
        ),
      ),
      child: Tooltip(
        message: name,
        child: Icon(
          iconData,
          size: 20,
          color: isEnabled ? const Color(0xFFD4AF37) : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }

  Widget _buildDietaryBadge(RestaurantModel r) {
    List<Widget> badges = [];

    Widget buildSquareBadge(Color color) {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: color, width: 1.2),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    if (r.isVeg) {
      badges.add(buildSquareBadge(Colors.green));
    }
    if (r.isNonveg) {
      badges.add(buildSquareBadge(Colors.red));
    }
    if (r.isJain) {
      badges.add(buildSquareBadge(Colors.purple));
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: badges,
    );
  }
}
