import 'food_item.dart';

class FrequentMealEntry {
  final int foodItemId;
  final int usageCount;
  final String lastUsed;
  final FoodItem foodItem;

  const FrequentMealEntry({
    required this.foodItemId,
    required this.usageCount,
    required this.lastUsed,
    required this.foodItem,
  });

  factory FrequentMealEntry.fromJson(Map<String, dynamic> json) {
    return FrequentMealEntry(
      foodItemId: json['food_item_id'] as int,
      usageCount: json['usage_count'] as int,
      lastUsed: json['last_used'] as String,
      foodItem: FoodItem.fromJson(json['food_item'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_item_id': foodItemId,
      'usage_count': usageCount,
      'last_used': lastUsed,
      'food_item': foodItem.toJson(),
    };
  }

  FrequentMealEntry copyWith({
    int? foodItemId,
    int? usageCount,
    String? lastUsed,
    FoodItem? foodItem,
  }) {
    return FrequentMealEntry(
      foodItemId: foodItemId ?? this.foodItemId,
      usageCount: usageCount ?? this.usageCount,
      lastUsed: lastUsed ?? this.lastUsed,
      foodItem: foodItem ?? this.foodItem,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FrequentMealEntry &&
        other.foodItemId == foodItemId &&
        other.usageCount == usageCount &&
        other.lastUsed == lastUsed &&
        other.foodItem == foodItem;
  }

  @override
  int get hashCode {
    return Object.hash(foodItemId, usageCount, lastUsed, foodItem);
  }
}

class QuickLog {
  final int id;
  final int userId;
  final List<Map<String, dynamic>> frequentMeals;
  final DateTime updatedAt;

  const QuickLog({
    required this.id,
    required this.userId,
    required this.frequentMeals,
    required this.updatedAt,
  });

  factory QuickLog.fromJson(Map<String, dynamic> json) {
    return QuickLog(
      id: json['id'] as int,
      userId: json['user'] as int,
      frequentMeals: (json['frequent_meals'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': userId,
      'frequent_meals': frequentMeals,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  QuickLog copyWith({
    int? id,
    int? userId,
    List<Map<String, dynamic>>? frequentMeals,
    DateTime? updatedAt,
  }) {
    return QuickLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      frequentMeals: frequentMeals ?? this.frequentMeals,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuickLog &&
        other.id == id &&
        other.userId == userId &&
        other.frequentMeals == frequentMeals &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, userId, frequentMeals, updatedAt);
  }
}
