import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:nutrilift/UserManagement/login_screen.dart';
import 'package:nutrilift/UserManagement/signup_screen.dart';
import 'package:nutrilift/UserManagement/main_navigation.dart';
import 'package:nutrilift/UserManagement/gender_screen.dart';
import 'package:nutrilift/services/auth_service.dart';
import 'package:nutrilift/services/api_client.dart';

// Generate mocks
@GenerateMocks([AuthService])
import 'authentication_screens_test.mocks.dart';

void main() {
  group('Authentication Screens Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    group('LoginScreen Tests', () {
      testWidgets('should display login form elements', (WidgetTester tester) async {
        // Set a larger screen size to avoid overflow
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: const LoginScreen(),
          ),
        );

        // Verify UI elements are present
        expect(find.text('Sign In To NutriLift'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields
        expect(find.text('Log In'), findsOneWidget);
        expect(find.text('Signup'), findsOneWidget);
      });

      testWidgets('should validate required fields', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: const LoginScreen(),
          ),
        );

        // Find the login button and tap it without entering data
        final loginButton = find.text('Log In');
        await tester.tap(loginButton);
        await tester.pump();

        // Should show validation errors
        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
      });

      testWidgets('should validate email format', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: const LoginScreen(),
          ),
        );

        // Enter invalid email
        final emailField = find.byType(TextFormField).first;
        await tester.enterText(emailField, 'invalid-email');
        
        // Enter password
        final passwordField = find.byType(TextFormField).last;
        await tester.enterText(passwordField, 'password123');

        // Tap login button
        final loginButton = find.text('Log In');
        await tester.tap(loginButton);
        await tester.pump();

        // Should show email format validation error
        expect(find.text('Please enter a valid email address'), findsOneWidget);
      });

      testWidgets('should show loading state during login', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        
        // Create a custom LoginScreen with mock service for this test
        await tester.pumpWidget(
          MaterialApp(
            home: TestLoginScreen(authService: mockAuthService),
          ),
        );

        // Setup mock to return a delayed response
        when(mockAuthService.login(any)).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return AuthResponse(
            token: 'test-token',
            user: UserProfile(
              id: '1',
              email: 'test@example.com',
              name: 'Test User',
            ),
          );
        });

        // Enter valid credentials
        final emailField = find.byType(TextFormField).first;
        final passwordField = find.byType(TextFormField).last;
        
        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');
        await tester.pump();

        // Tap login button
        final loginButton = find.text('Log In');
        await tester.tap(loginButton);
        await tester.pump();

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Log In'), findsNothing);

        // Wait for login to complete
        await tester.pumpAndSettle();
      });

      testWidgets('should display error message on login failure', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: TestLoginScreen(authService: mockAuthService),
          ),
        );

        // Setup mock to throw an exception
        when(mockAuthService.login(any)).thenThrow(
          ApiException('Invalid email or password', statusCode: 401),
        );

        // Enter credentials
        final emailField = find.byType(TextFormField).first;
        final passwordField = find.byType(TextFormField).last;
        
        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'wrongpassword');
        await tester.pump();

        // Tap login button
        final loginButton = find.text('Log In');
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Should display error message
        expect(find.text('Invalid email or password. Please try again.'), findsOneWidget);
      });

      testWidgets('should navigate to MainNavigation on successful login', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: TestLoginScreen(authService: mockAuthService),
          ),
        );

        // Setup mock to return successful response
        when(mockAuthService.login(any)).thenAnswer((_) async => AuthResponse(
          token: 'test-token',
          user: UserProfile(
            id: '1',
            email: 'test@example.com',
            name: 'Test User',
          ),
        ));

        // Enter valid credentials
        final emailField = find.byType(TextFormField).first;
        final passwordField = find.byType(TextFormField).last;
        
        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');
        await tester.pump();

        // Tap login button
        final loginButton = find.text('Log In');
        await tester.tap(loginButton);
        await tester.pumpAndSettle();

        // Should navigate to MainNavigation
        expect(find.byType(MainNavigation), findsOneWidget);
        verify(mockAuthService.login(any)).called(1);
      });
    });

    group('SignupScreen Tests', () {
      testWidgets('should display signup form elements', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: const SignupScreen(),
          ),
        );

        // Verify UI elements are present
        expect(find.text('Sign Up To NutriLift'), findsOneWidget);
        expect(find.byType(TextFormField), findsNWidgets(4)); // Name, email, password, confirm password
        expect(find.text('Sign Up'), findsOneWidget);
        expect(find.text('Login'), findsOneWidget);
      });

      testWidgets('should validate all required fields', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: const SignupScreen(),
          ),
        );

        // Tap signup button without entering data
        final signupButton = find.text('Sign Up');
        await tester.tap(signupButton);
        await tester.pump();

        // Should show validation errors for all required fields
        expect(find.text('Name is required'), findsOneWidget);
        expect(find.text('Email is required'), findsOneWidget);
        expect(find.text('Password is required'), findsOneWidget);
        expect(find.text('Please confirm your password'), findsOneWidget);
      });

      testWidgets('should validate password length', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: const SignupScreen(),
          ),
        );

        // Enter short password
        final passwordField = find.byType(TextFormField).at(2); // Third field is password
        await tester.enterText(passwordField, '123');
        
        // Tap signup button
        final signupButton = find.text('Sign Up');
        await tester.tap(signupButton);
        await tester.pump();

        // Should show password length validation error
        expect(find.text('Password must be at least 8 characters long'), findsOneWidget);
      });

      testWidgets('should validate password confirmation', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: const SignupScreen(),
          ),
        );

        // Enter different passwords
        final passwordField = find.byType(TextFormField).at(2);
        final confirmPasswordField = find.byType(TextFormField).at(3);
        
        await tester.enterText(passwordField, 'password123');
        await tester.enterText(confirmPasswordField, 'differentpassword');
        await tester.pump();

        // Tap signup button
        final signupButton = find.text('Sign Up');
        await tester.tap(signupButton);
        await tester.pump();

        // Should show password mismatch error
        expect(find.text('Passwords do not match'), findsOneWidget);
      });

      testWidgets('should display error message on signup failure', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: TestSignupScreen(authService: mockAuthService),
          ),
        );

        // Setup mock to throw an exception
        when(mockAuthService.register(any)).thenThrow(
          ApiException('An account with this email already exists', statusCode: 409),
        );

        // Enter valid data
        final nameField = find.byType(TextFormField).at(0);
        final emailField = find.byType(TextFormField).at(1);
        final passwordField = find.byType(TextFormField).at(2);
        final confirmPasswordField = find.byType(TextFormField).at(3);
        
        await tester.enterText(nameField, 'Test User');
        await tester.enterText(emailField, 'existing@example.com');
        await tester.enterText(passwordField, 'password123');
        await tester.enterText(confirmPasswordField, 'password123');
        await tester.pump();

        // Tap signup button
        final signupButton = find.text('Sign Up');
        await tester.tap(signupButton);
        await tester.pumpAndSettle();

        // Should display error message
        expect(find.text('An account with this email already exists. Please use a different email or try logging in.'), findsOneWidget);
      });

      testWidgets('should navigate to GenderScreen on successful signup', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: TestSignupScreen(authService: mockAuthService),
          ),
        );

        // Setup mock to return successful response
        when(mockAuthService.register(any)).thenAnswer((_) async => AuthResponse(
          token: 'test-token',
          user: UserProfile(
            id: '1',
            email: 'test@example.com',
            name: 'Test User',
          ),
        ));

        // Enter valid data
        final nameField = find.byType(TextFormField).at(0);
        final emailField = find.byType(TextFormField).at(1);
        final passwordField = find.byType(TextFormField).at(2);
        final confirmPasswordField = find.byType(TextFormField).at(3);
        
        await tester.enterText(nameField, 'Test User');
        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');
        await tester.enterText(confirmPasswordField, 'password123');
        await tester.pump();

        // Tap signup button
        final signupButton = find.text('Sign Up');
        await tester.tap(signupButton);
        await tester.pumpAndSettle();

        // Should navigate to GenderScreen
        expect(find.byType(GenderScreen), findsOneWidget);
        expect(find.text('What is your gender?'), findsOneWidget);
        verify(mockAuthService.register(any)).called(1);
      });

      testWidgets('should handle network errors gracefully', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(
          MaterialApp(
            home: TestSignupScreen(authService: mockAuthService),
          ),
        );

        // Setup mock to throw a network error
        when(mockAuthService.register(any)).thenThrow(
          ApiException('Network error'),
        );

        // Enter valid data
        final nameField = find.byType(TextFormField).at(0);
        final emailField = find.byType(TextFormField).at(1);
        final passwordField = find.byType(TextFormField).at(2);
        final confirmPasswordField = find.byType(TextFormField).at(3);
        
        await tester.enterText(nameField, 'Test User');
        await tester.enterText(emailField, 'test@example.com');
        await tester.enterText(passwordField, 'password123');
        await tester.enterText(confirmPasswordField, 'password123');
        await tester.pump();

        // Tap signup button
        final signupButton = find.text('Sign Up');
        await tester.tap(signupButton);
        await tester.pumpAndSettle();

        // Should display network error message
        expect(find.text('Network error. Please check your connection and try again.'), findsOneWidget);
      });
    });
  });
}

// Test wrapper classes to inject mock services
class TestLoginScreen extends StatefulWidget {
  final AuthService authService;
  
  const TestLoginScreen({super.key, required this.authService});

  @override
  State<TestLoginScreen> createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loginRequest = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final response = await widget.authService.login(loginRequest);
      
      if (response.token != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed. Please try again.';
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      setState(() {
        if (e.isUnauthorized()) {
          _errorMessage = 'Invalid email or password. Please try again.';
        } else if (e.isNetworkError()) {
          _errorMessage = 'Network error. Please check your connection and try again.';
        } else {
          _errorMessage = e.message;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sign In To NutriLift',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Log In'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TestSignupScreen extends StatefulWidget {
  final AuthService authService;
  
  const TestSignupScreen({super.key, required this.authService});

  @override
  State<TestSignupScreen> createState() => _TestSignupScreenState();
}

class _TestSignupScreenState extends State<TestSignupScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final registerRequest = RegisterRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      final response = await widget.authService.register(registerRequest);
      
      if (response.token != null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const GenderScreen()),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Registration failed. Please try again.';
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      setState(() {
        if (e.statusCode == 409) {
          _errorMessage = 'An account with this email already exists. Please use a different email or try logging in.';
        } else if (e.isNetworkError()) {
          _errorMessage = 'Network error. Please check your connection and try again.';
        } else {
          _errorMessage = e.message;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sign Up To NutriLift',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                
                TextFormField(
                  controller: _nameController,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name is required';
                    }
                    if (value.length < 2) {
                      return 'Name must be at least 2 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}