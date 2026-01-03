import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
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
}