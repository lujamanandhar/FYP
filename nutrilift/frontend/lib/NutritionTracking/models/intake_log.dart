import 'food_item.dart';

class IntakeLog {
  final int? id;
  final String? userId;  // Changed from int? to String? for UUID
  final int foodItemId;
  final FoodItem? foodItemDetails;
  final String entryType;
  final String? description;
  final double quantity;
  final String unit;
  final double calories;
  final double protein;
  final double carbs;
  final double fats;
  final DateTime loggedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const IntakeLog({
    this.id,
    this.userId,
    required this.foodItemId,
    this.foodItemDetails,
    required this.entryType,
    this.description,
    required this.quantity,
    required this.unit,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.loggedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory IntakeLog.fromJson(Map<String, dynamic> json) {
    return IntakeLog(
      id: json['id'] as int?,
      userId: json['user']?.toString(),
      foodItemId: json['food_item'] as int,
      foodItemDetails: json['food_item_details'] != null
          ? FoodItem.fromJson(json['food_item_details'] as Map<String, dynamic>)
          : null,
      entryType: json['entry_type'] as String,
      description: json['description'] as String?,
      quantity: _parseDouble(json['quantity']),
      unit: json['unit'] as String,
      calories: _parseDouble(json['calories']),
      protein: _parseDouble(json['protein']),
      carbs: _parseDouble(json['carbs']),
      fats: _parseDouble(json['fats']),
      loggedAt: DateTime.parse(json['logged_at'] as String),
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

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user': userId,
      'food_item': foodItemId,
      if (foodItemDetails != null) 'food_item_details': foodItemDetails!.toJson(),
      'entry_type': entryType,
      if (description != null) 'description': description,
      'quantity': quantity,
      'unit': unit,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'logged_at': loggedAt.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  IntakeLog copyWith({
    int? id,
    String? userId,  // Changed from int? to String?
    int? foodItemId,
    FoodItem? foodItemDetails,
    String? entryType,
    String? description,
    double? quantity,
    String? unit,
    double? calories,
    double? protein,
    double? carbs,
    double? fats,
    DateTime? loggedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IntakeLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      foodItemId: foodItemId ?? this.foodItemId,
      foodItemDetails: foodItemDetails ?? this.foodItemDetails,
      entryType: entryType ?? this.entryType,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      loggedAt: loggedAt ?? this.loggedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IntakeLog &&
        other.id == id &&
        other.userId == userId &&
        other.foodItemId == foodItemId &&
        other.foodItemDetails == foodItemDetails &&
        other.entryType == entryType &&
        other.description == description &&
        other.quantity == quantity &&
        other.unit == unit &&
        other.calories == calories &&
        other.protein == protein &&
        other.carbs == carbs &&
        other.fats == fats &&
        other.loggedAt == loggedAt &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      foodItemId,
      foodItemDetails,
      entryType,
      description,
      quantity,
      unit,
      calories,
      protein,
      carbs,
      fats,
      loggedAt,
      createdAt,
      updatedAt,
    );
  }
}
