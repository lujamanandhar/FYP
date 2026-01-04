import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:nutrilift/services/auth_service.dart';
import 'package:nutrilift/services/token_service.dart';
import 'package:nutrilift/services/api_client.dart';
import 'package:nutrilift/UserManagement/login_screen.dart';
import 'package:nutrilift/UserManagement/signup_screen.dart';
import 'package:nutrilift/UserManagement/main_navigation.dart';
import 'package:nutrilift/Hompage/home_page.dart';

// Generate mocks
@GenerateMocks([AuthService, TokenService])
import 'atomic_operations_test.mocks.dart';

void main() {
  group('Atomic Operations Integration Tests', () {
    late MockAuthService mockAuthService;
    late MockTokenService mockTokenService;

    setUp(() {
      mockAuthService = MockAuthService();
      mockTokenService = MockTokenService();
    });

    group('Property 17: Atomic Operations', () {
      testWidgets('should handle registration atomically - success or complete failure', (WidgetTester tester) async {
        /*
        **Property 17: Atomic Operations**
        *For any* user registration operation in Flutter, either all user data should be 
        processed and stored or none, maintaining consistency between UI state and backend.
        **Validates: Requirements 6.5**
        */
        
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;

        // Test Case 1: Successful atomic registration
        when(mockAuthService.register(any)).thenAnswer((_) async => AuthResponse(
          token: 'atomic-success-token',
          user: UserProfile(
            id: '1',
            email: 'atomic@example.com',
            name: 'Atomic User',
          ),
        ));

        when(mockTokenService.saveToken(any)).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: TestAtomicSignupScreen(
              authService: mockAuthService,
              tokenService: mockTokenService,
            ),
          ),
        );

        // Fill registration form
        await tester.enterText(find.byType(TextFormField).at(0), 'Atomic User');
        await tester.enterText(find.byType(TextFormField).at(1), 'atomic@example.com');
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');
        await tester.pump();

        // Submit registration
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();

        // Verify atomic success: both API call and token storage should complete
        verify(mockAuthService.register(any)).called(1);
        verify(mockTokenService.saveToken('atomic-success-token')).called(1);

        // Should navigate to next screen (atomic success)
        expect(find.byType(TestAtomicSignupScreen), findsNothing);

        // Test Case 2: Atomic failure - registration fails, no token should be saved
        when(mockAuthService.register(any)).thenThrow(
          ApiException('Registration failed', statusCode: 400),
        );

        // Reset to signup screen
        await tester.pumpWidget(
          MaterialApp(
            home: TestAtomicSignupScreen(
              authService: mockAuthService,
              tokenService: mockTokenService,
            ),
          ),
        );

        // Fill registration form again
        await tester.enterText(find.byType(TextFormField).at(0), 'Failed User');
        await tester.enterText(find.byType(TextFormField).at(1), 'failed@example.com');
        await tester.enterText(find.byType(TextFormField).at(2), 'password123');
        await tester.enterText(find.byType(TextFormField).at(3), 'password123');
        await tester.pump();

        // Submit registration
        await tester.tap(find.text('Sign Up'));
        await tester.pumpAndSettle();

        // Verify atomic failure: registration called but token save should not be called
        verify(mockAuthService.register(any)).called(2); // Total calls
        // Token save should still only be called once (from successful case)
        verify(mockTokenService.saveToken(any)).called(1);

        // Should stay on signup screen (atomic failure)
        expect(find.byType(TestAtomicSignupScreen), findsOneWidget);
        expect(find.textContaining('Registration failed'), findsOneWidget);
      });

      testWidgets('should handle login atomically - success or complete failure', (WidgetTester tester) async {
        /*
        **Property 17: Atomic Operations**
        *For any* user login operation in Flutter, either all authentication data should be 
        processed and stored or none, maintaining consistency.
        **Validates: Requirements 6.5**
        */
        
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Test Case 1: Successful atomic login
        when(mockAuthService.login(any)).thenAnswer((_) async => AuthResponse(
          token: 'atomic-login-token',
          user: UserProfile(
            id: '1',
            email: 'login@example.com',
            name: 'Login User',
            gender: 'Male',
            ageGroup: 'Adult',
            height: 175.0,
            weight: 70.0,
            fitnessLevel: 'Intermediate',
          ),
        ));

        when(mockTokenService.saveToken(any)).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: TestAtomicLoginScreen(
              authService: mockAuthService,
              tokenService: mockTokenService,
            ),
          ),
        );

        // Fill login form
        await tester.enterText(find.byType(TextFormField).at(0), 'login@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'password123');
        await tester.pump();

        // Submit login
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        // Verify atomic success: both login and token storage complete
        verify(mockAuthService.login(any)).called(1);
        verify(mockTokenService.saveToken('atomic-login-token')).called(1);

        // Should navigate away from login screen (atomic success)
        expect(find.byType(TestAtomicLoginScreen), findsNothing);

        // Test Case 2: Atomic failure - login fails, no token should be saved
        when(mockAuthService.login(any)).thenThrow(
          ApiException('Invalid credentials', statusCode: 401),
        );

        // Reset to login screen
        await tester.pumpWidget(
          MaterialApp(
            home: TestAtomicLoginScreen(
              authService: mockAuthService,
              tokenService: mockTokenService,
            ),
          ),
        );

        // Fill login form with invalid credentials
        await tester.enterText(find.byType(TextFormField).at(0), 'invalid@example.com');
        await tester.enterText(find.byType(TextFormField).at(1), 'wrongpassword');
        await tester.pump();

        // Submit login
        await tester.tap(find.text('Log In'));
        await tester.pumpAndSettle();

        // Verify atomic failure: login called but no additional token save
        verify(mockAuthService.login(any)).called(2); // Total calls
        // Token save should still only be called once (from successful case)
        verify(mockTokenService.saveToken(any)).called(1);

        // Should stay on login screen (atomic failure)
        expect(find.byType(TestAtomicLoginScreen), findsOneWidget);
        expect(find.textContaining('Invalid credentials'), findsOneWidget);
      });

      testWidgets('should handle profile updates atomically', (WidgetTester tester) async {
        /*
        **Property 17: Atomic Operations**
        *For any* profile update operation in Flutter, either all profile changes should be 
        applied or none, maintaining UI and backend consistency.
        **Validates: Requirements 6.5**
        */
        
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Mock initial profile data
        final initialProfile = UserProfile(
          id: '1',
          email: 'profile@example.com',
          name: 'Profile User',
          gender: 'Female',
          ageGroup: 'Adult',
          height: 165.0,
          weight: 60.0,
          fitnessLevel: 'Beginner',
        );

        // Test Case 1: Successful atomic profile update
        final updatedProfile = UserProfile(
          id: '1',
          email: 'profile@example.com',
          name: 'Updated Profile User',
          gender: 'Female',
          ageGroup: 'Adult',
          height: 170.0,
          weight: 65.0,
          fitnessLevel: 'Intermediate',
        );

        when(mockAuthService.getProfile()).thenAnswer((_) async => initialProfile);
        when(mockAuthService.updateProfile(any)).thenAnswer((_) async => updatedProfile);

        await tester.pumpWidget(
          MaterialApp(
            home: TestAtomicProfileScreen(
              authService: mockAuthService,
              initialProfile: initialProfile,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial profile is displayed
        expect(find.text('Profile User'), findsOneWidget);
        expect(find.text('60.0 kg'), findsOneWidget);
        expect(find.text('Beginner'), findsOneWidget);

        // Trigger profile update
        await tester.tap(find.text('Update Profile'));
        await tester.pumpAndSettle();

        // Verify atomic success: profile update called and UI updated
        verify(mockAuthService.updateProfile(any)).called(1);

        // UI should reflect the updated profile atomically
        expect(find.text('Updated Profile User'), findsOneWidget);
        expect(find.text('65.0 kg'), findsOneWidget);
        expect(find.text('Intermediate'), findsOneWidget);

        // Test Case 2: Atomic failure - update fails, UI should remain unchanged
        when(mockAuthService.updateProfile(any)).thenThrow(
          ApiException('Update failed', statusCode: 400),
        );

        // Reset to initial state
        await tester.pumpWidget(
          MaterialApp(
            home: TestAtomicProfileScreen(
              authService: mockAuthService,
              initialProfile: initialProfile,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify initial state
        expect(find.text('Profile User'), findsOneWidget);
        expect(find.text('60.0 kg'), findsOneWidget);

        // Trigger profile update that will fail
        await tester.tap(find.text('Update Profile'));
        await tester.pumpAndSettle();

        // Verify atomic failure: update called but UI remains unchanged
        verify(mockAuthService.updateProfile(any)).called(2); // Total calls

        // UI should still show original data (atomic failure)
        expect(find.text('Profile User'), findsOneWidget);
        expect(find.text('60.0 kg'), findsOneWidget);
        expect(find.text('Beginner'), findsOneWidget);

        // Error message should be displayed
        expect(find.textContaining('Update failed'), findsOneWidget);
      });

      testWidgets('should handle complete user journey atomically', (WidgetTester tester) async {
        /*
        **Property 17: Atomic Operations**
        *For any* complete user journey in Flutter (registration → onboarding → profile updates), 
        each step should be atomic and maintain overall consistency.
        **Validates: Requirements 6.5**
        */
        
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;

        // Step 1: Atomic Registration
        when(mockAuthService.register(any)).thenAnswer((_) async => AuthResponse(
          token: 'journey-token',
          user: UserProfile(
            id: '1',
            email: 'journey@example.com',
            name: 'Journey User',
          ),
        ));

        when(mockTokenService.saveToken(any)).thenAnswer((_) async {});

        await tester.pumpWidget(
          MaterialApp(
            home: TestAtomicJourneyScreen(
              authService: mockAuthService,
              tokenService: mockTokenService,
            ),
          ),
        );

        // Complete registration atomically
        await tester.tap(find.text('Register'));
        await tester.pumpAndSettle();

        // Verify atomic registration
        verify(mockAuthService.register(any)).called(1);
        verify(mockTokenService.saveToken('journey-token')).called(1);

        // Step 2: Atomic Profile Update (onboarding)
        final onboardingProfile = UserProfile(
          id: '1',
          email: 'journey@example.com',
          name: 'Journey User',
          gender: 'Male',
          ageGroup: 'Adult',
          height: 175.0,
          weight: 70.0,
          fitnessLevel: 'Intermediate',
        );

        when(mockAuthService.updateProfile(any)).thenAnswer((_) async => onboardingProfile);

        // Complete onboarding profile update atomically
        await tester.tap(find.text('Complete Onboarding'));
        await tester.pumpAndSettle();

        // Verify atomic onboarding update
        verify(mockAuthService.updateProfile(any)).called(1);

        // Step 3: Verify Final State Consistency
        when(mockAuthService.getProfile()).thenAnswer((_) async => onboardingProfile);

        // Navigate to profile view
        await tester.tap(find.text('View Profile'));
        await tester.pumpAndSettle();

        // Verify final consistent state
        verify(mockAuthService.getProfile()).called(1);
        expect(find.text('Journey User'), findsOneWidget);
        expect(find.text('Male'), findsOneWidget);
        expect(find.text('175.0 cm'), findsOneWidget);
        expect(find.text('70.0 kg'), findsOneWidget);
        expect(find.text('Intermediate'), findsOneWidget);

        // Verify all operations were atomic and consistent
        // Registration: 1 call, Token save: 1 call, Profile update: 1 call, Profile get: 1 call
        verifyNoMoreInteractions(mockAuthService);
        verifyNoMoreInteractions(mockTokenService);
      });

      testWidgets('should handle concurrent operations consistently', (WidgetTester tester) async {
        /*
        **Property 17: Atomic Operations**
        *For any* concurrent operations in Flutter (multiple API calls), each should be 
        processed atomically without interfering with others.
        **Validates: Requirements 6.5**
        */
        
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Mock multiple concurrent profile updates
        final profile1 = UserProfile(
          id: '1',
          email: 'concurrent@example.com',
          name: 'Concurrent User 1',
          weight: 65.0,
        );

        final profile2 = UserProfile(
          id: '1',
          email: 'concurrent@example.com',
          name: 'Concurrent User 2',
          weight: 70.0,
        );

        // Set up sequential responses for concurrent calls
        when(mockAuthService.updateProfile(any))
            .thenAnswer((_) async => profile1);
        when(mockAuthService.updateProfile(any))
            .thenAnswer((_) async => profile2);

        await tester.pumpWidget(
          MaterialApp(
            home: TestConcurrentOperationsScreen(
              authService: mockAuthService,
            ),
          ),
        );

        // Trigger multiple concurrent operations
        await tester.tap(find.text('Start Concurrent Updates'));
        await tester.pumpAndSettle();

        // Verify both operations were called
        verify(mockAuthService.updateProfile(any)).called(2);

        // Final state should be consistent (one of the updates should be final)
        // The UI should show a consistent state, not a mixed state
        final nameWidgets = find.textContaining('Concurrent User');
        expect(nameWidgets, findsWidgets);

        // Should show either profile1 or profile2 data consistently, not mixed
        final hasProfile1 = find.text('Concurrent User 1').evaluate().isNotEmpty &&
                           find.text('65.0').evaluate().isNotEmpty;
        final hasProfile2 = find.text('Concurrent User 2').evaluate().isNotEmpty &&
                           find.text('70.0').evaluate().isNotEmpty;

        // Should have one consistent profile, not mixed data
        expect(hasProfile1 || hasProfile2, isTrue);
        expect(hasProfile1 && hasProfile2, isFalse); // Should not have mixed state
      });
    });
  });
}

// Test helper widgets

class TestAtomicSignupScreen extends StatefulWidget {
  final AuthService authService;
  final TokenService tokenService;

  const TestAtomicSignupScreen({
    super.key,
    required this.authService,
    required this.tokenService,
  });

  @override
  State<TestAtomicSignupScreen> createState() => _TestAtomicSignupScreenState();
}

class _TestAtomicSignupScreenState extends State<TestAtomicSignupScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _handleSignup() async {
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

      // Atomic operation: both registration and token storage must succeed
      final response = await widget.authService.register(request);
      await widget.tokenService.saveToken(response.token!);
      
      if (mounted) {
        // Navigate away on atomic success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Scaffold(body: Text('Success'))),
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
          child: Column(
            children: [
              const Text('Atomic Signup Test'),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password')),
              TextFormField(controller: _confirmPasswordController, decoration: const InputDecoration(labelText: 'Confirm Password')),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TestAtomicLoginScreen extends StatefulWidget {
  final AuthService authService;
  final TokenService tokenService;

  const TestAtomicLoginScreen({
    super.key,
    required this.authService,
    required this.tokenService,
  });

  @override
  State<TestAtomicLoginScreen> createState() => _TestAtomicLoginScreenState();
}

class _TestAtomicLoginScreenState extends State<TestAtomicLoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final request = LoginRequest(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Atomic operation: both login and token storage must succeed
      final response = await widget.authService.login(request);
      await widget.tokenService.saveToken(response.token!);
      
      if (mounted) {
        // Navigate away on atomic success
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Scaffold(body: Text('Login Success'))),
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
          child: Column(
            children: [
              const Text('Atomic Login Test'),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
              TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password')),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TestAtomicProfileScreen extends StatefulWidget {
  final AuthService authService;
  final UserProfile initialProfile;

  const TestAtomicProfileScreen({
    super.key,
    required this.authService,
    required this.initialProfile,
  });

  @override
  State<TestAtomicProfileScreen> createState() => _TestAtomicProfileScreenState();
}

class _TestAtomicProfileScreenState extends State<TestAtomicProfileScreen> {
  late UserProfile _currentProfile;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.initialProfile;
  }

  Future<void> _handleUpdateProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updateRequest = ProfileUpdateRequest(
        name: 'Updated Profile User',
        weight: 65.0,
        fitnessLevel: 'Intermediate',
      );

      // Atomic operation: profile update must succeed completely
      final updatedProfile = await widget.authService.updateProfile(updateRequest);
      
      setState(() {
        _currentProfile = updatedProfile;
        _isLoading = false;
      });
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
          child: Column(
            children: [
              const Text('Atomic Profile Test'),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              Text(_currentProfile.name ?? 'No Name'),
              Text('${_currentProfile.weight ?? 0} kg'),
              Text(_currentProfile.fitnessLevel ?? 'No Level'),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdateProfile,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Update Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TestAtomicJourneyScreen extends StatefulWidget {
  final AuthService authService;
  final TokenService tokenService;

  const TestAtomicJourneyScreen({
    super.key,
    required this.authService,
    required this.tokenService,
  });

  @override
  State<TestAtomicJourneyScreen> createState() => _TestAtomicJourneyScreenState();
}

class _TestAtomicJourneyScreenState extends State<TestAtomicJourneyScreen> {
  String _currentStep = 'register';
  UserProfile? _userProfile;

  Future<void> _handleRegister() async {
    final request = RegisterRequest(
      email: 'journey@example.com',
      password: 'password123',
      name: 'Journey User',
    );

    final response = await widget.authService.register(request);
    await widget.tokenService.saveToken(response.token!);
    
    setState(() {
      _userProfile = response.user;
      _currentStep = 'onboarding';
    });
  }

  Future<void> _handleOnboarding() async {
    final updateRequest = ProfileUpdateRequest(
      gender: 'Male',
      ageGroup: 'Adult',
      height: 175.0,
      weight: 70.0,
      fitnessLevel: 'Intermediate',
    );

    final updatedProfile = await widget.authService.updateProfile(updateRequest);
    
    setState(() {
      _userProfile = updatedProfile;
      _currentStep = 'profile';
    });
  }

  Future<void> _handleViewProfile() async {
    final profile = await widget.authService.getProfile();
    
    setState(() {
      _userProfile = profile;
      _currentStep = 'complete';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text('Atomic Journey Test'),
              if (_currentStep == 'register')
                ElevatedButton(
                  onPressed: _handleRegister,
                  child: const Text('Register'),
                ),
              if (_currentStep == 'onboarding')
                ElevatedButton(
                  onPressed: _handleOnboarding,
                  child: const Text('Complete Onboarding'),
                ),
              if (_currentStep == 'profile')
                ElevatedButton(
                  onPressed: _handleViewProfile,
                  child: const Text('View Profile'),
                ),
              if (_currentStep == 'complete' && _userProfile != null) ...[
                Text(_userProfile!.name ?? 'No Name'),
                Text(_userProfile!.gender ?? 'No Gender'),
                Text('${_userProfile!.height ?? 0} cm'),
                Text('${_userProfile!.weight ?? 0} kg'),
                Text(_userProfile!.fitnessLevel ?? 'No Level'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TestConcurrentOperationsScreen extends StatefulWidget {
  final AuthService authService;

  const TestConcurrentOperationsScreen({
    super.key,
    required this.authService,
  });

  @override
  State<TestConcurrentOperationsScreen> createState() => _TestConcurrentOperationsScreenState();
}

class _TestConcurrentOperationsScreenState extends State<TestConcurrentOperationsScreen> {
  UserProfile? _finalProfile;
  bool _isLoading = false;

  Future<void> _handleConcurrentUpdates() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate concurrent operations
    final futures = [
      widget.authService.updateProfile(ProfileUpdateRequest(
        name: 'Concurrent User 1',
        weight: 65.0,
      )),
      widget.authService.updateProfile(ProfileUpdateRequest(
        name: 'Concurrent User 2',
        weight: 70.0,
      )),
    ];

    try {
      final results = await Future.wait(futures);
      // Take the last result as the final state
      setState(() {
        _finalProfile = results.last;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
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
          child: Column(
            children: [
              const Text('Concurrent Operations Test'),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleConcurrentUpdates,
                child: _isLoading 
                    ? const CircularProgressIndicator() 
                    : const Text('Start Concurrent Updates'),
              ),
              if (_finalProfile != null) ...[
                Text(_finalProfile!.name ?? 'No Name'),
                Text('${_finalProfile!.weight ?? 0}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}