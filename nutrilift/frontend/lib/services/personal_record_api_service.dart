import 'package:dio/dio.dart';
import '../models/personal_record.dart';
import '../repositories/personal_record_repository.dart';
import 'dio_client.dart';
import 'workout_api_service.dart';

/// API service for personal record operations using Dio.
/// 
/// Implements the PersonalRecordRepository interface to provide
/// personal record data access through the backend API.
/// 
/// Validates: Requirements 4.4, 4.6, 5.4
class PersonalRecordApiService implements PersonalRecordRepository {
  final DioClient _dioClient;
  late Dio _dio;

  PersonalRecordApiService(this._dioClient) {
    _dio = _dioClient.dio;
  }

  @override
  Future<List<PersonalRecord>> getPersonalRecords() async {
    try {
      final response = await _dio.get('/personal-records/');

      final List<dynamic> data = response.data as List;
      return data.map((json) => PersonalRecord.fromJson(json as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw _handleDioError(e, 'Failed to load personal records');
    }
  }

  @override
  Future<PersonalRecord?> getPersonalRecordForExercise(String exerciseId) async {
    try {
      final response = await _dio.get(
        '/personal-records/',
        queryParameters: {'exercise_id': exerciseId},
      );

      final List<dynamic> data = response.data as List;
      if (data.isEmpty) {
        return null;
      }

      // Return the first matching record
      return PersonalRecord.fromJson(data.first as Map<String, dynamic>);
    } on DioException catch (e) {
      // If it's a 404, return null (no record found)
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw _handleDioError(e, 'Failed to load personal record');
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
