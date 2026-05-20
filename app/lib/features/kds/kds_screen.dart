import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/kot_provider.dart';
import '../../core/kds_station_provider.dart';
import 'kds_stations_screen.dart';
import 'package:intl/intl.dart';

class KdsScreen extends StatefulWidget {
  const KdsScreen({super.key});

  @override
  State<KdsScreen> createState() => _KdsScreenState();
}

class _KdsScreenState extends State<KdsScreen> {
  bool _isAutoRefresh = true;
  Timer? _refreshTimer;
  String? _selectedStationId;
  String? _selectedStationName;

  @override
  void initState() {
    super.initState();
    _loadSelectedStation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchStations();
      _refreshKots();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSelectedStation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedStationId = prefs.getString('kds_station_id');
      _selectedStationName = prefs.getString('kds_station_name');
    });
  }

  Future<void> _saveSelectedStation(String? id, String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove('kds_station_id');
      await prefs.remove('kds_station_name');
      setState(() {
        _selectedStationId = null;
        _selectedStationName = null;
      });
    } else {
      await prefs.setString('kds_station_id', id);
      await prefs.setString('kds_station_name', name ?? 'Station');
      setState(() {
        _selectedStationId = id;
        _selectedStationName = name;
      });
    }
    _refreshKots();
  }

  void _fetchStations() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final resto = Provider.of<RestaurantProvider>(context, listen: false);
    if (auth.token != null && resto.restaurants.isNotEmpty) {
      final activeRestaurantId = resto.selectedRestaurant?.id ?? resto.restaurants.first.id;
      Provider.of<KdsStationProvider>(context, listen: false)
          .fetchStations(auth.token!, activeRestaurantId);
    }
  }

  void _refreshKots() async {
    if (!mounted) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final resto = Provider.of<RestaurantProvider>(context, listen: false);
    if (auth.token != null && resto.restaurants.isNotEmpty) {
      final activeRestaurantId = resto.selectedRestaurant?.id ?? resto.restaurants.first.id;
      await Provider.of<KotProvider>(context, listen: false)
          .fetchActiveKots(
            auth.token!, 
            activeRestaurantId,
            kdsStationId: _selectedStationId
          );
    }

    if (_isAutoRefresh && mounted) {
      _refreshTimer?.cancel();
      _refreshTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) _refreshKots();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16181D),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('KDS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              (_selectedStationId == null || _selectedStationId == 'all') 
                ? 'All Stations' 
                : (_selectedStationName ?? 'Station'), 
              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10)
            ),

          ],
        ),
        actions: [
          _buildStationPicker(),
          const SizedBox(width: 8),
          Row(
            children: [
              const Text('Auto', style: TextStyle(color: Colors.white70, fontSize: 12)),
              Switch(
                value: _isAutoRefresh,
                onChanged: (val) {
                  setState(() => _isAutoRefresh = val);
                  if (val) {
                    _refreshKots();
                  } else {
                    _refreshTimer?.cancel();
                  }
                },
                activeThumbColor: const Color(0xFFD4AF37),
              ),
            ],
          ),
          IconButton(
            onPressed: _refreshKots,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFD4AF37)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<KotProvider>(
        builder: (context, kotProvider, _) {
          if (kotProvider.isLoading && kotProvider.activeKots.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }

          if (kotProvider.activeKots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_rounded, size: 64, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text(
                    _selectedStationId == null 
                      ? 'No active orders' 
                      : 'No active orders for $_selectedStationName', 
                    style: const TextStyle(color: Colors.white38)
                  ),
                ],
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int crossAxisCount = (width / 400).ceil().clamp(1, 10);
              final double itemWidth = (width - 32 - (crossAxisCount - 1) * 16) / crossAxisCount;
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: kotProvider.activeKots.map((kot) {
                    return SizedBox(
                      width: itemWidth,
                      child: _buildKotCard(kot),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStationPicker() {
    return Consumer<KdsStationProvider>(
      builder: (context, provider, _) {
        return PopupMenuButton<String?>(
          icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
          tooltip: 'Select Station',
          onSelected: (id) {
            if (id == 'all' || id == null) {
              _saveSelectedStation(null, null);
            } else {
              final station = provider.stations.firstWhere((s) => s.id == id);
              _saveSelectedStation(station.id, station.name);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'all',
              child: Row(
                children: [
                  Icon(Icons.all_inclusive, color: Color(0xFFD4AF37), size: 18),
                  SizedBox(width: 12),
                  Text('All Stations', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const PopupMenuDivider(),
            ...provider.stations.map((s) => PopupMenuItem(
              value: s.id,
              child: Row(
                children: [
                  const Icon(Icons.kitchen_rounded, color: Colors.white24, size: 18),
                  const SizedBox(width: 12),
                  Text(s.name),
                ],
              ),
            )),
          ],
        );
      },
    );
  }

  Widget _buildKotCard(dynamic kot) {
    final bool isCooking = kot['status'] == 'cooking';
    final DateTime createdAt = DateTime.parse(kot['created_at']);
    final duration = DateTime.now().difference(createdAt);
    final color = duration.inMinutes > 20 ? Colors.redAccent : (duration.inMinutes > 10 ? Colors.orange : Colors.green);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16181D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TABLE ${kot['order']?['table']?['name'] ?? 'DIRECT'}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    Text(
                      'Order #${kot['order_id'].toString().substring(0, 8)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${duration.inMinutes}m',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: () {
              final allItems = (kot['items'] as List);
              return allItems.where((item) {
                final parentId = item['parent_order_item_id'];
                if (parentId == null) return true;
                return !allItems.any((i) => i['id'] == parentId);
              }).length;
            }(),
            separatorBuilder: (context, _) => const Divider(color: Colors.white10),
            itemBuilder: (context, idx) {
              final allItems = (kot['items'] as List);
              final rootItems = allItems.where((item) {
                final parentId = item['parent_order_item_id'];
                if (parentId == null) return true;
                return !allItems.any((i) => i['id'] == parentId);
              }).toList();
              
              final item = rootItems[idx];
              final isOrphanedChild = item['parent_order_item_id'] != null;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${item['quantity']}',
                          style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['menu_item']?['name'] ?? 'Unknown Item',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          if (isOrphanedChild)
                            Text(
                              'PART OF: ${item['parent']?['menu_item']?['name'] ?? "COMBO"}',
                              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          if (item['children'] != null && (item['children'] as List).isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: (item['children'] as List).where((child) => allItems.any((i) => i['id'] == child['id'])).map((child) => Text(
                                  '• ${child['menu_item']?['name'] ?? 'Unknown'}',
                                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                                )).toList(),
                              ),
                            ),
                          if (item['notes'] != null && item['notes'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'NOTE: ${item['notes']}',
                                style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),

                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Footer Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (!isCooking)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(kot['id'].toString(), 'cooking'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('COOKING', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateStatus(kot['id'].toString(), 'completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('READY', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateStatus(String kotId, String status) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await Provider.of<KotProvider>(context, listen: false)
        .updateStatus(auth.token!, kotId, status);
    
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update status')));
    }
  }
}
