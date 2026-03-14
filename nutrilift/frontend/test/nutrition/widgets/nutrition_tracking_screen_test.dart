import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrilift/NutritionTracking/nutrition_tracking.dart';
import 'package:nutrilift/NutritionTracking/providers/nutrition_providers.dart';
import 'package:nutrilift/NutritionTracking/models/nutrition_progress.dart';
import 'package:nutrilift/NutritionTracking/models/nutrition_goals.dart';
import 'package:nutrilift/NutritionTracking/models/intake_log.dart';
import 'package:nutrilift/NutritionTracking/models/food_item.dart';
import 'package:nutrilift/NutritionTracking/widgets/error_retry_widget.dart';

void main() {
  group('NutritionTracking Screen Widget Tests', () {
    /// Helper to build the widget with mock providers
    Widget buildTestWidget({
      NutritionProgress? mockProgress,
      NutritionGoals? mockGoals,
      List<IntakeLog>? mockLogs,
      bool hasError = false,
      String? errorMessage,
    }) {
      return ProviderScope(
        overrides: [
          dailyProgressProvider.overrideWith((ref, date) async {
            if (hasError) {
              throw Exception(errorMessage ?? 'Failed to load progress');
            }
            return mockProgress;
          }),
          nutritionGoalsProvider.overrideWith((ref) async {
            if (hasError) {
              throw Exception(errorMessage ?? 'Failed to load goals');
            }
            return mockGoals ?? _createDefaultGoals();
          }),
          intakeLogsProvider.overrideWith((ref, date) async {
            if (hasError) {
              throw Exception(errorMessage ?? 'Failed to load logs');
            }
            return mockLogs ?? [];
          }),
        ],
        child: const MaterialApp(home: NutritionTracking()),
      );
    }

    testWidgets('should display macro cards with progress data', (WidgetTester tester) async {
      // Arrange
      final mockProgress = _createMockProgress(
        protein: 120.0,
        carbs: 180.0,
        fats: 60.0,
      );
      final mockGoals = _createMockGoals(
        protein: 150.0,
        carbs: 200.0,
        fats: 65.0,
      );

      // Act
      await tester.pumpWidget(buildTestWidget(
        mockProgress: mockProgress,
        mockGoals: mockGoals,
      ));
      await tester.pumpAndSettle();

      // Assert - Should show macro cards with values
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('Carbs'), findsOneWidget);
      expect(find.text('Fats'), findsOneWidget);
      expect(find.text('120g'), findsOneWidget);
      expect(find.text('180g'), findsOneWidget);
      expect(find.text('60g'), findsOneWidget);
      expect(find.text('/150g'), findsOneWidget);
      expect(find.text('/200g'), findsOneWidget);
      expect(find.text('/65g'), findsOneWidget);
    });

    testWidgets('should display loading indicator while loading data', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      
      // Assert - Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      
      // Wait for data to load
      await tester.pumpAndSettle();
    });

    testWidgets('should display error widget when loading fails', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget(
        hasError: true,
        errorMessage: 'Network error',
      ));
      await tester.pumpAndSettle();

      // Assert - Should show error widget
      expect(find.byType(ErrorRetryWidget), findsWidgets);
      expect(find.textContaining('Network error'), findsOneWidget);
    });

    testWidgets('should display date navigation controls', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should have date navigation buttons
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      
      // Should display current date
      final now = DateTime.now();
      expect(find.textContaining('${now.day}'), findsOneWidget);
    });

    testWidgets('should navigate to previous day when left arrow tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap left arrow
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // Assert - No errors should occur
      expect(tester.takeException(), isNull);
    });

    testWidgets('should navigate to next day when right arrow tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Act - Tap right arrow
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Assert - No errors should occur
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display meal sections', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show meal sections
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
      expect(find.text('Dinner'), findsOneWidget);
    });

    testWidgets('should display add food buttons for today', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show add food buttons
      expect(find.text('+ Add Food'), findsWidgets);
    });

    testWidgets('should display logged meals in meal sections', (WidgetTester tester) async {
      // Arrange
      final mockLogs = [
        _createMockIntakeLog(
          id: 1,
          description: 'Breakfast',
          foodName: 'Oatmeal',
          quantity: 100,
          calories: 350,
        ),
        _createMockIntakeLog(
          id: 2,
          description: 'Lunch',
          foodName: 'Chicken Salad',
          quantity: 200,
          calories: 450,
        ),
      ];

      // Act
      await tester.pumpWidget(buildTestWidget(mockLogs: mockLogs));
      await tester.pumpAndSettle();

      // Assert - Should show logged meals
      expect(find.text('Oatmeal'), findsOneWidget);
      expect(find.text('Chicken Salad'), findsOneWidget);
      expect(find.textContaining('350 cal'), findsOneWidget);
      expect(find.textContaining('450 cal'), findsOneWidget);
    });

    testWidgets('should display meal calories in section headers', (WidgetTester tester) async {
      // Arrange
      final mockLogs = [
        _createMockIntakeLog(
          id: 1,
          description: 'Breakfast',
          foodName: 'Oatmeal',
          quantity: 100,
          calories: 350,
        ),
        _createMockIntakeLog(
          id: 2,
          description: 'Breakfast',
          foodName: 'Banana',
          quantity: 120,
          calories: 100,
        ),
      ];

      // Act
      await tester.pumpWidget(buildTestWidget(mockLogs: mockLogs));
      await tester.pumpAndSettle();

      // Assert - Should show total calories for breakfast (350 + 100 = 450)
      expect(find.text('450 cal'), findsOneWidget);
    });

    testWidgets('should show edit button for logged meals', (WidgetTester tester) async {
      // Arrange
      final mockLogs = [
        _createMockIntakeLog(
          id: 1,
          description: 'Breakfast',
          foodName: 'Oatmeal',
          quantity: 100,
          calories: 350,
        ),
      ];

      // Act
      await tester.pumpWidget(buildTestWidget(mockLogs: mockLogs));
      await tester.pumpAndSettle();

      // Assert - Should show edit icon
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('should display food item images when available', (WidgetTester tester) async {
      // Arrange
      final mockLogs = [
        _createMockIntakeLog(
          id: 1,
          description: 'Breakfast',
          foodName: 'Oatmeal',
          quantity: 100,
          calories: 350,
          imageUrl: 'https://example.com/oatmeal.jpg',
        ),
      ];

      // Act
      await tester.pumpWidget(buildTestWidget(mockLogs: mockLogs));
      await tester.pumpAndSettle();

      // Assert - Should show image widget
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should display fallback icon when no image available', (WidgetTester tester) async {
      // Arrange
      final mockLogs = [
        _createMockIntakeLog(
          id: 1,
          description: 'Breakfast',
          foodName: 'Oatmeal',
          quantity: 100,
          calories: 350,
          imageUrl: null,
        ),
      ];

      // Act
      await tester.pumpWidget(buildTestWidget(mockLogs: mockLogs));
      await tester.pumpAndSettle();

      // Assert - Should show fastfood icon
      expect(find.byIcon(Icons.fastfood), findsWidgets);
    });

    testWidgets('should handle empty meal sections', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget(mockLogs: []));
      await tester.pumpAndSettle();

      // Assert - Should show meal sections with 0 calories
      expect(find.text('0 cal'), findsWidgets);
    });

    testWidgets('should display snacks section when snacks are logged', (WidgetTester tester) async {
      // Arrange
      final mockLogs = [
        _createMockIntakeLog(
          id: 1,
          description: 'Snack',
          foodName: 'Apple',
          quantity: 150,
          calories: 80,
          entryType: 'snack',
        ),
      ];

      // Act
      await tester.pumpWidget(buildTestWidget(mockLogs: mockLogs));
      await tester.pumpAndSettle();

      // Assert - Should show snacks section
      expect(find.text('Snacks'), findsOneWidget);
      expect(find.text('Apple'), findsOneWidget);
    });

    testWidgets('should not display snacks section when no snacks logged', (WidgetTester tester) async {
      // Arrange
      final mockLogs = [
        _createMockIntakeLog(
          id: 1,
          description: 'Breakfast',
          foodName: 'Oatmeal',
          quantity: 100,
          calories: 350,
        ),
      ];

      // Act
      await tester.pumpWidget(buildTestWidget(mockLogs: mockLogs));
      await tester.pumpAndSettle();

      // Assert - Should not show snacks section
      expect(find.text('Snacks'), findsNothing);
    });
  });

  group('Macro Cards Loading States', () {
    Widget buildTestWidget({bool isLoading = false}) {
      return ProviderScope(
        overrides: [
          dailyProgressProvider.overrideWith((ref, date) async {
            if (isLoading) {
              await Future.delayed(const Duration(seconds: 10));
            }
            return _createMockProgress();
          }),
          nutritionGoalsProvider.overrideWith((ref) async {
            if (isLoading) {
              await Future.delayed(const Duration(seconds: 10));
            }
            return _createDefaultGoals();
          }),
          intakeLogsProvider.overrideWith((ref, date) async {
            return [];
          }),
        ],
        child: const MaterialApp(home: NutritionTracking()),
      );
    }

    testWidgets('should show loading placeholders in macro cards', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget(isLoading: true));
      await tester.pump();

      // Assert - Should show loading placeholders
      expect(find.text('...'), findsWidgets);
    });
  });

  group('Error Handling Tests', () {
    testWidgets('should display retry button on error', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dailyProgressProvider.overrideWith((ref, date) async {
            throw Exception('Network error');
          }),
          nutritionGoalsProvider.overrideWith((ref) async {
            throw Exception('Network error');
          }),
          intakeLogsProvider.overrideWith((ref, date) async {
            throw Exception('Network error');
          }),
        ],
        child: const MaterialApp(home: NutritionTracking()),
      ));
      await tester.pumpAndSettle();

      // Assert - Should show retry button
      expect(find.text('Retry'), findsWidgets);
    });

    testWidgets('should retry loading when retry button tapped', (WidgetTester tester) async {
      // Arrange
      bool shouldFail = true;
      
      await tester.pumpWidget(ProviderScope(
        overrides: [
          dailyProgressProvider.overrideWith((ref, date) async {
            if (shouldFail) {
              throw Exception('Network error');
            }
            return _createMockProgress();
          }),
          nutritionGoalsProvider.overrideWith((ref) async {
            if (shouldFail) {
              throw Exception('Network error');
            }
            return _createDefaultGoals();
          }),
          intakeLogsProvider.overrideWith((ref, date) async {
            return [];
          }),
        ],
        child: const MaterialApp(home: NutritionTracking()),
      ));
      await tester.pumpAndSettle();

      // Act - Fix the error and tap retry
      shouldFail = false;
      await tester.tap(find.text('Retry').first);
      await tester.pumpAndSettle();

      // Assert - Should now show data
      expect(find.text('Protein'), findsOneWidget);
    });
  });
}

// Helper functions to create mock data
NutritionProgress _createMockProgress({
  double protein = 100.0,
  double carbs = 150.0,
  double fats = 50.0,
}) {
  return NutritionProgress(
    id: 1,
    userId: '1',
    progressDate: DateTime.now(),
    totalCalories: (protein * 4 + carbs * 4 + fats * 9),
    totalProtein: protein,
    totalCarbs: carbs,
    totalFats: fats,
    totalWater: 1500.0,
    caloriesAdherence: 80.0,
    proteinAdherence: 75.0,
    carbsAdherence: 85.0,
    fatsAdherence: 70.0,
    waterAdherence: 75.0,
    updatedAt: DateTime.now(),
  );
}

NutritionGoals _createMockGoals({
  double protein = 150.0,
  double carbs = 200.0,
  double fats = 65.0,
}) {
  return NutritionGoals(
    id: 1,
    userId: '1',
    dailyCalories: 2000.0,
    dailyProtein: protein,
    dailyCarbs: carbs,
    dailyFats: fats,
    dailyWater: 2000.0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

NutritionGoals _createDefaultGoals() {
  return NutritionGoals(
    id: 1,
    userId: '1',
    dailyCalories: 2000.0,
    dailyProtein: 150.0,
    dailyCarbs: 200.0,
    dailyFats: 65.0,
    dailyWater: 2000.0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

IntakeLog _createMockIntakeLog({
  required int id,
  required String description,
  required String foodName,
  required double quantity,
  required double calories,
  String entryType = 'meal',
  String? imageUrl,
}) {
  final foodItem = FoodItem(
    id: id,
    name: foodName,
    brand: null,
    caloriesPer100g: calories,
    proteinPer100g: 10.0,
    carbsPer100g: 20.0,
    fatsPer100g: 5.0,
    fiberPer100g: 2.0,
    sugarPer100g: 3.0,
    isCustom: false,
    createdBy: null,
    imageUrl: imageUrl,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  return IntakeLog(
    id: id,
    userId: '1',
    foodItemId: id,
    foodItemDetails: foodItem,
    entryType: entryType,
    description: description,
    quantity: quantity,
    unit: 'g',
    calories: calories,
    protein: 10.0,
    carbs: 20.0,
    fats: 5.0,
    loggedAt: DateTime.now(),
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}
