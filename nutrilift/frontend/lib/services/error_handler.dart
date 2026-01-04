import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_client.dart';

/// Global error handler service for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  // Global navigator key for showing dialogs without context
  static GlobalKey<NavigatorState>? navigatorKey;
  
  // Connectivity service
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Error tracking
  bool _isOffline = false;
  final List<String> _errorLog = [];
  
  // Callbacks
  Function()? onNetworkRestored;
  Function()? onNetworkLost;

  /// Initialize the global error handler
  void initialize({GlobalKey<NavigatorState>? navKey}) {
    if (navKey != null) {
      navigatorKey = navKey;
    }
    
    // Set up global error handling for Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };
    
    // Set up global error handling for async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _handleAsyncError(error, stack);
      return true;
    };
    
    // Monitor network connectivity
    _initializeConnectivityMonitoring();
  }

  /// Initialize network connectivity monitoring
  void _initializeConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOffline = _isOffline;
        _isOffline = results.contains(ConnectivityResult.none) || results.isEmpty;
        
        if (wasOffline && !_isOffline) {
          // Network restored
          _handleNetworkRestored();
        } else if (!wasOffline && _isOffline) {
          // Network lost
          _handleNetworkLost();
        }
      },
    );
    
    // Check initial connectivity state
    _checkInitialConnectivity();
  }

  /// Check initial connectivity state
  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isOffline = results.contains(ConnectivityResult.none) || results.isEmpty;
    } catch (e) {
      _isOffline = false; // Assume online if check fails
    }
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    // Log error
    _logError('Flutter Error: ${details.exception}', details.stack);
    
    // In debug mode, use default Flutter error handling
    if (kDebugMode) {
      FlutterError.presentError(details);
      return;
    }
    
    // In release mode, show user-friendly error
    _showUserFriendlyError(
      'Something went wrong',
      'The app encountered an unexpected error. Please try again.',
      canRetry: true,
    );
  }

  /// Handle async errors outside Flutter framework
  void _handleAsyncError(Object error, StackTrace stack) {
    // Log error
    _logError('Async Error: $error', stack);
    
    // In debug mode, print to console
    if (kDebugMode) {
      debugPrint('Async Error: $error');
      debugPrint('Stack trace: $stack');
      return;
    }
    
    // In release mode, show user-friendly error
    _showUserFriendlyError(
      'Unexpected Error',
      'An unexpected error occurred. Please restart the app if the problem persists.',
      canRetry: false,
    );
  }

  /// Handle API errors with user-friendly messages
  String handleApiError(ApiException error) {
    _logError('API Error: ${error.message}', null);
    
    if (error.isNetworkError()) {
      if (_isOffline) {
        return 'You appear to be offline. Please check your internet connection and try again.';
      }
      return 'Network error occurred. Please check your connection and try again.';
    }
    
    if (error.isUnauthorized()) {
      return 'Your session has expired. Please log in again.';
    }
    
    if (error.isValidationError()) {
      // Return the first validation error or a generic message
      final firstError = error.errors?.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      return error.message;
    }
    
    if (error.isServerError()) {
      return 'Server error occurred. Please try again later.';
    }
    
    // Return original message for other errors
    return error.message;
  }

  /// Extract server validation errors for form display
  Map<String, dynamic>? extractValidationErrors(ApiException error) {
    if (!error.isValidationError() || error.errors == null) {
      return null;
    }
    
    return error.errors;
  }

  /// Show success message with animation
  void showSuccessMessage(String message, {BuildContext? context}) {
    final targetContext = context ?? navigatorKey?.currentContext;
    if (targetContext == null) return;
    
    ScaffoldMessenger.of(targetContext).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Handle network errors with retry mechanism
  Future<T> handleNetworkOperation<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    String? operationName,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        // Check if offline before attempting
        if (_isOffline) {
          throw ApiException('No internet connection available');
        }
        
        return await operation();
      } on SocketException {
        attempts++;
        if (attempts >= maxRetries) {
          throw ApiException('Network connection failed after $maxRetries attempts');
        }
        
        // Show retry message to user
        if (operationName != null) {
          _showRetryMessage(operationName, attempts, maxRetries);
        }
        
        await Future.delayed(retryDelay * attempts);
      } on ApiException catch (e) {
        if (e.isNetworkError() && attempts < maxRetries - 1) {
          attempts++;
          
          if (operationName != null) {
            _showRetryMessage(operationName, attempts, maxRetries);
          }
          
          await Future.delayed(retryDelay * attempts);
        } else {
          rethrow;
        }
      }
    }
    
    throw ApiException('Operation failed after $maxRetries attempts');
  }

  /// Show user-friendly error dialog
  void _showUserFriendlyError(
    String title,
    String message, {
    bool canRetry = false,
    VoidCallback? onRetry,
  }) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            if (canRetry && onRetry != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text('Retry'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Show retry message to user
  void _showRetryMessage(String operationName, int attempt, int maxAttempts) {
    final context = navigatorKey?.currentContext;
    if (context == null) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$operationName failed. Retrying... ($attempt/$maxAttempts)'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Handle network restored event
  void _handleNetworkRestored() {
    final context = navigatorKey?.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi, color: Colors.white),
              SizedBox(width: 8),
              Text('Connection restored'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
    
    onNetworkRestored?.call();
  }

  /// Handle network lost event
  void _handleNetworkLost() {
    final context = navigatorKey?.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white),
              SizedBox(width: 8),
              Text('No internet connection'),
            ],
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    onNetworkLost?.call();
  }

  /// Log error for debugging and analytics
  void _logError(String error, StackTrace? stack) {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = '[$timestamp] $error';
    
    _errorLog.add(logEntry);
    
    // Keep only last 100 errors to prevent memory issues
    if (_errorLog.length > 100) {
      _errorLog.removeAt(0);
    }
    
    // In debug mode, print to console
    if (kDebugMode) {
      debugPrint(logEntry);
      if (stack != null) {
        debugPrint('Stack trace: $stack');
      }
    }
    
    // TODO: Send to analytics service in production
  }

  /// Show offline mode dialog
  void showOfflineDialog() {
    final context = navigatorKey?.currentContext;
    if (context == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.orange),
              SizedBox(width: 8),
              Text('Offline Mode'),
            ],
          ),
          content: const Text(
            'You are currently offline. Some features may not be available until you reconnect to the internet.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Check if currently offline
  bool get isOffline => _isOffline;

  /// Get error log for debugging
  List<String> get errorLog => List.unmodifiable(_errorLog);

  /// Clear error log
  void clearErrorLog() {
    _errorLog.clear();
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

/// Extension to add error handling to widgets
extension ErrorHandlingWidget on Widget {
  Widget withErrorHandling() {
    return Builder(
      builder: (context) {
        return this;
      },
    );
  }
}

/// Mixin for widgets that need error handling
mixin ErrorHandlingMixin<T extends StatefulWidget> on State<T> {
  final ErrorHandler _errorHandler = ErrorHandler();

  /// Handle API errors with user feedback
  void handleApiError(ApiException error) {
    final message = _errorHandler.handleApiError(error);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: error.isNetworkError()
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () {
                    // Override in implementing widget
                  },
                )
              : null,
        ),
      );
    }
  }

  /// Handle server validation errors
  Map<String, dynamic>? handleValidationErrors(ApiException error) {
    return _errorHandler.extractValidationErrors(error);
  }

  /// Show success message
  void showSuccessMessage(String message) {
    _errorHandler.showSuccessMessage(message, context: context);
  }

  /// Show loading indicator
  void showLoading() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
  }

  /// Hide loading indicator
  void hideLoading() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  /// Execute operation with error handling
  Future<R?> executeWithErrorHandling<R>(
    Future<R> Function() operation, {
    String? loadingMessage,
    String? successMessage,
    bool showLoading = false,
  }) async {
    try {
      if (showLoading) {
        this.showLoading();
      }

      final result = await _errorHandler.handleNetworkOperation(operation);

      if (showLoading) {
        hideLoading();
      }

      if (successMessage != null && mounted) {
        showSuccessMessage(successMessage);
      }

      return result;
    } on ApiException catch (e) {
      if (showLoading) {
        hideLoading();
      }
      handleApiError(e);
      return null;
    } catch (e) {
      if (showLoading) {
        hideLoading();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}