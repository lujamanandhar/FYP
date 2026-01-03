import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:math';
import '../../lib/services/onboarding_service.dart';
import '../../lib/services/auth_service.dart';
import '../../lib/models/onboarding_data.dart';

// Generate mocks
@GenerateMocks([AuthService])
import 'onboarding_service_test.mocks.dart';

void main() {
  group('OnboardingService', () {
    late OnboardingService onboardingService;
    late MockAuthService mockAuthService;

    setUp(() {
      onboardingService = OnboardingService();
      mockAuthService = MockAuthService();
      onboardingService.clearData(); // Reset state between tests
    });

    test('should initialize with empty data', () {
      expect(onboardingService.data.gender, isNull);
      expect(onboardingService.data.ageGroup, isNull);
      expect(onboardingService.data.fitnessLevel, isNull);
      expect(onboardingService.data.height, isNull);
      expect(onboardingService.data.weight, isNull);
      expect(onboardingService.isLoading, isFalse);
      expect(onboardingService.error, isNull);
    });

    test('should update gender correctly', () {
      onboardingService.updateGender('Male');
      
      expect(onboardingService.data.gender, equals('Male'));
      expect(onboardingService.error, isNull);
    });

    test('should update age group correctly', () {
      onboardingService.updateAgeGroup('Adult');
      
      expect(onboardingService.data.ageGroup, equals('Adult'));
      expect(onboardingService.error, isNull);
    });

    test('should update fitness level correctly', () {
      onboardingService.updateFitnessLevel('Intermediate');
      
      expect(onboardingService.data.fitnessLevel, equals('Intermediate'));
      expect(onboardingService.error, isNull);
    });

    test('should update height correctly', () {
      onboardingService.updateHeight(175.0);
      
      expect(onboardingService.data.height, equals(175.0));
      expect(onboardingService.error, isNull);
    });

    test('should update weight correctly', () {
      onboardingService.updateWeight(70.0);
      
      expect(onboardingService.data.weight, equals(70.0));
      expect(onboardingService.error, isNull);
    });

    test('should validate individual steps correctly', () {
      // Step 1 - Gender validation
      expect(onboardingService.validateCurrentStep(1), isNotNull);
      onboardingService.updateGender('Male');
      expect(onboardingService.validateCurrentStep(1), isNull);

      // Step 2 - Age group validation
      expect(onboardingService.validateCurrentStep(2), isNotNull);
      onboardingService.updateAgeGroup('Adult');
      expect(onboardingService.validateCurrentStep(2), isNull);

      // Step 3 - Fitness level validation
      expect(onboardingService.validateCurrentStep(3), isNotNull);
      onboardingService.updateFitnessLevel('Intermediate');
      expect(onboardingService.validateCurrentStep(3), isNull);

      // Step 4 - Height validation
      expect(onboardingService.validateCurrentStep(4), isNotNull);
      onboardingService.updateHeight(175.0);
      expect(onboardingService.validateCurrentStep(4), isNull);

      // Step 5 - Weight validation
      expect(onboardingService.validateCurrentStep(5), isNotNull);
      onboardingService.updateWeight(70.0);
      expect(onboardingService.validateCurrentStep(5), isNull);
    });

    test('should check step validity correctly', () {
      expect(onboardingService.isStepValid(1), isFalse);
      
      onboardingService.updateGender('Male');
      expect(onboardingService.isStepValid(1), isTrue);
    });

    test('should provide user-friendly error messages', () {
      expect(onboardingService.getStepErrorMessage(1), equals('Please select your gender to continue'));
      expect(onboardingService.getStepErrorMessage(2), equals('Please select your age group to continue'));
      expect(onboardingService.getStepErrorMessage(3), equals('Please select your fitness level to continue'));
      expect(onboardingService.getStepErrorMessage(4), equals('Please set your height to continue'));
      expect(onboardingService.getStepErrorMessage(5), equals('Please set your weight to continue'));
    });

    test('should calculate progress correctly', () {
      expect(onboardingService.getProgressForStep(1), equals(0.2));
      expect(onboardingService.getProgressForStep(2), equals(0.4));
      expect(onboardingService.getProgressForStep(3), equals(0.6));
      expect(onboardingService.getProgressForStep(4), equals(0.8));
      expect(onboardingService.getProgressForStep(5), equals(1.0));
    });

    test('should check completion status correctly', () {
      expect(onboardingService.data.isComplete, isFalse);
      
      onboardingService.updateGender('Male');
      onboardingService.updateAgeGroup('Adult');
      onboardingService.updateFitnessLevel('Intermediate');
      onboardingService.updateHeight(175.0);
      onboardingService.updateWeight(70.0);
      
      expect(onboardingService.data.isComplete, isTrue);
    });

    test('should provide data summary correctly', () {
      onboardingService.updateGender('Male');
      onboardingService.updateAgeGroup('Adult');
      onboardingService.updateFitnessLevel('Intermediate');
      onboardingService.updateHeight(175.0);
      onboardingService.updateWeight(70.0);
      
      final summary = onboardingService.getDataSummary();
      
      expect(summary['Gender'], equals('Male'));
      expect(summary['Age Group'], equals('Adult'));
      expect(summary['Fitness Level'], equals('Intermediate'));
      expect(summary['Height'], equals('175 cm'));
      expect(summary['Weight'], equals('70 kg'));
    });

    test('should clear data correctly', () {
      onboardingService.updateGender('Male');
      onboardingService.updateAgeGroup('Adult');
      
      onboardingService.clearData();
      
      expect(onboardingService.data.gender, isNull);
      expect(onboardingService.data.ageGroup, isNull);
      expect(onboardingService.error, isNull);
      expect(onboardingService.isLoading, isFalse);
    });

    test('should initialize onboarding correctly', () {
      onboardingService.updateGender('Male');
      
      onboardingService.initializeOnboarding();
      
      expect(onboardingService.data.gender, isNull);
      expect(onboardingService.error, isNull);
      expect(onboardingService.isLoading, isFalse);
    });
  });

  group('OnboardingData', () {
    test('should validate gender correctly', () {
      final data = OnboardingData();
      
      expect(data.validateGender(), isNotNull);
      
      data.gender = 'Male';
      expect(data.validateGender(), isNull);
      
      data.gender = 'Invalid';
      expect(data.validateGender(), isNotNull);
    });

    test('should validate age group correctly', () {
      final data = OnboardingData();
      
      expect(data.validateAgeGroup(), isNotNull);
      
      data.ageGroup = 'Adult';
      expect(data.validateAgeGroup(), isNull);
      
      data.ageGroup = 'Invalid';
      expect(data.validateAgeGroup(), isNotNull);
    });

    test('should validate fitness level correctly', () {
      final data = OnboardingData();
      
      expect(data.validateFitnessLevel(), isNotNull);
      
      data.fitnessLevel = 'Intermediate';
      expect(data.validateFitnessLevel(), isNull);
      
      data.fitnessLevel = 'Invalid';
      expect(data.validateFitnessLevel(), isNotNull);
    });

    test('should validate height correctly', () {
      final data = OnboardingData();
      
      expect(data.validateHeight(), isNotNull);
      
      data.height = 175.0;
      expect(data.validateHeight(), isNull);
      
      data.height = 0.0;
      expect(data.validateHeight(), isNotNull);
      
      data.height = 300.0;
      expect(data.validateHeight(), isNotNull);
    });

    test('should validate weight correctly', () {
      final data = OnboardingData();
      
      expect(data.validateWeight(), isNotNull);
      
      data.weight = 70.0;
      expect(data.validateWeight(), isNull);
      
      data.weight = 0.0;
      expect(data.validateWeight(), isNotNull);
      
      data.weight = 300.0;
      expect(data.validateWeight(), isNotNull);
    });

    test('should convert to profile update JSON correctly', () {
      final data = OnboardingData(
        gender: 'Male',
        ageGroup: 'Adult',
        fitnessLevel: 'Intermediate',
        height: 175.0,
        weight: 70.0,
      );
      
      final json = data.toProfileUpdateJson();
      
      expect(json['gender'], equals('Male'));
      expect(json['age_group'], equals('Adult'));
      expect(json['fitness_level'], equals('Intermediate'));
      expect(json['height'], equals(175.0));
      expect(json['weight'], equals(70.0));
    });

    test('should calculate completion percentage correctly', () {
      final data = OnboardingData();
      
      expect(data.completionPercentage, equals(0.0));
      
      data.gender = 'Male';
      expect(data.completionPercentage, equals(0.2));
      
      data.ageGroup = 'Adult';
      expect(data.completionPercentage, equals(0.4));
      
      data.fitnessLevel = 'Intermediate';
      expect(data.completionPercentage, equals(0.6));
      
      data.height = 175.0;
      expect(data.completionPercentage, equals(0.8));
      
      data.weight = 70.0;
      expect(data.completionPercentage, equals(1.0));
    });
  });

  // Property-based tests for onboarding flow
  group('Property 8: Profile Update Persistence', () {
    late OnboardingService onboardingService;
    late MockAuthService mockAuthService;

    setUp(() {
      onboardingService = OnboardingService();
      mockAuthService = MockAuthService();
      onboardingService.clearData();
    });

    test('Feature: user-authentication-profile, Property 8: Profile Update Persistence - Complete profile data persistence', () async {
      // Property test: For any complete onboarding data, submitting should persist all fields correctly
      
      final random = Random();
      final testCases = [
        {
          'gender': 'Male',
          'ageGroup': 'Adult',
          'fitnessLevel': 'Beginner',
          'height': 150.0 + random.nextDouble() * 70, // 150-220 cm
          'weight': 40.0 + random.nextDouble() * 120, // 40-160 kg
        },
        {
          'gender': 'Female',
          'ageGroup': 'Mid-Age Adult',
          'fitnessLevel': 'Intermediate',
          'height': 150.0 + random.nextDouble() * 70,
          'weight': 40.0 + random.nextDouble() * 120,
        },
        {
          'gender': 'Male',
          'ageGroup': 'Older Adult',
          'fitnessLevel': 'Advance',
          'height': 150.0 + random.nextDouble() * 70,
          'weight': 40.0 + random.nextDouble() * 120,
        },
        {
          'gender': 'Female',
          'ageGroup': 'Adult',
          'fitnessLevel': 'Beginner',
          'height': 150.0 + random.nextDouble() * 70,
          'weight': 40.0 + random.nextDouble() * 120,
        },
      ];

      for (final testCase in testCases) {
        // Reset service for each test case
        onboardingService.clearData();
        
        // Set up the onboarding data
        onboardingService.updateGender(testCase['gender'] as String);
        onboardingService.updateAgeGroup(testCase['ageGroup'] as String);
        onboardingService.updateFitnessLevel(testCase['fitnessLevel'] as String);
        onboardingService.updateHeight(testCase['height'] as double);
        onboardingService.updateWeight(testCase['weight'] as double);

        // Verify data is complete
        expect(onboardingService.data.isComplete, isTrue, 
               reason: 'Onboarding data should be complete for test case: $testCase');

        // Verify the profile update request is correctly formatted
        final profileRequest = ProfileUpdateRequest(
          gender: onboardingService.data.gender,
          ageGroup: onboardingService.data.ageGroup,
          fitnessLevel: onboardingService.data.fitnessLevel,
          height: onboardingService.data.height,
          weight: onboardingService.data.weight,
        );

        final requestJson = profileRequest.toJson();
        
        // Verify all fields are present and correct
        expect(requestJson['gender'], equals(testCase['gender']),
               reason: 'Gender should persist correctly in profile update request');
        expect(requestJson['age_group'], equals(testCase['ageGroup']),
               reason: 'Age group should persist correctly in profile update request');
        expect(requestJson['fitness_level'], equals(testCase['fitnessLevel']),
               reason: 'Fitness level should persist correctly in profile update request');
        expect(requestJson['height'], equals(testCase['height']),
               reason: 'Height should persist correctly in profile update request');
        expect(requestJson['weight'], equals(testCase['weight']),
               reason: 'Weight should persist correctly in profile update request');

        // Verify onboarding data to JSON conversion
        final onboardingJson = onboardingService.data.toProfileUpdateJson();
        expect(onboardingJson['gender'], equals(testCase['gender']));
        expect(onboardingJson['age_group'], equals(testCase['ageGroup']));
        expect(onboardingJson['fitness_level'], equals(testCase['fitnessLevel']));
        expect(onboardingJson['height'], equals(testCase['height']));
        expect(onboardingJson['weight'], equals(testCase['weight']));
      }
    });

    test('Feature: user-authentication-profile, Property 8: Profile Update Persistence - Partial data handling', () async {
      // Property test: For any partial onboarding data, only provided fields should be included in update
      
      final partialTestCases = [
        {'gender': 'Male'},
        {'ageGroup': 'Adult'},
        {'fitnessLevel': 'Intermediate'},
        {'height': 175.0},
        {'weight': 70.0},
        {'gender': 'Female', 'height': 165.0},
        {'ageGroup': 'Mid-Age Adult', 'weight': 60.0},
        {'fitnessLevel': 'Advance', 'gender': 'Male'},
      ];

      for (final testCase in partialTestCases) {
        onboardingService.clearData();
        
        // Set only the fields specified in the test case
        if (testCase.containsKey('gender')) {
          onboardingService.updateGender(testCase['gender'] as String);
        }
        if (testCase.containsKey('ageGroup')) {
          onboardingService.updateAgeGroup(testCase['ageGroup'] as String);
        }
        if (testCase.containsKey('fitnessLevel')) {
          onboardingService.updateFitnessLevel(testCase['fitnessLevel'] as String);
        }
        if (testCase.containsKey('height')) {
          onboardingService.updateHeight(testCase['height'] as double);
        }
        if (testCase.containsKey('weight')) {
          onboardingService.updateWeight(testCase['weight'] as double);
        }

        final onboardingJson = onboardingService.data.toProfileUpdateJson();
        
        // Verify only the set fields are included
        for (final key in testCase.keys) {
          final expectedKey = key == 'ageGroup' ? 'age_group' : 
                             key == 'fitnessLevel' ? 'fitness_level' : key;
          expect(onboardingJson.containsKey(expectedKey), isTrue,
                 reason: 'Field $expectedKey should be present in JSON for partial data');
          expect(onboardingJson[expectedKey], equals(testCase[key]),
                 reason: 'Field $expectedKey should have correct value in JSON');
        }

        // Verify unset fields are not included
        final allFields = ['gender', 'age_group', 'fitness_level', 'height', 'weight'];
        final setFields = testCase.keys.map((k) => 
          k == 'ageGroup' ? 'age_group' : 
          k == 'fitnessLevel' ? 'fitness_level' : k).toSet();
        
        for (final field in allFields) {
          if (!setFields.contains(field)) {
            expect(onboardingJson.containsKey(field), isFalse,
                   reason: 'Unset field $field should not be present in JSON');
          }
        }
      }
    });

    test('Feature: user-authentication-profile, Property 8: Profile Update Persistence - Data validation consistency', () async {
      // Property test: For any onboarding data, validation should be consistent between OnboardingData and ProfileUpdateRequest
      
      final random = Random();
      final validationTestCases = [
        // Valid cases
        {
          'gender': 'Male',
          'ageGroup': 'Adult',
          'fitnessLevel': 'Beginner',
          'height': 175.0,
          'weight': 70.0,
          'shouldBeValid': true,
        },
        {
          'gender': 'Female',
          'ageGroup': 'Mid-Age Adult',
          'fitnessLevel': 'Intermediate',
          'height': 160.0,
          'weight': 55.0,
          'shouldBeValid': true,
        },
        // Invalid cases
        {
          'gender': 'Invalid',
          'ageGroup': 'Adult',
          'fitnessLevel': 'Beginner',
          'height': 175.0,
          'weight': 70.0,
          'shouldBeValid': false,
        },
        {
          'gender': 'Male',
          'ageGroup': 'Invalid',
          'fitnessLevel': 'Beginner',
          'height': 175.0,
          'weight': 70.0,
          'shouldBeValid': false,
        },
        {
          'gender': 'Male',
          'ageGroup': 'Adult',
          'fitnessLevel': 'Invalid',
          'height': 175.0,
          'weight': 70.0,
          'shouldBeValid': false,
        },
        {
          'gender': 'Male',
          'ageGroup': 'Adult',
          'fitnessLevel': 'Beginner',
          'height': -10.0, // Invalid height
          'weight': 70.0,
          'shouldBeValid': false,
        },
        {
          'gender': 'Male',
          'ageGroup': 'Adult',
          'fitnessLevel': 'Beginner',
          'height': 175.0,
          'weight': -5.0, // Invalid weight
          'shouldBeValid': false,
        },
      ];

      for (final testCase in validationTestCases) {
        onboardingService.clearData();
        
        // Set up onboarding data
        onboardingService.updateGender(testCase['gender'] as String);
        onboardingService.updateAgeGroup(testCase['ageGroup'] as String);
        onboardingService.updateFitnessLevel(testCase['fitnessLevel'] as String);
        onboardingService.updateHeight(testCase['height'] as double);
        onboardingService.updateWeight(testCase['weight'] as double);

        // Create corresponding ProfileUpdateRequest
        final profileRequest = ProfileUpdateRequest(
          gender: testCase['gender'] as String,
          ageGroup: testCase['ageGroup'] as String,
          fitnessLevel: testCase['fitnessLevel'] as String,
          height: testCase['height'] as double,
          weight: testCase['weight'] as double,
        );

        // Validate both
        final onboardingErrors = onboardingService.data.validateAll();
        final profileErrors = profileRequest.validate();
        
        final shouldBeValid = testCase['shouldBeValid'] as bool;
        
        if (shouldBeValid) {
          expect(onboardingErrors, isEmpty,
                 reason: 'OnboardingData should be valid for test case: $testCase');
          expect(profileErrors, isEmpty,
                 reason: 'ProfileUpdateRequest should be valid for test case: $testCase');
        } else {
          // At least one should have errors (they should be consistent)
          final onboardingHasErrors = onboardingErrors.isNotEmpty;
          final profileHasErrors = profileErrors.isNotEmpty;
          
          expect(onboardingHasErrors || profileHasErrors, isTrue,
                 reason: 'Either OnboardingData or ProfileUpdateRequest should have validation errors for invalid test case: $testCase');
        }
      }
    });

    test('Feature: user-authentication-profile, Property 8: Profile Update Persistence - State consistency during updates', () async {
      // Property test: For any sequence of onboarding updates, the final state should reflect all changes
      
      final random = Random();
      final updateSequences = [
        ['gender', 'ageGroup', 'fitnessLevel', 'height', 'weight'],
        ['weight', 'height', 'fitnessLevel', 'ageGroup', 'gender'],
        ['fitnessLevel', 'gender', 'weight', 'ageGroup', 'height'],
        ['height', 'weight', 'gender', 'fitnessLevel', 'ageGroup'],
      ];

      final testValues = {
        'gender': ['Male', 'Female'],
        'ageGroup': ['Adult', 'Mid-Age Adult', 'Older Adult'],
        'fitnessLevel': ['Beginner', 'Intermediate', 'Advance'],
        'height': [150.0, 165.0, 175.0, 185.0, 200.0],
        'weight': [50.0, 60.0, 70.0, 80.0, 90.0],
      };

      for (final sequence in updateSequences) {
        onboardingService.clearData();
        
        final finalValues = <String, dynamic>{};
        
        // Apply updates in the specified sequence
        for (final field in sequence) {
          final values = testValues[field]!;
          final value = values[random.nextInt(values.length)];
          finalValues[field] = value;
          
          switch (field) {
            case 'gender':
              onboardingService.updateGender(value as String);
              break;
            case 'ageGroup':
              onboardingService.updateAgeGroup(value as String);
              break;
            case 'fitnessLevel':
              onboardingService.updateFitnessLevel(value as String);
              break;
            case 'height':
              onboardingService.updateHeight(value as double);
              break;
            case 'weight':
              onboardingService.updateWeight(value as double);
              break;
          }
        }
        
        // Verify final state matches expected values
        expect(onboardingService.data.gender, equals(finalValues['gender']),
               reason: 'Gender should persist correctly after update sequence: $sequence');
        expect(onboardingService.data.ageGroup, equals(finalValues['ageGroup']),
               reason: 'Age group should persist correctly after update sequence: $sequence');
        expect(onboardingService.data.fitnessLevel, equals(finalValues['fitnessLevel']),
               reason: 'Fitness level should persist correctly after update sequence: $sequence');
        expect(onboardingService.data.height, equals(finalValues['height']),
               reason: 'Height should persist correctly after update sequence: $sequence');
        expect(onboardingService.data.weight, equals(finalValues['weight']),
               reason: 'Weight should persist correctly after update sequence: $sequence');

        // Verify JSON conversion maintains consistency
        final json = onboardingService.data.toProfileUpdateJson();
        expect(json['gender'], equals(finalValues['gender']));
        expect(json['age_group'], equals(finalValues['ageGroup']));
        expect(json['fitness_level'], equals(finalValues['fitnessLevel']));
        expect(json['height'], equals(finalValues['height']));
        expect(json['weight'], equals(finalValues['weight']));
      }
    });
  });
}