import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilift/NutritionTracking/repositories/nutrition_repository.dart';
import 'package:nutrilift/NutritionTracking/services/nutrition_api_service.dart';
import 'package:nutrilift/NutritionTracking/models/food_item.dart';
import 'package:nutrilift/NutritionTracking/models/intake_log.dart';
import 'package:nutrilift/NutritionTracking/models/hydration_log.dart';
import 'package:nutrilift/NutritionTracking/models/nutrition_goals.dart';
import 'package:nutrilift/NutritionTracking/models/nutrition_progress.dart';

/// Manual mock implementation of NutritionApiService for testing
class MockNutritionApiService implements NutritionApiService {
  final Map<String, dynamic> _responses = {};
  final Map<String, int> _callCounts = {};
  
  void setResponse(String method, dynamic response) {
    _responses[method] = response;
  }
  
  int getCallCount(String method) {
    return _callCounts[method] ?? 0;
  }
  
  void _recordCall(String method) {
    _callCounts[method] = (_callCounts[method] ?? 0) + 1;
  }
  
  @override
  Future<List<FoodItem>> searchFoods(String query) async {
    _recordCall('searchFoods');
    final response = _responses['searchFoods'];
    if (response is Exception) throw response;
    return response as List<FoodItem>;
  }
  
  @override
  Future<FoodItem> createCustomFood(FoodItem food) async {
    _recordCall('createCustomFood');
    final response = _responses['createCustomFood'];
    if (response is Exception) throw response;
    return response as FoodItem;
  }
  
  @override
  Future<FoodItem> getFoodItem(int id) async {
    _recordCall('getFoodItem');
    final response = _responses['getFoodItem'];
    if (response is Exception) throw response;
    return response as FoodItem;
  }
  
  @override
  Future<IntakeLog> logMeal(IntakeLog log) async {
    _recordCall('logMeal');
    final response = _responses['logMeal'];
    if (response is List) {
      final result = response.removeAt(0);
      if (result is Exception) throw result;
      return result as IntakeLog;
    }
    if (response is Exception) throw response;
    return response as IntakeLog;
  }
  
  @override
  Future<List<IntakeLog>> getIntakeLogs({required DateTime dateFrom, required DateTime dateTo}) async {
    _recordCall('getIntakeLogs');
    final response = _responses['getIntakeLogs'];
    if (response is Exception) throw response;
    return response as List<IntakeLog>;
  }
  
  @override
  Future<IntakeLog> updateIntakeLog(IntakeLog log) async {
    _recordCall('updateIntakeLog');
    final response = _responses['updateIntakeLog'];
    if (response is Exception) throw response;
    return response as IntakeLog;
  }
  
  @override
  Future<void> deleteIntakeLog(int id) async {
    _recordCall('deleteIntakeLog');
    final response = _responses['deleteIntakeLog'];
    if (response is Exception) throw response;
  }
  
  @override
  Future<List<FoodItem>> getRecentFoods() async {
    _recordCall('getRecentFoods');
    final response = _responses['getRecentFoods'];
    if (response is Exception) throw response;
    return response as List<FoodItem>;
  }
  
  @override
  Future<HydrationLog> logHydration(HydrationLog log) async {
    _recordCall('logHydration');
    final response = _responses['logHydration'];
    if (response is List) {
      final result = response.removeAt(0);
      if (result is Exception) throw result;
      return result as HydrationLog;
    }
    if (response is Exception) throw response;
    return response as HydrationLog;
  }
  
  @override
  Future<List<HydrationLog>> getHydrationLogs({required DateTime dateFrom, required DateTime dateTo}) async {
    _recordCall('getHydrationLogs');
    final response = _responses['getHydrationLogs'];
    if (response is Exception) throw response;
    return response as List<HydrationLog>;
  }
  
  @override
  Future<void> deleteHydrationLog(int id) async {
    _recordCall('deleteHydrationLog');
    final response = _responses['deleteHydrationLog'];
    if (response is Exception) throw response;
  }
  
  @override
  Future<NutritionProgress?> getProgress(DateTime date) async {
    _recordCall('getProgress');
    final response = _responses['getProgress'];
    if (response is List) {
      final result = response.removeAt(0);
      if (result is Exception) throw result;
      return result as NutritionProgress?;
    }
    if (response is Exception) throw response;
    return response as NutritionProgress?;
  }
  
  @override
  Future<NutritionGoals?> getGoals() async {
    _recordCall('getGoals');
    final response = _responses['getGoals'];
    if (response is List) {
      final result = response.removeAt(0);
      if (result is Exception) throw result;
      return result as NutritionGoals?;
    }
    if (response is Exception) throw response;
    return response as NutritionGoals?;
  }
  
  @override
  Future<NutritionGoals> updateGoals(NutritionGoals goals) async {
    _recordCall('updateGoals');
    final response = _responses['updateGoals'];
    if (response is List) {
      final result = response.removeAt(0);
      if (result is Exception) throw result;
      return result as NutritionGoals;
    }
    if (response is Exception) throw response;
    return response as NutritionGoals;
  }
  
  @override
  Future<NutritionGoals> createGoals(NutritionGoals goals) async {
    _recordCall('createGoals');
    final response = _responses['createGoals'];
    if (response is Exception) throw response;
    return response as NutritionGoals;
  }
  
  @override
  Future<List<FoodItem>> getFrequentFoods() async {
    _recordCall('getFrequentFoods');
    final response = _responses['getFrequentFoods'];
    if (response is Exception) throw response;
    return response as List<FoodItem>;
  }
}

void main() {
  late NutritionRepository repository;
  late MockNutritionApiService mockApiService;

  setUp(() {
    mockApiService = MockNutritionApiService();
    repository = NutritionRepository(mockApiService);
  });

  group('Food Items', () {
    test('searchFoods returns list of food items', () async {
      final mockFoods = [
        FoodItem(
          id: 1,
          name: 'Apple',
          brand: null,
          caloriesPer100g: 52.0,
          proteinPer100g: 0.3,
          carbsPer100g: 14.0,
          fatsPer100g: 0.2,
          fiberPer100g: 2.4,
          sugarPer100g: 10.0,
          isCustom: false,
          createdBy: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      mockApiService.setResponse('searchFoods', mockFoods);

      final result = await repository.searchFoods('apple');

      expect(result, equals(mockFoods));
      expect(mockApiService.getCallCount('searchFoods'), equals(1));
    });

    test('searchFoods handles network errors', () async {
      mockApiService.setResponse('searchFoods', NetworkException('No connection'));

      expect(
        () => repository.searchFoods('apple'),
        throwsA(isA<Exception>()),
      );
    });

    test('createCustomFood returns created food', () async {
      final newFood = FoodItem(
        id: 0,
        name: 'Custom Shake',
        brand: 'MyBrand',
        caloriesPer100g: 100.0,
        proteinPer100g: 20.0,
        carbsPer100g: 5.0,
        fatsPer100g: 2.0,
        fiberPer100g: 1.0,
        sugarPer100g: 2.0,
        isCustom: true,
        createdBy: '1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final createdFood = newFood.copyWith(id: 100);
      mockApiService.setResponse('createCustomFood', createdFood);

      final result = await repository.createCustomFood(newFood);

      expect(result.id, equals(100));
      expect(mockApiService.getCallCount('createCustomFood'), equals(1));
    });
  });

  group('Intake Logs', () {
    test('logMeal returns created intake log', () async {
      final log = IntakeLog(
        id: 0,
        userId: '1',
        foodItemId: 1,
        foodItemDetails: null,
        entryType: 'meal',
        description: 'Breakfast',
        quantity: 150.0,
        unit: 'g',
        calories: 78.0,
        protein: 0.45,
        carbs: 21.0,
        fats: 0.3,
        loggedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final createdLog = log.copyWith(id: 1);
      mockApiService.setResponse('logMeal', [createdLog]);

      final result = await repository.logMeal(log);

      expect(result.id, equals(1));
      expect(mockApiService.getCallCount('logMeal'), equals(1));
    });

    test('logMeal retries on server errors', () async {
      final log = IntakeLog(
        id: 0,
        userId: '1',
        foodItemId: 1,
        foodItemDetails: null,
        entryType: 'meal',
        description: 'Breakfast',
        quantity: 150.0,
        unit: 'g',
        calories: 78.0,
        protein: 0.45,
        carbs: 21.0,
        fats: 0.3,
        loggedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final createdLog = log.copyWith(id: 1);
      mockApiService.setResponse('logMeal', [
        ServerException('Server error'),
        createdLog,
      ]);

      final result = await repository.logMeal(log);

      expect(result.id, equals(1));
      expect(mockApiService.getCallCount('logMeal'), equals(2));
    });

    test('logMeal does not retry on authentication errors', () async {
      final log = IntakeLog(
        id: 0,
        userId: '1',
        foodItemId: 1,
        foodItemDetails: null,
        entryType: 'meal',
        description: 'Breakfast',
        quantity: 150.0,
        unit: 'g',
        calories: 78.0,
        protein: 0.45,
        carbs: 21.0,
        fats: 0.3,
        loggedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockApiService.setResponse('logMeal', [AuthenticationException('Unauthorized')]);

      expect(
        () => repository.logMeal(log),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('session has expired'),
        )),
      );
      expect(mockApiService.getCallCount('logMeal'), equals(1));
    });

    test('getIntakeLogs returns list of logs', () async {
      final date = DateTime(2024, 1, 15);
      final mockLogs = [
        IntakeLog(
          id: 1,
          userId: '1',
          foodItemId: 1,
          foodItemDetails: null,
          entryType: 'meal',
          description: 'Breakfast',
          quantity: 150.0,
          unit: 'g',
          calories: 78.0,
          protein: 0.45,
          carbs: 21.0,
          fats: 0.3,
          loggedAt: date,
          createdAt: date,
          updatedAt: date,
        ),
      ];
      mockApiService.setResponse('getIntakeLogs', mockLogs);

      final result = await repository.getIntakeLogs(date);

      expect(result, equals(mockLogs));
      expect(mockApiService.getCallCount('getIntakeLogs'), equals(1));
    });

    test('deleteIntakeLog calls API service', () async {
      mockApiService.setResponse('deleteIntakeLog', null);

      await repository.deleteIntakeLog(1);

      expect(mockApiService.getCallCount('deleteIntakeLog'), equals(1));
    });
  });

  group('Hydration Logs', () {
    test('logHydration returns created hydration log', () async {
      final log = HydrationLog(
        id: 0,
        userId: '1',
        amount: 500.0,
        unit: 'ml',
        loggedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      final createdLog = log.copyWith(id: 1);
      mockApiService.setResponse('logHydration', [createdLog]);

      final result = await repository.logHydration(log);

      expect(result.id, equals(1));
      expect(mockApiService.getCallCount('logHydration'), equals(1));
    });

    test('logHydration retries on server errors', () async {
      final log = HydrationLog(
        id: 0,
        userId: '1',
        amount: 500.0,
        unit: 'ml',
        loggedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      final createdLog = log.copyWith(id: 1);
      mockApiService.setResponse('logHydration', [
        ServerException('Server error'),
        createdLog,
      ]);

      final result = await repository.logHydration(log);

      expect(result.id, equals(1));
      expect(mockApiService.getCallCount('logHydration'), equals(2));
    });
  });

  group('Nutrition Progress', () {
    test('getDailyProgress returns progress for date', () async {
      final date = DateTime(2024, 1, 15);
      final mockProgress = NutritionProgress(
        id: 1,
        userId: '1',
        progressDate: date,
        totalCalories: 1850.0,
        totalProtein: 120.0,
        totalCarbs: 180.0,
        totalFats: 60.0,
        totalWater: 2000.0,
        caloriesAdherence: 92.5,
        proteinAdherence: 80.0,
        carbsAdherence: 90.0,
        fatsAdherence: 92.3,
        waterAdherence: 100.0,
        updatedAt: date,
      );
      mockApiService.setResponse('getProgress', [mockProgress]);

      final result = await repository.getDailyProgress(date);

      expect(result, equals(mockProgress));
      expect(mockApiService.getCallCount('getProgress'), equals(1));
    });

    test('getDailyProgress returns null when no progress exists', () async {
      mockApiService.setResponse('getProgress', [null]);

      final result = await repository.getDailyProgress(DateTime.now());

      expect(result, isNull);
    });
  });

  group('Nutrition Goals', () {
    test('getGoals returns goals from API', () async {
      final mockGoals = NutritionGoals(
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
      mockApiService.setResponse('getGoals', [mockGoals]);

      final result = await repository.getGoals();

      expect(result, equals(mockGoals));
      expect(mockApiService.getCallCount('getGoals'), equals(1));
    });

    test('getGoals caches goals for 5 minutes', () async {
      final mockGoals = NutritionGoals(
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
      mockApiService.setResponse('getGoals', [mockGoals]);

      await repository.getGoals();
      final result = await repository.getGoals();

      expect(result, equals(mockGoals));
      expect(mockApiService.getCallCount('getGoals'), equals(1));
    });

    test('getGoals force refresh bypasses cache', () async {
      final mockGoals = NutritionGoals(
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
      mockApiService.setResponse('getGoals', [mockGoals, mockGoals]);

      await repository.getGoals();
      final result = await repository.getGoals(forceRefresh: true);

      expect(result, equals(mockGoals));
      expect(mockApiService.getCallCount('getGoals'), equals(2));
    });

    test('getGoals creates default goals when none exist', () async {
      final createdGoals = NutritionGoals.defaults(userId: 1).copyWith(id: 1, userId: '1');
      mockApiService.setResponse('getGoals', [null]);
      mockApiService.setResponse('createGoals', createdGoals);

      final result = await repository.getGoals();

      expect(result.id, equals(1));
      expect(result.dailyCalories, equals(2000.0));
      expect(mockApiService.getCallCount('createGoals'), equals(1));
    });

    test('updateGoals returns updated goals and updates cache', () async {
      final updatedGoals = NutritionGoals(
        id: 1,
        userId: '1',
        dailyCalories: 2200.0,
        dailyProtein: 160.0,
        dailyCarbs: 220.0,
        dailyFats: 70.0,
        dailyWater: 2500.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockApiService.setResponse('updateGoals', [updatedGoals]);

      final result = await repository.updateGoals(updatedGoals);

      expect(result, equals(updatedGoals));
      expect(mockApiService.getCallCount('updateGoals'), equals(1));
    });
  });

  group('Quick Access', () {
    test('getFrequentFoods returns list of frequent foods', () async {
      final mockFoods = [
        FoodItem(
          id: 1,
          name: 'Chicken Breast',
          brand: null,
          caloriesPer100g: 165.0,
          proteinPer100g: 31.0,
          carbsPer100g: 0.0,
          fatsPer100g: 3.6,
          fiberPer100g: 0.0,
          sugarPer100g: 0.0,
          isCustom: false,
          createdBy: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      mockApiService.setResponse('getFrequentFoods', mockFoods);

      final result = await repository.getFrequentFoods();

      expect(result, equals(mockFoods));
      expect(mockApiService.getCallCount('getFrequentFoods'), equals(1));
    });
  });

  group('Error Handling', () {
    test('converts NetworkException to user-friendly message', () async {
      mockApiService.setResponse('searchFoods', NetworkException('Connection failed'));

      expect(
        () => repository.searchFoods('apple'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('No internet connection'),
        )),
      );
    });

    test('converts AuthenticationException to user-friendly message', () async {
      mockApiService.setResponse('searchFoods', AuthenticationException('Unauthorized'));

      expect(
        () => repository.searchFoods('apple'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('session has expired'),
        )),
      );
    });

    test('converts ValidationException to user-friendly message', () async {
      final errors = {'name': ['This field is required']};
      mockApiService.setResponse('searchFoods', ValidationException('Validation failed', errors));

      expect(
        () => repository.searchFoods('apple'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Invalid input'),
        )),
      );
    });

    test('converts ServerException to user-friendly message', () async {
      mockApiService.setResponse('searchFoods', ServerException('Internal server error'));

      expect(
        () => repository.searchFoods('apple'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Server error'),
        )),
      );
    });
  });
}
