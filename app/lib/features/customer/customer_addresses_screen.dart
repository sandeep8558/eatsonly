import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/auth_provider.dart';
import '../../core/customer_provider.dart';
import '../../core/settings_provider.dart';
import '../../services/address_service.dart';
import '../../core/widgets/main_layout.dart';
import 'customer_home_screen.dart';

class CustomerAddressesScreen extends StatefulWidget {
  const CustomerAddressesScreen({super.key});

  @override
  State<CustomerAddressesScreen> createState() => _CustomerAddressesScreenState();
}

class _CustomerAddressesScreenState extends State<CustomerAddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAddressesFromServer();
      _loadSettings();
    });
  }

  void _loadSettings() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token != null) {
      Provider.of<SettingsProvider>(context, listen: false).fetchSettings(auth.token!);
    }
  }

  void _loadAddressesFromServer() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.token != null) {
      Provider.of<CustomerProvider>(context, listen: false).fetchAddresses(auth.token!);
    }
  }

  void _openAddressForm({AddressModel? editingAddress}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddressFormSheet(
        editingAddress: editingAddress,
        onSaved: () {
          _loadAddressesFromServer();
        },
      ),
    );
  }

  // Edit helper for legacy offline mode
  void _editLegacyAddressDialog(BuildContext context, String currentVal, CustomerProvider provider) {
    final controller = TextEditingController(text: currentVal);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16181D),
          title: const Text('Edit Address', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 18)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Address Details',
              labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.05))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  provider.updateAddress(currentVal, controller.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Address updated!'), backgroundColor: Colors.green),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                foregroundColor: Colors.black,
              ),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    final bool useServer = auth.token != null;
    final List<dynamic> currentList = useServer ? customerProvider.apiAddresses : customerProvider.savedAddresses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add New Address Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add_location_alt_rounded, color: Colors.black, size: 20),
              label: const Text('Add New Address', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () => _openAddressForm(),
            ),
          ),
          const SizedBox(height: 28),

          // Saved Addresses Header
          Text(
            'SAVED ADDRESSES',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          if (currentList.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Icon(Icons.location_off_outlined, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2), size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'No saved addresses yet.\nTap "Add New Address" to get started.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentList.length,
              itemBuilder: (context, index) {
                final item = currentList[index];
                final String addressLabel = useServer ? (item as AddressModel).label : 'Address';
                final String addressText = useServer ? (item as AddressModel).address : item.toString();
                final bool isActive = useServer
                    ? (item as AddressModel).isDefault
                    : item.toString() == customerProvider.currentAddress;

                return InkWell(
                  onTap: () async {
                    if (useServer) {
                      await customerProvider.selectAddress(auth.token!, item as AddressModel);
                    } else {
                      customerProvider.selectSavedAddress(item.toString());
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Active address set to: $addressLabel'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFD4AF37).withOpacity(0.05)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFD4AF37).withOpacity(0.3)
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon + Label + Active badge row
                              Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive
                                          ? const Color(0xFFD4AF37)
                                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                                    ),
                                    child: Icon(
                                      isActive ? Icons.check_rounded : Icons.location_on_outlined,
                                      color: isActive ? Colors.black : Colors.white38,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD4AF37).withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      addressLabel.toUpperCase(),
                                      style: const TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                                      ),
                                      child: const Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                addressText,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                              if (useServer) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'GPS: [${(item as AddressModel).latitude.toStringAsFixed(5)}, ${item.longitude.toStringAsFixed(5)}]',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.22),
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Edit / Delete action row
                        Container(
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.edit_rounded, size: 14, color: Colors.white54),
                                  label: const Text('Edit', style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w600)),
                                  onPressed: () {
                                    if (useServer) {
                                      _openAddressForm(editingAddress: item as AddressModel);
                                    } else {
                                      _editLegacyAddressDialog(context, item.toString(), customerProvider);
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  ),
                                ),
                              ),
                              Container(width: 1, height: 28, color: Colors.white.withOpacity(0.06)),
                              Expanded(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.delete_rounded, size: 14, color: Colors.redAccent),
                                  label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                                  onPressed: () async {
                                    if (useServer) {
                                      await customerProvider.removeAddress(auth.token!, (item as AddressModel).id);
                                    } else {
                                      customerProvider.deleteAddress(item.toString());
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Address deleted successfully.')),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// ─── Add / Edit Address Bottom Sheet ────────────────────────────────────────

class _AddressFormSheet extends StatefulWidget {
  final AddressModel? editingAddress;
  final VoidCallback onSaved;

  const _AddressFormSheet({this.editingAddress, required this.onSaved});

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final MapController _mapController = MapController();
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();

  double? _latitude;
  double? _longitude;
  bool _showMap = false;
  bool _isFetchingGPS = false;
  bool _isSaving = false;

  bool get _canSave =>
      _labelController.text.trim().length >= 2 &&
      _streetController.text.trim().length >= 6 &&
      _latitude != null &&
      _longitude != null;

  @override
  void initState() {
    super.initState();
    if (widget.editingAddress != null) {
      final a = widget.editingAddress!;
      _labelController.text = a.label;
      _streetController.text = a.address;
      _latitude = a.latitude;
      _longitude = a.longitude;
    }
    _labelController.addListener(_onFieldChanged);
    _streetController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _labelController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentGPS() async {
    setState(() => _isFetchingGPS = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location service is disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permission denied.');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Location permission permanently denied.');

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _showMap = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS location captured!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isFetchingGPS = false);
    }
  }

  void _toggleMap() {
    setState(() {
      _showMap = !_showMap;
      if (_showMap && _latitude != null && _longitude != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(LatLng(_latitude!, _longitude!), 15.0);
        });
      }
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);

    try {
      if (auth.token != null) {
        if (widget.editingAddress != null) {
          await customerProvider.editAddress(
            auth.token!,
            widget.editingAddress!.id,
            _streetController.text.trim(),
            _latitude!,
            _longitude!,
            label: _labelController.text.trim(),
          );
        } else {
          await customerProvider.addAddress(
            auth.token!,
            _streetController.text.trim(),
            _latitude!,
            _longitude!,
            label: _labelController.text.trim(),
          );
        }
      } else {
        customerProvider.addSavedAddress('${_labelController.text.trim()}: ${_streetController.text.trim()}');
      }

      widget.onSaved();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingAddress != null ? 'Address updated!' : 'Address saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final isEditing = widget.editingAddress != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16181D),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      isEditing ? 'EDIT ADDRESS' : 'ADD NEW ADDRESS',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.white.withOpacity(0.06)),

              // Scrollable form
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                  children: [
                    // Label
                    _FormLabel(label: 'LABEL', icon: Icons.label_outline_rounded),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _labelController,
                      hint: 'e.g. Home, Work, Parents',
                      prefixIcon: Icons.bookmark_border_rounded,
                    ),
                    const SizedBox(height: 20),

                    // Street / Address
                    _FormLabel(label: 'STREET & ADDRESS', icon: Icons.home_outlined),
                    const SizedBox(height: 8),
                    _StyledTextField(
                      controller: _streetController,
                      hint: 'Street name, building, flat number…',
                      prefixIcon: Icons.location_city_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),

                    // GPS Coordinates Section
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GPS COORDINATES',
                                style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Required for delivery routing',
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        if (_latitude != null && _longitude != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 12),
                                SizedBox(width: 4),
                                Text('Set', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Two option buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: _isFetchingGPS
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2),
                                  )
                                : const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFFD4AF37)),
                            label: Text(
                              _isFetchingGPS ? 'Locating…' : 'Use Current GPS',
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            onPressed: _isFetchingGPS ? null : _useCurrentGPS,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: Icon(
                              _showMap ? Icons.map_rounded : Icons.map_outlined,
                              size: 16,
                              color: _showMap ? Colors.white : Colors.white54,
                            ),
                            label: Text(
                              _showMap ? 'Hide Map' : 'Set on Map',
                              style: TextStyle(
                                color: _showMap ? Colors.white : Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: _toggleMap,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white.withOpacity(_showMap ? 0.3 : 0.15)),
                              backgroundColor: _showMap ? Colors.white.withOpacity(0.05) : null,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Coordinate readout
                    if (_latitude != null && _longitude != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.07)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.pin_drop_rounded, color: Color(0xFFD4AF37), size: 16),
                            const SizedBox(width: 10),
                            Text(
                              'LAT: ${_latitude!.toStringAsFixed(6)}   LNG: ${_longitude!.toStringAsFixed(6)}',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 11,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Map picker
                    if (_showMap) ...[
                      const SizedBox(height: 14),
                      const Text(
                        'TAP ON MAP TO SET PIN',
                        style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          height: 240,
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter: LatLng(
                                _latitude ?? 12.9716,
                                _longitude ?? 77.5946,
                              ),
                              initialZoom: 14.0,
                              onTap: (tapPosition, latLng) {
                                setState(() {
                                  _latitude = latLng.latitude;
                                  _longitude = latLng.longitude;
                                });
                              },
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    "https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}&key=${settingsProvider.settings['google_maps_api_key'] ?? 'YOUR_GOOGLE_MAPS_API_KEY'}",
                                userAgentPackageName: 'com.eatsonly.app',
                              ),
                              if (_latitude != null && _longitude != null)
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: LatLng(_latitude!, _longitude!),
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.topCenter,
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFFD4AF37),
                                        size: 38,
                                        shadows: [Shadow(color: Colors.black54, offset: Offset(0, 3), blurRadius: 6)],
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                              )
                            : Icon(
                                isEditing ? Icons.edit_note_rounded : Icons.check_circle_outline_rounded,
                                color: _canSave ? Colors.black : Colors.black38,
                                size: 20,
                              ),
                        label: Text(
                          _isSaving ? 'Saving…' : (isEditing ? 'Update Address' : 'Save Address'),
                          style: TextStyle(
                            color: _canSave ? Colors.black : Colors.black38,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: _canSave && !_isSaving ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canSave ? const Color(0xFFD4AF37) : const Color(0xFFD4AF37).withOpacity(0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),

                    if (!_canSave) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          _latitude == null
                              ? 'Set GPS coordinates to enable saving'
                              : _labelController.text.trim().length < 2
                                  ? 'Enter a label (at least 2 characters)'
                                  : 'Enter a full street address (at least 6 characters)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Reusable Widgets ────────────────────────────────────────────────────────

class _FormLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FormLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
      ],
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final int maxLines;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13),
        prefixIcon: Icon(prefixIcon, color: Colors.white38, size: 18),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.03),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
      ),
    );
  }
}