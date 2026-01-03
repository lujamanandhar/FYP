import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'token_service.dart';

class AuthInterceptor {
  static final AuthInterceptor _instance = AuthInterceptor._internal();
  factory AuthInterceptor() => _instance;
  AuthInterceptor._internal();

  final AuthService _authService = AuthService();
  final TokenService _tokenService = TokenService();
  
  // Navigation context for redirecting to login
  BuildContext? _context;
  
  // Route name for login screen
  String _loginRoute = '/login';
  
  // Flag to prevent multiple simultaneous logout operations
  bool _isLoggingOut = false;

  // Initialize the interceptor with navigation context
  void initialize(BuildContext context, {String loginRoute = '/login'}) {
    _context = context;
    _loginRoute = loginRoute;
    
    // Set up authentication failure callback
    _authService.setAuthenticationFailureCallback(_handleAuthenticationFailure);
  }

  // Update navigation context (useful when context changes)
  void updateContext(BuildContext context) {
    _context = context;
  }

  // Handle authentication failure
  void _handleAuthenticationFailure() {
    if (_isLoggingOut) return; // Prevent multiple logout operations
    
    _performLogout();
  }

  // Perform logout and redirect to login screen
  Future<void> _performLogout() async {
    if (_isLoggingOut) return;
    
    _isLoggingOut = true;
    
    try {
      // Clear all authentication data
      await _authService.logout();
      
      // Navigate to login screen if context is available
      if (_context != null && _context!.mounted) {
        // Clear the navigation stack and go to login
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          _loginRoute,
          (route) => false,
        );
        
        // Show a message to user about session expiry
        _showSessionExpiredMessage();
      }
    } catch (e) {
      // Log error but don't throw to prevent app crashes
      debugPrint('Error during logout: $e');
    } finally {
      _isLoggingOut = false;
    }
  }

  // Show session expired message
  void _showSessionExpiredMessage() {
    if (_context != null && _context!.mounted) {
      ScaffoldMessenger.of(_context!).showSnackBar(
        const SnackBar(
          content: Text('Your session has expired. Please log in again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // Manual logout (called by user action)
  Future<void> logout() async {
    await _performLogout();
  }

  // Check authentication status and redirect if needed
  Future<bool> checkAuthenticationStatus() async {
    final isAuthenticated = await _authService.isAuthenticated();
    
    if (!isAuthenticated && _context != null && _context!.mounted) {
      // Redirect to login if not authenticated
      Navigator.of(_context!).pushNamedAndRemoveUntil(
        _loginRoute,
        (route) => false,
      );
      return false;
    }
    
    return isAuthenticated;
  }

  // Initialize authentication on app start
  Future<bool> initializeAuthentication() async {
    try {
      // Initialize auth service with stored token
      await _authService.initialize();
      
      // Check if we have valid authentication
      return await _authService.isAuthenticated();
    } catch (e) {
      debugPrint('Error initializing authentication: $e');
      return false;
    }
  }

  // Get time until token expires (for UI display)
  Future<Duration?> getTimeUntilTokenExpiry() async {
    return await _tokenService.getTimeUntilExpiry();
  }

  // Check if token will expire soon (within specified duration)
  Future<bool> willTokenExpireSoon({Duration threshold = const Duration(minutes: 5)}) async {
    final timeUntilExpiry = await getTimeUntilTokenExpiry();
    if (timeUntilExpiry == null) return true;
    
    return timeUntilExpiry <= threshold;
  }

  // Dispose resources
  void dispose() {
    _context = null;
    _authService.dispose();
  }
}

// Extension to make it easier to use with widgets
extension AuthInterceptorWidget on Widget {
  Widget withAuthInterceptor(BuildContext context, {String loginRoute = '/login'}) {
    // Initialize the interceptor when the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthInterceptor().initialize(context, loginRoute: loginRoute);
    });
    
    return this;
  }
}

// Mixin for screens that require authentication
mixin AuthRequiredMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final interceptor = AuthInterceptor();
    interceptor.updateContext(context);
    
    final isAuthenticated = await interceptor.checkAuthenticationStatus();
    if (!isAuthenticated) {
      // Navigation will be handled by the interceptor
      return;
    }
  }
}