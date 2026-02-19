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
        '/workouts/history/',
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

      final response = await _dio.post(
        '/workouts/log/',
        data: requestData,
      );

      return WorkoutLog.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to log workout');
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
        '/workouts/statistics/',
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
    // The backend expects: custom_workout, gym, date, duration, notes, exercises[]
    // Each exercise should have: exercise (id), sets, reps, weight, order
    
    final exercises = <Map<String, dynamic>>[];
    for (var exerciseSet in request.exercises) {
      // For each exercise set, we need to aggregate the sets into a single entry
      // The backend expects: exercise, sets (count), reps, weight, order
      if (exerciseSet.sets.isNotEmpty) {
        final firstSet = exerciseSet.sets.first;
        exercises.add({
          'exercise': int.parse(exerciseSet.exerciseId),
          'sets': exerciseSet.sets.length,
          'reps': firstSet.reps ?? 0,
          'weight': firstSet.weight ?? 0.0,
          'order': exerciseSet.order,
        });
      }
    }

    return {
      if (request.customWorkoutId != null) 
        'custom_workout': int.parse(request.customWorkoutId!),
      if (request.gymId != null) 
        'gym': int.parse(request.gymId!),
      'date': DateTime.now().toIso8601String(),
      'duration': request.durationMinutes,
      'notes': request.notes ?? '',
      'exercises': exercises,
    };
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
