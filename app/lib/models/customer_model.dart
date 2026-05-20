class CustomerModel {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final int points;
  final double totalSpent;

  CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.points = 0,
    this.totalSpent = 0.0,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      phone: (json['mobile'] ?? json['phone'] ?? '').toString(),
      email: json['email'],
      points: json['points'] ?? 0,
      totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mobile': phone,
      'email': email,
      'points': points,
      'total_spent': totalSpent,
    };
  }
}
