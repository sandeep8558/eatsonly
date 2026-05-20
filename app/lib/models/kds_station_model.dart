class KdsStationModel {
  final String id;
  final String name;
  final String restaurantId;
  final String? printerIp;
  final int printerPort;
  final bool isActive;

  KdsStationModel({
    required this.id,
    required this.name,
    required this.restaurantId,
    this.printerIp,
    this.printerPort = 9100,
    this.isActive = true,
  });

  factory KdsStationModel.fromJson(Map<String, dynamic> json) {
    try {
      return KdsStationModel(
        id: json['id'].toString(),
        name: json['name'] ?? 'Unnamed Station',
        restaurantId: json['restaurant_id'].toString(),
        printerIp: json['printer_ip'],
        printerPort: json['printer_port'] != null 
            ? (int.tryParse(json['printer_port'].toString()) ?? 9100) 
            : 9100,
        isActive: json['is_active'] == 1 || json['is_active'] == true,
      );
    } catch (e) {
      print('Error parsing KDS Station: $e');
      return KdsStationModel(
        id: json['id']?.toString() ?? '0',
        name: 'Error Loading',
        restaurantId: '0',
      );
    }
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'restaurant_id': restaurantId,
      'printer_ip': printerIp,
      'printer_port': printerPort,
      'is_active': isActive ? 1 : 0,
    };
  }
}
