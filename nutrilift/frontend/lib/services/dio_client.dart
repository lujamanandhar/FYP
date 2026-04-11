import 'package:dio/dio.dart';
import 'token_service.dart';
import 'app_config.dart';

/// Dio HTTP client with JWT authentication, auto-refresh, and error handling
class DioClient {
  static String get _baseUrl => AppConfig.baseUrl;
  static const Duration _timeout = Duration(seconds: 10);

  late final Dio _dio;
  final TokenService _tokenService = TokenService();
  bool _isRefreshing = false;

  // Callback for when authentication fails and refresh is impossible
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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenService.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  void _onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    // Rate limiting — wait and retry once
    if (error.response?.statusCode == 429) {
      final retryAfter = error.response?.headers.value('Retry-After');
      if (retryAfter != null) {
        await Future.delayed(Duration(seconds: int.tryParse(retryAfter) ?? 60));
        try {
          final response = await _dio.fetch(error.requestOptions);
          return handler.resolve(response);
        } catch (_) {}
      }
    }

    // 401 — try to refresh the token once
    if (error.response?.statusCode == 401 && !_isRefreshing) {
      // Don't try to refresh the refresh endpoint itself
      if (error.requestOptions.path.contains('/auth/token/refresh/') ||
          error.requestOptions.path.contains('/auth/login/') ||
          error.requestOptions.path.contains('/auth/register/')) {
        onAuthenticationFailed?.call();
        return handler.next(error);
      }

      _isRefreshing = true;
      try {
        final newToken = await _tokenService.refreshTokenIfNeeded();
        if (newToken != null) {
          // Retry the original request with the new token
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await _dio.fetch(opts);
          _isRefreshing = false;
          return handler.resolve(response);
        }
      } catch (_) {}
      _isRefreshing = false;
      onAuthenticationFailed?.call();
    }

    handler.next(error);
  }

  Dio get dio => _dio;

  void dispose() {
    _dio.close();
  }
}
