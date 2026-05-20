import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/integration_provider.dart';

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _lastLoadedRestaurantId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final resto = Provider.of<RestaurantProvider>(context, listen: false);
    final integration = Provider.of<IntegrationProvider>(context, listen: false);

    if (auth.token != null && resto.selectedRestaurant != null) {
      final restaurantId = resto.selectedRestaurant!.id.toString();
      integration.fetchIntegrations(auth.token!, restaurantId);
      integration.fetchMenuMapping(auth.token!, restaurantId);
    }
  }

  void _showCredentialsDialog(String aggregator, Map<String, dynamic>? credentials) {
    showDialog(
      context: context,
      builder: (context) => CredentialFormDialog(aggregator: aggregator, credentials: credentials),
    ).then((_) => _loadData());
  }

  void _showMappingDialog(Map<String, dynamic> item, String aggregator) {
    showDialog(
      context: context,
      builder: (context) => ItemMappingDialog(item: item, aggregator: aggregator),
    ).then((_) => _loadData());
  }

  @override
  Widget build(BuildContext context) {
    final resto = Provider.of<RestaurantProvider>(context);
    final integration = Provider.of<IntegrationProvider>(context);

    // If the selected restaurant changed, automatically trigger load data!
    final selectedId = resto.selectedRestaurant?.id.toString();
    if (selectedId != _lastLoadedRestaurantId) {
      _lastLoadedRestaurantId = selectedId;
      if (selectedId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadData();
        });
      }
    }

    if (resto.selectedRestaurant == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.storefront_rounded, size: 64, color: Colors.white24),
              SizedBox(height: 16),
              Text(
                'Please select a restaurant context first.',
                style: TextStyle(color: Colors.white38),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PREFERENCES',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Delivery Integrations',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: _loadData,
                  tooltip: 'Refresh data',
                  icon: integration.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37)),
                        )
                      : const Icon(Icons.refresh_rounded, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Main Layout Row
            Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Active Connection Cards Row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isNarrow = constraints.maxWidth < 600;
                      if (isNarrow) {
                        return Column(
                          children: [
                            _buildIntegrationCard(
                              context,
                              'ZOMATO',
                              'Direct Food Aggregator Integration',
                              'assets/images/zomato.png',
                              integration.zomatoCredentials,
                              const Color(0xFFE23744),
                            ),
                            const SizedBox(height: 16),
                            _buildIntegrationCard(
                              context,
                              'SWIGGY',
                              'Direct Delivery Partner Sync',
                              'assets/images/swiggy.png',
                              integration.swiggyCredentials,
                              const Color(0xFFFC8019),
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: _buildIntegrationCard(
                              context,
                              'ZOMATO',
                              'Direct Food Aggregator Integration',
                              'assets/images/zomato.png',
                              integration.zomatoCredentials,
                              const Color(0xFFE23744),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _buildIntegrationCard(
                              context,
                              'SWIGGY',
                              'Direct Delivery Partner Sync',
                              'assets/images/swiggy.png',
                              integration.swiggyCredentials,
                              const Color(0xFFFC8019),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Tab navigation & Mapping search Bar
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      const Text(
                        'MENU ITEM DIRECT MAPPINGS',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search menu items...',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                            prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.02),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim().toLowerCase();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mappings List Panel
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.01),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: _buildMappingList(integration),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntegrationCard(
    BuildContext context,
    String name,
    String subtitle,
    String assetPath,
    Map<String, dynamic>? credentials,
    Color brandColor,
  ) {
    final bool isConnected = credentials != null && credentials['is_active'] == true;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isConnected ? brandColor.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              name == 'ZOMATO' ? Icons.restaurant_rounded : Icons.delivery_dining_rounded,
              color: brandColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.green.withOpacity(0.12) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isConnected ? 'CONNECTED' : 'DISCONNECTED',
                        style: TextStyle(
                          color: isConnected ? Colors.greenAccent : Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isConnected ? 'Merchant ID: ${credentials['merchant_id']}' : subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showCredentialsDialog(name.toLowerCase(), credentials),
                  icon: const Icon(Icons.settings_outlined, size: 16),
                  label: Text(isConnected ? 'Configure Keys' : 'Link Account'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConnected ? Colors.white.withOpacity(0.05) : const Color(0xFFD4AF37),
                    foregroundColor: isConnected ? Colors.white70 : Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMappingList(IntegrationProvider provider) {
    if (provider.isLoading && provider.menuItems.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }

    final filteredItems = provider.menuItems.where((item) {
      final name = item['name']?.toString().toLowerCase() ?? '';
      final category = item['category']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery) || category.contains(_searchQuery);
    }).toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.find_in_page_rounded, size: 48, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 16),
            const Text(
              'No menu items matched your search query.',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
      itemBuilder: (context, index) {
        final item = filteredItems[index];

        final zomatoMapping = item['zomato_mapping'];
        final swiggyMapping = item['swiggy_mapping'];

        final hasZomato = zomatoMapping != null;
        final hasSwiggy = swiggyMapping != null;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              // Local Item Detail
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          item['type'] == 'veg' ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: item['type'] == 'veg' ? Colors.green : Colors.redAccent,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'] ?? 'Item',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item['category']}  •  ₹${item['price']}',
                            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Zomato Mapping Panel
              Expanded(
                flex: 2,
                child: _buildAggregatorMappingBadge(
                  'zomato',
                  hasZomato,
                  zomatoMapping,
                  const Color(0xFFE23744),
                  () => _showMappingDialog(item, 'zomato'),
                ),
              ),

              // Swiggy Mapping Panel
              Expanded(
                flex: 2,
                child: _buildAggregatorMappingBadge(
                  'swiggy',
                  hasSwiggy,
                  swiggyMapping,
                  const Color(0xFFFC8019),
                  () => _showMappingDialog(item, 'swiggy'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAggregatorMappingBadge(
    String aggregator,
    bool mapped,
    dynamic mapping,
    Color brandColor,
    VoidCallback onMap,
  ) {
    return Row(
      children: [
        mapped
            ? Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ID: ${mapping['external_item_id']}',
                        style: TextStyle(color: brandColor, fontSize: 10, fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Synced Price: ₹${mapping['external_price']}',
                      style: const TextStyle(color: Colors.white30, fontSize: 10),
                    ),
                  ],
                ),
              )
            : const Expanded(
                child: Text(
                  'Unmapped',
                  style: TextStyle(color: Colors.white24, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onMap,
          icon: Icon(mapped ? Icons.edit_rounded : Icons.link_rounded, size: 18),
          color: mapped ? const Color(0xFFD4AF37) : Colors.white38,
          tooltip: mapped ? 'Edit Mapping' : 'Establish Link',
        ),
      ],
    );
  }
}

class CredentialFormDialog extends StatefulWidget {
  final String aggregator;
  final Map<String, dynamic>? credentials;

  const CredentialFormDialog({super.key, required this.aggregator, this.credentials});

  @override
  State<CredentialFormDialog> createState() => _CredentialFormDialogState();
}

class _CredentialFormDialogState extends State<CredentialFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantController;
  late TextEditingController _accessTokenController;
  late TextEditingController _refreshTokenController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.credentials?['merchant_id'] ?? '');
    _accessTokenController = TextEditingController(text: widget.credentials?['access_token'] ?? '');
    _refreshTokenController = TextEditingController(text: widget.credentials?['refresh_token'] ?? '');
    _isActive = widget.credentials?['is_active'] ?? true;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _accessTokenController.dispose();
    _refreshTokenController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.aggregator.toUpperCase();

    return Dialog(
      backgroundColor: const Color(0xFF16181D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Link $title Account',
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Merchant ID Field
              TextFormField(
                controller: _merchantController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _inputDecoration(widget.aggregator == 'zomato' ? 'Zomato Merchant ID' : 'Swiggy Outlet ID'),
                validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),

              // API Access Key
              TextFormField(
                controller: _accessTokenController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _inputDecoration('OAuth Access Token / App Key'),
              ),
              const SizedBox(height: 16),

              // Active Connection Toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Integration Connection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        SizedBox(height: 2),
                        Text('Accept automated orders on KDS', style: TextStyle(color: Colors.white30, fontSize: 10)),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      onChanged: (val) => setState(() => _isActive = val),
                      activeThumbColor: const Color(0xFFD4AF37),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save Connections', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final resto = Provider.of<RestaurantProvider>(context, listen: false);
    final provider = Provider.of<IntegrationProvider>(context, listen: false);

    final payload = {
      'restaurant_id': resto.selectedRestaurant!.id.toString(),
      'aggregator': widget.aggregator,
      'merchant_id': _merchantController.text.trim(),
      'access_token': _accessTokenController.text.trim(),
      'refresh_token': _refreshTokenController.text.trim(),
      'is_active': _isActive,
    };

    final success = await provider.saveCredentials(auth.token!, payload);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.aggregator.toUpperCase()} parameters updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'An error occurred.')),
        );
      }
    }
  }
}

class ItemMappingDialog extends StatefulWidget {
  final Map<String, dynamic> item;
  final String aggregator;

  const ItemMappingDialog({super.key, required this.item, required this.aggregator});

  @override
  State<ItemMappingDialog> createState() => _ItemMappingDialogState();
}

class _ItemMappingDialogState extends State<ItemMappingDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _externalIdController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    final mapping = widget.aggregator == 'zomato' ? widget.item['zomato_mapping'] : widget.item['swiggy_mapping'];
    _externalIdController = TextEditingController(text: mapping?['external_item_id'] ?? '');
    _priceController = TextEditingController(
      text: mapping?['external_price'] != null ? mapping['external_price'].toString() : widget.item['price'].toString(),
    );
  }

  @override
  void dispose() {
    _externalIdController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.03),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.aggregator.toUpperCase();

    return Dialog(
      backgroundColor: const Color(0xFF16181D),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Map Item to $title',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Mapping Local Item: "${widget.item['name']}"',
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
              const SizedBox(height: 24),

              // External ID
              TextFormField(
                controller: _externalIdController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: _inputDecoration('$title External Item ID / SKU'),
                validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
              ),
              const SizedBox(height: 16),

              // Sync Price
              TextFormField(
                controller: _priceController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration('$title Specialized Price (INR)'),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Required field';
                  if (double.tryParse(val) == null) return 'Must be a valid price number';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Map Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final resto = Provider.of<RestaurantProvider>(context, listen: false);
    final provider = Provider.of<IntegrationProvider>(context, listen: false);

    final payload = {
      'restaurant_id': resto.selectedRestaurant!.id.toString(),
      'menu_item_id': widget.item['id'].toString(),
      'aggregator': widget.aggregator,
      'external_item_id': _externalIdController.text.trim(),
      'external_price': double.parse(_priceController.text.trim()),
    };

    final success = await provider.mapItem(auth.token!, payload);

    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Menu mapping synchronized successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? 'An error occurred.')),
        );
      }
    }
  }
}
