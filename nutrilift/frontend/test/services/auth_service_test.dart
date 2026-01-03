import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilift/services/auth_service.dart';

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
}