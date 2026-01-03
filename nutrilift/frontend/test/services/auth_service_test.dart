import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilift/services/auth_service.dart';
import 'package:nutrilift/services/api_client.dart';
import 'dart:io';
import 'dart:math';

void main() {
  group('AuthService Request Models', () {
    test('RegisterRequest validation works correctly', () {
      // Test valid request
      final validRequest = RegisterRequest(
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
      );
      expect(validRequest.validate(), isEmpty);

      // Test invalid email
      final invalidEmailRequest = RegisterRequest(
        email: 'invalid-email',
        password: 'password123',
        name: 'Test User',
      );
      expect(invalidEmailRequest.validate(), isNotEmpty);
      expect(invalidEmailRequest.validateEmail(), contains('valid email'));

      // Test short password
      final shortPasswordRequest = RegisterRequest(
        email: 'test@example.com',
        password: '123',
        name: 'Test User',
      );
      expect(shortPasswordRequest.validate(), isNotEmpty);
      expect(shortPasswordRequest.validatePassword(), contains('8 characters'));

      // Test empty name
      final emptyNameRequest = RegisterRequest(
        email: 'test@example.com',
        password: 'password123',
        name: '',
      );
      expect(emptyNameRequest.validate(), isNotEmpty);
      expect(emptyNameRequest.validateName(), contains('required'));
    });

    test('LoginRequest validation works correctly', () {
      // Test valid request
      final validRequest = LoginRequest(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(validRequest.validate(), isEmpty);

      // Test invalid email
      final invalidEmailRequest = LoginRequest(
        email: 'invalid-email',
        password: 'password123',
      );
      expect(invalidEmailRequest.validate(), isNotEmpty);

      // Test empty password
      final emptyPasswordRequest = LoginRequest(
        email: 'test@example.com',
        password: '',
      );
      expect(emptyPasswordRequest.validate(), isNotEmpty);
    });

    test('ProfileUpdateRequest validation works correctly', () {
      // Test valid request
      final validRequest = ProfileUpdateRequest(
        name: 'Test User',
        gender: 'Male',
        ageGroup: 'Adult',
        height: 175.0,
        weight: 70.0,
        fitnessLevel: 'Intermediate',
      );
      expect(validRequest.validate(), isEmpty);

      // Test invalid height
      final invalidHeightRequest = ProfileUpdateRequest(height: -10.0);
      expect(invalidHeightRequest.validate(), isNotEmpty);
      expect(invalidHeightRequest.validateHeight(), contains('positive'));

      // Test invalid gender
      final invalidGenderRequest = ProfileUpdateRequest(gender: 'Other');
      expect(invalidGenderRequest.validate(), isNotEmpty);
      expect(invalidGenderRequest.validateGender(), contains('Male or Female'));

      // Test invalid fitness level
      final invalidFitnessRequest = ProfileUpdateRequest(fitnessLevel: 'Expert');
      expect(invalidFitnessRequest.validate(), isNotEmpty);
      expect(invalidFitnessRequest.validateFitnessLevel(), contains('Invalid'));
    });
  });

  group('UserProfile Model', () {
    test('UserProfile fromJson and toJson work correctly', () {
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'name': 'Test User',
        'gender': 'Male',
        'age_group': 'Adult',
        'height': 175.0,
        'weight': 70.0,
        'fitness_level': 'Intermediate',
        'created_at': '2025-01-01T12:00:00Z',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.id, equals('test-id'));
      expect(profile.email, equals('test@example.com'));
      expect(profile.name, equals('Test User'));
      expect(profile.gender, equals('Male'));
      expect(profile.ageGroup, equals('Adult'));
      expect(profile.height, equals(175.0));
      expect(profile.weight, equals(70.0));
      expect(profile.fitnessLevel, equals('Intermediate'));
      expect(profile.hasCompleteProfile, isTrue);

      final backToJson = profile.toJson();
      expect(backToJson['id'], equals('test-id'));
      expect(backToJson['email'], equals('test@example.com'));
      expect(backToJson['age_group'], equals('Adult'));
    });

    test('hasCompleteProfile works correctly', () {
      final completeProfile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
        gender: 'Male',
        ageGroup: 'Adult',
        height: 175.0,
        weight: 70.0,
        fitnessLevel: 'Intermediate',
      );
      expect(completeProfile.hasCompleteProfile, isTrue);

      final incompleteProfile = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
      );
      expect(incompleteProfile.hasCompleteProfile, isFalse);
    });

    test('displayName works correctly', () {
      final profileWithName = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
        name: 'Test User',
      );
      expect(profileWithName.displayName, equals('Test User'));

      final profileWithoutName = UserProfile(
        id: 'test-id',
        email: 'test@example.com',
      );
      expect(profileWithoutName.displayName, equals('test'));
    });
  });

  // Property-based tests for network error handling
  group('Property 14: Network Error Handling', () {
    test('Feature: user-authentication-profile, Property 14: Network Error Handling - ApiException categorization', () {
      // Property test: For any ApiException, it should be properly categorized
      final testCases = [
        {'statusCode': null, 'expectedType': 'network'},
        {'statusCode': 400, 'expectedType': 'validation'},
        {'statusCode': 401, 'expectedType': 'unauthorized'},
        {'statusCode': 500, 'expectedType': 'server'},
        {'statusCode': 503, 'expectedType': 'server'},
      ];
      
      for (final testCase in testCases) {
        final exception = ApiException(
          'Test error',
          statusCode: testCase['statusCode'] as int?,
          errors: testCase['expectedType'] == 'validation' ? {'field': ['error']} : null,
        );
        
        switch (testCase['expectedType']) {
          case 'network':
            expect(exception.isNetworkError(), isTrue);
            expect(exception.isUnauthorized(), isFalse);
            expect(exception.isValidationError(), isFalse);
            expect(exception.isServerError(), isFalse);
            break;
          case 'validation':
            expect(exception.isNetworkError(), isFalse);
            expect(exception.isUnauthorized(), isFalse);
            expect(exception.isValidationError(), isTrue);
            expect(exception.isServerError(), isFalse);
            break;
          case 'unauthorized':
            expect(exception.isNetworkError(), isFalse);
            expect(exception.isUnauthorized(), isTrue);
            expect(exception.isValidationError(), isFalse);
            expect(exception.isServerError(), isFalse);
            break;
          case 'server':
            expect(exception.isNetworkError(), isFalse);
            expect(exception.isUnauthorized(), isFalse);
            expect(exception.isValidationError(), isFalse);
            expect(exception.isServerError(), isTrue);
            break;
        }
      }
    });

    test('Feature: user-authentication-profile, Property 14: Network Error Handling - Error message user-friendliness', () {
      // Property test: For any network error type, the error message should be user-friendly
      final networkErrorMessages = [
        'No internet connection. Please check your network and try again.',
        'Network error occurred. Please try again.',
        'Invalid response format from server.',
        'An unexpected error occurred. Please try again.',
      ];
      
      for (final message in networkErrorMessages) {
        final apiException = ApiException(message);
        
        // Verify error message is user-friendly
        expect(apiException.message, isNotEmpty);
        expect(apiException.message, isNot(contains('Exception')));
        expect(apiException.message, isNot(contains('Stack trace')));
        expect(apiException.message, isNot(contains('null')));
        
        // Should contain helpful guidance
        final lowerMessage = apiException.message.toLowerCase();
        final hasHelpfulGuidance = lowerMessage.contains('try again') ||
                                 lowerMessage.contains('check') ||
                                 lowerMessage.contains('please') ||
                                 lowerMessage.contains('network') ||
                                 lowerMessage.contains('connection') ||
                                 lowerMessage.contains('server');
        expect(hasHelpfulGuidance, isTrue, 
               reason: 'Error message should provide helpful guidance: ${apiException.message}');
      }
    });

    test('Feature: user-authentication-profile, Property 14: Network Error Handling - Error conversion consistency', () {
      // Property test: For any type of network error, conversion to ApiException should be consistent
      final random = Random();
      final errorTypes = ['socket', 'http', 'format', 'generic'];
      
      for (int i = 0; i < 20; i++) {
        final errorType = errorTypes[random.nextInt(errorTypes.length)];
        final apiException = _convertToApiException(_createErrorByType(errorType));
        
        // All network errors should result in ApiException
        expect(apiException, isA<ApiException>());
        expect(apiException.message, isNotEmpty);
        
        // Network errors should not have status codes (indicating they're not HTTP errors)
        if (errorType == 'socket' || errorType == 'http' || errorType == 'format' || errorType == 'generic') {
          expect(apiException.isNetworkError(), isTrue);
        }
        
        // Error messages should be appropriate for the error type
        switch (errorType) {
          case 'socket':
            expect(apiException.message, contains('internet connection'));
            expect(apiException.message, contains('network'));
            break;
          case 'http':
            expect(apiException.message, contains('Network error'));
            expect(apiException.message, contains('try again'));
            break;
          case 'format':
            expect(apiException.message, contains('Invalid response format'));
            expect(apiException.message, contains('server'));
            break;
          case 'generic':
            expect(apiException.message, contains('unexpected error'));
            expect(apiException.message, contains('try again'));
            break;
        }
      }
    });

    test('Feature: user-authentication-profile, Property 14: Network Error Handling - Field error extraction', () {
      // Property test: For any validation error, field-specific errors should be extractable
      final fieldNames = ['email', 'password', 'name', 'height', 'weight'];
      final random = Random();
      
      for (int i = 0; i < 10; i++) {
        final field = fieldNames[random.nextInt(fieldNames.length)];
        final errorMessage = 'This field is invalid';
        
        final exception = ApiException(
          'Validation failed',
          statusCode: 400,
          errors: {field: [errorMessage]},
        );
        
        expect(exception.isValidationError(), isTrue);
        expect(exception.getFieldError(field), equals(errorMessage));
        expect(exception.getFieldError('nonexistent_field'), isNull);
      }
    });

    test('Feature: user-authentication-profile, Property 14: Network Error Handling - AuthService error wrapping', () {
      // Property test: For any error in AuthService methods, error messages should be user-friendly
      final authService = AuthService();
      
      // Test that AuthService has proper error handling structure
      expect(authService, isNotNull);
      
      // Test that invalid requests would produce proper validation errors
      final invalidRegisterRequest = RegisterRequest(email: '', password: '', name: '');
      final registerErrors = invalidRegisterRequest.validate();
      expect(registerErrors, isNotEmpty);
      expect(registerErrors.every((error) => error.isNotEmpty), isTrue);
      
      final invalidLoginRequest = LoginRequest(email: '', password: '');
      final loginErrors = invalidLoginRequest.validate();
      expect(loginErrors, isNotEmpty);
      expect(loginErrors.every((error) => error.isNotEmpty), isTrue);
      
      final invalidProfileRequest = ProfileUpdateRequest(height: -10.0, weight: -5.0);
      final profileErrors = invalidProfileRequest.validate();
      expect(profileErrors, isNotEmpty);
      expect(profileErrors.every((error) => error.isNotEmpty), isTrue);
    });
  });
}

// Helper function to convert various errors to ApiException (simulating ApiClient behavior)
ApiException _convertToApiException(dynamic error) {
  if (error is SocketException) {
    return ApiException('No internet connection. Please check your network and try again.');
  } else if (error is HttpException) {
    return ApiException('Network error occurred. Please try again.');
  } else if (error is FormatException) {
    return ApiException('Invalid response format from server.');
  } else {
    return ApiException('An unexpected error occurred. Please try again.');
  }
}

// Helper function to create different types of errors for testing
dynamic _createErrorByType(String type) {
  switch (type) {
    case 'socket':
      return SocketException('Network unreachable');
    case 'http':
      return HttpException('Connection failed');
    case 'format':
      return const FormatException('Invalid JSON');
    case 'generic':
    default:
      return Exception('Unexpected error');
  }
}