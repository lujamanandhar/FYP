import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'auth_token_expiry';
  static const String _refreshTokenKey = 'refresh_token';

  SharedPreferences? _prefs;

  // Initialize shared preferences
  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // Save authentication token with expiry
  Future<void> saveToken(String token, {DateTime? expiryTime}) async {
    await _initPrefs();
    
    await _prefs!.setString(_tokenKey, token);
    
    // If no expiry time provided, extract from JWT token or set default
    final expiry = expiryTime ?? _extractExpiryFromToken(token) ?? DateTime.now().add(const Duration(hours: 24));
    await _prefs!.setString(_tokenExpiryKey, expiry.toIso8601String());
  }

  // Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _initPrefs();
    await _prefs!.setString(_refreshTokenKey, refreshToken);
  }

  // Retrieve authentication token
  Future<String?> getToken() async {
    await _initPrefs();
    return _prefs!.getString(_tokenKey);
  }

  // Retrieve refresh token
  Future<String?> getRefreshToken() async {
    await _initPrefs();
    return _prefs!.getString(_refreshTokenKey);
  }

  // Get token expiry time
  Future<DateTime?> getTokenExpiry() async {
    await _initPrefs();
    final expiryString = _prefs!.getString(_tokenExpiryKey);
    if (expiryString == null) return null;
    
    try {
      return DateTime.parse(expiryString);
    } catch (e) {
      return null;
    }
  }

  // Check if token is valid (exists and not expired)
  Future<bool> isTokenValid() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    
    final expiry = await getTokenExpiry();
    if (expiry == null) {
      // If no expiry is set, try to extract from token if it's a JWT
      if (isValidTokenFormat(token)) {
        final extractedExpiry = _extractExpiryFromToken(token);
        if (extractedExpiry != null) {
          // Save the extracted expiry for future use
          await _initPrefs();
          await _prefs!.setString(_tokenExpiryKey, extractedExpiry.toIso8601String());
          return DateTime.now().isBefore(extractedExpiry.subtract(const Duration(minutes: 5)));
        }
      }
      // No expiry information available, consider valid (for simple string tokens)
      return true;
    }
    
    // Add 5 minute buffer to account for clock skew
    return DateTime.now().isBefore(expiry.subtract(const Duration(minutes: 5)));
  }

  // Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;
    
    return DateTime.now().isAfter(expiry);
  }

  // Get time until token expires
  Future<Duration?> getTimeUntilExpiry() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return null;
    
    final now = DateTime.now();
    if (now.isAfter(expiry)) return Duration.zero;
    
    return expiry.difference(now);
  }

  // Clear all stored tokens
  Future<void> clearTokens() async {
    await _initPrefs();
    await Future.wait([
      _prefs!.remove(_tokenKey),
      _prefs!.remove(_tokenExpiryKey),
      _prefs!.remove(_refreshTokenKey),
    ]);
  }

  // Clear only access token (keep refresh token)
  Future<void> clearAccessToken() async {
    await _initPrefs();
    await Future.wait([
      _prefs!.remove(_tokenKey),
      _prefs!.remove(_tokenExpiryKey),
    ]);
  }

  // Check if user has any stored authentication
  Future<bool> hasStoredAuth() async {
    final token = await getToken();
    final refreshToken = await getRefreshToken();
    return (token != null && token.isNotEmpty) || (refreshToken != null && refreshToken.isNotEmpty);
  }

  // Automatic token refresh logic placeholder
  // This would be implemented when refresh token endpoint is available
  Future<String?> refreshTokenIfNeeded() async {
    if (await isTokenValid()) {
      return await getToken();
    }

    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    // TODO: Implement actual refresh token API call when backend supports it
    // For now, return null to indicate refresh is needed
    return null;
  }

  // Extract expiry time from JWT token payload
  DateTime? _extractExpiryFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (second part)
      final payload = parts[1];
      
      // Add padding if needed for base64 decoding
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      final payloadMap = jsonDecode(decoded) as Map<String, dynamic>;

      // Extract 'exp' claim (expiry timestamp)
      final exp = payloadMap['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    } catch (e) {
      // If we can't parse the token, return null
      return null;
    }
    return null;
  }

  // Validate token format (basic JWT structure check)
  bool isValidTokenFormat(String token) {
    if (token.isEmpty) return false;
    
    final parts = token.split('.');
    if (parts.length != 3) return false;
    
    // Check if each part is valid base64
    try {
      for (final part in parts) {
        if (part.isEmpty) return false;
        // Try to decode each part - if it fails, it's not valid base64
        base64Url.decode(base64Url.normalize(part));
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get token payload as Map (for debugging/info purposes)
  Map<String, dynamic>? getTokenPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final normalizedPayload = base64Url.normalize(payload);
      final decoded = utf8.decode(base64Url.decode(normalizedPayload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // Dispose resources (if needed)
  void dispose() {
    // SharedPreferences doesn't need explicit disposal
  }
}