import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilift/config/environment.dart';

void main() {
  group('EnvironmentConfig', () {
    group('Development Environment', () {
      test('should have correct configuration', () {
        const config = EnvironmentConfig.development;

        expect(config.environment, Environment.development);
        expect(config.apiBaseUrl, 'http://127.0.0.1:8000/api');
        expect(config.apiTimeout, const Duration(seconds: 30));
        expect(config.enableLogging, true);
      });

      test('should identify as development', () {
        const config = EnvironmentConfig.development;

        expect(config.isDevelopment, true);
        expect(config.isStaging, false);
        expect(config.isProduction, false);
      });

      test('should return correct environment name', () {
        const config = EnvironmentConfig.development;

        expect(config.environmentName, 'Development');
      });
    });

    group('Staging Environment', () {
      test('should have correct configuration', () {
        const config = EnvironmentConfig.staging;

        expect(config.environment, Environment.staging);
        expect(config.apiBaseUrl, 'https://nutrilift-staging.railway.app/api');
        expect(config.apiTimeout, const Duration(seconds: 30));
        expect(config.enableLogging, true);
      });

      test('should identify as staging', () {
        const config = EnvironmentConfig.staging;

        expect(config.isDevelopment, false);
        expect(config.isStaging, true);
        expect(config.isProduction, false);
      });

      test('should return correct environment name', () {
        const config = EnvironmentConfig.staging;

        expect(config.environmentName, 'Staging');
      });

      test('should use HTTPS', () {
        const config = EnvironmentConfig.staging;

        expect(config.apiBaseUrl.startsWith('https://'), true);
      });
    });

    group('Production Environment', () {
      test('should have correct configuration', () {
        const config = EnvironmentConfig.production;

        expect(config.environment, Environment.production);
        expect(config.apiBaseUrl, 'https://nutrilift.railway.app/api');
        expect(config.apiTimeout, const Duration(seconds: 30));
        expect(config.enableLogging, false);
      });

      test('should identify as production', () {
        const config = EnvironmentConfig.production;

        expect(config.isDevelopment, false);
        expect(config.isStaging, false);
        expect(config.isProduction, true);
      });

      test('should return correct environment name', () {
        const config = EnvironmentConfig.production;

        expect(config.environmentName, 'Production');
      });

      test('should use HTTPS', () {
        const config = EnvironmentConfig.production;

        expect(config.apiBaseUrl.startsWith('https://'), true);
      });

      test('should have logging disabled', () {
        const config = EnvironmentConfig.production;

        expect(config.enableLogging, false);
      });
    });

    group('Current Environment', () {
      test('should have a valid current environment', () {
        const config = EnvironmentConfig.current;

        expect(config.environment, isNotNull);
        expect(config.apiBaseUrl, isNotEmpty);
        expect(config.apiTimeout.inSeconds, greaterThan(0));
      });

      test('should be one of the predefined environments', () {
        const config = EnvironmentConfig.current;

        expect(
          [
            Environment.development,
            Environment.staging,
            Environment.production,
          ].contains(config.environment),
          true,
        );
      });
    });

    group('Custom Configuration', () {
      test('should allow custom configuration', () {
        const customConfig = EnvironmentConfig(
          environment: Environment.development,
          apiBaseUrl: 'http://custom-url.com/api',
          apiTimeout: Duration(seconds: 60),
          enableLogging: false,
        );

        expect(customConfig.apiBaseUrl, 'http://custom-url.com/api');
        expect(customConfig.apiTimeout, const Duration(seconds: 60));
        expect(customConfig.enableLogging, false);
      });

      test('should use default timeout if not specified', () {
        const customConfig = EnvironmentConfig(
          environment: Environment.development,
          apiBaseUrl: 'http://custom-url.com/api',
        );

        expect(customConfig.apiTimeout, const Duration(seconds: 30));
      });

      test('should use default logging setting if not specified', () {
        const customConfig = EnvironmentConfig(
          environment: Environment.development,
          apiBaseUrl: 'http://custom-url.com/api',
        );

        expect(customConfig.enableLogging, false);
      });
    });

    group('API Base URL Format', () {
      test('development should use localhost', () {
        const config = EnvironmentConfig.development;

        expect(
          config.apiBaseUrl.contains('127.0.0.1') ||
              config.apiBaseUrl.contains('localhost'),
          true,
        );
      });

      test('all environments should end with /api', () {
        expect(EnvironmentConfig.development.apiBaseUrl.endsWith('/api'), true);
        expect(EnvironmentConfig.staging.apiBaseUrl.endsWith('/api'), true);
        expect(EnvironmentConfig.production.apiBaseUrl.endsWith('/api'), true);
      });

      test('production and staging should not use localhost', () {
        expect(
          EnvironmentConfig.staging.apiBaseUrl.contains('127.0.0.1') ||
              EnvironmentConfig.staging.apiBaseUrl.contains('localhost'),
          false,
        );
        expect(
          EnvironmentConfig.production.apiBaseUrl.contains('127.0.0.1') ||
              EnvironmentConfig.production.apiBaseUrl.contains('localhost'),
          false,
        );
      });
    });

    group('Security Settings', () {
      test('production should have logging disabled', () {
        const config = EnvironmentConfig.production;

        expect(config.enableLogging, false,
            reason: 'Production should not have logging enabled for security');
      });

      test('production should use HTTPS', () {
        const config = EnvironmentConfig.production;

        expect(config.apiBaseUrl.startsWith('https://'), true,
            reason: 'Production must use HTTPS for security');
      });

      test('staging should use HTTPS', () {
        const config = EnvironmentConfig.staging;

        expect(config.apiBaseUrl.startsWith('https://'), true,
            reason: 'Staging should use HTTPS for security');
      });
    });

    group('Timeout Configuration', () {
      test('all environments should have reasonable timeout', () {
        expect(
          EnvironmentConfig.development.apiTimeout.inSeconds,
          greaterThanOrEqualTo(10),
        );
        expect(
          EnvironmentConfig.staging.apiTimeout.inSeconds,
          greaterThanOrEqualTo(10),
        );
        expect(
          EnvironmentConfig.production.apiTimeout.inSeconds,
          greaterThanOrEqualTo(10),
        );
      });

      test('timeout should not be too long', () {
        expect(
          EnvironmentConfig.development.apiTimeout.inSeconds,
          lessThanOrEqualTo(120),
        );
        expect(
          EnvironmentConfig.staging.apiTimeout.inSeconds,
          lessThanOrEqualTo(120),
        );
        expect(
          EnvironmentConfig.production.apiTimeout.inSeconds,
          lessThanOrEqualTo(120),
        );
      });
    });
  });
}
