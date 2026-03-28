import 'package:dio/dio.dart';
import '../models/workout_log.dart';
import '../models/workout_models.dart' show CreateWorkoutLogRequest, ExerciseSetRequest, WorkoutSetRequest;
import '../repositories/workout_repository.dart';
import 'dio_client.dart';

/// API service for workout-related operations using Dio.
/// 
/// Implements the WorkoutRepository interface to provide
/// workout data access through the backend API.
/// 
/// Validates: Requirements 1.2, 2.8, 15.1, 7.4, 7.5
class WorkoutApiService implements WorkoutRepository {
  final DioClient _dioClient;
  late Dio _dio;

  WorkoutApiService(this._dioClient) {
    _dio = _dioClient.dio;
  }

  @override
  Future<List<WorkoutLog>> getWorkoutHistory({
    DateTime? dateFrom,
    int? limit,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String();
      }
      if (limit != null) {
        queryParams['limit'] = limit;
      }

      final response = await _dio.get(
        '/workouts/logs/get_history/',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data as List;
      return data.map((json) => WorkoutLog.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to load workout history');
    }
  }

  @override
  Future<WorkoutLog> logWorkout(CreateWorkoutLogRequest workout) async {
    try {
      // Convert the request to match backend API format
      final requestData = _convertWorkoutLogRequest(workout);

      print('DEBUG: Sending workout log request: $requestData');

      final response = await _dio.post(
        '/workouts/logs/log_workout/',
        data: requestData,
      );

      print('DEBUG: Workout log response: ${response.data}');

      return WorkoutLog.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      print('DEBUG: Workout log error: ${e.response?.data}');
      print('DEBUG: Status code: ${e.response?.statusCode}');
      throw _handleDioError(e, 'Failed to log workout');
    }
  }

  /// Fetch user's custom workout templates
  Future<List<Map<String, dynamic>>> getCustomWorkouts() async {
    try {
      final response = await _dio.get('/workouts/custom-workouts/');
      final List<dynamic> data = response.data as List;
      return data.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to load custom workouts');
    }
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String();
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String();
      }

      final response = await _dio.get(
        '/workouts/logs/statistics/',
        queryParameters: queryParams,
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to load workout statistics');
    }
  }

  /// Convert CreateWorkoutLogRequest to backend API format
  Map<String, dynamic> _convertWorkoutLogRequest(CreateWorkoutLogRequest request) {
    // Convert the request format to match the backend API expectations
    // The backend expects: workout_name, custom_workout, gym_id, duration_minutes, notes, workout_exercises[]
    // Each exercise should have: exercise (id), sets (count), reps, weight, order
    
    final exercises = <Map<String, dynamic>>[];
    for (var exerciseSet in request.exercises) {
      if (exerciseSet.sets.isNotEmpty) {
        // Use the first set's values as representative values
        final firstSet = exerciseSet.sets.first;
        final reps = firstSet.reps ?? 1;
        // Backend requires weight >= 0.1; use 0.1 as minimum for bodyweight exercises
        final weight = (firstSet.weight != null && firstSet.weight! >= 0.1)
            ? firstSet.weight!
            : 0.1;
        exercises.add({
          'exercise': int.parse(exerciseSet.exerciseId),
          'sets': exerciseSet.sets.length,
          'reps': reps.clamp(1, 100),
          'weight': weight,
          'order': exerciseSet.order,
        });
      }
    }

    final data = {
      'workout_name': request.workoutName,
      'duration_minutes': request.durationMinutes,
      'workout_exercises': exercises,
    };

    // Include calories_burned if provided (e.g. guided workouts estimate)
    if (request.caloriesBurned > 0) {
      data['calories_burned'] = request.caloriesBurned;
    }

    // Only include custom_workout if it's provided and valid
    if (request.customWorkoutId != null && request.customWorkoutId!.isNotEmpty) {
      try {
        data['custom_workout'] = int.parse(request.customWorkoutId!);
      } catch (e) {
        // Invalid custom workout ID, skip it
        print('DEBUG: Skipping invalid custom_workout_id: ${request.customWorkoutId}');
      }
    }
    
    // Only include gym_id if it's provided and valid
    if (request.gymId != null && request.gymId!.isNotEmpty) {
      try {
        data['gym_id'] = int.parse(request.gymId!);
      } catch (e) {
        // Invalid gym ID, skip it
        print('DEBUG: Skipping invalid gym_id: ${request.gymId}');
      }
    }
    
    if (request.notes != null && request.notes!.isNotEmpty) {
      data['notes'] = request.notes!;
    }

    return data;
  }

  /// Handle Dio errors and convert to user-friendly exceptions
  Exception _handleDioError(DioException error, String defaultMessage) {
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;

      String message = defaultMessage;
      if (data is Map<String, dynamic>) {
        message = data['message'] ?? data['error'] ?? defaultMessage;
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

// Custom exception classes for better error handling

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}

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

class AuthenticationException extends ApiException {
  AuthenticationException(String message) : super(message, 401);
}

class AuthorizationException extends ApiException {
  AuthorizationException(String message) : super(message, 403);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, 404);
}

class RateLimitException extends ApiException {
  RateLimitException(String message) : super(message, 429);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message, 500);
}

class NetworkException extends ApiException {
  NetworkException(String message) : super(message, null);
}
