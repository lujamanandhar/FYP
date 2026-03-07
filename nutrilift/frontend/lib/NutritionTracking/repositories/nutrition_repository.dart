import '../models/food_item.dart';
import '../models/intake_log.dart';
import '../models/hydration_log.dart';
import '../models/nutrition_goals.dart';
import '../models/nutrition_progress.dart';
import '../services/nutrition_api_service.dart';

/// Repository for nutrition-related data operations.
/// 
/// Provides business logic layer between API service and UI,
/// including caching, error handling, and data transformation.
/// 
/// Validates: Requirements 19.1, 19.2, 19.3, 19.4, 19.5, 19.6, 19.7, 19.8
class NutritionRepository {
  final NutritionApiService _apiService;

  // Cache for goals to minimize API calls (5 minutes)
  NutritionGoals? _cachedGoals;
  DateTime? _goalsCacheTime;
  static const Duration _goalsCacheDuration = Duration(minutes: 5);

  // Cache for recent food searches
  final Map<String, List<FoodItem>> _searchCache = {};
  final Map<String, DateTime> _searchCacheTime = {};
  static const Duration _searchCacheDuration = Duration(minutes: 2);

  NutritionRepository(this._apiService);

  // ==================== Retry Logic ====================

  /// Retry a failed operation with exponential backoff
  /// 
  /// Validates: Requirement 22.5
  Future<T> _retryOperation<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        // Don't retry for certain error types
        if (e is AuthenticationException ||
            e is AuthorizationException ||
            e is ValidationException) {
          rethrow;
        }

        // If max attempts reached, rethrow the error
        if (attempt >= maxAttempts) {
          rethrow;
        }

        // Wait before retrying with exponential backoff
        await Future.delayed(delay);
        delay *= 2; // Double the delay for next attempt
      }
    }
  }

  // ==================== Food Items ====================

  /// Search for food items with caching
  /// 
  /// Validates: Requirement 19.3
  Future<List<FoodItem>> searchFoods(String query) async {
    try {
      // Check cache first
      if (_searchCache.containsKey(query) && _searchCacheTime.containsKey(query)) {
        final cacheTime = _searchCacheTime[query]!;
        if (DateTime.now().difference(cacheTime) < _searchCacheDuration) {
          return _searchCache[query]!;
        }
      }

      // Fetch from API
      final results = await _apiService.searchFoods(query);

      // Update cache
      _searchCache[query] = results;
      _searchCacheTime[query] = DateTime.now();

      return results;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create a custom food item
  Future<FoodItem> createCustomFood(FoodItem food) async {
    try {
      return await _apiService.createCustomFood(food);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get a specific food item by ID
  Future<FoodItem> getFoodItem(int id) async {
    try {
      return await _apiService.getFoodItem(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Intake Logs ====================

  /// Log a meal and return updated progress
  /// 
  /// Validates: Requirements 19.4, 22.5
  Future<IntakeLog> logMeal(IntakeLog log) async {
    try {
      final result = await _retryOperation(() => _apiService.logMeal(log));
      return result;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get intake logs for a specific date
  /// 
  /// Validates: Requirements 19.4, 22.5
  Future<List<IntakeLog>> getIntakeLogs(DateTime date) async {
    try {
      return await _retryOperation(() => _apiService.getIntakeLogs(
        dateFrom: date,
        dateTo: date,
      ));
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update an existing intake log
  Future<IntakeLog> updateIntakeLog(IntakeLog log) async {
    try {
      return await _apiService.updateIntakeLog(log);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete an intake log
  /// 
  /// Validates: Requirement 19.4
  Future<void> deleteIntakeLog(int id) async {
    try {
      await _apiService.deleteIntakeLog(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get recently logged foods
  Future<List<FoodItem>> getRecentFoods() async {
    try {
      return await _retryOperation(() => _apiService.getRecentFoods());
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Hydration Logs ====================

  /// Log water intake
  /// 
  /// Validates: Requirement 22.5
  Future<HydrationLog> logHydration(HydrationLog log) async {
    try {
      return await _retryOperation(() => _apiService.logHydration(log));
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Get hydration logs for a specific date
  Future<List<HydrationLog>> getHydrationLogs(DateTime date) async {
    try {
      return await _apiService.getHydrationLogs(
        dateFrom: date,
        dateTo: date,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Delete a hydration log
  Future<void> deleteHydrationLog(int id) async {
    try {
      await _apiService.deleteHydrationLog(id);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Nutrition Progress ====================

  /// Get daily nutrition progress for a specific date
  /// 
  /// Validates: Requirements 19.5, 22.5
  Future<NutritionProgress?> getDailyProgress(DateTime date) async {
    try {
      return await _retryOperation(() => _apiService.getProgress(date));
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Nutrition Goals ====================

  /// Get user's nutrition goals with caching
  /// 
  /// Validates: Requirements 19.5, 19.8, 22.5
  Future<NutritionGoals> getGoals({bool forceRefresh = false}) async {
    try {
      // Return cached goals if available and not expired
      if (!forceRefresh &&
          _cachedGoals != null &&
          _goalsCacheTime != null &&
          DateTime.now().difference(_goalsCacheTime!) < _goalsCacheDuration) {
        return _cachedGoals!;
      }

      // Fetch from API with retry logic
      final goals = await _retryOperation(() => _apiService.getGoals());

      // If no goals exist, create default goals
      if (goals == null) {
        final defaultGoals = NutritionGoals.defaults(userId: null);
        final created = await _retryOperation(() => _apiService.createGoals(defaultGoals));
        _cachedGoals = created;
        _goalsCacheTime = DateTime.now();
        return created;
      }

      // Update cache
      _cachedGoals = goals;
      _goalsCacheTime = DateTime.now();

      return goals;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Update user's nutrition goals
  /// 
  /// Validates: Requirement 22.5
  Future<NutritionGoals> updateGoals(NutritionGoals goals) async {
    try {
      final updated = await _retryOperation(() => _apiService.updateGoals(goals));

      // Update cache
      _cachedGoals = updated;
      _goalsCacheTime = DateTime.now();

      return updated;
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Create user's nutrition goals
  Future<NutritionGoals> createGoals(NutritionGoals goals) async {
    try {
      final created = await _apiService.createGoals(goals);

      // Update cache
      _cachedGoals = created;
      _goalsCacheTime = DateTime.now();

      return created;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Quick Access ====================

  /// Get frequently logged foods
  /// 
  /// Validates: Requirement 19.6
  Future<List<FoodItem>> getFrequentFoods() async {
    try {
      return await _apiService.getFrequentFoods();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ==================== Error Handling ====================

  /// Handle errors and provide user-friendly messages
  /// 
  /// Validates: Requirements 19.7, 22.1, 22.2, 22.3, 22.4
  Exception _handleError(dynamic error) {
    // If it's already a typed exception from the API service, return it with user-friendly message
    if (error is NetworkException) {
      return Exception('No internet connection. Please check your network and try again.');
    }
    
    if (error is AuthenticationException) {
      return Exception('Your session has expired. Please log in again.');
    }
    
    if (error is AuthorizationException) {
      return Exception('You don\'t have permission to perform this action.');
    }
    
    if (error is ValidationException) {
      // Extract field-specific errors if available
      final fieldErrors = error.fieldErrors;
      if (fieldErrors != null && fieldErrors.isNotEmpty) {
        final firstError = fieldErrors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return Exception('Invalid input: ${firstError.first}');
        }
        return Exception('Invalid input: $firstError');
      }
      return Exception('Please check your input and try again.');
    }
    
    if (error is NotFoundException) {
      return Exception('The requested item was not found.');
    }
    
    if (error is RateLimitException) {
      return Exception('Too many requests. Please wait a moment and try again.');
    }
    
    if (error is ServerException) {
      return Exception('Server error. Please try again in a few moments.');
    }
    
    if (error is ApiException) {
      return Exception('Unable to complete request. Please try again.');
    }

    // For any other error, wrap it in a generic exception
    return Exception('An unexpected error occurred. Please try again.');
  }
}
