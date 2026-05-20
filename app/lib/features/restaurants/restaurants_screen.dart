import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/pdf_service.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/constants.dart';
import '../../models/restaurant_model.dart';
import '../../core/menu_provider.dart';

class RestaurantsScreen extends StatefulWidget {
  const RestaurantsScreen({super.key});

  @override
  State<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends State<RestaurantsScreen> {
  final _picker = ImagePicker();
  Uint8List? _selectedLogoBytes;
  String? _selectedLogoName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token != null) {
        Provider.of<RestaurantProvider>(context, listen: false).fetchRestaurants(auth.token!, myRestaurants: true);
        Provider.of<MenuProvider>(context, listen: false).fetchMenuCards(auth.token!);
      }
    });
  }

  Future<void> _pickLogo(StateSetter setDialogState) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setDialogState(() {
        _selectedLogoBytes = bytes;
        _selectedLogoName = image.name;
      });
    }
  }

  void _showRestaurantForm({RestaurantModel? restaurant}) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    
    final nameController = TextEditingController(text: restaurant?.name);
    final slugController = TextEditingController(text: restaurant?.slug);
    final addressController = TextEditingController(text: restaurant?.address);
    final latitudeController = TextEditingController(text: restaurant?.latitude?.toString() ?? '');
    final longitudeController = TextEditingController(text: restaurant?.longitude?.toString() ?? '');
    bool isDelivery = restaurant?.isDelivery ?? true;
    bool isTakeaway = restaurant?.isTakeaway ?? true;
    bool isDinein = restaurant?.isDinein ?? true;
    _selectedLogoBytes = null;
    _selectedLogoName = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            restaurant == null ? 'Add Restaurant' : 'Edit Base Info',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _pickLogo(setDialogState),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: _selectedLogoBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.memory(_selectedLogoBytes!, fit: BoxFit.cover),
                            )
                          : (restaurant?.logo != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    ApiConstants.storageUrl + restaurant!.logo!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(Icons.add_a_photo_outlined, color: Color(0xFFD4AF37)),
                                  ),
                                )
                              : const Icon(Icons.add_a_photo_outlined, color: Color(0xFFD4AF37), size: 30)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Tap to upload logo', style: TextStyle(color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Restaurant Name', Icons.storefront),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: slugController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Identifier (Slug)', Icons.link),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Address', Icons.location_on_outlined),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Latitude', Icons.location_searching_rounded),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration('Longitude', Icons.location_searching_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFFD4AF37)),
                    label: const Text('Get Current Location', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      bool serviceEnabled;
                      LocationPermission permission;

                      serviceEnabled = await Geolocator.isLocationServiceEnabled();
                      if (!serviceEnabled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location services are disabled.')),
                        );
                        return;
                      }

                      permission = await Geolocator.checkPermission();
                      if (permission == LocationPermission.denied) {
                        permission = await Geolocator.requestPermission();
                        if (permission == LocationPermission.denied) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Location permissions are denied.')),
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
                        Position position = await Geolocator.getCurrentPosition(
                          desiredAccuracy: LocationAccuracy.high
                        );
                        setDialogState(() {
                          latitudeController.text = position.latitude.toString();
                          longitudeController.text = position.longitude.toString();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location fetched successfully!'), backgroundColor: Colors.green),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error fetching location: $e')),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('SERVICES OFFERED', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                        Switch(
                          value: isDelivery,
                          onChanged: (val) => setDialogState(() => isDelivery = val),
                          activeThumbColor: const Color(0xFFD4AF37),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Takeaway', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                        Switch(
                          value: isTakeaway,
                          onChanged: (val) => setDialogState(() => isTakeaway = val),
                          activeThumbColor: const Color(0xFFD4AF37),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Dine-in', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
                        Switch(
                          value: isDinein,
                          onChanged: (val) => setDialogState(() => isDinein = val),
                          activeThumbColor: const Color(0xFFD4AF37),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
              onPressed: () async {
                bool success;
                if (restaurant == null) {
                  success = await provider.addRestaurant(
                    auth.token!,
                    nameController.text,
                    addressController.text,
                    slug: slugController.text.isNotEmpty ? slugController.text : null,
                    logoBytes: _selectedLogoBytes?.toList(),
                    logoName: _selectedLogoName,
                    latitude: double.tryParse(latitudeController.text),
                    longitude: double.tryParse(longitudeController.text),
                    isDelivery: isDelivery,
                    isTakeaway: isTakeaway,
                    isDinein: isDinein,
                  );
                } else {
                  success = await provider.editRestaurant(
                    auth.token!,
                    restaurant.id,
                    nameController.text,
                    addressController.text,
                    slug: slugController.text.isNotEmpty ? slugController.text : null,
                    logoBytes: _selectedLogoBytes?.toList(),
                    logoName: _selectedLogoName,
                    latitude: double.tryParse(latitudeController.text),
                    longitude: double.tryParse(longitudeController.text),
                    isDelivery: isDelivery,
                    isTakeaway: isTakeaway,
                    isDinein: isDinein,
                    // Preserve other fields
                    upiId: restaurant.upiId,
                    takeawayMenuCardId: restaurant.takeawayMenuCardId,
                    deliveryMenuCardId: restaurant.deliveryMenuCardId,
                    isVeg: restaurant.isVeg,
                    isNonveg: restaurant.isNonveg,
                    isJain: restaurant.isJain,
                    taxName: restaurant.taxName,
                    taxRegistrationNumber: restaurant.taxRegistrationNumber,
                    fssaiNumber: restaurant.fssaiNumber,
                  );
                }
                if (success && mounted) Navigator.pop(context);
              },
              child: Text(restaurant == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37))),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }

  void _confirmDelete(RestaurantModel restaurant) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Delete Restaurant?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await provider.removeRestaurant(auth.token!, restaurant.id);
              if (success && mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37),
        onPressed: () {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final provider = Provider.of<RestaurantProvider>(context, listen: false);
          final outletsAllowed = auth.user?.subscription?.outletsAllowed ?? 1;
          
          if (provider.restaurants.length >= outletsAllowed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('You have reached your limit of $outletsAllowed outlets. Please upgrade your plan to add more.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          
          _showRestaurantForm();
        },
        child: const Icon(Icons.add_business_rounded, color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('MY RESTAURANTS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text('Manage your outlets', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Consumer<RestaurantProvider>(
                    builder: (context, provider, _) {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final allowed = auth.user?.subscription?.outletsAllowed ?? 1;
                      final current = provider.restaurants.length;
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: current >= allowed ? Colors.red.withOpacity(0.1) : const Color(0xFFD4AF37).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: current >= allowed ? Colors.red.withOpacity(0.5) : const Color(0xFFD4AF37).withOpacity(0.3)
                          )
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              current >= allowed ? Icons.warning_amber_rounded : Icons.storefront_rounded,
                              size: 14,
                              color: current >= allowed ? Colors.redAccent : const Color(0xFFD4AF37),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$current / $allowed Allowed',
                              style: TextStyle(
                                color: current >= allowed ? Colors.redAccent : const Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Consumer<RestaurantProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading && provider.restaurants.isEmpty) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                    if (provider.restaurants.isEmpty) return const Center(child: Text('No restaurants yet.', style: TextStyle(color: Colors.white54)));
  
                    return ListView.separated(
                      itemCount: provider.restaurants.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        return RestaurantCard(
                          restaurant: provider.restaurants[index],
                          onEdit: () => _showRestaurantForm(restaurant: provider.restaurants[index]),
                          onDelete: () => _confirmDelete(provider.restaurants[index]),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RestaurantCard extends StatefulWidget {
  final RestaurantModel restaurant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  bool _isExpanded = false;
  late TextEditingController _upiController;
  late TextEditingController _taxNameController;
  late TextEditingController _taxRegController;
  late TextEditingController _fssaiController;
  late TextEditingController _billPrinterIpController;
  late TextEditingController _billPrinterPortController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late bool _isDelivery;
  late bool _isTakeaway;
  late bool _isDinein;
  late bool _isVeg;
  late bool _isNonveg;
  late bool _isJain;
  String? _takeawayMenuCardId;
  String? _deliveryMenuCardId;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(RestaurantCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.restaurant.isDelivery != widget.restaurant.isDelivery ||
        oldWidget.restaurant.isTakeaway != widget.restaurant.isTakeaway ||
        oldWidget.restaurant.isDinein != widget.restaurant.isDinein ||
        oldWidget.restaurant.name != widget.restaurant.name ||
        oldWidget.restaurant.address != widget.restaurant.address) {
      _initControllers();
    }
  }

  void _initControllers() {
    _upiController = TextEditingController(text: widget.restaurant.upiId);
    _taxNameController = TextEditingController(text: widget.restaurant.taxName);
    _taxRegController = TextEditingController(text: widget.restaurant.taxRegistrationNumber);
    _fssaiController = TextEditingController(text: widget.restaurant.fssaiNumber);
    _latitudeController = TextEditingController(text: widget.restaurant.latitude?.toString() ?? '');
    _longitudeController = TextEditingController(text: widget.restaurant.longitude?.toString() ?? '');
    _isDelivery = widget.restaurant.isDelivery;
    _isTakeaway = widget.restaurant.isTakeaway;
    _isDinein = widget.restaurant.isDinein;
    _billPrinterIpController = TextEditingController(text: widget.restaurant.billPrinterIp);
    _billPrinterPortController = TextEditingController(text: widget.restaurant.billPrinterPort.toString());
    _isVeg = widget.restaurant.isVeg;
    _isNonveg = widget.restaurant.isNonveg;
    _isJain = widget.restaurant.isJain;
    _takeawayMenuCardId = widget.restaurant.takeawayMenuCardId;
    _deliveryMenuCardId = widget.restaurant.deliveryMenuCardId;
  }

  @override
  void dispose() {
    _upiController.dispose();
    _taxNameController.dispose();
    _taxRegController.dispose();
    _fssaiController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _billPrinterIpController.dispose();
    _billPrinterPortController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied.')),
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
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location fetched successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching location: $e')),
      );
    }
  }

  Future<void> _saveFastServiceToggle() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<RestaurantProvider>(context, listen: false);
    
    final success = await provider.editRestaurant(
      auth.token!,
      widget.restaurant.id,
      widget.restaurant.name,
      widget.restaurant.address ?? '',
      slug: widget.restaurant.slug,
      upiId: _upiController.text,
      taxName: _taxNameController.text,
      taxRegistrationNumber: _taxRegController.text,
      fssaiNumber: _fssaiController.text,
      latitude: double.tryParse(_latitudeController.text),
      longitude: double.tryParse(_longitudeController.text),
      isDelivery: _isDelivery,
      isTakeaway: _isTakeaway,
      isDinein: _isDinein,
      billPrinterIp: _billPrinterIpController.text,
      billPrinterPort: int.tryParse(_billPrinterPortController.text) ?? 9100,
      takeawayMenuCardId: _takeawayMenuCardId,
      deliveryMenuCardId: _deliveryMenuCardId,
      isVeg: _isVeg,
      isNonveg: _isNonveg,
      isJain: _isJain,
    );
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Services updated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showRestaurantQRDialog(BuildContext context, RestaurantModel restaurant) {
    // Construct the public menu URL
    final String slug = restaurant.name.toLowerCase().replaceAll(' ', '-');
    final String url = "https://eatsonly.com/m/$slug";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16181D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('${restaurant.name} Counter QR Code', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            SizedBox(
              width: 200,
              height: 200,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(url, style: const TextStyle(color: Colors.white24, fontSize: 10), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text(
              'Customers can scan this Counter QR to view the digital menu and place pre-orders natively inside the EatsOnly app.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final pdfService = PdfService();
              pdfService.generateQrPdf(
                restaurantName: restaurant.name,
                tableName: 'Takeaway Counter',
                url: url,
              );
            },
            icon: const Icon(Icons.picture_as_pdf, size: 16),
            label: const Text('Download PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
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
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              bool isSmall = constraints.maxWidth < 450;
              
              Widget actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(_isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_rounded, color: Color(0xFFD4AF37), size: 20),
                    tooltip: 'Restaurant Counter QR',
                    onPressed: () => _showRestaurantQRDialog(context, widget.restaurant),
                  ),
                  IconButton(icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), size: 20), onPressed: widget.onEdit),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: widget.onDelete),
                ],
              );

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                          child: (widget.restaurant.logo != null)
                              ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(ApiConstants.storageUrl + widget.restaurant.logo!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.store, color: Color(0xFFD4AF37))))
                              : const Icon(Icons.store, color: Color(0xFFD4AF37), size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.restaurant.name, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(height: 4),
                              Text(widget.restaurant.address ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 12)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildFastToggle('Delivery', _isDelivery, (val) async {
                                    setState(() => _isDelivery = val);
                                    await _saveFastServiceToggle();
                                  }),
                                  _buildFastToggle('Takeaway', _isTakeaway, (val) async {
                                    setState(() => _isTakeaway = val);
                                    await _saveFastServiceToggle();
                                  }),
                                  _buildFastToggle('Dine-in', _isDinein, (val) async {
                                    setState(() => _isDinein = val);
                                    await _saveFastServiceToggle();
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!isSmall) actions,
                      ],
                    ),
                  ),
                  if (isSmall) ...[
                    const Divider(color: Colors.white10, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          actions,
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                  const Text('DETAILED CONFIGURATION', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 20),
                  _buildDetailField('UPI ID', Icons.qr_code_scanner, _upiController),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isSmall = constraints.maxWidth < 400;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isSmall) ...[
                            _buildDetailField('Tax Name', Icons.label_important_outline, _taxNameController),
                            const SizedBox(height: 16),
                            _buildDetailField('Tax Reg No', Icons.assignment_ind_outlined, _taxRegController),
                          ] else
                            Row(
                              children: [
                                Expanded(child: _buildDetailField('Tax Name', Icons.label_important_outline, _taxNameController)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildDetailField('Tax Reg No', Icons.assignment_ind_outlined, _taxRegController)),
                              ],
                            ),
                          const SizedBox(height: 16),
                          _buildDetailField('FSSAI Number', Icons.verified_user_outlined, _fssaiController),
                          const SizedBox(height: 24),
                          const Text('GEOLOCATION CONFIGURATION', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildDetailField('Latitude', Icons.location_searching_rounded, _latitudeController)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildDetailField('Longitude', Icons.location_searching_rounded, _longitudeController)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFFD4AF37)),
                              label: const Text('Get Current Location', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _getCurrentLocation,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text('PRINTER CONFIGURATION', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(flex: 3, child: _buildDetailField('Bill Printer IP', Icons.print_rounded, _billPrinterIpController)),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: _buildDetailField('Port', Icons.numbers_rounded, _billPrinterPortController)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Consumer<MenuProvider>(
                            builder: (context, menuProvider, _) {
                              final items = menuProvider.menuCards.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList();
                              
                              if (isSmall) {
                                return Column(
                                  children: [
                                    _buildDetailDropdown('Takeaway Menu', Icons.shopping_bag_outlined, _takeawayMenuCardId, items, (val) => setState(() => _takeawayMenuCardId = val)),
                                    const SizedBox(height: 16),
                                    _buildDetailDropdown('Delivery Menu', Icons.delivery_dining_outlined, _deliveryMenuCardId, items, (val) => setState(() => _deliveryMenuCardId = val)),
                                  ],
                                );
                              }
                              
                              return Row(
                                children: [
                                  Expanded(child: _buildDetailDropdown('Takeaway Menu', Icons.shopping_bag_outlined, _takeawayMenuCardId, items, (val) => setState(() => _takeawayMenuCardId = val))),
                                  const SizedBox(width: 16),
                                  Expanded(child: _buildDetailDropdown('Delivery Menu', Icons.delivery_dining_outlined, _deliveryMenuCardId, items, (val) => setState(() => _deliveryMenuCardId = val))),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.02),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Column(
                              children: [
                                _buildDietaryTile('Veg', Colors.green, _isVeg, (val) => setState(() => _isVeg = val)),
                                Divider(color: Colors.white.withOpacity(0.05), height: 1),
                                _buildDietaryTile('Non-Veg', Colors.redAccent, _isNonveg, (val) => setState(() => _isNonveg = val)),
                                Divider(color: Colors.white.withOpacity(0.05), height: 1),
                                _buildDietaryTile('Jain', Colors.purpleAccent, _isJain, (val) => setState(() => _isJain = val)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        final provider = Provider.of<RestaurantProvider>(context, listen: false);
                        final success = await provider.editRestaurant(
                          auth.token!,
                          widget.restaurant.id,
                          widget.restaurant.name,
                          widget.restaurant.address ?? '',
                          slug: widget.restaurant.slug,
                          upiId: _upiController.text,
                          taxName: _taxNameController.text,
                          taxRegistrationNumber: _taxRegController.text,
                          fssaiNumber: _fssaiController.text,
                          latitude: double.tryParse(_latitudeController.text),
                          longitude: double.tryParse(_longitudeController.text),
                          isDelivery: _isDelivery,
                          isTakeaway: _isTakeaway,
                          isDinein: _isDinein,
                          billPrinterIp: _billPrinterIpController.text,
                          billPrinterPort: int.tryParse(_billPrinterPortController.text) ?? 9100,
                          takeawayMenuCardId: _takeawayMenuCardId,
                          deliveryMenuCardId: _deliveryMenuCardId,
                          isVeg: _isVeg,
                          isNonveg: _isNonveg,
                          isJain: _isJain,
                        );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Details saved successfully'), backgroundColor: Colors.green),
                          );
                          setState(() => _isExpanded = false);
                        }
                      },
                      child: const Text('Save Detailed Config', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailField(String label, IconData icon, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37).withOpacity(0.7), size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  Widget _buildDetailDropdown(String label, IconData icon, String? value, List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: items.any((i) => i.value == value) ? value : null,
      onChanged: onChanged,
      dropdownColor: Theme.of(context).colorScheme.surface,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37).withOpacity(0.7), size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      items: items,
    );
  }

  Widget _buildDietaryTile(String label, Color color, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14)),
      value: value,
      onChanged: onChanged,
      activeThumbColor: color,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildFastToggle(String label, bool value, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? const Color(0xFFD4AF37).withOpacity(0.2) : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: value ? const Color(0xFFD4AF37) : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 32,
            height: 20,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: const Color(0xFFD4AF37),
                activeTrackColor: const Color(0xFFD4AF37).withOpacity(0.2),
                inactiveThumbColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                inactiveTrackColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
