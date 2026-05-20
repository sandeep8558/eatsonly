class RestaurantModel {
  final String id;
  final String userId;
  final String name;
  final String slug;
  final String? logo;
  final String? address;
  final bool isVeg;
  final bool isNonveg;
  final bool isJain;
  final String? upiId;
  final String? takeawayMenuCardId;
  final String? deliveryMenuCardId;
  final String? taxName;
  final String? taxRegistrationNumber;
  final String? fssaiNumber;
  final double? latitude;
  final double? longitude;
  final bool isDelivery;
  final bool isTakeaway;
  final bool isDinein;
  final String? billPrinterIp;
  final int billPrinterPort;


  RestaurantModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.slug,
    this.logo,
    this.address,
    this.isVeg = true,
    this.isNonveg = true,
    this.isJain = false,
    this.upiId,
    this.takeawayMenuCardId,
    this.deliveryMenuCardId,
    this.taxName,
    this.taxRegistrationNumber,
    this.fssaiNumber,
    this.latitude,
    this.longitude,
    this.isDelivery = true,
    this.isTakeaway = true,
    this.isDinein = true,
    this.billPrinterIp,
    this.billPrinterPort = 9100,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      name: json['name'],
      slug: json['slug'],
      logo: json['logo'],
      address: json['address'],
      isVeg: json['is_veg'] == 1 || json['is_veg'] == true,
      isNonveg: json['is_nonveg'] == 1 || json['is_nonveg'] == true,
      isJain: json['is_jain'] == 1 || json['is_jain'] == true,
      upiId: json['upi_id'],
      takeawayMenuCardId: json['takeaway_menu_card_id']?.toString(),
      deliveryMenuCardId: json['delivery_menu_card_id']?.toString(),
      taxName: json['tax_name'],
      taxRegistrationNumber: json['tax_registration_number'],
      fssaiNumber: json['fssai_number'],
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : null,
      isDelivery: json['is_delivery'] == 1 || json['is_delivery'] == true || json['is_delivery'] == null,
      isTakeaway: json['is_takeaway'] == 1 || json['is_takeaway'] == true || json['is_takeaway'] == null,
      isDinein: json['is_dinein'] == 1 || json['is_dinein'] == true || json['is_dinein'] == null,
      billPrinterIp: json['bill_printer_ip'],
      billPrinterPort: json['bill_printer_port'] != null ? int.parse(json['bill_printer_port'].toString()) : 9100,
    );
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'slug': slug,
      'logo': logo,
      'address': address,
      'is_veg': isVeg,
      'is_nonveg': isNonveg,
      'is_jain': isJain,
      'upi_id': upiId,
      'takeaway_menu_card_id': takeawayMenuCardId,
      'delivery_menu_card_id': deliveryMenuCardId,
      'tax_name': taxName,
      'tax_registration_number': taxRegistrationNumber,
      'fssai_number': fssaiNumber,
      'latitude': latitude,
      'longitude': longitude,
      'is_delivery': isDelivery,
      'is_takeaway': isTakeaway,
      'is_dinein': isDinein,
      'bill_printer_ip': billPrinterIp,
      'bill_printer_port': billPrinterPort,
    };

  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestaurantModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
