class NutritionProgress {
  final int id;
  final String userId;  // Changed from int to String for UUID
  final DateTime progressDate;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFats;
  final double totalWater;
  final double caloriesAdherence;
  final double proteinAdherence;
  final double carbsAdherence;
  final double fatsAdherence;
  final double waterAdherence;
  final DateTime updatedAt;

  const NutritionProgress({
    required this.id,
    required this.userId,
    required this.progressDate,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFats,
    required this.totalWater,
    required this.caloriesAdherence,
    required this.proteinAdherence,
    required this.carbsAdherence,
    required this.fatsAdherence,
    required this.waterAdherence,
    required this.updatedAt,
  });

  factory NutritionProgress.fromJson(Map<String, dynamic> json) {
    return NutritionProgress(
      id: json['id'] as int,
      userId: json['user'].toString(),
      progressDate: DateTime.parse(json['progress_date'] as String),
      totalCalories: _parseDouble(json['total_calories']),
      totalProtein: _parseDouble(json['total_protein']),
      totalCarbs: _parseDouble(json['total_carbs']),
      totalFats: _parseDouble(json['total_fats']),
      totalWater: _parseDouble(json['total_water']),
      caloriesAdherence: _parseDouble(json['calories_adherence']),
      proteinAdherence: _parseDouble(json['protein_adherence']),
      carbsAdherence: _parseDouble(json['carbs_adherence']),
      fatsAdherence: _parseDouble(json['fats_adherence']),
      waterAdherence: _parseDouble(json['water_adherence']),
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
      'user': userId,
      'progress_date': progressDate.toIso8601String(),
      'total_calories': totalCalories,
      'total_protein': totalProtein,
      'total_carbs': totalCarbs,
      'total_fats': totalFats,
      'total_water': totalWater,
      'calories_adherence': caloriesAdherence,
      'protein_adherence': proteinAdherence,
      'carbs_adherence': carbsAdherence,
      'fats_adherence': fatsAdherence,
      'water_adherence': waterAdherence,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NutritionProgress copyWith({
    int? id,
    String? userId,  // Changed from int? to String?
    DateTime? progressDate,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFats,
    double? totalWater,
    double? caloriesAdherence,
    double? proteinAdherence,
    double? carbsAdherence,
    double? fatsAdherence,
    double? waterAdherence,
    DateTime? updatedAt,
  }) {
    return NutritionProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      progressDate: progressDate ?? this.progressDate,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFats: totalFats ?? this.totalFats,
      totalWater: totalWater ?? this.totalWater,
      caloriesAdherence: caloriesAdherence ?? this.caloriesAdherence,
      proteinAdherence: proteinAdherence ?? this.proteinAdherence,
      carbsAdherence: carbsAdherence ?? this.carbsAdherence,
      fatsAdherence: fatsAdherence ?? this.fatsAdherence,
      waterAdherence: waterAdherence ?? this.waterAdherence,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NutritionProgress &&
        other.id == id &&
        other.userId == userId &&
        other.progressDate == progressDate &&
        other.totalCalories == totalCalories &&
        other.totalProtein == totalProtein &&
        other.totalCarbs == totalCarbs &&
        other.totalFats == totalFats &&
        other.totalWater == totalWater &&
        other.caloriesAdherence == caloriesAdherence &&
        other.proteinAdherence == proteinAdherence &&
        other.carbsAdherence == carbsAdherence &&
        other.fatsAdherence == fatsAdherence &&
        other.waterAdherence == waterAdherence &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      progressDate,
      totalCalories,
      totalProtein,
      totalCarbs,
      totalFats,
      totalWater,
      caloriesAdherence,
      proteinAdherence,
      carbsAdherence,
      fatsAdherence,
      waterAdherence,
      updatedAt,
    );
  }
}
