import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/inventory_provider.dart';
import '../../models/restaurant_model.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  RestaurantModel? _selectedRestaurant;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initData();
    });
  }

  void _initData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final restoProvider = Provider.of<RestaurantProvider>(context, listen: false);
    if (restoProvider.restaurants.isEmpty) {
      await restoProvider.fetchRestaurants(auth.token!, myRestaurants: true);
    }
  }

  void _refreshSuppliers() {
    if (_selectedRestaurant == null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<InventoryProvider>(context, listen: false).fetchSuppliers(
      auth.token!,
      _selectedRestaurant!.id,
      search: _searchController.text,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 650;
    final restoProvider = Provider.of<RestaurantProvider>(context);
    final invProvider = Provider.of<InventoryProvider>(context);

    final activeResto = restoProvider.selectedRestaurant ?? (restoProvider.restaurants.isNotEmpty ? restoProvider.restaurants.first : null);
    if (activeResto?.id != _selectedRestaurant?.id) {
      _selectedRestaurant = activeResto;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _refreshSuppliers();
      });
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: () async => _refreshSuppliers(),
        color: const Color(0xFFD4AF37),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(isSmall ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(restoProvider, isSmall),
              const SizedBox(height: 24),
              _buildControls(isSmall),
              const SizedBox(height: 24),
              invProvider.isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 60),
                        child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                      ),
                    )
                  : _buildSuppliersGrid(invProvider, isSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(RestaurantProvider restoProvider, bool isSmall) {
    final elements = [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'SUPPLIERS DIRECTORY',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Manage ingredient distributors and logistics contacts',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
      if (isSmall) const SizedBox(height: 16),
      Row(
        children: [
          ElevatedButton.icon(
            onPressed: () => _showAddSupplierSheet(context),
            icon: const Icon(Icons.person_add_rounded, size: 18, color: Colors.black),
            label: const Text('ADD SUPPLIER', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    ];

    if (isSmall) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: elements,
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: elements,
    );
  }
  Widget _buildControls(bool isSmall) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => _refreshSuppliers(),
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: 'Search suppliers, contact persons or phone numbers...',
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
        fillColor: const Color(0xFF16181D),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildSuppliersGrid(InventoryProvider provider, bool isSmall) {
    if (provider.suppliers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          children: const [
            Icon(Icons.storefront_rounded, size: 48, color: Colors.white24),
            SizedBox(height: 16),
            Text('No suppliers registered', style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Click "Add Supplier" to register your raw supply contractors.', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.suppliers.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isSmall ? 1.8 : 1.5,
          ),
          itemBuilder: (context, index) {
            final s = provider.suppliers[index];
            final String name = s['name'] ?? 'Unknown Co.';
            final String person = s['contact_person'] ?? 'Contact Person';
            final String phone = s['phone'] ?? '';
            final String email = s['email'] ?? '';
            final String address = s['address'] ?? 'No Address';

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16181D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contact: $person',
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Colors.white38, size: 18),
                            onPressed: () => _showEditSupplierSheet(context, s),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            onPressed: () => _confirmDelete(context, s),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(color: Colors.white38, fontSize: 11, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Divider(color: Colors.white10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (phone.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                          icon: const Icon(Icons.phone_rounded, color: Colors.greenAccent, size: 14),
                          label: Text(phone, style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      if (email.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => launchUrl(Uri.parse('mailto:$email')),
                          icon: const Icon(Icons.mail_outline_rounded, color: Colors.blueAccent, size: 14),
                          label: const Text('EMAIL', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAddSupplierSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final personCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Register New Supply Contractor', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Supplier Company Name', labelStyle: TextStyle(color: Colors.white38)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: personCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Contact Person Name', labelStyle: TextStyle(color: Colors.white38)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Mobile Phone', labelStyle: TextStyle(color: Colors.white38)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(color: Colors.white38)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Business Address', labelStyle: TextStyle(color: Colors.white38)),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company name is required')));
                        return;
                      }

                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final success = await Provider.of<InventoryProvider>(context, listen: false).addSupplier(
                        auth.token!,
                        {
                          'restaurant_id': _selectedRestaurant!.id,
                          'name': nameCtrl.text,
                          'contact_person': personCtrl.text,
                          'phone': phoneCtrl.text,
                          'email': emailCtrl.text,
                          'address': addressCtrl.text,
                        }
                      );

                      if (success && mounted) {
                        Navigator.pop(context);
                        _refreshSuppliers();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier registered successfully')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                    child: const Text('REGISTER SUPPLIER', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditSupplierSheet(BuildContext context, dynamic s) {
    final nameCtrl = TextEditingController(text: s['name']);
    final personCtrl = TextEditingController(text: s['contact_person'] ?? '');
    final phoneCtrl = TextEditingController(text: s['phone'] ?? '');
    final emailCtrl = TextEditingController(text: s['email'] ?? '');
    final addressCtrl = TextEditingController(text: s['address'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16181D),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Contractor details', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Supplier Company Name', labelStyle: TextStyle(color: Colors.white38)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: personCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Contact Person Name', labelStyle: TextStyle(color: Colors.white38)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Mobile Phone', labelStyle: TextStyle(color: Colors.white38)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(color: Colors.white38)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Business Address', labelStyle: TextStyle(color: Colors.white38)),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final success = await Provider.of<InventoryProvider>(context, listen: false).editSupplier(
                        auth.token!,
                        s['id'],
                        {
                          'name': nameCtrl.text,
                          'contact_person': personCtrl.text,
                          'phone': phoneCtrl.text,
                          'email': emailCtrl.text,
                          'address': addressCtrl.text,
                        }
                      );

                      if (success && mounted) {
                        Navigator.pop(context);
                        _refreshSuppliers();
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier details updated')));
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                    child: const Text('UPDATE DETAILS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, dynamic s) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF16181D),
          title: Text('Remove Supplier ${s['name']}?', style: const TextStyle(color: Colors.white)),
          content: const Text('This will permanently delete the supplier from the ledger directory.', style: TextStyle(color: Colors.white60)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: Colors.white38))),
            TextButton(
              onPressed: () async {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final success = await Provider.of<InventoryProvider>(context, listen: false).removeSupplier(
                  auth.token!,
                  s['id']
                );
                if (success && mounted) {
                  Navigator.pop(context);
                  _refreshSuppliers();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier removed')));
                }
              },
              child: const Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
