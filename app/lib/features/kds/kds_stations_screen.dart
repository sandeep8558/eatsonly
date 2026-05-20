import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/restaurant_provider.dart';
import '../../core/kds_station_provider.dart';
import '../../models/kds_station_model.dart';


class KdsStationsScreen extends StatefulWidget {
  const KdsStationsScreen({super.key});

  @override
  State<KdsStationsScreen> createState() => _KdsStationsScreenState();
}

class _KdsStationsScreenState extends State<KdsStationsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '9100');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStations();
    });
  }

  void _loadStations() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final resto = Provider.of<RestaurantProvider>(context, listen: false);
    if (auth.token != null && resto.restaurants.isNotEmpty) {
      final activeRestaurantId = resto.selectedRestaurant?.id ?? resto.restaurants.first.id;
      Provider.of<KdsStationProvider>(context, listen: false)
          .fetchStations(auth.token!, activeRestaurantId);
    }
  }

  void _addStation() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final resto = Provider.of<RestaurantProvider>(context, listen: false);
    if (_nameController.text.isEmpty) return;

    final provider = Provider.of<KdsStationProvider>(context, listen: false);
    // Note: addStation might need to support IP/Port too if we want to set them during creation
    // For now, I'll update the addStation call or just update immediately after
    final activeRestaurantId = resto.selectedRestaurant?.id ?? resto.restaurants.first.id;
    final success = await provider.addStation(auth.token!, activeRestaurantId, _nameController.text);

    if (success) {
       final newStation = provider.stations.last;
       await provider.updateStation(auth.token!, newStation.id, {
         'printer_ip': _ipController.text,
         'printer_port': int.tryParse(_portController.text) ?? 9100,
       });
      _nameController.clear();
      _ipController.clear();
      _portController.text = '9100';
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16181D),
        title: const Text('KDS Stations Management', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<KdsStationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
          }

          if (provider.stations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.kitchen_outlined, size: 64, color: Colors.white10),
                  const SizedBox(height: 16),
                  const Text('No KDS Stations found', style: TextStyle(color: Colors.white38, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text('Add your first station using the button below', style: TextStyle(color: Colors.white12, fontSize: 12)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.stations.length,
            itemBuilder: (context, index) {
              final station = provider.stations[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16181D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.kitchen_rounded, color: Color(0xFFD4AF37)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(station.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          Row(
                            children: [
                              Container(
                                width: 6, height: 6,
                                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              const Text('Active', style: TextStyle(color: Colors.white38, fontSize: 11)),
                              if (station.printerIp != null) ...[
                                const Text(' • ', style: TextStyle(color: Colors.white10)),
                                Expanded(
                                  child: Text(
                                    'Printer: ${station.printerIp}', 
                                    style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.white38, size: 20),
                      onPressed: () => _showEditDialog(station),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.redAccent.withOpacity(0.7), size: 20),
                      onPressed: () => _confirmDelete(station.id),
                    ),

                  ],
                ),
              );
            },
          );

        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('New Station', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showEditDialog(KdsStationModel station) {
    _nameController.text = station.name;
    _ipController.text = station.printerIp ?? "";
    _portController.text = station.printerPort.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16181D),
        title: Text('Edit ${station.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Station Name', labelStyle: TextStyle(color: Colors.white38)),
            ),
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Printer IP', hintText: 'e.g. 192.168.1.100', hintStyle: TextStyle(color: Colors.white10)),
            ),
            TextField(
              controller: _portController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Printer Port', hintText: '9100'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
               final auth = Provider.of<AuthProvider>(context, listen: false);
               final success = await Provider.of<KdsStationProvider>(context, listen: false).updateStation(auth.token!, station.id, {
                 'name': _nameController.text,
                 'printer_ip': _ipController.text,
                 'printer_port': int.tryParse(_portController.text) ?? 9100,
               });
               if (success && mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16181D),
        title: const Text('Delete Station?'),
        content: const Text('This will remove the station. Categories linked to this station will lose their routing.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              final auth = Provider.of<AuthProvider>(context, listen: false);
              await Provider.of<KdsStationProvider>(context, listen: false).deleteStation(auth.token!, id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog() {
    _nameController.clear();
    _ipController.clear();
    _portController.text = '9100';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16181D),
        title: const Text('Create New KDS Station'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Station Name', hintStyle: TextStyle(color: Colors.white38)),
              autofocus: true,
            ),
            TextField(
              controller: _ipController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Printer IP (e.g. 192.168.1.50)', hintStyle: TextStyle(color: Colors.white10)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: _addStation,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            child: const Text('CREATE'),
          ),
        ],
      ),
    );
  }
}

