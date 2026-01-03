import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _baseUrl = 'http://localhost:8000/api';
  static const Duration _timeout = Duration(seconds: 30);
  static const int _maxRetries = 3;

  final http.Client _client;
  String? _authToken;

  ApiClient() : _client = http.Client();

  // Set authentication token
  void setAuthToken(String? token) {
    _authToken = token;
  }

  // Get common headers
  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  // Generic request method with retry logic
  Future<ApiResponse> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    int retryCount = 0,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final requestHeaders = _getHeaders(additionalHeaders: headers);

      http.Response response;
      
      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client.get(uri, headers: requestHeaders).timeout(_timeout);
          break;
        case 'POST':
          response = await _client.post(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(_timeout);
          break;
        case 'PUT':
          response = await _client.put(
            uri,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(_timeout);
          break;
        case 'DELETE':
          response = await _client.delete(uri, headers: requestHeaders).timeout(_timeout);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }

      return _handleResponse(response);
    } on SocketException {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _makeRequest(method, endpoint, body: body, headers: headers, retryCount: retryCount + 1);
      }
      throw ApiException('No internet connection. Please check your network and try again.');
    } on HttpException {
      if (retryCount < _maxRetries) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _makeRequest(method, endpoint, body: body, headers: headers, retryCount: retryCount + 1);
      }
      throw ApiException('Network error occurred. Please try again.');
    } on FormatException {
      throw ApiException('Invalid response format from server.');
    } catch (e) {
      if (retryCount < _maxRetries && _isRetryableError(e)) {
        await Future.delayed(Duration(seconds: retryCount + 1));
        return _makeRequest(method, endpoint, body: body, headers: headers, retryCount: retryCount + 1);
      }
      
      if (e is ApiException) {
        rethrow;
      }
      
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Handle HTTP response
  ApiResponse _handleResponse(http.Response response) {
    try {
      final Map<String, dynamic> data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse(
          success: true,
          statusCode: response.statusCode,
          data: data,
        );
      } else {
        final message = data['message'] ?? 'An error occurred';
        final errors = data['errors'] as Map<String, dynamic>?;
        
        throw ApiException(
          message,
          statusCode: response.statusCode,
          errors: errors,
        );
      }
    } on FormatException {
      throw ApiException('Invalid response format from server.');
    }
  }

  // Check if error is retryable
  bool _isRetryableError(dynamic error) {
    if (error is ApiException) {
      // Don't retry client errors (4xx), only server errors (5xx) and network errors
      return error.statusCode == null || error.statusCode! >= 500;
    }
    return true; // Retry other types of errors
  }

  // Public HTTP methods
  Future<ApiResponse> get(String endpoint, {Map<String, String>? headers}) {
    return _makeRequest('GET', endpoint, headers: headers);
  }

  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers}) {
    return _makeRequest('POST', endpoint, body: body, headers: headers);
  }

  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body, Map<String, String>? headers}) {
    return _makeRequest('PUT', endpoint, body: body, headers: headers);
  }

  Future<ApiResponse> delete(String endpoint, {Map<String, String>? headers}) {
    return _makeRequest('DELETE', endpoint, headers: headers);
  }

  // Dispose resources
  void dispose() {
    _client.close();
  }
}

// API Response model
class ApiResponse {
  final bool success;
  final int statusCode;
  final Map<String, dynamic> data;

  ApiResponse({
    required this.success,
    required this.statusCode,
    required this.data,
  });

  T? getData<T>() {
    return data['data'] as T?;
  }

  String? getMessage() {
    return data['message'] as String?;
  }
}

// API Exception for error handling
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() {
    return 'ApiException: $message';
  }

  // Get field-specific error messages
  String? getFieldError(String field) {
    if (errors == null) return null;
    final fieldErrors = errors![field];
    if (fieldErrors is List && fieldErrors.isNotEmpty) {
      return fieldErrors.first.toString();
    }
    return fieldErrors?.toString();
  }

  // Check if it's a specific type of error
  bool isNetworkError() {
    return statusCode == null;
  }

  bool isUnauthorized() {
    return statusCode == 401;
  }

  bool isValidationError() {
    return statusCode == 400 && errors != null;
  }

  bool isServerError() {
    return statusCode != null && statusCode! >= 500;
  }
}