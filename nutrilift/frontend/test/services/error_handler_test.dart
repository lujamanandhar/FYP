import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilift/services/error_handler.dart';
import 'package:nutrilift/services/api_client.dart';

void main() {
  group('ErrorHandler', () {
    late ErrorHandler errorHandler;

    setUp(() {
      errorHandler = ErrorHandler();
    });

    test('should handle API errors correctly', () {
      // Test network error
      final networkError = ApiException('Network error');
      final networkMessage = errorHandler.handleApiError(networkError);
      expect(networkMessage, contains('Network error'));

      // Test unauthorized error
      final unauthorizedError = ApiException('Unauthorized', statusCode: 401);
      final unauthorizedMessage = errorHandler.handleApiError(unauthorizedError);
      expect(unauthorizedMessage, contains('session has expired'));

      // Test validation error
      final validationError = ApiException('Validation failed', 
          statusCode: 400, 
          errors: {'email': ['Invalid email format']});
      final validationMessage = errorHandler.handleApiError(validationError);
      expect(validationMessage, contains('Invalid email format'));

      // Test server error
      final serverError = ApiException('Server error', statusCode: 500);
      final serverMessage = errorHandler.handleApiError(serverError);
      expect(serverMessage, contains('Server error occurred'));
    });

    test('should track error log', () {
      // Clear any existing errors
      errorHandler.clearErrorLog();
      expect(errorHandler.errorLog, isEmpty);
      
      // This would normally be called internally, but we can test the log functionality
      final error = ApiException('Test error');
      errorHandler.handleApiError(error);
      
      // The error log should now contain one entry
      expect(errorHandler.errorLog, hasLength(1));
      expect(errorHandler.errorLog.first, contains('Test error'));
    });

    test('should detect offline status', () {
      // Initially should not be offline (default state)
      expect(errorHandler.isOffline, isFalse);
    });

    tearDown(() {
      errorHandler.dispose();
    });
  });
}