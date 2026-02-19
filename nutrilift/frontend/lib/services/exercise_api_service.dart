import 'package:dio/dio.dart';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';
import 'dio_client.dart';
import 'workout_api_service.dart';

/// API service for exercise library operations using Dio.
/// 
/// Implements the ExerciseRepository interface to provide
/// exercise data access through the backend API.
/// 
/// Validates: Requirements 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.9
class ExerciseApiService implements ExerciseRepository {
  final DioClient _dioClient;
  late Dio _dio;

  ExerciseApiService(this._dioClient) {
    _dio = _dioClient.dio;
  }

  @override
  Future<List<Exercise>> getExercises({
    String? category,
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      if (category != null) {
        queryParams['category'] = category;
      }
      if (muscleGroup != null) {
        queryParams['muscle'] = muscleGroup;
      }
      if (equipment != null) {
        queryParams['equipment'] = equipment;
      }
      if (difficulty != null) {
        queryParams['difficulty'] = difficulty;
      }
      if (search != null) {
        queryParams['search'] = search;
      }

      final response = await _dio.get(
        '/exercises/',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data as List;
      return data.map((json) => Exercise.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to load exercises');
    }
  }

  @override
  Future<Exercise> getExerciseById(String id) async {
    try {
      final response = await _dio.get('/exercises/$id/');

      return Exercise.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to load exercise');
    }
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
