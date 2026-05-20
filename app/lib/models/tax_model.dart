class TaxGroupModel {
  final String id;
  final String name;
  final bool isActive;
  final bool isInclusive;
  final List<TaxModel> taxes;

  TaxGroupModel({
    required this.id,
    required this.name,
    required this.isActive,
    required this.isInclusive,
    required this.taxes,
  });

  factory TaxGroupModel.fromJson(Map<String, dynamic> json) {
    return TaxGroupModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      isInclusive: json['is_inclusive'] == 1 || json['is_inclusive'] == true,
      taxes: (json['taxes'] as List?)
              ?.map((t) => TaxModel.fromJson(t))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_active': isActive,
      'is_inclusive': isInclusive,
      'taxes': taxes.map((t) => t.toJson()).toList(),
    };
  }
}

class TaxModel {
  final String id;
  final String? taxGroupId;
  final String name;
  final double percentage;

  TaxModel({
    required this.id,
    this.taxGroupId,
    required this.name,
    required this.percentage,
  });

  factory TaxModel.fromJson(Map<String, dynamic> json) {
    return TaxModel(
      id: json['id'].toString(),
      taxGroupId: json['tax_group_id']?.toString(),
      name: json['name'] ?? '',
      percentage: double.tryParse(json['percentage'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tax_group_id': taxGroupId,
      'name': name,
      'percentage': percentage,
    };
  }
}
