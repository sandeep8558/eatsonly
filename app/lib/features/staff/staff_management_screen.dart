import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/auth_provider.dart';
import '../../core/staff_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/role_provider.dart';
import '../../models/staff_model.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  String? _selectedRestaurantId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.token != null) {
        Provider.of<StaffProvider>(context, listen: false).fetchStaff(auth.token!);
        Provider.of<RestaurantProvider>(context, listen: false).fetchRestaurants(auth.token!, myRestaurants: true).then((_) {
          final restos = Provider.of<RestaurantProvider>(context, listen: false).restaurants;
          if (restos.isNotEmpty && _selectedRestaurantId == null) {
            // No default selection, show all by default or first one?
            // User said "add filter", usually default is "All" or first.
            // Let's keep it null for "All" initially.
          }
        });
        Provider.of<RoleProvider>(context, listen: false).fetchRoles(auth.token!);
      }
    });
  }

  void _showStaffForm({StaffModel? staff}) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final restoProvider = Provider.of<RestaurantProvider>(context, listen: false);
    final roleProvider = Provider.of<RoleProvider>(context, listen: false);

    final nameController = TextEditingController(text: staff?.name);
    final emailController = TextEditingController(text: staff?.email);
    final mobileController = TextEditingController(text: staff?.mobile);
    
    List<String> selectedRoles = List<String>.from(staff?.roles ?? ['staff']);
    String? selectedRestoId = staff?.restaurantId ?? 
        (restoProvider.restaurants.isNotEmpty ? restoProvider.restaurants.first.id : null);

    bool isExistingUser = staff != null;
    bool isSearching = false;
    Timer? searchDebounce;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          
          void onSearch(String value) {
            if (searchDebounce?.isActive ?? false) searchDebounce!.cancel();
            if (value.isEmpty) return;

            searchDebounce = Timer(const Duration(milliseconds: 600), () async {
              setDialogState(() => isSearching = true);
              final result = await staffProvider.checkUserExists(auth.token!, value);
              setDialogState(() {
                isSearching = false;
                if (result['success'] && result['exists']) {
                  isExistingUser = true;
                  nameController.text = result['data']['name'];
                  if (emailController.text.isEmpty) emailController.text = result['data']['email'];
                  if (mobileController.text.isEmpty) mobileController.text = result['data']['mobile'];
                } else {
                  isExistingUser = false;
                }
              });
            });
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Text(
                  staff == null ? 'Invite Staff' : 'Edit Staff',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (isSearching) ...[
                  const SizedBox(width: 12),
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37))),
                ]
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (staff == null) ...[
                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: onSearch,
                      decoration: _inputDecoration('Email Address', Icons.email_outlined),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: mobileController,
                      style: const TextStyle(color: Colors.white),
                      onChanged: onSearch,
                      decoration: _inputDecoration('Mobile Number', Icons.phone_android),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  if (!isExistingUser || staff != null) ...[
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Full Name', Icons.person_outline),
                    ),
                    const SizedBox(height: 16),
                  ] else if (isExistingUser && staff == null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFFD4AF37), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('USER FOUND', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold)),
                                Text(nameController.text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  DropdownButtonFormField<String>(
                    initialValue: selectedRestoId,
                    dropdownColor: const Color(0xFF1A1A1A),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Assign to Restaurant', Icons.storefront),
                    items: restoProvider.restaurants.map((r) => DropdownMenuItem(
                      value: r.id,
                      child: Text(r.name),
                    )).toList(),
                    onChanged: (val) => setDialogState(() => selectedRestoId = val),
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'SELECT ROLES',
                    style: TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  selectedRestoId == null
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFFD4AF37), size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Please assign a restaurant above first to select roles.',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      )
                    : roleProvider.isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
                      : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: roleProvider.roles.where((roleObj) => roleObj['name'] != 'customer' && roleObj['name'] != 'admin').map((roleObj) {
                      final role = roleObj['name'];
                      final isSelected = selectedRoles.contains(role);
                      return ChoiceChip(
                        label: Text(
                          roleObj['display_name'] ?? role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.black : Colors.white70,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setDialogState(() {
                            if (selected) {
                              selectedRoles.add(role);
                            } else {
                              if (selectedRoles.length > 1) {
                                selectedRoles.remove(role);
                              }
                            }
                          });
                        },
                        selectedColor: const Color(0xFFD4AF37),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFD4AF37) : Colors.white10,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final email = emailController.text.trim();
                  final mobile = mobileController.text.trim();
                  final name = nameController.text.trim();

                  if (email.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter an email address'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(email)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid email address'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  if (mobile.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a mobile number'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  if (mobile.length < 8) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid mobile number (at least 8 digits)'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter full name'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  if (selectedRestoId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please assign a restaurant'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  if (selectedRoles.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select at least one role'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  
                  bool success;
                  if (staff == null) {
                    success = await staffProvider.addStaff(
                      token: auth.token!,
                      name: nameController.text,
                      email: emailController.text,
                      mobile: mobileController.text,
                      roles: selectedRoles,
                      restaurantId: selectedRestoId!,
                    );
                  } else {
                    success = await staffProvider.updateStaff(
                      token: auth.token!,
                      userId: staff.id,
                      name: nameController.text,
                      roles: selectedRoles,
                      restaurantId: selectedRestoId!,
                    );
                  }

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(staff == null ? 'Invite Sent' : 'Updated Successfully')),
                    );
                  }
                },
                child: Text(staff == null ? 'Invite' : 'Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4AF37)),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }

  void _confirmDelete(StaffModel staff) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<StaffProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Remove Staff?', style: TextStyle(color: Colors.white)),
        content: Text('Remove ${staff.name} from ${staff.restaurantName}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await provider.removeStaff(auth.token!, staff.id, staff.restaurantId);
              if (success && mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Staff'),
        onPressed: () => _showStaffForm(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'STAFF & ROLES',
              style: TextStyle(
                color: Color(0xFFD4AF37),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                bool isNarrow = constraints.maxWidth < 450;
                
                Widget title = Text(
                  'Manage your team',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: isNarrow ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                );

                Widget filter = Consumer<RestaurantProvider>(
                  builder: (context, restoProvider, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: _selectedRestaurantId,
                          hint: const Text('All Restaurants', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          dropdownColor: const Color(0xFF1A1A1A),
                          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFD4AF37), size: 18),
                          isExpanded: isNarrow,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All Restaurants', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ),
                            ...restoProvider.restaurants.map((r) => DropdownMenuItem(
                              value: r.id,
                              child: Text(r.name, style: const TextStyle(color: Colors.white, fontSize: 12), overflow: TextOverflow.ellipsis),
                            )),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedRestaurantId = val);
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            Provider.of<StaffProvider>(context, listen: false).fetchStaff(auth.token!, restaurantId: val);
                          },
                        ),
                      ),
                    );
                  },
                );

                return isNarrow 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: filter),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        title,
                        filter,
                      ],
                    );
              },
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Consumer<StaffProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.staffList.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                  }

                  if (provider.staffList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, color: const Color(0xFFD4AF37).withOpacity(0.1), size: 100),
                          const SizedBox(height: 16),
                          const Text('No staff members added yet.', style: TextStyle(color: Colors.white54)),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: provider.staffList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final staff = provider.staffList[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
                              child: Text(
                                staff.name[0].toUpperCase(),
                                style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff.name,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: staff.roles.map((r) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
                                      ),
                                      child: Text(
                                        r.toUpperCase(),
                                        style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    )).toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.storefront, size: 12, color: Colors.white38),
                                      const SizedBox(width: 4),
                                      Text(
                                        staff.restaurantName,
                                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white38),
                                  onPressed: () => _showStaffForm(staff: staff),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                  onPressed: () => _confirmDelete(staff),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
