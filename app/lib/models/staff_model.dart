class StaffModel {
  final String id;
  final String name;
  final String email;
  final String? mobile;
  final List<String> roles;
  final String restaurantId;
  final String restaurantName;

  StaffModel({
    required this.id,
    required this.name,
    required this.email,
    this.mobile,
    required this.roles,
    required this.restaurantId,
    required this.restaurantName,
  });

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    return StaffModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      mobile: json['mobile'],
      roles: List<String>.from(json['roles'] ?? []),
      restaurantId: json['restaurant_id'].toString(),
      restaurantName: json['restaurant_name'],
    );
  }
}
