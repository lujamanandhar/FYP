import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilift/services/token_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

void main() {
  group('TokenService', () {
    late TokenService tokenService;

    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      tokenService = TokenService();
    });

    tearDown(() {
      tokenService.dispose();
    });

    group('Property 13: Token Storage Round-trip', () {
      test('Feature: user-authentication-profile, Property 13: Token Storage Round-trip - Basic token storage', () async {
        // Property test: For any valid token string, storing and retrieving should return the same value
        final testTokens = [
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMTIzIiwiZW1haWwiOiJ0ZXN0QGV4YW1wbGUuY29tIiwiZXhwIjoxNzA0MDY3MjAwfQ.test-signature',
          _createJWTToken({'user_id': 'test1', 'email': 'test1@example.com'}),
          _createJWTToken({'user_id': 'test2', 'exp': _futureTimestamp(hours: 1)}),
          _createJWTToken({'user_id': 'test3', 'name': 'Test User', 'role': 'user'}),
        ];

        for (final originalToken in testTokens) {
          // Clear any existing token
          await tokenService.clearTokens();
          
          // Save token
          await tokenService.saveToken(originalToken);
          
          // Retrieve token
          final retrievedToken = await tokenService.getToken();
          
          // Verify round-trip consistency
          expect(retrievedToken, equals(originalToken), 
                 reason: 'Token round-trip failed for: $originalToken');
          
          // Verify token is considered valid if not expired
          final hasStoredAuth = await tokenService.hasStoredAuth();
          expect(hasStoredAuth, isTrue, 
                 reason: 'Token should be detected as stored: $originalToken');
        }
      });

      test('Feature: user-authentication-profile, Property 13: Token Storage Round-trip - Token with expiry', () async {
        // Property test: For any token with expiry time, storage should preserve both token and expiry
        final random = Random();
        
        for (int i = 0; i < 10; i++) {
          await tokenService.clearTokens();
          
          final token = 'test-token-$i';
          // Create expiry time that's well beyond the 5-minute buffer (1-2 hours)
          final expiryTime = DateTime.now().add(Duration(hours: random.nextInt(2) + 1));
          
          // Save token with expiry
          await tokenService.saveToken(token, expiryTime: expiryTime);
          
          // Retrieve token and expiry
          final retrievedToken = await tokenService.getToken();
          final retrievedExpiry = await tokenService.getTokenExpiry();
          
          // Verify round-trip consistency
          expect(retrievedToken, equals(token));
          expect(retrievedExpiry, isNotNull);
          
          // Expiry should be within 1 second of original (accounting for storage precision)
          final timeDifference = retrievedExpiry!.difference(expiryTime).abs();
          expect(timeDifference.inSeconds, lessThanOrEqualTo(1));
          
          // Token should be valid since expiry is well in the future
          final isValid = await tokenService.isTokenValid();
          expect(isValid, isTrue, reason: 'Token with future expiry (${expiryTime}) should be valid');
        }
      });

      test('Feature: user-authentication-profile, Property 13: Token Storage Round-trip - Refresh token storage', () async {
        // Property test: For any refresh token, storage and retrieval should be consistent
        final refreshTokens = [
          'refresh-token-1',
          'very-long-refresh-token-with-lots-of-characters-and-data',
          'rt.payload.signature',
          'simple-refresh',
        ];

        for (final originalRefreshToken in refreshTokens) {
          await tokenService.clearTokens();
          
          // Save refresh token
          await tokenService.saveRefreshToken(originalRefreshToken);
          
          // Retrieve refresh token
          final retrievedRefreshToken = await tokenService.getRefreshToken();
          
          // Verify round-trip consistency
          expect(retrievedRefreshToken, equals(originalRefreshToken));
          
          // Should be detected as having stored auth
          final hasStoredAuth = await tokenService.hasStoredAuth();
          expect(hasStoredAuth, isTrue);
        }
      });

      test('Feature: user-authentication-profile, Property 13: Token Storage Round-trip - Token clearing', () async {
        // Property test: For any stored tokens, clearing should remove all traces
        final random = Random();
        
        for (int i = 0; i < 5; i++) {
          final token = 'test-token-$i';
          final refreshToken = 'refresh-token-$i';
          final expiryTime = DateTime.now().add(Duration(hours: random.nextInt(24) + 1));
          
          // Store both tokens
          await tokenService.saveToken(token, expiryTime: expiryTime);
          await tokenService.saveRefreshToken(refreshToken);
          
          // Verify they're stored
          expect(await tokenService.getToken(), equals(token));
          expect(await tokenService.getRefreshToken(), equals(refreshToken));
          expect(await tokenService.getTokenExpiry(), isNotNull);
          expect(await tokenService.hasStoredAuth(), isTrue);
          
          // Clear all tokens
          await tokenService.clearTokens();
          
          // Verify everything is cleared
          expect(await tokenService.getToken(), isNull);
          expect(await tokenService.getRefreshToken(), isNull);
          expect(await tokenService.getTokenExpiry(), isNull);
          expect(await tokenService.hasStoredAuth(), isFalse);
          expect(await tokenService.isTokenValid(), isFalse);
        }
      });

      test('Feature: user-authentication-profile, Property 13: Token Storage Round-trip - JWT token parsing', () async {
        // Property test: For any valid JWT token, parsing should extract correct information
        final testCases = [
          {
            'token': _createJWTToken({'exp': _futureTimestamp(hours: 1), 'user_id': '123'}),
            'shouldBeValid': true,
            'hasExpiry': true,
          },
          {
            'token': _createJWTToken({'exp': _pastTimestamp(hours: 1), 'user_id': '456'}),
            'shouldBeValid': false,
            'hasExpiry': true,
          },
          {
            'token': _createJWTToken({'user_id': '789', 'email': 'test@example.com'}),
            'shouldBeValid': true, // No expiry, but valid format should be considered valid
            'hasExpiry': false,
          },
        ];

        for (final testCase in testCases) {
          await tokenService.clearTokens();
          
          final token = testCase['token'] as String;
          await tokenService.saveToken(token);
          
          // Test token format validation
          expect(tokenService.isValidTokenFormat(token), isTrue);
          
          // Test payload extraction
          final payload = tokenService.getTokenPayload(token);
          expect(payload, isNotNull);
          expect(payload, isA<Map<String, dynamic>>());
          
          // Test expiry extraction and validation
          if (testCase['hasExpiry'] as bool) {
            final expiry = await tokenService.getTokenExpiry();
            expect(expiry, isNotNull);
            
            final isValid = await tokenService.isTokenValid();
            expect(isValid, equals(testCase['shouldBeValid']));
          }
        }
      });

      test('Feature: user-authentication-profile, Property 13: Token Storage Round-trip - Invalid token handling', () async {
        // Property test: For any invalid token format, the system should handle gracefully
        final invalidTokens = [
          '',
          'invalid',
          'not.a.jwt',
          'too.many.parts.in.this.token',
          'invalid-base64.invalid-base64.invalid-base64',
          'null',
        ];

        for (final invalidToken in invalidTokens) {
          await tokenService.clearTokens();
          
          if (invalidToken.isNotEmpty && invalidToken != 'null') {
            // Should be able to store even invalid tokens
            await tokenService.saveToken(invalidToken);
            final retrieved = await tokenService.getToken();
            expect(retrieved, equals(invalidToken));
          }
          
          // Invalid format should be detected
          if (invalidToken.isNotEmpty) {
            expect(tokenService.isValidTokenFormat(invalidToken), isFalse);
            
            // Payload extraction should return null for invalid tokens
            final payload = tokenService.getTokenPayload(invalidToken);
            expect(payload, isNull);
          }
        }
      });

      test('Feature: user-authentication-profile, Property 13: Token Storage Round-trip - Concurrent operations', () async {
        // Property test: For any sequence of concurrent token operations, final state should be consistent
        await tokenService.clearTokens();
        
        final futures = <Future>[];
        final tokens = <String>[];
        
        // Create multiple concurrent save operations
        for (int i = 0; i < 5; i++) {
          final token = 'concurrent-token-$i';
          tokens.add(token);
          futures.add(tokenService.saveToken(token));
        }
        
        // Wait for all operations to complete
        await Future.wait(futures);
        
        // The final token should be one of the saved tokens
        final finalToken = await tokenService.getToken();
        expect(finalToken, isNotNull);
        expect(tokens.contains(finalToken), isTrue);
        
        // Should have stored auth
        expect(await tokenService.hasStoredAuth(), isTrue);
      });

      test('Feature: user-authentication-profile, Property 13: Token Storage Round-trip - Time-based validation', () async {
        // Property test: For any token with time-based expiry, validation should be time-accurate
        await tokenService.clearTokens();
        
        // Test token that expires in 10 minutes (well beyond the 5-minute buffer)
        final shortLivedToken = _createJWTToken({
          'exp': _futureTimestamp(minutes: 10),
          'user_id': 'test'
        });
        
        await tokenService.saveToken(shortLivedToken);
        
        // Should be valid initially
        expect(await tokenService.isTokenValid(), isTrue);
        expect(await tokenService.isTokenExpired(), isFalse);
        
        final timeUntilExpiry = await tokenService.getTimeUntilExpiry();
        expect(timeUntilExpiry, isNotNull);
        expect(timeUntilExpiry!.inMinutes, greaterThan(5)); // Should be more than 5 minutes
        expect(timeUntilExpiry.inMinutes, lessThanOrEqualTo(10)); // Should be around 10 minutes
        
        // Wait for token to expire (create a new token that expires in 1 second for this test)
        final quickExpiryToken = _createJWTToken({
          'exp': _futureTimestamp(seconds: 1),
          'user_id': 'test'
        });
        await tokenService.saveToken(quickExpiryToken);
        await Future.delayed(const Duration(seconds: 2));
        
        // Should be expired now
        expect(await tokenService.isTokenExpired(), isTrue);
        expect(await tokenService.isTokenValid(), isFalse);
        
        final expiredTimeUntilExpiry = await tokenService.getTimeUntilExpiry();
        expect(expiredTimeUntilExpiry, equals(Duration.zero));
      });

      test('Feature: user-authentication-profile, Property 13: Token Storage Round-trip - Multiple service instances', () async {
        // Property test: For any token stored by one service instance, it should be accessible by another
        final service1 = TokenService();
        final service2 = TokenService();
        
        try {
          await service1.clearTokens();
          
          final testToken = 'shared-token-test';
          final testRefreshToken = 'shared-refresh-token';
          
          // Store tokens using first service
          await service1.saveToken(testToken);
          await service1.saveRefreshToken(testRefreshToken);
          
          // Retrieve using second service
          final retrievedToken = await service2.getToken();
          final retrievedRefreshToken = await service2.getRefreshToken();
          
          // Should be the same (shared storage)
          expect(retrievedToken, equals(testToken));
          expect(retrievedRefreshToken, equals(testRefreshToken));
          
          // Both services should report having stored auth
          expect(await service1.hasStoredAuth(), isTrue);
          expect(await service2.hasStoredAuth(), isTrue);
          
          // Clear using second service
          await service2.clearTokens();
          
          // First service should also see the cleared state
          expect(await service1.hasStoredAuth(), isFalse);
          expect(await service1.getToken(), isNull);
        } finally {
          service1.dispose();
          service2.dispose();
        }
      });
    });

    group('Token Service Unit Tests', () {
      test('Token format validation works correctly', () {
        // Valid JWT format with proper base64 encoding
        final validJWT = _createJWTToken({'user_id': '123'});
        expect(tokenService.isValidTokenFormat(validJWT), isTrue);
        
        expect(tokenService.isValidTokenFormat('invalid'), isFalse);
        expect(tokenService.isValidTokenFormat(''), isFalse);
        expect(tokenService.isValidTokenFormat('too.many.parts.here.invalid'), isFalse);
        expect(tokenService.isValidTokenFormat('a.b.c'), isFalse); // Not valid base64
      });

      test('Clear access token preserves refresh token', () async {
        await tokenService.saveToken('access-token');
        await tokenService.saveRefreshToken('refresh-token');
        
        expect(await tokenService.getToken(), equals('access-token'));
        expect(await tokenService.getRefreshToken(), equals('refresh-token'));
        
        await tokenService.clearAccessToken();
        
        expect(await tokenService.getToken(), isNull);
        expect(await tokenService.getRefreshToken(), equals('refresh-token'));
        expect(await tokenService.hasStoredAuth(), isTrue);
      });

      test('Token refresh logic returns null when no refresh token', () async {
        await tokenService.clearTokens();
        
        final refreshedToken = await tokenService.refreshTokenIfNeeded();
        expect(refreshedToken, isNull);
      });
    });
  });
}

// Helper function to create a JWT token with given payload
String _createJWTToken(Map<String, dynamic> payload) {
  final header = {'alg': 'HS256', 'typ': 'JWT'};
  final encodedHeader = base64Url.encode(utf8.encode(jsonEncode(header)));
  final encodedPayload = base64Url.encode(utf8.encode(jsonEncode(payload)));
  final signature = base64Url.encode(utf8.encode('test-signature'));
  
  return '$encodedHeader.$encodedPayload.$signature';
}

// Helper function to get future timestamp
int _futureTimestamp({int hours = 0, int minutes = 0, int seconds = 0}) {
  return DateTime.now().add(Duration(hours: hours, minutes: minutes, seconds: seconds)).millisecondsSinceEpoch ~/ 1000;
}

// Helper function to get past timestamp
int _pastTimestamp({int hours = 0, int minutes = 0, int seconds = 0}) {
  return DateTime.now().subtract(Duration(hours: hours, minutes: minutes, seconds: seconds)).millisecondsSinceEpoch ~/ 1000;
}