class FoodItem {
  final int id;
  final String name;
  final String? brand;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatsPer100g;
  final double fiberPer100g;
  final double sugarPer100g;
  final bool isCustom;
  final String? createdBy;  // Changed from int? to String? to handle UUID
  final DateTime createdAt;
  final DateTime updatedAt;

  const FoodItem({
    required this.id,
    required this.name,
    this.brand,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatsPer100g,
    required this.fiberPer100g,
    required this.sugarPer100g,
    required this.isCustom,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as int,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      caloriesPer100g: _parseDouble(json['calories_per_100g']),
      proteinPer100g: _parseDouble(json['protein_per_100g']),
      carbsPer100g: _parseDouble(json['carbs_per_100g']),
      fatsPer100g: _parseDouble(json['fats_per_100g']),
      fiberPer100g: _parseDouble(json['fiber_per_100g']),
      sugarPer100g: _parseDouble(json['sugar_per_100g']),
      isCustom: json['is_custom'] as bool,
      createdBy: json['created_by'] as String?,  // Changed from int? to String?
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  // Helper method to parse double from either String or num
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'calories_per_100g': caloriesPer100g,
      'protein_per_100g': proteinPer100g,
      'carbs_per_100g': carbsPer100g,
      'fats_per_100g': fatsPer100g,
      'fiber_per_100g': fiberPer100g,
      'sugar_per_100g': sugarPer100g,
      'is_custom': isCustom,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FoodItem copyWith({
    int? id,
    String? name,
    String? brand,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatsPer100g,
    double? fiberPer100g,
    double? sugarPer100g,
    bool? isCustom,
    String? createdBy,  // Changed from int? to String?
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatsPer100g: fatsPer100g ?? this.fatsPer100g,
      fiberPer100g: fiberPer100g ?? this.fiberPer100g,
      sugarPer100g: sugarPer100g ?? this.sugarPer100g,
      isCustom: isCustom ?? this.isCustom,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FoodItem &&
        other.id == id &&
        other.name == name &&
        other.brand == brand &&
        other.caloriesPer100g == caloriesPer100g &&
        other.proteinPer100g == proteinPer100g &&
        other.carbsPer100g == carbsPer100g &&
        other.fatsPer100g == fatsPer100g &&
        other.fiberPer100g == fiberPer100g &&
        other.sugarPer100g == sugarPer100g &&
        other.isCustom == isCustom &&
        other.createdBy == createdBy &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      brand,
      caloriesPer100g,
      proteinPer100g,
      carbsPer100g,
      fatsPer100g,
      fiberPer100g,
      sugarPer100g,
      isCustom,
      createdBy,
      createdAt,
      updatedAt,
    );
  }
}
