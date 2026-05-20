class FloorModel {
  final String id;
  final String restaurantId;
  final String? menuCardId;
  final String? menuCardName;
  final String name;
  final List<TableModel> tables;

  FloorModel({
    required this.id,
    required this.restaurantId,
    this.menuCardId,
    this.menuCardName,
    required this.name,
    this.tables = const [],
  });

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: json['id'],
      restaurantId: json['restaurant_id'].toString(),
      menuCardId: json['menu_card_id'],
      menuCardName: json['menu_card'] != null ? json['menu_card']['name'] : null,
      name: json['name'],
      tables: (json['tables'] as List?)?.map((t) => TableModel.fromJson(t)).toList() ?? [],
    );
  }
}

class TableModel {
  final String id;
  final String floorId;
  final String name;
  final int capacity;
  final String shape;
  double xPos;
  double yPos;
  String status;

  TableModel({
    required this.id,
    required this.floorId,
    required this.name,
    required this.capacity,
    required this.shape,
    required this.xPos,
    required this.yPos,
    required this.status,
  });

  factory TableModel.fromJson(Map<String, dynamic> json) {
    return TableModel(
      id: json['id'],
      floorId: json['floor_id'],
      name: json['name'],
      capacity: json['capacity'] ?? 2,
      shape: json['shape'] ?? 'square',
      xPos: double.tryParse(json['x_pos'].toString()) ?? 0.0,
      yPos: double.tryParse(json['y_pos'].toString()) ?? 0.0,
      status: json['status'] ?? 'available',
    );
  }
}
