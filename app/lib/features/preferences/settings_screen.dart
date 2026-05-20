import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Takeaway Controllers
  final _tkPackingController = TextEditingController();
  final _tkServiceController = TextEditingController();
  
  // Delivery Controllers
  final _dlDeliveryController = TextEditingController();
  final _dlPackingController = TextEditingController();
  final _dlServiceController = TextEditingController();
  
  // Dine-in Controllers
  final _diPackingController = TextEditingController();
  final _diServiceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  void _loadSettings() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<SettingsProvider>(context, listen: false);
    await provider.fetchSettings(auth.token!);
    
    _tkPackingController.text = provider.takeawayPackingAmount;
    _tkServiceController.text = provider.takeawayServiceAmount;
    
    _dlDeliveryController.text = provider.deliveryDeliveryAmount;
    _dlPackingController.text = provider.deliveryPackingAmount;
    _dlServiceController.text = provider.deliveryServiceAmount;
    
    _diPackingController.text = provider.dineinPackingAmount;
    _diServiceController.text = provider.dineinServiceAmount;
  }

  @override
  void dispose() {
    _tkPackingController.dispose();
    _tkServiceController.dispose();
    _dlDeliveryController.dispose();
    _dlPackingController.dispose();
    _dlServiceController.dispose();
    _diPackingController.dispose();
    _diServiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
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
            const Text(
              'General Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            
            Expanded(
              child: Consumer<SettingsProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.settings.isEmpty) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                  }

                  return ListView(
                    children: [
                      _buildSettingsSection(
                        title: 'Localization',
                        children: [
                          _buildDropdownSetting(
                            title: 'Currency',
                            subtitle: 'Default currency for all transactions and bills.',
                            value: provider.currency,
                            icon: Icons.payments_rounded,
                            items: [
                              {'label': 'Indian Rupee (₹)', 'value': 'INR'},
                              {'label': 'US Dollar (\$)', 'value': 'USD'},
                              {'label': 'Euro (€)', 'value': 'EUR'},
                              {'label': 'British Pound (£)', 'value': 'GBP'},
                            ],
                            onChanged: (val) async {
                              if (val != null) {
                                final auth = Provider.of<AuthProvider>(context, listen: false);
                                await provider.updateSettings(auth.token!, {'currency': val});
                              }
                            },
                          ),
                        ],
                      ),

                      _buildSettingsSection(
                        title: 'Dine-in Order Charges',
                        children: [
                          _buildToggleSetting(
                            title: 'Packing Charges',
                            subtitle: 'Packaging fee for leftover packing.',
                            value: provider.dineinPackingEnabled,
                            amountController: _diPackingController,
                            icon: Icons.inventory_2_outlined,
                            onToggle: (val) => _updateSetting('dinein_packing_enabled', val ? 'yes' : 'no'),
                            onAmountChanged: (val) => _updateSetting('dinein_packing_amount', val),
                          ),
                          _buildToggleSetting(
                            title: 'Service Charges',
                            subtitle: 'Service fee for table service.',
                            value: provider.dineinServiceEnabled,
                            amountController: _diServiceController,
                            icon: Icons.room_service_outlined,
                            onToggle: (val) => _updateSetting('dinein_service_enabled', val ? 'yes' : 'no'),
                            onAmountChanged: (val) => _updateSetting('dinein_service_amount', val),
                          ),
                        ],
                      ),

                      _buildSettingsSection(
                        title: 'Takeaway Order Charges',
                        children: [
                          _buildToggleSetting(
                            title: 'Packing Charges',
                            subtitle: 'Charges for takeaway packaging.',
                            value: provider.takeawayPackingEnabled,
                            amountController: _tkPackingController,
                            icon: Icons.inventory_2_outlined,
                            onToggle: (val) => _updateSetting('takeaway_packing_enabled', val ? 'yes' : 'no'),
                            onAmountChanged: (val) => _updateSetting('takeaway_packing_amount', val),
                          ),
                          _buildToggleSetting(
                            title: 'Service Charges',
                            subtitle: 'Service fee for takeaway orders.',
                            value: provider.takeawayServiceEnabled,
                            amountController: _tkServiceController,
                            icon: Icons.room_service_outlined,
                            onToggle: (val) => _updateSetting('takeaway_service_enabled', val ? 'yes' : 'no'),
                            onAmountChanged: (val) => _updateSetting('takeaway_service_amount', val),
                          ),
                        ],
                      ),

                      _buildSettingsSection(
                        title: 'Delivery Order Charges',
                        children: [
                          _buildToggleSetting(
                            title: 'Delivery Charges',
                            subtitle: 'Flat delivery fee.',
                            value: provider.deliveryDeliveryEnabled,
                            amountController: _dlDeliveryController,
                            icon: Icons.delivery_dining_rounded,
                            onToggle: (val) => _updateSetting('delivery_delivery_enabled', val ? 'yes' : 'no'),
                            onAmountChanged: (val) => _updateSetting('delivery_delivery_amount', val),
                          ),
                          _buildToggleSetting(
                            title: 'Packing Charges',
                            subtitle: 'Packaging fee for delivery.',
                            value: provider.deliveryPackingEnabled,
                            amountController: _dlPackingController,
                            icon: Icons.inventory_2_outlined,
                            onToggle: (val) => _updateSetting('delivery_packing_enabled', val ? 'yes' : 'no'),
                            onAmountChanged: (val) => _updateSetting('delivery_packing_amount', val),
                          ),
                          _buildToggleSetting(
                            title: 'Service Charges',
                            subtitle: 'Service fee for delivery orders.',
                            value: provider.deliveryServiceEnabled,
                            amountController: _dlServiceController,
                            icon: Icons.room_service_outlined,
                            onToggle: (val) => _updateSetting('delivery_service_enabled', val ? 'yes' : 'no'),
                            onAmountChanged: (val) => _updateSetting('delivery_service_amount', val),
                          ),
                        ],
                      ),

                      _buildSettingsSection(
                        title: 'Payment Methods',
                        children: [
                          _buildSimpleToggleSetting(
                            title: 'Cash on Delivery (COD)',
                            subtitle: 'Enable or disable cash payments on delivery.',
                            value: provider.codEnabled,
                            icon: Icons.money_rounded,
                            onToggle: (val) => _updateSetting('cod_enabled', val ? 'yes' : 'no'),
                          ),
                          _buildSimpleToggleSetting(
                            title: 'Online Payment',
                            subtitle: 'Enable or disable online payments (Razorpay).',
                            value: provider.onlinePaymentEnabled,
                            icon: Icons.payment_rounded,
                            onToggle: (val) => _updateSetting('online_payment_enabled', val ? 'yes' : 'no'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateSetting(String key, String value) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<SettingsProvider>(context, listen: false);
    await provider.updateSettings(auth.token!, {key: value});
  }

  Widget _buildSettingsSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildTextFieldSetting({
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 200,
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Enter $title',
                hintStyle: const TextStyle(color: Colors.white12),
                filled: true,
                fillColor: const Color(0xFF0F1115),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required bool value,
    required TextEditingController amountController,
    required IconData icon,
    required Function(bool) onToggle,
    required Function(String) onAmountChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          if (value) ...[
            SizedBox(
              width: 100,
              child: TextField(
                controller: amountController,
                onChanged: onAmountChanged,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Amount',
                  hintStyle: const TextStyle(color: Colors.white12),
                  filled: true,
                  fillColor: const Color(0xFF0F1115),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Switch(
            value: value,
            onChanged: onToggle,
            activeThumbColor: const Color(0xFFD4AF37),
            activeTrackColor: const Color(0xFFD4AF37).withOpacity(0.3),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1115),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.any((i) => i['value'] == value) ? value : items.first['value'],
                dropdownColor: const Color(0xFF16181D),
                items: items.map((item) => DropdownMenuItem(
                  value: item['value'],
                  child: Text(item['label']!, style: const TextStyle(color: Colors.white, fontSize: 13)),
                )).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleToggleSetting({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Switch(
            value: value,
            onChanged: onToggle,
            activeThumbColor: const Color(0xFFD4AF37),
            activeTrackColor: const Color(0xFFD4AF37).withOpacity(0.3),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
          ),
        ],
      ),
    );
  }
}
