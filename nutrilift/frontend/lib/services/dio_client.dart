import 'package:dio/dio.dart';
import 'token_service.dart';
import 'app_config.dart';

/// Dio HTTP client with JWT authentication and error handling interceptors
class DioClient {
  static String get _baseUrl => AppConfig.baseUrl;
  static const Duration _timeout = Duration(seconds: 10);

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

    // Handle authentication failures (401) - but don't clear tokens automatically
    // Let the UI handle re-authentication
    if (error.response?.statusCode == 401) {
      onAuthenticationFailed?.call();
    }

    handler.next(error);
  }

  /// Get valid token (without refresh - backend doesn't support token refresh yet)
  Future<String?> _getValidToken() async {
    // Simply return the stored token if it exists
    // Note: Token refresh is not implemented in the backend yet
    return await _tokenService.getToken();
  }

  /// Get the Dio instance for making requests
  Dio get dio => _dio;

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}
