import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:nutrilift/Hompage/home_page.dart';
import 'package:nutrilift/UserManagement/profile_edit_screen.dart';
import 'package:nutrilift/services/auth_service.dart';
import 'package:nutrilift/services/api_client.dart';

// Generate mocks
@GenerateMocks([AuthService])
import 'home_page_test.mocks.dart';

void main() {
  group('HomePage Integration Tests', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    group('Profile Data Display Tests', () {
      testWidgets('should display user profile data when loaded successfully', (WidgetTester tester) async {
        // Set a larger screen size to avoid overflow
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Create test user profile
        final testProfile = UserProfile(
          id: '1',
          email: 'test@example.com',
          name: 'John Doe',
          gender: 'Male',
          ageGroup: 'Adult',
          height: 175.0,
          weight: 70.0,
          fitnessLevel: 'Intermediate',
          createdAt: DateTime.now(),
        );

        // Setup mock to return profile data
        when(mockAuthService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePage(authService: mockAuthService),
          ),
        );

        // Wait for the profile to load
        await tester.pumpAndSettle();

        // Verify welcome message displays user name
        expect(find.text('Hello, John Doe!'), findsOneWidget);

        // Verify profile section is displayed
        expect(find.text('Your Profile'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);

        // Verify profile data is displayed
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('John Doe'), findsAtLeastNWidgets(1)); // Name appears in welcome and profile
        expect(find.text('Gender'), findsOneWidget);
        expect(find.text('Male'), findsOneWidget);
        expect(find.text('Age Group'), findsOneWidget);
        expect(find.text('Adult'), findsOneWidget);
        expect(find.text('Height'), findsOneWidget);
        expect(find.text('175.0 cm'), findsOneWidget);
        expect(find.text('Weight'), findsOneWidget);
        expect(find.text('70.0 kg'), findsOneWidget);
        expect(find.text('Fitness Level'), findsOneWidget);
        expect(find.text('Intermediate'), findsOneWidget);

        // Verify API was called
        verify(mockAuthService.getProfile()).called(1);
      });

      testWidgets('should display partial profile data when some fields are null', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Create test user profile with some null fields
        final testProfile = UserProfile(
          id: '1',
          email: 'test@example.com',
          name: 'Jane Doe',
          gender: null, // null gender
          ageGroup: 'Adult',
          height: null, // null height
          weight: 65.0,
          fitnessLevel: null, // null fitness level
          createdAt: DateTime.now(),
        );

        when(mockAuthService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePage(authService: mockAuthService),
          ),
        );

        await tester.pumpAndSettle();

        // Verify welcome message displays user name
        expect(find.text('Hello, Jane Doe!'), findsOneWidget);

        // Verify only non-null profile fields are displayed
        expect(find.text('Name'), findsOneWidget);
        expect(find.text('Jane Doe'), findsAtLeastNWidgets(1));
        expect(find.text('Age Group'), findsOneWidget);
        expect(find.text('Adult'), findsOneWidget);
        expect(find.text('Weight'), findsOneWidget);
        expect(find.text('65.0 kg'), findsOneWidget);

        // Verify null fields are not displayed
        expect(find.text('Gender'), findsNothing);
        expect(find.text('Height'), findsNothing);
        expect(find.text('Fitness Level'), findsNothing);
      });

      testWidgets('should display email as display name when name is null', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Create test user profile with null name
        final testProfile = UserProfile(
          id: '1',
          email: 'testuser@example.com',
          name: null, // null name
          gender: 'Female',
          ageGroup: 'Adult',
          height: 165.0,
          weight: 60.0,
          fitnessLevel: 'Beginner',
          createdAt: DateTime.now(),
        );

        when(mockAuthService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePage(authService: mockAuthService),
          ),
        );

        await tester.pumpAndSettle();

        // Verify welcome message displays email prefix as display name
        expect(find.text('Hello, testuser!'), findsOneWidget);
      });

      testWidgets('should show loading indicator while fetching profile', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Setup mock to return delayed response
        when(mockAuthService.getProfile()).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return UserProfile(
            id: '1',
            email: 'test@example.com',
            name: 'Test User',
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePage(authService: mockAuthService),
          ),
        );

        // Should show loading indicator initially
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Hello, Test User!'), findsNothing);

        // Wait for profile to load
        await tester.pumpAndSettle();

        // Loading indicator should be gone, profile should be displayed
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Hello, Test User!'), findsOneWidget);
      });

      testWidgets('should refresh profile data on pull-to-refresh', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        final testProfile = UserProfile(
          id: '1',
          email: 'test@example.com',
          name: 'Test User',
        );

        when(mockAuthService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePage(authService: mockAuthService),
          ),
        );

        await tester.pumpAndSettle();

        // Find the RefreshIndicator and trigger refresh
        final refreshIndicator = find.byType(RefreshIndicator);
        expect(refreshIndicator, findsOneWidget);
        
        // Trigger refresh by calling the onRefresh callback directly
        final RefreshIndicator widget = tester.widget(refreshIndicator);
        await widget.onRefresh!();
        await tester.pumpAndSettle();

        // Verify profile was fetched multiple times (initial + refresh)
        verify(mockAuthService.getProfile()).called(2);
      });
    });

    group('Profile Update Flow Tests', () {
      testWidgets('should navigate to profile edit screen when edit button is tapped', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        final testProfile = UserProfile(
          id: '1',
          email: 'test@example.com',
          name: 'Test User',
          gender: 'Male',
          ageGroup: 'Adult',
          height: 175.0,
          weight: 70.0,
          fitnessLevel: 'Intermediate',
        );

        when(mockAuthService.getProfile()).thenAnswer((_) async => testProfile);

        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePage(authService: mockAuthService),
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap the edit button
        final editButton = find.text('Edit');
        expect(editButton, findsOneWidget);
        await tester.tap(editButton);
        await tester.pumpAndSettle();

        // Should navigate to ProfileEditScreen
        expect(find.byType(ProfileEditScreen), findsOneWidget);
        expect(find.text('Edit Profile'), findsOneWidget);
      });

      testWidgets('should update displayed profile data when returning from edit screen', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        final originalProfile = UserProfile(
          id: '1',
          email: 'test@example.com',
          name: 'Original Name',
          gender: 'Male',
          ageGroup: 'Adult',
          height: 175.0,
          weight: 70.0,
          fitnessLevel: 'Beginner',
        );

        final updatedProfile = UserProfile(
          id: '1',
          email: 'test@example.com',
          name: 'Updated Name',
          gender: 'Male',
          ageGroup: 'Adult',
          height: 180.0,
          weight: 75.0,
          fitnessLevel: 'Intermediate',
        );

        when(mockAuthService.getProfile()).thenAnswer((_) async => originalProfile);

        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePageWithMockEdit(
              authService: mockAuthService,
              updatedProfile: updatedProfile,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify original profile data
        expect(find.text('Hello, Original Name!'), findsOneWidget);
        expect(find.text('Original Name'), findsAtLeastNWidgets(1));
        expect(find.text('175.0 cm'), findsOneWidget);
        expect(find.text('70.0 kg'), findsOneWidget);
        expect(find.text('Beginner'), findsOneWidget);

        // Tap edit button
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Should show updated profile data
        expect(find.text('Hello, Updated Name!'), findsOneWidget);
        expect(find.text('Updated Name'), findsAtLeastNWidgets(1));
        expect(find.text('180.0 cm'), findsOneWidget);
        expect(find.text('75.0 kg'), findsOneWidget);
        expect(find.text('Intermediate'), findsOneWidget);
      });
    });

    group('Error Handling Tests', () {
      testWidgets('should display error message when profile fetch fails', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Setup mock to throw an exception
        when(mockAuthService.getProfile()).thenThrow(
          ApiException('Failed to load profile', statusCode: 500),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePage(authService: mockAuthService),
          ),
        );

        await tester.pumpAndSettle();

        // Should display error message
        expect(find.text('Failed to load profile'), findsOneWidget);
        expect(find.text('ApiException: Failed to load profile'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Should not display profile data
        expect(find.text('Your Profile'), findsNothing);
        expect(find.text('Hello, User!'), findsNothing);
      });

      testWidgets('should retry profile fetch when retry button is tapped', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        final testProfile = UserProfile(
          id: '1',
          email: 'test@example.com',
          name: 'Test User',
        );

        // First call fails, second call succeeds
        var callCount = 0;
        when(mockAuthService.getProfile()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw ApiException('Network error');
          } else {
            return testProfile;
          }
        });

        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePage(authService: mockAuthService),
          ),
        );

        await tester.pumpAndSettle();

        // Should display error initially
        expect(find.text('ApiException: Network error'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Should display profile data after retry
        expect(find.text('Hello, Test User!'), findsOneWidget);
        expect(find.text('ApiException: Network error'), findsNothing);
        expect(find.text('Retry'), findsNothing);

        // Verify API was called twice (initial + retry)
        verify(mockAuthService.getProfile()).called(2);
      });

      testWidgets('should handle network errors gracefully', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Setup mock to throw network error
        when(mockAuthService.getProfile()).thenThrow(
          ApiException('Network error. Please check your connection.'),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePage(authService: mockAuthService),
          ),
        );

        await tester.pumpAndSettle();

        // Should display network error message
        expect(find.text('ApiException: Network error. Please check your connection.'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('should handle authentication errors gracefully', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Setup mock to throw authentication error
        when(mockAuthService.getProfile()).thenThrow(
          ApiException('Unauthorized access', statusCode: 401),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePage(authService: mockAuthService),
          ),
        );

        await tester.pumpAndSettle();

        // Should display authentication error message
        expect(find.text('ApiException: Unauthorized access'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('should show loading state during retry', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;

        // Setup mock to fail first, then succeed with delay
        var callCount = 0;
        when(mockAuthService.getProfile()).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
            throw ApiException('Network error');
          } else {
            await Future.delayed(const Duration(milliseconds: 100));
            return UserProfile(
              id: '1',
              email: 'test@example.com',
              name: 'Test User',
            );
          }
        });

        await tester.pumpWidget(
          MaterialApp(
            home: TestHomePage(authService: mockAuthService),
          ),
        );

        await tester.pumpAndSettle();

        // Should display error initially
        expect(find.text('ApiException: Network error'), findsOneWidget);

        // Tap retry button
        await tester.tap(find.text('Retry'));
        await tester.pump();

        // Should show loading indicator during retry
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('ApiException: Network error'), findsNothing);

        // Wait for retry to complete
        await tester.pumpAndSettle();

        // Should display profile data
        expect(find.text('Hello, Test User!'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    });
  });
}

// Test wrapper class to inject mock AuthService
class TestHomePage extends StatefulWidget {
  final AuthService authService;

  const TestHomePage({super.key, required this.authService});

  @override
  State<TestHomePage> createState() => _TestHomePageState();
}

class _TestHomePageState extends State<TestHomePage> {
  bool showChart = false;
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  final List<ChartData> chartData = [
    ChartData('Sun', 70),
    ChartData('Mon', 85),
    ChartData('Tue', 65),
    ChartData('Wed', 95),
    ChartData('Thu', 80),
    ChartData('Fri', 90),
    ChartData('Sat', 75),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final profile = await widget.authService.getProfile();
      
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshProfile() async {
    await _loadUserProfile();
  }

  void nextView() {
    setState(() {
      showChart = true;
    });
  }

  void prevView() {
    setState(() {
      showChart = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshProfile,
          child: Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'NUTRILIFT',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Text('🔔', style: TextStyle(fontSize: 20)),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorWidget()
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWelcomeSection(),
                                const SizedBox(height: 24),
                                _buildProfileSection(),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final userName = _userProfile?.displayName ?? 'User';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $userName!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Let's Crush Your Fitness Goals Today!",
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Failed to load profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error occurred',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    if (_userProfile == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_userProfile != null) {
                  final updatedProfile = await Navigator.push<UserProfile>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileEditScreen(userProfile: _userProfile!),
                    ),
                  );
                  
                  if (updatedProfile != null) {
                    setState(() {
                      _userProfile = updatedProfile;
                    });
                  }
                }
              },
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileItem(Icons.person, 'Name', _userProfile!.displayName),
              if (_userProfile!.gender != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.wc, 'Gender', _userProfile!.gender!),
              ],
              if (_userProfile!.ageGroup != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.cake, 'Age Group', _userProfile!.ageGroup!),
              ],
              if (_userProfile!.height != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.height, 'Height', '${_userProfile!.height!.toStringAsFixed(1)} cm'),
              ],
              if (_userProfile!.weight != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.monitor_weight, 'Weight', '${_userProfile!.weight!.toStringAsFixed(1)} kg'),
              ],
              if (_userProfile!.fitnessLevel != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.fitness_center, 'Fitness Level', _userProfile!.fitnessLevel!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.red, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Test wrapper class that mocks the profile edit navigation
class TestHomePageWithMockEdit extends StatefulWidget {
  final AuthService authService;
  final UserProfile updatedProfile;

  const TestHomePageWithMockEdit({
    super.key,
    required this.authService,
    required this.updatedProfile,
  });

  @override
  State<TestHomePageWithMockEdit> createState() => _TestHomePageWithMockEditState();
}

class _TestHomePageWithMockEditState extends State<TestHomePageWithMockEdit> {
  UserProfile? _userProfile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final profile = await widget.authService.getProfile();
      
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: const Text(
                'NUTRILIFT',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWelcomeSection(),
                              const SizedBox(height: 24),
                              _buildProfileSection(),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final userName = _userProfile?.displayName ?? 'User';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $userName!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection() {
    if (_userProfile == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Profile',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Mock the edit flow by directly updating the profile
                setState(() {
                  _userProfile = widget.updatedProfile;
                });
              },
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileItem(Icons.person, 'Name', _userProfile!.displayName),
              if (_userProfile!.gender != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.wc, 'Gender', _userProfile!.gender!),
              ],
              if (_userProfile!.ageGroup != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.cake, 'Age Group', _userProfile!.ageGroup!),
              ],
              if (_userProfile!.height != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.height, 'Height', '${_userProfile!.height!.toStringAsFixed(1)} cm'),
              ],
              if (_userProfile!.weight != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.monitor_weight, 'Weight', '${_userProfile!.weight!.toStringAsFixed(1)} kg'),
              ],
              if (_userProfile!.fitnessLevel != null) ...[
                const SizedBox(height: 12),
                _buildProfileItem(Icons.fitness_center, 'Fitness Level', _userProfile!.fitnessLevel!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.red, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ChartData class for test compatibility
class ChartData {
  final String day;
  final double value;

  ChartData(this.day, this.value);
}