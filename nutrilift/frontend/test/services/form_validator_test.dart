import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilift/services/form_validator.dart';

void main() {
  group('FormValidator', () {
    late FormValidator validator;

    setUp(() {
      validator = FormValidator();
    });

    group('Email validation', () {
      test('should validate correct email addresses', () {
        final result = validator.validateEmail('test@example.com');
        expect(result.isValid, isTrue);
        expect(result.error, isNull);
      });

      test('should reject invalid email addresses', () {
        final result = validator.validateEmail('invalid-email');
        expect(result.isValid, isFalse);
        expect(result.error, contains('valid email'));
      });

      test('should reject empty email', () {
        final result = validator.validateEmail('');
        expect(result.isValid, isFalse);
        expect(result.error, contains('required'));
      });
    });

    group('Password validation', () {
      test('should validate strong passwords', () {
        final result = validator.validatePassword('StrongPass123');
        expect(result.isValid, isTrue);
        expect(result.error, isNull);
      });

      test('should reject short passwords', () {
        final result = validator.validatePassword('short');
        expect(result.isValid, isFalse);
        expect(result.error, contains('8 characters'));
      });

      test('should reject empty passwords', () {
        final result = validator.validatePassword('');
        expect(result.isValid, isFalse);
        expect(result.error, contains('required'));
      });
    });

    group('Password confirmation validation', () {
      test('should validate matching passwords', () {
        final result = validator.validatePasswordConfirmation('password123', 'password123');
        expect(result.isValid, isTrue);
        expect(result.error, isNull);
      });

      test('should reject non-matching passwords', () {
        final result = validator.validatePasswordConfirmation('password123', 'different');
        expect(result.isValid, isFalse);
        expect(result.error, contains('do not match'));
      });
    });

    group('Name validation', () {
      test('should validate proper names', () {
        final result = validator.validateName('John Doe');
        expect(result.isValid, isTrue);
        expect(result.error, isNull);
      });

      test('should reject short names', () {
        final result = validator.validateName('A');
        expect(result.isValid, isFalse);
        expect(result.error, contains('2 characters'));
      });

      test('should reject empty names', () {
        final result = validator.validateName('');
        expect(result.isValid, isFalse);
        expect(result.error, contains('required'));
      });
    });

    group('Height validation', () {
      test('should validate proper heights', () {
        final result = validator.validateHeight('175.5');
        expect(result.isValid, isTrue);
        expect(result.error, isNull);
      });

      test('should reject invalid heights', () {
        final result = validator.validateHeight('invalid');
        expect(result.isValid, isFalse);
        expect(result.error, contains('valid height'));
      });

      test('should reject negative heights', () {
        final result = validator.validateHeight('-10');
        expect(result.isValid, isFalse);
        expect(result.error, contains('between 1 and 300'));
      });
    });

    group('Weight validation', () {
      test('should validate proper weights', () {
        final result = validator.validateWeight('70.5');
        expect(result.isValid, isTrue);
        expect(result.error, isNull);
      });

      test('should reject invalid weights', () {
        final result = validator.validateWeight('invalid');
        expect(result.isValid, isFalse);
        expect(result.error, contains('valid weight'));
      });

      test('should reject negative weights', () {
        final result = validator.validateWeight('-5');
        expect(result.isValid, isFalse);
        expect(result.error, contains('between 1 and 500'));
      });
    });

    group('Password strength', () {
      test('should rate weak passwords correctly', () {
        final strength = validator.getPasswordStrength('weak');
        expect(strength.score, lessThan(3));
        expect(strength.label, contains('weak'));
      });

      test('should rate strong passwords correctly', () {
        final strength = validator.getPasswordStrength('StrongPassword123!');
        expect(strength.score, greaterThanOrEqualTo(3));
      });

      test('should handle empty passwords', () {
        final strength = validator.getPasswordStrength('');
        expect(strength.score, equals(0));
        expect(strength.label, contains('Too weak'));
      });
    });
  });
}