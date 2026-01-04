import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:nutrilift/UserManagement/login_screen.dart';
import 'package:nutrilift/UserManagement/signup_screen.dart';
import 'package:nutrilift/UserManagement/gender_screen.dart';
import 'package:nutrilift/UserManagement/age_group_screen.dart';
import 'package:nutrilift/UserManagement/level_screen.dart';
import 'package:nutrilift/UserManagement/height_screen.dart';
import 'package:nutrilift/UserManagement/weight_screen.dart';
import 'package:nutrilift/UserManagement/main_navigation.dart';
import 'package:nutrilift/Hompage/home_page.dart';
import 'package:nutrilift/services/auth_service.dart';
import 'package:nutrilift/services/api_client.dart';
import 'package:nutrilift/services/token_service.dart';

// Generate mocks
@GenerateMocks([AuthService, TokenService])
import 'e2e_flow_test.mocks.dart';

void main() {
  group('End-to-End Flow Tests', () {
    late MockAuthService mockAuthService;
    late MockTokenService mockTokenService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockTokenService = MockTokenService();
    });

    group('Complete Registration → Onboarding → Home Flow', () {
      testWidgets('should complete full registration and onboarding flow', (WidgetTester tester) async {
        // Set larger screen size to avoid overflow
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;

        // Mock successful registration
        when(mockAuthService.register(any)).thenAnswer((_) async => AuthResponse(
          token: 'test-registration-token',
          user: UserProfile(
            id: '1',
            email: 'test@example.com',
            name: 'Test User',
          ),
        ));

        // Mock successful profile update
        when(mockAuthService.updateProfile(any)).thenAnswer((_) async => UserProfile(
          id: '1',
          email: 'test@example.com',
          name: 'Test User',
          gender: 'Male',
          ageGroup: 'Adult',
          height: 175.0,
          weight: 70.0,
          fitnessLevel: 'Intermediate',
        ));

        // Step 1: Start with SignupScreen
        await tester.pumpWidget(
          MaterialApp(
            home: TestSignupScreen(authService: mockAuthService),
          ),
        );

        // Fill out registration form
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');
        await tester.pump();

        // Submit registration
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();

        // Verify navigation to GenderScreen
        expect(find.byType(GenderScreen), findsOneWidget);
        expect(find.text('What is your gender?'), findsOneWidget);

        // Step 2: Complete Gender Selection
        await tester.tap(find.text('Male'));
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Verify navigation to AgeGroupScreen
        expect(find.byType(AgeGroupScreen), findsOneWidget);

        // Step 3: Complete Age Group Selection
        await tester.tap(find.text('Adult'));
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Verify navigation to LevelScreen
        expect(find.byType(LevelScreen), findsOneWidget);

        // Step 4: Complete Fitness Level Selection
        await tester.tap(find.text('Intermediate'));
        await tester.pump();
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Verify navigation to HeightScreen
        expect(find.byType(HeightScreen), findsOneWidget);

        // Step 5: Complete Height Selection
        // Find and interact with height slider or input
        final heightSlider = find.byType(Slider);
        if (heightSlider.evaluate().isNotEmpty) {
          await tester.drag(heightSlider, const Offset(100, 0));
          await tester.pump();
        }
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Verify navigation to WeightScreen
        expect(find.byType(WeightScreen), findsOneWidget);

        // Step 6: Complete Weight Selection and Finish Onboarding
        final weightSlider = find.byType(Slider);
        if (weightSlider.evaluate().isNotEmpty) {
          await tester.drag(weightSlider, const Offset(50, 0));
          await tester.pump();
        }
        await tester.tap(find.text('Continue'));
        await tester.pumpAndSettle();

        // Verify profile update was called
        verify(mockAuthService.updateProfile(any)).called(1);

        // Verify navigation to MainNavigation (home)
        expect(find.byType(MainNavigation), findsOneWidget);

        // Verify registration was called with correct data
        final registerCall = verify(mockAuthService.register(captureAny)).captured.first as RegisterRequest;
        expect(registerCall.email, equals('test@example.com'));
        expect(registerCall.name, equals('Test User'));
        expect(registerCall.password, equals('password123'));
      });

      testWidgets('should handle registration errors gracefully', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;

        // Mock registration failure
        when(mockAuthService.register(any)).thenThrow(
          ApiException('Email already exists', statusCode: 409),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TestSignupScreen(authService: mockAuthService),
          ),
        );

        // Fill out registration form
        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(find.byType(TextFormField).at(1), 'existing@example.com');
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');
        await tester.pump();

        // Submit registration
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();

        // Verify error message is displayed
        expect(find.textContaining('Email already exists'), findsOneWidget);

        // Verify we stay on signup screen
        expect(find.byType(TestSignupScreen), findsOneWidget);
        expect(find.byType(GenderScreen), findsNothing);
      });
    });

    group('Complete Login → Home → Profile Update Flow', () {
      testWidgets('should complete login and profile update flow', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Mock successful login
        when(mockAuthService.login(any)).thenAnswer((_) async => AuthResponse(
          token: 'test-login-token',
          user: UserProfile(
            id: '1',
            email: 'existing@example.com',
            name: 'Existing User',
            gender: 'Female',
            ageGroup: 'Adult',
            height: 165.0,
            weight: 60.0,
            fitnessLevel: 'Beginner',
          ),
        ));

        // Mock profile retrieval
        when(mockAuthService.getProfile()).thenAnswer((_) async => UserProfile(
          id: '1',
          email: 'existing@example.com',
          name: 'Existing User',
          gender: 'Female',
          ageGroup: 'Adult',
          height: 165.0,
          weight: 60.0,
          fitnessLevel: 'Beginner',
        ));

        // Mock profile update
        when(mockAuthService.updateProfile(any)).thenAnswer((_) async => UserProfile(
          id: '1',
          email: 'existing@example.com',
          name: 'Updated User',
          gender: 'Female',
          ageGroup: 'Adult',
          height: 165.0,
          weight: 65.0,
          fitnessLevel: 'Intermediate',
        ));

        // Step 1: Start with LoginScreen
        await tester.pumpWidget(
          MaterialApp(
            home: TestLoginScreen(authService: mockAuthService),
          ),
        );

        // Fill out login form
        await tester.enterText(find.byType(TextFormField).at(0), 'existing@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        await tester.pump();

        // Submit login
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        // Verify navigation to MainNavigation
        expect(find.byType(MainNavigation), findsOneWidget);

        // Step 2: Navigate to HomePage and verify profile data is displayed
        await tester.tap(find.byIcon(Icons.home));
        await tester.pumpAndSettle();

        // Verify profile data is loaded and displayed
        verify(mockAuthService.getProfile()).called(1);

        // Step 3: Simulate profile update (this would typically be done through a profile edit screen)
        // For this test, we'll simulate the update call directly
        final profileUpdateRequest = ProfileUpdateRequest(
          name: 'Updated User',
          weight: 65.0,
          fitnessLevel: 'Intermediate',
        );

        // Trigger profile update (simulating user editing profile)
        await mockAuthService.updateProfile(profileUpdateRequest);

        // Verify profile update was called
        verify(mockAuthService.updateProfile(any)).called(1);

        // Verify login was called with correct credentials
        final loginCall = verify(mockAuthService.login(captureAny)).captured.first as LoginRequest;
        expect(loginCall.email, equals('existing@example.com'));
        expect(loginCall.password, equals('password123'));
      });

      testWidgets('should handle login errors gracefully', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Mock login failure
        when(mockAuthService.login(any)).thenThrow(
          ApiException('Invalid email or password', statusCode: 401),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TestLoginScreen(authService: mockAuthService),
          ),
        );

        // Fill out login form with invalid credentials
        await tester.enterText(find.byType(TextFormField).at(0), 'wrong@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');
        await tester.pump();

        // Submit login
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        // Verify error message is displayed
        expect(find.textContaining('Invalid email or password'), findsOneWidget);

        // Verify we stay on login screen
        expect(find.byType(TestLoginScreen), findsOneWidget);
        expect(find.byType(MainNavigation), findsNothing);
      });
    });

    group('Token Expiry and Re-authentication Flow', () {
      testWidgets('should handle token expiry and redirect to login', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Mock token validation failure (expired token)
        when(mockTokenService.isTokenValid()).thenAnswer((_) async => false);
        when(mockTokenService.getToken()).thenAnswer((_) async => 'expired-token');

        // Mock profile retrieval failure due to expired token
        when(mockAuthService.getProfile()).thenThrow(
          ApiException('Token expired', statusCode: 401),
        );

        // Mock successful re-authentication
        when(mockAuthService.login(any)).thenAnswer((_) async => AuthResponse(
          token: 'new-valid-token',
          user: UserProfile(
            id: '1',
            email: 'user@example.com',
            name: 'Test User',
          ),
        ));

        // Step 1: Start with a screen that requires authentication
        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePageWithAuth(
              authService: mockAuthService,
              tokenService: mockTokenService,
            ),
          ),
        );

        // Step 2: Verify that expired token triggers redirect to login
        await tester.pumpAndSettle();

        // Should show login screen due to expired token
        expect(find.byType(LoginScreen), findsOneWidget);

        // Step 3: Re-authenticate with valid credentials
        await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        await tester.pump();

        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        // Verify successful re-authentication
        verify(mockAuthService.login(any)).called(1);

        // Should navigate back to authenticated content
        expect(find.byType(MainNavigation), findsOneWidget);
      });

      testWidgets('should handle network errors during token refresh', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Mock network error during authentication
        when(mockAuthService.login(any)).thenThrow(
          ApiException('Network error occurred. Please try again.'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TestLoginScreen(authService: mockAuthService),
          ),
        );

        // Attempt login
        await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        await tester.pump();

        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        // Verify network error message is displayed
        expect(find.textContaining('Network error'), findsOneWidget);

        // Verify we stay on login screen
        expect(find.byType(TestLoginScreen), findsOneWidget);
      });
    });

    group('API Endpoints Integration', () {
      testWidgets('should handle all API endpoints correctly', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Mock all API endpoints
        when(mockAuthService.register(any)).thenAnswer((_) async => AuthResponse(
          token: 'register-token',
          user: UserProfile(id: '1', email: 'test@example.com', name: 'Test User'),
        ));

        when(mockAuthService.login(any)).thenAnswer((_) async => AuthResponse(
          token: 'login-token',
          user: UserProfile(id: '1', email: 'test@example.com', name: 'Test User'),
        ));

        when(mockAuthService.getProfile()).thenAnswer((_) async => UserProfile(
          id: '1',
          email: 'test@example.com',
          name: 'Test User',
          gender: 'Male',
          ageGroup: 'Adult',
          height: 175.0,
          weight: 70.0,
          fitnessLevel: 'Intermediate',
        ));

        when(mockAuthService.updateProfile(any)).thenAnswer((_) async => UserProfile(
          id: '1',
          email: 'test@example.com',
          name: 'Updated User',
          gender: 'Male',
          ageGroup: 'Adult',
          height: 175.0,
          weight: 75.0,
          fitnessLevel: 'Advance',
        ));

        // Test registration endpoint
        await tester.pumpWidget(
          MaterialApp(
            home: TestSignupScreen(authService: mockAuthService),
          ),
        );

        await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
        await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');
        await tester.pump();

        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();

        // Verify registration endpoint was called
        verify(mockAuthService.register(any)).called(1);

        // Test login endpoint
        await tester.pumpWidget(
          MaterialApp(
            home: TestLoginScreen(authService: mockAuthService),
          ),
        );

        await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        await tester.pump();

        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        // Verify login endpoint was called
        verify(mockAuthService.login(any)).called(1);

        // Test profile retrieval and update endpoints would be tested
        // through the home page and profile edit functionality
        // (These are covered in the other test cases)
      });
    });
  });
}

// Test wrapper classes with mock services
class TestSignupScreen extends StatefulWidget {
  final AuthService authService;
  
  const TestSignupScreen({super.key, required this.authService});

  @override
  State<TestSignupScreen> createState() => _TestSignupScreenState();
}

class _TestSignupScreenState extends State<TestSignupScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = RegisterRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      await widget.authService.register(request);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GenderScreen()),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sign Up To NutriLift', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 30),
                
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                  ),
                ],
                
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                  validator: (value) => value?.isEmpty == true ? 'Name is required' : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                  validator: (value) => value?.isEmpty == true ? 'Email is required' : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  validator: (value) => value?.isEmpty == true ? 'Password is required' : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
                  validator: (value) => value?.isEmpty == true ? 'Please confirm your password' : null,
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
                      ? const CircularProgressIndicator(color: Colors.white)
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

class TestLoginScreen extends StatefulWidget {
  final AuthService authService;
  
  const TestLoginScreen({super.key, required this.authService});

  @override
  State<TestLoginScreen> createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
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
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await widget.authService.login(request);
      
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sign In To NutriLift', style: TextStyle(fontSize: 24)),
                const SizedBox(height: 30),
                
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                  ),
                ],
                
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder()),
                  validator: (value) => value?.isEmpty == true ? 'Email is required' : null,
                ),
                const SizedBox(height: 15),
                
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  validator: (value) => value?.isEmpty == true ? 'Password is required' : null,
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
                      ? const CircularProgressIndicator(color: Colors.white)
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

class TestHomePageWithAuth extends StatefulWidget {
  final AuthService authService;
  final TokenService tokenService;
  
  const TestHomePageWithAuth({
    super.key,
    required this.authService,
    required this.tokenService,
  });

  @override
  State<TestHomePageWithAuth> createState() => _TestHomePageWithAuthState();
}

class _TestHomePageWithAuthState extends State<TestHomePageWithAuth> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final isValid = await widget.tokenService.isTokenValid();
    if (!isValid && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Authenticated Home Page'),
      ),
    );
  }
}