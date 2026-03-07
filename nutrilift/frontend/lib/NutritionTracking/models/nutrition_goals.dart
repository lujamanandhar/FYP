class NutritionGoals {
  final int? id;
  final String? userId;  // Changed from int? to String? to match backend UUID
  final double dailyCalories;
  final double dailyProtein;
  final double dailyCarbs;
  final double dailyFats;
  final double dailyWater;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const NutritionGoals({
    this.id,
    this.userId,
    required this.dailyCalories,
    required this.dailyProtein,
    required this.dailyCarbs,
    required this.dailyFats,
    required this.dailyWater,
    this.createdAt,
    this.updatedAt,
  });

  factory NutritionGoals.fromJson(Map<String, dynamic> json) {
    return NutritionGoals(
      id: json['id'] as int?,
      userId: json['user']?.toString(),
      dailyCalories: _parseDouble(json['daily_calories']),
      dailyProtein: _parseDouble(json['daily_protein']),
      dailyCarbs: _parseDouble(json['daily_carbs']),
      dailyFats: _parseDouble(json['daily_fats']),
      dailyWater: _parseDouble(json['daily_water']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Helper method to parse double from either String or num
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory NutritionGoals.defaults({int? userId}) {
    return NutritionGoals(
      id: null,
      userId: userId?.toString(),  // Convert int to String if provided
      dailyCalories: 2000,
      dailyProtein: 150,
      dailyCarbs: 200,
      dailyFats: 65,
      dailyWater: 2000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user': userId,
      'daily_calories': dailyCalories,
      'daily_protein': dailyProtein,
      'daily_carbs': dailyCarbs,
      'daily_fats': dailyFats,
      'daily_water': dailyWater,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  NutritionGoals copyWith({
    int? id,
    String? userId,  // Changed from int? to String?
    double? dailyCalories,
    double? dailyProtein,
    double? dailyCarbs,
    double? dailyFats,
    double? dailyWater,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NutritionGoals(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dailyCalories: dailyCalories ?? this.dailyCalories,
      dailyProtein: dailyProtein ?? this.dailyProtein,
      dailyCarbs: dailyCarbs ?? this.dailyCarbs,
      dailyFats: dailyFats ?? this.dailyFats,
      dailyWater: dailyWater ?? this.dailyWater,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NutritionGoals &&
        other.id == id &&
        other.userId == userId &&
        other.dailyCalories == dailyCalories &&
        other.dailyProtein == dailyProtein &&
        other.dailyCarbs == dailyCarbs &&
        other.dailyFats == dailyFats &&
        other.dailyWater == dailyWater &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      dailyCalories,
      dailyProtein,
      dailyCarbs,
      dailyFats,
      dailyWater,
      createdAt,
      updatedAt,
    );
  }
}
