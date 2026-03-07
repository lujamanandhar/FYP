import 'package:dio/dio.dart';
import '../models/food_item.dart';
import '../models/intake_log.dart';
import '../models/hydration_log.dart';
import '../models/nutrition_goals.dart';
import '../models/nutrition_progress.dart';
import '../../services/dio_client.dart';

/// API service for nutrition-related operations using Dio.
/// 
/// Provides methods for all nutrition endpoints including:
/// - Food item search and creation
/// - Meal intake logging
/// - Hydration tracking
/// - Progress monitoring
/// - Goals management
/// - Quick access to frequent/recent foods
/// 
/// Validates: Requirements 18.1, 18.2, 18.3, 18.4, 18.5, 18.6, 18.7, 18.8, 18.9, 18.10
class NutritionApiService {
  final DioClient _dioClient;
  late Dio _dio;

  NutritionApiService(this._dioClient) {
    _dio = _dioClient.dio;
  }

  // ==================== Food Items ====================

  /// Search for food items by query string
  /// 
  /// Validates: Requirement 18.3
  Future<List<FoodItem>> searchFoods(String query) async {
    try {
      final response = await _dio.get(
        '/nutrition/food-items/',
        queryParameters: {'search': query},
      );

      // Handle both paginated and non-paginated responses
      final List<dynamic> results;
      if (response.data is List) {
        results = response.data as List;
      } else if (response.data is Map && response.data.containsKey('results')) {
        results = response.data['results'] as List;
      } else {
        results = [];
      }
      
      return results.map((json) => FoodItem.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to search foods');
    }
  }

  /// Create a custom food item
  /// 
  /// Validates: Requirement 18.4
  Future<FoodItem> createCustomFood(FoodItem food) async {
    try {
      // Only send necessary fields for creation (exclude id, created_at, updated_at, created_by)
      final data = {
        'name': food.name,
        'brand': food.brand,
        'calories_per_100g': food.caloriesPer100g,
        'protein_per_100g': food.proteinPer100g,
        'carbs_per_100g': food.carbsPer100g,
        'fats_per_100g': food.fatsPer100g,
        'fiber_per_100g': food.fiberPer100g,
        'sugar_per_100g': food.sugarPer100g,
      };
      
      print('🔍 Creating custom food with data: $data');
      
      final response = await _dio.post(
        '/nutrition/food-items/',
        data: data,
      );

      print('✅ Custom food created successfully: ${response.data}');
      print('✅ Response status: ${response.statusCode}');
      
      return FoodItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('❌ DioException creating custom food:');
      print('   Type: ${e.type}');
      print('   Message: ${e.message}');
      print('   Response status: ${e.response?.statusCode}');
      print('   Response data: ${e.response?.data}');
      print('   Request data: ${e.requestOptions.data}');
      throw _handleDioError(e, 'Failed to create custom food');
    } catch (e, stack) {
      print('❌ Unexpected error creating custom food: $e');
      print('   Stack trace: $stack');
      rethrow;
    }
  }

  /// Get a specific food item by ID
  Future<FoodItem> getFoodItem(int id) async {
    try {
      final response = await _dio.get('/nutrition/food-items/$id/');
      return FoodItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get food item');
    }
  }

  // ==================== Intake Logs ====================

  /// Log a meal/snack/drink
  /// 
  /// Validates: Requirement 18.5
  Future<IntakeLog> logMeal(IntakeLog log) async {
    try {
      final response = await _dio.post(
        '/nutrition/intake-logs/',
        data: log.toJson(),
      );

      return IntakeLog.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to log meal');
    }
  }

  /// Get intake logs for a date range
  /// 
  /// Validates: Requirement 18.6
  Future<List<IntakeLog>> getIntakeLogs({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    try {
      print('🔍 API: Fetching intake logs from ${dateFrom.toIso8601String().split('T')[0]} to ${dateTo.toIso8601String().split('T')[0]}');
      final response = await _dio.get(
        '/nutrition/intake-logs/',
        queryParameters: {
          'date_from': dateFrom.toIso8601String().split('T')[0],
          'date_to': dateTo.toIso8601String().split('T')[0],
        },
      );

      print('🔍 API: Response status: ${response.statusCode}');
      print('🔍 API: Response data type: ${response.data.runtimeType}');
      print('🔍 API: Response data: ${response.data}');

      // Handle both paginated and non-paginated responses
      final List<dynamic> results;
      if (response.data is List) {
        results = response.data as List;
      } else if (response.data is Map && response.data.containsKey('results')) {
        results = response.data['results'] as List;
      } else {
        results = [];
      }
      
      print('🔍 API: Parsed ${results.length} intake logs');
      return results.map((json) => IntakeLog.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      print('❌ API: DioException - ${e.type}: ${e.message}');
      print('❌ API: Response: ${e.response?.data}');
      throw _handleDioError(e, 'Failed to get intake logs');
    } catch (e, stack) {
      print('❌ API: Unexpected error: $e');
      print('❌ API: Stack trace: $stack');
      rethrow;
    }
  }

  /// Update an existing intake log
  /// 
  /// Validates: Requirement 18.6
  Future<IntakeLog> updateIntakeLog(IntakeLog log) async {
    try {
      final response = await _dio.put(
        '/nutrition/intake-logs/${log.id}/',
        data: log.toJson(),
      );

      return IntakeLog.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update intake log');
    }
  }

  /// Delete an intake log
  /// 
  /// Validates: Requirement 18.6
  Future<void> deleteIntakeLog(int id) async {
    try {
      await _dio.delete('/nutrition/intake-logs/$id/');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to delete intake log');
    }
  }

  /// Get recently logged foods
  /// Returns unique food items from user's recent logs
  Future<List<FoodItem>> getRecentFoods() async {
    try {
      final response = await _dio.get('/nutrition/intake-logs/recent_foods/');
      
      final List<dynamic> results;
      if (response.data is List) {
        results = response.data as List;
      } else if (response.data is Map && response.data.containsKey('results')) {
        results = response.data['results'] as List;
      } else {
        results = [];
      }
      
      return results.map((json) => FoodItem.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get recent foods');
    }
  }

  // ==================== Hydration Logs ====================

  /// Log water intake
  /// 
  /// Validates: Requirement 18.7
  Future<HydrationLog> logHydration(HydrationLog log) async {
    try {
      final response = await _dio.post(
        '/nutrition/hydration-logs/',
        data: log.toJson(),
      );

      return HydrationLog.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to log hydration');
    }
  }

  /// Get hydration logs for a date range
  Future<List<HydrationLog>> getHydrationLogs({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    try {
      final response = await _dio.get(
        '/nutrition/hydration-logs/',
        queryParameters: {
          'date_from': dateFrom.toIso8601String().split('T')[0],
          'date_to': dateTo.toIso8601String().split('T')[0],
        },
      );

      // Handle both paginated and non-paginated responses
      final List<dynamic> results;
      if (response.data is List) {
        results = response.data as List;
      } else if (response.data is Map && response.data.containsKey('results')) {
        results = response.data['results'] as List;
      } else {
        results = [];
      }
      
      return results.map((json) => HydrationLog.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get hydration logs');
    }
  }

  /// Delete a hydration log
  Future<void> deleteHydrationLog(int id) async {
    try {
      await _dio.delete('/nutrition/hydration-logs/$id/');
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to delete hydration log');
    }
  }

  // ==================== Nutrition Progress ====================

  /// Get nutrition progress for a specific date
  /// 
  /// Validates: Requirement 18.8
  Future<NutritionProgress?> getProgress(DateTime date) async {
    try {
      final response = await _dio.get(
        '/nutrition/nutrition-progress/',
        queryParameters: {
          'date_from': date.toIso8601String().split('T')[0],
          'date_to': date.toIso8601String().split('T')[0],
        },
      );

      // Handle both paginated and non-paginated responses
      final List<dynamic> results;
      if (response.data is List) {
        results = response.data as List;
      } else if (response.data is Map && response.data.containsKey('results')) {
        results = response.data['results'] as List;
      } else {
        results = [];
      }
      
      if (results.isEmpty) return null;
      
      return NutritionProgress.fromJson(results.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get nutrition progress');
    }
  }

  // ==================== Nutrition Goals ====================

  /// Get user's nutrition goals
  /// 
  /// Validates: Requirement 18.9
  Future<NutritionGoals?> getGoals() async {
    try {
      final response = await _dio.get('/nutrition/nutrition-goals/');
      
      // Handle both paginated and non-paginated responses
      final List<dynamic> results;
      if (response.data is List) {
        results = response.data as List;
      } else if (response.data is Map && response.data.containsKey('results')) {
        results = response.data['results'] as List;
      } else {
        results = [];
      }
      
      if (results.isEmpty) return null;
      
      return NutritionGoals.fromJson(results.first as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get nutrition goals');
    }
  }

  /// Update user's nutrition goals
  /// 
  /// Validates: Requirement 18.9
  Future<NutritionGoals> updateGoals(NutritionGoals goals) async {
    try {
      final response = await _dio.put(
        '/nutrition/nutrition-goals/${goals.id}/',
        data: goals.toJson(),
      );

      return NutritionGoals.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to update nutrition goals');
    }
  }

  /// Create user's nutrition goals
  /// 
  /// Validates: Requirement 18.9
  Future<NutritionGoals> createGoals(NutritionGoals goals) async {
    try {
      final response = await _dio.post(
        '/nutrition/nutrition-goals/',
        data: goals.toJson(),
      );

      return NutritionGoals.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to create nutrition goals');
    }
  }

  // ==================== Quick Log ====================

  /// Get frequently logged foods
  /// 
  /// Validates: Requirement 18.9
  Future<List<FoodItem>> getFrequentFoods() async {
    try {
      final response = await _dio.get('/nutrition/quick-logs/frequent/');
      
      final List<dynamic> results = response.data as List;
      return results.map((json) => FoodItem.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to get frequent foods');
    }
  }

  // ==================== Error Handling ====================

  /// Handle Dio errors and convert to user-friendly exceptions
  /// 
  /// Validates: Requirement 18.10
  Exception _handleDioError(DioException error, String defaultMessage) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      String message = defaultMessage;
      if (data is Map<String, dynamic>) {
        message = data['message'] ?? data['error'] ?? data['detail'] ?? defaultMessage;
      }

      switch (statusCode) {
        case 400:
          return ValidationException(message, data);
        case 401:
          return AuthenticationException(message);
        case 403:
          return AuthorizationException(message);
        case 404:
          return NotFoundException(message);
        case 429:
          return RateLimitException(message);
        case 500:
        case 502:
        case 503:
          return ServerException(message);
        default:
          return ApiException(message, statusCode);
      }
    }

    // Network errors
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return NetworkException('Request timeout. Please check your connection and try again.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return NetworkException('No internet connection. Please check your network and try again.');
    }

    return ApiException(defaultMessage, null);
  }
}

// ==================== Custom Exception Classes ====================

/// Base API exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

/// Validation error (400)
class ValidationException extends ApiException {
  final dynamic errors;

  ValidationException(String message, this.errors) : super(message, 400);

  Map<String, dynamic>? get fieldErrors {
    if (errors is Map<String, dynamic>) {
      return errors as Map<String, dynamic>;
    }
    return null;
  }
}

/// Authentication error (401)
class AuthenticationException extends ApiException {
  AuthenticationException(String message) : super(message, 401);
}

/// Authorization error (403)
class AuthorizationException extends ApiException {
  AuthorizationException(String message) : super(message, 403);
}

/// Not found error (404)
class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, 404);
}

/// Rate limit error (429)
class RateLimitException extends ApiException {
  RateLimitException(String message) : super(message, 429);
}

/// Server error (500+)
class ServerException extends ApiException {
  ServerException(String message) : super(message, 500);
}

/// Network error (no connection, timeout)
class NetworkException extends ApiException {
  NetworkException(String message) : super(message, null);
}
