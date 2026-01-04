import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrilift/services/token_service.dart';

void main() {
  group('Simple Performance and Security Tests', () {
    late TokenService tokenService;

    setUp(() {
      tokenService = TokenService();
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    group('Token Storage Performance', () {
      test('should store and retrieve tokens efficiently', () async {
        const String testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMTIzIiwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiZXhwIjoxNjQwOTk1MjAwfQ.test-signature';
        
        // Test token storage performance
        final storageStart = DateTime.now();
        await tokenService.saveToken(testToken);
        final storageDuration = DateTime.now().difference(storageStart).inMilliseconds;
        
        // Test token retrieval performance
        final retrievalStart = DateTime.now();
        final retrievedToken = await tokenService.getToken();
        final retrievalDuration = DateTime.now().difference(retrievalStart).inMilliseconds;
        
        // Verify correctness
        expect(retrievedToken, equals(testToken));
        
        // Verify performance (should be very fast for local storage)
        expect(storageDuration, lessThan(100), 
            reason: 'Token storage took ${storageDuration}ms, should be under 100ms');
        expect(retrievalDuration, lessThan(50), 
            reason: 'Token retrieval took ${retrievalDuration}ms, should be under 50ms');
        
        print('Token storage performance: ${storageDuration}ms');
        print('Token retrieval performance: ${retrievalDuration}ms');
      });

      test('should handle token round-trip correctly', () async {
        final testTokens = [
          'short-token',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMTIzIiwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiZXhwIjoxNjQwOTk1MjAwfQ.test-signature',
          'very-long-token-with-many-characters-to-test-storage-limits-and-ensure-proper-handling-of-large-tokens',
          'token-with-special-chars-!@#\$%^&*()_+-=[]{}|;:,.<>?',
        ];

        for (final token in testTokens) {
          // Store token
          await tokenService.saveToken(token);
          
          // Retrieve and verify
          final retrieved = await tokenService.getToken();
          expect(retrieved, equals(token), 
              reason: 'Token round-trip failed for: $token');
          
          // Clear for next iteration
          await tokenService.clearTokens();
        }
      });

      test('should validate token format correctly', () async {
        // Test valid JWT-like token structure
        const String validToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMTIzIiwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiZXhwIjoxNjQwOTk1MjAwfQ.dGVzdC1zaWduYXR1cmU';
        
        await tokenService.saveToken(validToken);
        final retrievedToken = await tokenService.getToken();
        
        // Verify token structure (JWT should have 3 parts separated by dots)
        final tokenParts = retrievedToken!.split('.');
        expect(tokenParts.length, equals(3), 
            reason: 'JWT token should have 3 parts separated by dots');
        
        // Each part should not be empty
        for (final part in tokenParts) {
          expect(part.isNotEmpty, isTrue, 
              reason: 'JWT token parts should not be empty');
        }
        
        // Test token format validation
        expect(tokenService.isValidTokenFormat(validToken), isTrue);
        expect(tokenService.isValidTokenFormat('invalid-token'), isFalse);
        expect(tokenService.isValidTokenFormat(''), isFalse);
      });

      test('should handle token validation efficiently', () async {
        const String testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMTIzIiwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiZXhwIjoxNjQwOTk1MjAwfQ.test-signature';
        
        await tokenService.saveToken(testToken);
        
        // Test validation performance
        final validationStart = DateTime.now();
        final isValid = await tokenService.isTokenValid();
        final validationDuration = DateTime.now().difference(validationStart).inMilliseconds;
        
        // Verify validation is fast
        expect(validationDuration, lessThan(50), 
            reason: 'Token validation took ${validationDuration}ms, should be under 50ms');
        
        // Verify validation result
        expect(isValid, isA<bool>());
        
        print('Token validation performance: ${validationDuration}ms');
      });
    });

    group('Security Measures', () {
      test('should ensure secure token transmission format', () async {
        // Test that tokens are properly formatted for HTTP headers
        const String testToken = 'test-bearer-token-123';
        
        await tokenService.saveToken(testToken);
        final retrievedToken = await tokenService.getToken();
        
        // Verify token can be used in Authorization header format
        final authHeader = 'Bearer $retrievedToken';
        expect(authHeader, equals('Bearer test-bearer-token-123'));
        
        // Verify token doesn't contain newlines or other problematic characters
        expect(retrievedToken!.contains('\n'), isFalse);
        expect(retrievedToken.contains('\r'), isFalse);
        expect(retrievedToken.contains(' '), isFalse);
      });

      test('should handle token clearing securely', () async {
        const String testToken = 'secure-test-token-123';
        const String refreshToken = 'refresh-token-456';
        
        // Store tokens
        await tokenService.saveToken(testToken);
        await tokenService.saveRefreshToken(refreshToken);
        
        // Verify tokens are stored
        expect(await tokenService.getToken(), equals(testToken));
        expect(await tokenService.getRefreshToken(), equals(refreshToken));
        
        // Clear all tokens
        await tokenService.clearTokens();
        
        // Verify tokens are cleared
        expect(await tokenService.getToken(), isNull);
        expect(await tokenService.getRefreshToken(), isNull);
        expect(await tokenService.hasStoredAuth(), isFalse);
      });

      test('should validate JWT token payload extraction', () async {
        // Test with a mock JWT token (not a real one, just for structure testing)
        const String mockJwtToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMTIzIiwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiZXhwIjoxNjQwOTk1MjAwfQ.mock-signature';
        
        // Test payload extraction
        final payload = tokenService.getTokenPayload(mockJwtToken);
        
        // Verify payload structure (this is a mock, so we expect it to work)
        expect(payload, isA<Map<String, dynamic>>());
        
        if (payload != null) {
          expect(payload.containsKey('user_id'), isTrue);
          expect(payload.containsKey('email'), isTrue);
          expect(payload.containsKey('exp'), isTrue);
        }
      });
    });

    group('Performance with Large Datasets', () {
      test('should handle multiple rapid token operations', () async {
        const int operationCount = 100;
        final tokens = List.generate(operationCount, (index) => 'token-$index');
        
        final totalStart = DateTime.now();
        
        // Perform rapid token operations
        for (int i = 0; i < operationCount; i++) {
          await tokenService.saveToken(tokens[i]);
          final retrieved = await tokenService.getToken();
          expect(retrieved, equals(tokens[i]));
          
          if (i < operationCount - 1) {
            await tokenService.clearTokens();
          }
        }
        
        final totalDuration = DateTime.now().difference(totalStart).inMilliseconds;
        final averagePerOperation = totalDuration / (operationCount * 3); // 3 operations per iteration
        
        // Verify performance is reasonable
        expect(averagePerOperation, lessThan(10), 
            reason: 'Average operation time ${averagePerOperation.toStringAsFixed(2)}ms should be under 10ms');
        
        print('Performed $operationCount token operations in ${totalDuration}ms');
        print('Average time per operation: ${averagePerOperation.toStringAsFixed(2)}ms');
      });

      test('should maintain consistency under rapid operations', () async {
        const int rapidOperations = 50;
        
        // Perform rapid save/retrieve cycles
        for (int i = 0; i < rapidOperations; i++) {
          final token = 'consistency-test-token-$i';
          
          await tokenService.saveToken(token);
          final retrieved = await tokenService.getToken();
          
          // Verify consistency
          expect(retrieved, equals(token), 
              reason: 'Token consistency failed at iteration $i');
          
          // Verify token validation works
          final isValid = await tokenService.isTokenValid();
          expect(isValid, isTrue, 
              reason: 'Token validation failed at iteration $i');
        }
        
        print('Completed $rapidOperations rapid consistency tests');
      });
    });
  });
}