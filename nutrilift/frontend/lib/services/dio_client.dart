import 'package:dio/dio.dart';
import 'token_service.dart';

/// Dio HTTP client with JWT authentication and error handling interceptors
class DioClient {
  static const String _baseUrl = 'http://127.0.0.1:8000/api';
  static const Duration _timeout = Duration(seconds: 30);

  late final Dio _dio;
  final TokenService _tokenService = TokenService();

  // Callback for when authentication fails
  Function()? onAuthenticationFailed;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: _timeout,
        receiveTimeout: _timeout,
        sendTimeout: _timeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add JWT interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  /// Request interceptor - adds JWT token to headers
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get valid token (handles refresh automatically)
    final token = await _getValidToken();
    
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  /// Response interceptor - handles successful responses
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  /// Error interceptor - handles errors and authentication failures
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    // Handle authentication failures (401)
    if (error.response?.statusCode == 401) {
      await _handleAuthenticationFailure();
    }

    // Handle rate limiting (429)
    if (error.response?.statusCode == 429) {
      final retryAfter = error.response?.headers.value('Retry-After');
      if (retryAfter != null) {
        final delay = int.tryParse(retryAfter) ?? 60;
        await Future.delayed(Duration(seconds: delay));
        
        // Retry the request
        try {
          final response = await _dio.fetch(error.requestOptions);
          return handler.resolve(response);
        } catch (e) {
          // If retry fails, pass the original error
        }
      }
    }

    handler.next(error);
  }

  /// Get valid token (with automatic refresh if needed)
  Future<String?> _getValidToken() async {
    // Check if token is still valid
    if (await _tokenService.isTokenValid()) {
      return await _tokenService.getToken();
    }

    // Try to refresh token if available
    final refreshedToken = await _tokenService.refreshTokenIfNeeded();
    if (refreshedToken != null) {
      return refreshedToken;
    }

    // No valid token available
    return null;
  }

  /// Handle authentication failure
  Future<void> _handleAuthenticationFailure() async {
    // Clear stored tokens
    await _tokenService.clearTokens();

    // Notify listeners about authentication failure
    onAuthenticationFailed?.call();
  }

  /// Get the Dio instance for making requests
  Dio get dio => _dio;

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}
