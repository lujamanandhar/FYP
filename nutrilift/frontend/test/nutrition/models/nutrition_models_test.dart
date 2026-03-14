import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilift/NutritionTracking/models/food_item.dart';
import 'package:nutrilift/NutritionTracking/models/intake_log.dart';
import 'package:nutrilift/NutritionTracking/models/hydration_log.dart';
import 'package:nutrilift/NutritionTracking/models/nutrition_goals.dart';
import 'package:nutrilift/NutritionTracking/models/nutrition_progress.dart';
import 'package:nutrilift/NutritionTracking/models/quick_log.dart';

void main() {
  group('FoodItem Model Tests', () {
    test('FoodItem fromJson should deserialize correctly', () {
      final json = {
        'id': 1,
        'name': 'Chicken Breast',
        'brand': 'Organic Farms',
        'calories_per_100g': 165.0,
        'protein_per_100g': 31.0,
        'carbs_per_100g': 0.0,
        'fats_per_100g': 3.6,
        'fiber_per_100g': 0.0,
        'sugar_per_100g': 0.0,
        'is_custom': false,
        'created_by': 'user-uuid-123',
        'image_url': 'https://example.com/chicken.jpg',
        'created_at': '2024-01-15T10:30:00Z',
        'updated_at': '2024-01-15T10:30:00Z',
      };

      final foodItem = FoodItem.fromJson(json);

      expect(foodItem.id, 1);
      expect(foodItem.name, 'Chicken Breast');
      expect(foodItem.brand, 'Organic Farms');
      expect(foodItem.caloriesPer100g, 165.0);
      expect(foodItem.proteinPer100g, 31.0);
      expect(foodItem.carbsPer100g, 0.0);
      expect(foodItem.fatsPer100g, 3.6);
      expect(foodItem.fiberPer100g, 0.0);
      expect(foodItem.sugarPer100g, 0.0);
      expect(foodItem.isCustom, false);
      expect(foodItem.createdBy, 'user-uuid-123');
      expect(foodItem.imageUrl, 'https://example.com/chicken.jpg');
      expect(foodItem.createdAt, isNotNull);
      expect(foodItem.updatedAt, isNotNull);
    });

    test('FoodItem toJson should serialize correctly', () {
      final foodItem = FoodItem(
        id: 1,
        name: 'Chicken Breast',
        brand: 'Organic Farms',
        caloriesPer100g: 165.0,
        proteinPer100g: 31.0,
        carbsPer100g: 0.0,
        fatsPer100g: 3.6,
        fiberPer100g: 0.0,
        sugarPer100g: 0.0,
        isCustom: false,
        createdBy: 'user-uuid-123',
        imageUrl: 'https://example.com/chicken.jpg',
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
        updatedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final json = foodItem.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Chicken Breast');
      expect(json['brand'], 'Organic Farms');
      expect(json['calories_per_100g'], 165.0);
      expect(json['protein_per_100g'], 31.0);
      expect(json['carbs_per_100g'], 0.0);
      expect(json['fats_per_100g'], 3.6);
      expect(json['fiber_per_100g'], 0.0);
      expect(json['sugar_per_100g'], 0.0);
      expect(json['is_custom'], false);
      expect(json['created_by'], 'user-uuid-123');
      expect(json['image_url'], 'https://example.com/chicken.jpg');
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNotNull);
    });

    test('FoodItem copyWith should update fields correctly', () {
      final foodItem = FoodItem(
        id: 1,
        name: 'Chicken Breast',
        caloriesPer100g: 165.0,
        proteinPer100g: 31.0,
        carbsPer100g: 0.0,
        fatsPer100g: 3.6,
        fiberPer100g: 0.0,
        sugarPer100g: 0.0,
        isCustom: false,
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
        updatedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final updated = foodItem.copyWith(name: 'Turkey Breast', proteinPer100g: 29.0);

      expect(updated.id, 1);
      expect(updated.name, 'Turkey Breast');
      expect(updated.proteinPer100g, 29.0);
      expect(updated.caloriesPer100g, 165.0);
    });

    test('FoodItem equality operator should work correctly', () {
      final foodItem1 = FoodItem(
        id: 1,
        name: 'Chicken Breast',
        caloriesPer100g: 165.0,
        proteinPer100g: 31.0,
        carbsPer100g: 0.0,
        fatsPer100g: 3.6,
        fiberPer100g: 0.0,
        sugarPer100g: 0.0,
        isCustom: false,
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
        updatedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final foodItem2 = FoodItem(
        id: 1,
        name: 'Chicken Breast',
        caloriesPer100g: 165.0,
        proteinPer100g: 31.0,
        carbsPer100g: 0.0,
        fatsPer100g: 3.6,
        fiberPer100g: 0.0,
        sugarPer100g: 0.0,
        isCustom: false,
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
        updatedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final foodItem3 = FoodItem(
        id: 2,
        name: 'Turkey Breast',
        caloriesPer100g: 135.0,
        proteinPer100g: 29.0,
        carbsPer100g: 0.0,
        fatsPer100g: 1.0,
        fiberPer100g: 0.0,
        sugarPer100g: 0.0,
        isCustom: false,
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
        updatedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      expect(foodItem1, equals(foodItem2));
      expect(foodItem1, isNot(equals(foodItem3)));
      expect(foodItem1.hashCode, equals(foodItem2.hashCode));
    });

    test('FoodItem should handle null optional fields', () {
      final json = {
        'id': 1,
        'name': 'Banana',
        'calories_per_100g': 89.0,
        'protein_per_100g': 1.1,
        'carbs_per_100g': 22.8,
        'fats_per_100g': 0.3,
        'fiber_per_100g': 2.6,
        'sugar_per_100g': 12.2,
        'is_custom': false,
        'created_at': '2024-01-15T10:30:00Z',
        'updated_at': '2024-01-15T10:30:00Z',
      };

      final foodItem = FoodItem.fromJson(json);

      expect(foodItem.id, 1);
      expect(foodItem.name, 'Banana');
      expect(foodItem.brand, isNull);
      expect(foodItem.createdBy, isNull);
      expect(foodItem.imageUrl, isNull);
    });
  });

  group('IntakeLog Model Tests', () {
    test('IntakeLog fromJson should deserialize correctly', () {
      final json = {
        'id': 123,
        'user': 'user-uuid-456',
        'food_item': 1,
        'food_item_details': {
          'id': 1,
          'name': 'Chicken Breast',
          'calories_per_100g': 165.0,
          'protein_per_100g': 31.0,
          'carbs_per_100g': 0.0,
          'fats_per_100g': 3.6,
          'fiber_per_100g': 0.0,
          'sugar_per_100g': 0.0,
          'is_custom': false,
          'created_at': '2024-01-15T10:30:00Z',
          'updated_at': '2024-01-15T10:30:00Z',
        },
        'entry_type': 'meal',
        'description': 'Grilled chicken',
        'quantity': 200.0,
        'unit': 'g',
        'calories': 330.0,
        'protein': 62.0,
        'carbs': 0.0,
        'fats': 7.2,
        'logged_at': '2024-01-15T12:00:00Z',
        'created_at': '2024-01-15T12:00:00Z',
        'updated_at': '2024-01-15T12:00:00Z',
      };

      final intakeLog = IntakeLog.fromJson(json);

      expect(intakeLog.id, 123);
      expect(intakeLog.userId, 'user-uuid-456');
      expect(intakeLog.foodItemId, 1);
      expect(intakeLog.foodItemDetails, isNotNull);
      expect(intakeLog.foodItemDetails!.name, 'Chicken Breast');
      expect(intakeLog.entryType, 'meal');
      expect(intakeLog.description, 'Grilled chicken');
      expect(intakeLog.quantity, 200.0);
      expect(intakeLog.unit, 'g');
      expect(intakeLog.calories, 330.0);
      expect(intakeLog.protein, 62.0);
      expect(intakeLog.carbs, 0.0);
      expect(intakeLog.fats, 7.2);
      expect(intakeLog.loggedAt, isNotNull);
      expect(intakeLog.createdAt, isNotNull);
      expect(intakeLog.updatedAt, isNotNull);
    });

    test('IntakeLog toJson should serialize correctly', () {
      final intakeLog = IntakeLog(
        id: 123,
        userId: 'user-uuid-456',
        foodItemId: 1,
        entryType: 'meal',
        description: 'Grilled chicken',
        quantity: 200.0,
        unit: 'g',
        calories: 330.0,
        protein: 62.0,
        carbs: 0.0,
        fats: 7.2,
        loggedAt: DateTime.parse('2024-01-15T12:00:00Z'),
        createdAt: DateTime.parse('2024-01-15T12:00:00Z'),
        updatedAt: DateTime.parse('2024-01-15T12:00:00Z'),
      );

      final json = intakeLog.toJson();

      expect(json['id'], 123);
      expect(json['user'], 'user-uuid-456');
      expect(json['food_item'], 1);
      expect(json['entry_type'], 'meal');
      expect(json['description'], 'Grilled chicken');
      expect(json['quantity'], 200.0);
      expect(json['unit'], 'g');
      expect(json['calories'], 330.0);
      expect(json['protein'], 62.0);
      expect(json['carbs'], 0.0);
      expect(json['fats'], 7.2);
      expect(json['logged_at'], isNotNull);
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNotNull);
    });

    test('IntakeLog copyWith should update fields correctly', () {
      final intakeLog = IntakeLog(
        id: 123,
        userId: 'user-uuid-456',
        foodItemId: 1,
        entryType: 'meal',
        quantity: 200.0,
        unit: 'g',
        calories: 330.0,
        protein: 62.0,
        carbs: 0.0,
        fats: 7.2,
        loggedAt: DateTime.parse('2024-01-15T12:00:00Z'),
      );

      final updated = intakeLog.copyWith(quantity: 250.0, calories: 412.5);

      expect(updated.id, 123);
      expect(updated.quantity, 250.0);
      expect(updated.calories, 412.5);
      expect(updated.protein, 62.0);
    });

    test('IntakeLog equality operator should work correctly', () {
      final intakeLog1 = IntakeLog(
        id: 123,
        userId: 'user-uuid-456',
        foodItemId: 1,
        entryType: 'meal',
        quantity: 200.0,
        unit: 'g',
        calories: 330.0,
        protein: 62.0,
        carbs: 0.0,
        fats: 7.2,
        loggedAt: DateTime.parse('2024-01-15T12:00:00Z'),
      );

      final intakeLog2 = IntakeLog(
        id: 123,
        userId: 'user-uuid-456',
        foodItemId: 1,
        entryType: 'meal',
        quantity: 200.0,
        unit: 'g',
        calories: 330.0,
        protein: 62.0,
        carbs: 0.0,
        fats: 7.2,
        loggedAt: DateTime.parse('2024-01-15T12:00:00Z'),
      );

      final intakeLog3 = IntakeLog(
        id: 124,
        userId: 'user-uuid-456',
        foodItemId: 2,
        entryType: 'snack',
        quantity: 100.0,
        unit: 'g',
        calories: 150.0,
        protein: 5.0,
        carbs: 20.0,
        fats: 3.0,
        loggedAt: DateTime.parse('2024-01-15T15:00:00Z'),
      );

      expect(intakeLog1, equals(intakeLog2));
      expect(intakeLog1, isNot(equals(intakeLog3)));
      expect(intakeLog1.hashCode, equals(intakeLog2.hashCode));
    });

    test('IntakeLog should handle null optional fields', () {
      final json = {
        'food_item': 1,
        'entry_type': 'snack',
        'quantity': 100.0,
        'unit': 'g',
        'calories': 150.0,
        'protein': 5.0,
        'carbs': 20.0,
        'fats': 3.0,
        'logged_at': '2024-01-15T15:00:00Z',
      };

      final intakeLog = IntakeLog.fromJson(json);

      expect(intakeLog.id, isNull);
      expect(intakeLog.userId, isNull);
      expect(intakeLog.foodItemDetails, isNull);
      expect(intakeLog.description, isNull);
      expect(intakeLog.createdAt, isNull);
      expect(intakeLog.updatedAt, isNull);
    });
  });

  group('HydrationLog Model Tests', () {
    test('HydrationLog fromJson should deserialize correctly', () {
      final json = {
        'id': 456,
        'user': 'user-uuid-789',
        'amount': 500.0,
        'unit': 'ml',
        'logged_at': '2024-01-15T14:00:00Z',
        'created_at': '2024-01-15T14:00:00Z',
      };

      final hydrationLog = HydrationLog.fromJson(json);

      expect(hydrationLog.id, 456);
      expect(hydrationLog.userId, 'user-uuid-789');
      expect(hydrationLog.amount, 500.0);
      expect(hydrationLog.unit, 'ml');
      expect(hydrationLog.loggedAt, isNotNull);
      expect(hydrationLog.createdAt, isNotNull);
    });

    test('HydrationLog toJson should serialize correctly', () {
      final hydrationLog = HydrationLog(
        id: 456,
        userId: 'user-uuid-789',
        amount: 500.0,
        unit: 'ml',
        loggedAt: DateTime.parse('2024-01-15T14:00:00Z'),
        createdAt: DateTime.parse('2024-01-15T14:00:00Z'),
      );

      final json = hydrationLog.toJson();

      expect(json['id'], 456);
      expect(json['user'], 'user-uuid-789');
      expect(json['amount'], 500.0);
      expect(json['unit'], 'ml');
      expect(json['logged_at'], isNotNull);
      expect(json['created_at'], isNotNull);
    });

    test('HydrationLog copyWith should update fields correctly', () {
      final hydrationLog = HydrationLog(
        id: 456,
        userId: 'user-uuid-789',
        amount: 500.0,
        unit: 'ml',
        loggedAt: DateTime.parse('2024-01-15T14:00:00Z'),
      );

      final updated = hydrationLog.copyWith(amount: 750.0);

      expect(updated.id, 456);
      expect(updated.amount, 750.0);
      expect(updated.unit, 'ml');
    });

    test('HydrationLog equality operator should work correctly', () {
      final hydrationLog1 = HydrationLog(
        id: 456,
        userId: 'user-uuid-789',
        amount: 500.0,
        unit: 'ml',
        loggedAt: DateTime.parse('2024-01-15T14:00:00Z'),
      );

      final hydrationLog2 = HydrationLog(
        id: 456,
        userId: 'user-uuid-789',
        amount: 500.0,
        unit: 'ml',
        loggedAt: DateTime.parse('2024-01-15T14:00:00Z'),
      );

      final hydrationLog3 = HydrationLog(
        id: 457,
        userId: 'user-uuid-789',
        amount: 250.0,
        unit: 'ml',
        loggedAt: DateTime.parse('2024-01-15T16:00:00Z'),
      );

      expect(hydrationLog1, equals(hydrationLog2));
      expect(hydrationLog1, isNot(equals(hydrationLog3)));
      expect(hydrationLog1.hashCode, equals(hydrationLog2.hashCode));
    });

    test('HydrationLog should handle null optional fields', () {
      final json = {
        'amount': 500.0,
        'unit': 'ml',
        'logged_at': '2024-01-15T14:00:00Z',
      };

      final hydrationLog = HydrationLog.fromJson(json);

      expect(hydrationLog.id, isNull);
      expect(hydrationLog.userId, isNull);
      expect(hydrationLog.createdAt, isNull);
    });
  });

  group('NutritionGoals Model Tests', () {
    test('NutritionGoals fromJson should deserialize correctly', () {
      final json = {
        'id': 1,
        'user': 'user-uuid-123',
        'daily_calories': 2500.0,
        'daily_protein': 180.0,
        'daily_carbs': 250.0,
        'daily_fats': 70.0,
        'daily_water': 3000.0,
        'created_at': '2024-01-15T10:00:00Z',
        'updated_at': '2024-01-15T10:00:00Z',
      };

      final nutritionGoals = NutritionGoals.fromJson(json);

      expect(nutritionGoals.id, 1);
      expect(nutritionGoals.userId, 'user-uuid-123');
      expect(nutritionGoals.dailyCalories, 2500.0);
      expect(nutritionGoals.dailyProtein, 180.0);
      expect(nutritionGoals.dailyCarbs, 250.0);
      expect(nutritionGoals.dailyFats, 70.0);
      expect(nutritionGoals.dailyWater, 3000.0);
      expect(nutritionGoals.createdAt, isNotNull);
      expect(nutritionGoals.updatedAt, isNotNull);
    });

    test('NutritionGoals toJson should serialize correctly', () {
      final nutritionGoals = NutritionGoals(
        id: 1,
        userId: 'user-uuid-123',
        dailyCalories: 2500.0,
        dailyProtein: 180.0,
        dailyCarbs: 250.0,
        dailyFats: 70.0,
        dailyWater: 3000.0,
        createdAt: DateTime.parse('2024-01-15T10:00:00Z'),
        updatedAt: DateTime.parse('2024-01-15T10:00:00Z'),
      );

      final json = nutritionGoals.toJson();

      expect(json['id'], 1);
      expect(json['user'], 'user-uuid-123');
      expect(json['daily_calories'], 2500.0);
      expect(json['daily_protein'], 180.0);
      expect(json['daily_carbs'], 250.0);
      expect(json['daily_fats'], 70.0);
      expect(json['daily_water'], 3000.0);
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNotNull);
    });

    test('NutritionGoals copyWith should update fields correctly', () {
      final nutritionGoals = NutritionGoals(
        id: 1,
        userId: 'user-uuid-123',
        dailyCalories: 2500.0,
        dailyProtein: 180.0,
        dailyCarbs: 250.0,
        dailyFats: 70.0,
        dailyWater: 3000.0,
      );

      final updated = nutritionGoals.copyWith(dailyCalories: 2800.0, dailyProtein: 200.0);

      expect(updated.id, 1);
      expect(updated.dailyCalories, 2800.0);
      expect(updated.dailyProtein, 200.0);
      expect(updated.dailyCarbs, 250.0);
    });

    test('NutritionGoals equality operator should work correctly', () {
      final nutritionGoals1 = NutritionGoals(
        id: 1,
        userId: 'user-uuid-123',
        dailyCalories: 2500.0,
        dailyProtein: 180.0,
        dailyCarbs: 250.0,
        dailyFats: 70.0,
        dailyWater: 3000.0,
      );

      final nutritionGoals2 = NutritionGoals(
        id: 1,
        userId: 'user-uuid-123',
        dailyCalories: 2500.0,
        dailyProtein: 180.0,
        dailyCarbs: 250.0,
        dailyFats: 70.0,
        dailyWater: 3000.0,
      );

      final nutritionGoals3 = NutritionGoals(
        id: 2,
        userId: 'user-uuid-456',
        dailyCalories: 2000.0,
        dailyProtein: 150.0,
        dailyCarbs: 200.0,
        dailyFats: 65.0,
        dailyWater: 2000.0,
      );

      expect(nutritionGoals1, equals(nutritionGoals2));
      expect(nutritionGoals1, isNot(equals(nutritionGoals3)));
      expect(nutritionGoals1.hashCode, equals(nutritionGoals2.hashCode));
    });

    test('NutritionGoals defaults factory should create default values', () {
      final nutritionGoals = NutritionGoals.defaults(userId: 123);

      expect(nutritionGoals.userId, '123');
      expect(nutritionGoals.dailyCalories, 2000.0);
      expect(nutritionGoals.dailyProtein, 150.0);
      expect(nutritionGoals.dailyCarbs, 200.0);
      expect(nutritionGoals.dailyFats, 65.0);
      expect(nutritionGoals.dailyWater, 2000.0);
    });

    test('NutritionGoals should handle null optional fields', () {
      final json = {
        'daily_calories': 2500.0,
        'daily_protein': 180.0,
        'daily_carbs': 250.0,
        'daily_fats': 70.0,
        'daily_water': 3000.0,
      };

      final nutritionGoals = NutritionGoals.fromJson(json);

      expect(nutritionGoals.id, isNull);
      expect(nutritionGoals.userId, isNull);
      expect(nutritionGoals.createdAt, isNull);
      expect(nutritionGoals.updatedAt, isNull);
    });
  });

  group('NutritionProgress Model Tests', () {
    test('NutritionProgress fromJson should deserialize correctly', () {
      final json = {
        'id': 1,
        'user': 'user-uuid-123',
        'progress_date': '2024-01-15',
        'total_calories': 2100.0,
        'total_protein': 165.0,
        'total_carbs': 220.0,
        'total_fats': 68.0,
        'total_water': 2500.0,
        'calories_adherence': 84.0,
        'protein_adherence': 91.7,
        'carbs_adherence': 88.0,
        'fats_adherence': 97.1,
        'water_adherence': 83.3,
        'updated_at': '2024-01-15T20:00:00Z',
      };

      final nutritionProgress = NutritionProgress.fromJson(json);

      expect(nutritionProgress.id, 1);
      expect(nutritionProgress.userId, 'user-uuid-123');
      expect(nutritionProgress.progressDate, isNotNull);
      expect(nutritionProgress.totalCalories, 2100.0);
      expect(nutritionProgress.totalProtein, 165.0);
      expect(nutritionProgress.totalCarbs, 220.0);
      expect(nutritionProgress.totalFats, 68.0);
      expect(nutritionProgress.totalWater, 2500.0);
      expect(nutritionProgress.caloriesAdherence, 84.0);
      expect(nutritionProgress.proteinAdherence, 91.7);
      expect(nutritionProgress.carbsAdherence, 88.0);
      expect(nutritionProgress.fatsAdherence, 97.1);
      expect(nutritionProgress.waterAdherence, 83.3);
      expect(nutritionProgress.updatedAt, isNotNull);
    });

    test('NutritionProgress toJson should serialize correctly', () {
      final nutritionProgress = NutritionProgress(
        id: 1,
        userId: 'user-uuid-123',
        progressDate: DateTime.parse('2024-01-15'),
        totalCalories: 2100.0,
        totalProtein: 165.0,
        totalCarbs: 220.0,
        totalFats: 68.0,
        totalWater: 2500.0,
        caloriesAdherence: 84.0,
        proteinAdherence: 91.7,
        carbsAdherence: 88.0,
        fatsAdherence: 97.1,
        waterAdherence: 83.3,
        updatedAt: DateTime.parse('2024-01-15T20:00:00Z'),
      );

      final json = nutritionProgress.toJson();

      expect(json['id'], 1);
      expect(json['user'], 'user-uuid-123');
      expect(json['progress_date'], isNotNull);
      expect(json['total_calories'], 2100.0);
      expect(json['total_protein'], 165.0);
      expect(json['total_carbs'], 220.0);
      expect(json['total_fats'], 68.0);
      expect(json['total_water'], 2500.0);
      expect(json['calories_adherence'], 84.0);
      expect(json['protein_adherence'], 91.7);
      expect(json['carbs_adherence'], 88.0);
      expect(json['fats_adherence'], 97.1);
      expect(json['water_adherence'], 83.3);
      expect(json['updated_at'], isNotNull);
    });

    test('NutritionProgress copyWith should update fields correctly', () {
      final nutritionProgress = NutritionProgress(
        id: 1,
        userId: 'user-uuid-123',
        progressDate: DateTime.parse('2024-01-15'),
        totalCalories: 2100.0,
        totalProtein: 165.0,
        totalCarbs: 220.0,
        totalFats: 68.0,
        totalWater: 2500.0,
        caloriesAdherence: 84.0,
        proteinAdherence: 91.7,
        carbsAdherence: 88.0,
        fatsAdherence: 97.1,
        waterAdherence: 83.3,
        updatedAt: DateTime.parse('2024-01-15T20:00:00Z'),
      );

      final updated = nutritionProgress.copyWith(
        totalCalories: 2300.0,
        caloriesAdherence: 92.0,
      );

      expect(updated.id, 1);
      expect(updated.totalCalories, 2300.0);
      expect(updated.caloriesAdherence, 92.0);
      expect(updated.totalProtein, 165.0);
    });

    test('NutritionProgress equality operator should work correctly', () {
      final nutritionProgress1 = NutritionProgress(
        id: 1,
        userId: 'user-uuid-123',
        progressDate: DateTime.parse('2024-01-15'),
        totalCalories: 2100.0,
        totalProtein: 165.0,
        totalCarbs: 220.0,
        totalFats: 68.0,
        totalWater: 2500.0,
        caloriesAdherence: 84.0,
        proteinAdherence: 91.7,
        carbsAdherence: 88.0,
        fatsAdherence: 97.1,
        waterAdherence: 83.3,
        updatedAt: DateTime.parse('2024-01-15T20:00:00Z'),
      );

      final nutritionProgress2 = NutritionProgress(
        id: 1,
        userId: 'user-uuid-123',
        progressDate: DateTime.parse('2024-01-15'),
        totalCalories: 2100.0,
        totalProtein: 165.0,
        totalCarbs: 220.0,
        totalFats: 68.0,
        totalWater: 2500.0,
        caloriesAdherence: 84.0,
        proteinAdherence: 91.7,
        carbsAdherence: 88.0,
        fatsAdherence: 97.1,
        waterAdherence: 83.3,
        updatedAt: DateTime.parse('2024-01-15T20:00:00Z'),
      );

      final nutritionProgress3 = NutritionProgress(
        id: 2,
        userId: 'user-uuid-456',
        progressDate: DateTime.parse('2024-01-16'),
        totalCalories: 1800.0,
        totalProtein: 140.0,
        totalCarbs: 180.0,
        totalFats: 60.0,
        totalWater: 2000.0,
        caloriesAdherence: 90.0,
        proteinAdherence: 93.3,
        carbsAdherence: 90.0,
        fatsAdherence: 92.3,
        waterAdherence: 100.0,
        updatedAt: DateTime.parse('2024-01-16T20:00:00Z'),
      );

      expect(nutritionProgress1, equals(nutritionProgress2));
      expect(nutritionProgress1, isNot(equals(nutritionProgress3)));
      expect(nutritionProgress1.hashCode, equals(nutritionProgress2.hashCode));
    });
  });

  group('QuickLog Model Tests', () {
    test('QuickLog fromJson should deserialize correctly', () {
      final json = {
        'id': 1,
        'user': 123,
        'frequent_meals': [
          {
            'food_item_id': 1,
            'usage_count': 15,
            'last_used': '2024-01-15',
          },
          {
            'food_item_id': 2,
            'usage_count': 10,
            'last_used': '2024-01-14',
          },
        ],
        'updated_at': '2024-01-15T20:00:00Z',
      };

      final quickLog = QuickLog.fromJson(json);

      expect(quickLog.id, 1);
      expect(quickLog.userId, 123);
      expect(quickLog.frequentMeals.length, 2);
      expect(quickLog.frequentMeals[0]['food_item_id'], 1);
      expect(quickLog.frequentMeals[0]['usage_count'], 15);
      expect(quickLog.updatedAt, isNotNull);
    });

    test('QuickLog toJson should serialize correctly', () {
      final quickLog = QuickLog(
        id: 1,
        userId: 123,
        frequentMeals: [
          {
            'food_item_id': 1,
            'usage_count': 15,
            'last_used': '2024-01-15',
          },
          {
            'food_item_id': 2,
            'usage_count': 10,
            'last_used': '2024-01-14',
          },
        ],
        updatedAt: DateTime.parse('2024-01-15T20:00:00Z'),
      );

      final json = quickLog.toJson();

      expect(json['id'], 1);
      expect(json['user'], 123);
      expect(json['frequent_meals'], isList);
      expect(json['frequent_meals'].length, 2);
      expect(json['updated_at'], isNotNull);
    });

    test('QuickLog copyWith should update fields correctly', () {
      final quickLog = QuickLog(
        id: 1,
        userId: 123,
        frequentMeals: [
          {
            'food_item_id': 1,
            'usage_count': 15,
            'last_used': '2024-01-15',
          },
        ],
        updatedAt: DateTime.parse('2024-01-15T20:00:00Z'),
      );

      final updated = quickLog.copyWith(
        frequentMeals: [
          {
            'food_item_id': 1,
            'usage_count': 16,
            'last_used': '2024-01-16',
          },
        ],
      );

      expect(updated.id, 1);
      expect(updated.frequentMeals[0]['usage_count'], 16);
    });

    test('QuickLog equality operator should work correctly', () {
      final frequentMealsList = [
        {
          'food_item_id': 1,
          'usage_count': 15,
          'last_used': '2024-01-15',
        },
      ];

      final quickLog1 = QuickLog(
        id: 1,
        userId: 123,
        frequentMeals: frequentMealsList,
        updatedAt: DateTime.parse('2024-01-15T20:00:00Z'),
      );

      final quickLog2 = QuickLog(
        id: 1,
        userId: 123,
        frequentMeals: frequentMealsList,
        updatedAt: DateTime.parse('2024-01-15T20:00:00Z'),
      );

      final quickLog3 = QuickLog(
        id: 2,
        userId: 456,
        frequentMeals: [],
        updatedAt: DateTime.parse('2024-01-16T20:00:00Z'),
      );

      expect(quickLog1, equals(quickLog2));
      expect(quickLog1, isNot(equals(quickLog3)));
      expect(quickLog1.hashCode, equals(quickLog2.hashCode));
    });
  });

  group('FrequentMealEntry Model Tests', () {
    test('FrequentMealEntry fromJson should deserialize correctly', () {
      final json = {
        'food_item_id': 1,
        'usage_count': 15,
        'last_used': '2024-01-15',
        'food_item': {
          'id': 1,
          'name': 'Chicken Breast',
          'calories_per_100g': 165.0,
          'protein_per_100g': 31.0,
          'carbs_per_100g': 0.0,
          'fats_per_100g': 3.6,
          'fiber_per_100g': 0.0,
          'sugar_per_100g': 0.0,
          'is_custom': false,
          'created_at': '2024-01-15T10:30:00Z',
          'updated_at': '2024-01-15T10:30:00Z',
        },
      };

      final frequentMealEntry = FrequentMealEntry.fromJson(json);

      expect(frequentMealEntry.foodItemId, 1);
      expect(frequentMealEntry.usageCount, 15);
      expect(frequentMealEntry.lastUsed, '2024-01-15');
      expect(frequentMealEntry.foodItem.name, 'Chicken Breast');
    });

    test('FrequentMealEntry toJson should serialize correctly', () {
      final frequentMealEntry = FrequentMealEntry(
        foodItemId: 1,
        usageCount: 15,
        lastUsed: '2024-01-15',
        foodItem: FoodItem(
          id: 1,
          name: 'Chicken Breast',
          caloriesPer100g: 165.0,
          proteinPer100g: 31.0,
          carbsPer100g: 0.0,
          fatsPer100g: 3.6,
          fiberPer100g: 0.0,
          sugarPer100g: 0.0,
          isCustom: false,
          createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
          updatedAt: DateTime.parse('2024-01-15T10:30:00Z'),
        ),
      );

      final json = frequentMealEntry.toJson();

      expect(json['food_item_id'], 1);
      expect(json['usage_count'], 15);
      expect(json['last_used'], '2024-01-15');
      expect(json['food_item'], isNotNull);
      expect(json['food_item']['name'], 'Chicken Breast');
    });

    test('FrequentMealEntry copyWith should update fields correctly', () {
      final frequentMealEntry = FrequentMealEntry(
        foodItemId: 1,
        usageCount: 15,
        lastUsed: '2024-01-15',
        foodItem: FoodItem(
          id: 1,
          name: 'Chicken Breast',
          caloriesPer100g: 165.0,
          proteinPer100g: 31.0,
          carbsPer100g: 0.0,
          fatsPer100g: 3.6,
          fiberPer100g: 0.0,
          sugarPer100g: 0.0,
          isCustom: false,
          createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
          updatedAt: DateTime.parse('2024-01-15T10:30:00Z'),
        ),
      );

      final updated = frequentMealEntry.copyWith(usageCount: 16, lastUsed: '2024-01-16');

      expect(updated.foodItemId, 1);
      expect(updated.usageCount, 16);
      expect(updated.lastUsed, '2024-01-16');
    });

    test('FrequentMealEntry equality operator should work correctly', () {
      final foodItem = FoodItem(
        id: 1,
        name: 'Chicken Breast',
        caloriesPer100g: 165.0,
        proteinPer100g: 31.0,
        carbsPer100g: 0.0,
        fatsPer100g: 3.6,
        fiberPer100g: 0.0,
        sugarPer100g: 0.0,
        isCustom: false,
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
        updatedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final frequentMealEntry1 = FrequentMealEntry(
        foodItemId: 1,
        usageCount: 15,
        lastUsed: '2024-01-15',
        foodItem: foodItem,
      );

      final frequentMealEntry2 = FrequentMealEntry(
        foodItemId: 1,
        usageCount: 15,
        lastUsed: '2024-01-15',
        foodItem: foodItem,
      );

      final frequentMealEntry3 = FrequentMealEntry(
        foodItemId: 2,
        usageCount: 10,
        lastUsed: '2024-01-14',
        foodItem: foodItem,
      );

      expect(frequentMealEntry1, equals(frequentMealEntry2));
      expect(frequentMealEntry1, isNot(equals(frequentMealEntry3)));
      expect(frequentMealEntry1.hashCode, equals(frequentMealEntry2.hashCode));
    });
  });
}
