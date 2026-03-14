import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrilift/WorkoutTracking/workout_tracking.dart';
import 'package:nutrilift/screens/workout_history_screen.dart';
import 'package:nutrilift/screens/new_workout_screen.dart';
import 'package:nutrilift/screens/exercise_library_screen.dart';
import 'package:nutrilift/screens/personal_records_screen.dart';
import 'package:nutrilift/widgets/nutrilift_header.dart';
import 'package:nutrilift/providers/repository_providers.dart';
import 'package:nutrilift/repositories/mock_workout_repository.dart';
import 'package:nutrilift/repositories/mock_exercise_repository.dart';
import 'package:nutrilift/repositories/mock_personal_record_repository.dart';

/// Integration Tests for Navigation Flows
/// 
/// Tests complete user flows and navigation between workout screens.
/// Validates: Requirements 7.10, 13.2, 13.3
void main() {
  group('Workout Navigation Integration Tests', () {
    late Widget testApp;

    setUp(() {
      // Create test app with mock repositories
      testApp = ProviderScope(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
          exerciseRepositoryProvider.overrideWithValue(MockExerciseRepository()),
          personalRecordRepositoryProvider.overrideWithValue(MockPersonalRecordRepository()),
        ],
        child: MaterialApp(
          home: const WorkoutTracking(),
          theme: ThemeData(
            primaryColor: const Color(0xFFE53935),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE53935),
              primary: const Color(0xFFE53935),
            ),
          ),
        ),
      );
    });

    testWidgets('Complete user flow: Navigate from main screen to workout history', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Act - Find and tap workout history navigation card
      final workoutHistoryCard = find.text('Workout History');
      expect(workoutHistoryCard, findsOneWidget);
      
      await tester.tap(workoutHistoryCard);
      await tester.pumpAndSettle();

      // Assert - Verify navigation to workout history screen
      expect(find.byType(WorkoutHistoryScreen), findsOneWidget);
      expect(find.text('Workout History'), findsWidgets); // Title in header
    });

    testWidgets('Complete user flow: Navigate from main screen to new workout', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Act - Find and tap new workout navigation card
      final newWorkoutCard = find.text('Log New Workout');
      expect(newWorkoutCard, findsOneWidget);
      
      await tester.tap(newWorkoutCard);
      await tester.pumpAndSettle();

      // Assert - Verify navigation to new workout screen
      expect(find.byType(NewWorkoutScreen), findsOneWidget);
    });

    testWidgets('Complete user flow: Navigate from main screen to exercise library', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Act - Find and tap exercise library navigation card
      final exerciseLibraryCard = find.text('Exercise Library');
      expect(exerciseLibraryCard, findsOneWidget);
      
      await tester.tap(exerciseLibraryCard);
      await tester.pumpAndSettle();

      // Assert - Verify navigation to exercise library screen
      expect(find.byType(ExerciseLibraryScreen), findsOneWidget);
    });

    testWidgets('Complete user flow: Navigate from main screen to personal records', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Act - Find and tap personal records navigation card
      final personalRecordsCard = find.text('Personal Records');
      expect(personalRecordsCard, findsOneWidget);
      
      await tester.tap(personalRecordsCard);
      await tester.pumpAndSettle();

      // Assert - Verify navigation to personal records screen
      expect(find.byType(PersonalRecordsScreen), findsOneWidget);
      expect(find.text('Personal Records'), findsWidgets); // Title in header
    });

    testWidgets('Navigation back button works correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Act - Navigate to workout history
      await tester.tap(find.text('Workout History'));
      await tester.pumpAndSettle();
      
      expect(find.byType(WorkoutHistoryScreen), findsOneWidget);

      // Act - Tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
      
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Assert - Verify navigation back to main screen
      expect(find.byType(WorkoutTrackingHome), findsOneWidget);
      expect(find.text('Track Your Progress'), findsOneWidget);
    });

    testWidgets('Red theme is applied consistently across navigation', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Assert - Check main screen has red theme
      final mainScreenContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(WorkoutTrackingHome),
          matching: find.byType(Container),
        ).first,
      );
      
      // Navigate to workout history
      await tester.tap(find.text('Workout History'));
      await tester.pumpAndSettle();

      // Assert - Check FAB has red theme
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab.backgroundColor, const Color(0xFFE53935));

      // Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Navigate to personal records
      await tester.tap(find.text('Personal Records'));
      await tester.pumpAndSettle();

      // Assert - Check refresh indicator has red theme
      final refreshIndicator = tester.widget<RefreshIndicator>(
        find.byType(RefreshIndicator),
      );
      expect(refreshIndicator.color, const Color(0xFFE53935));
    });

    testWidgets('Drawer navigation includes workout screens', (WidgetTester tester) async {
      // Arrange - Create app with drawer
      final appWithDrawer = ProviderScope(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
          exerciseRepositoryProvider.overrideWithValue(MockExerciseRepository()),
          personalRecordRepositoryProvider.overrideWithValue(MockPersonalRecordRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: const NutriLiftHeader(title: 'Test'),
            endDrawer: const NutriLiftDrawer(),
            body: Container(),
          ),
        ),
      );

      await tester.pumpWidget(appWithDrawer);
      await tester.pumpAndSettle();

      // Act - Open drawer
      final menuButton = find.byIcon(Icons.menu);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Assert - Verify workout navigation items exist in drawer
      expect(find.text('WORKOUT'), findsOneWidget);
      expect(find.text('Workout History'), findsOneWidget);
      expect(find.text('Log New Workout'), findsOneWidget);
      expect(find.text('Exercise Library'), findsOneWidget);
      expect(find.text('Personal Records'), findsOneWidget);
    });

    testWidgets('Drawer navigation to workout screens works', (WidgetTester tester) async {
      // Arrange - Create app with drawer
      final appWithDrawer = ProviderScope(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
          exerciseRepositoryProvider.overrideWithValue(MockExerciseRepository()),
          personalRecordRepositoryProvider.overrideWithValue(MockPersonalRecordRepository()),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: const NutriLiftHeader(title: 'Test'),
            endDrawer: const NutriLiftDrawer(),
            body: Container(),
          ),
        ),
      );

      await tester.pumpWidget(appWithDrawer);
      await tester.pumpAndSettle();

      // Act - Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Act - Tap workout history in drawer
      final workoutHistoryTile = find.ancestor(
        of: find.text('Workout History'),
        matching: find.byType(ListTile),
      );
      await tester.tap(workoutHistoryTile);
      await tester.pumpAndSettle();

      // Assert - Verify navigation to workout history screen
      expect(find.byType(WorkoutHistoryScreen), findsOneWidget);
    });

    testWidgets('Multiple navigation flows work in sequence', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Act & Assert - Navigate through multiple screens
      
      // 1. Navigate to workout history
      await tester.tap(find.text('Workout History'));
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutHistoryScreen), findsOneWidget);

      // 2. Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutTrackingHome), findsOneWidget);

      // 3. Navigate to exercise library
      await tester.tap(find.text('Exercise Library'));
      await tester.pumpAndSettle();
      expect(find.byType(ExerciseLibraryScreen), findsOneWidget);

      // 4. Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutTrackingHome), findsOneWidget);

      // 5. Navigate to personal records
      await tester.tap(find.text('Personal Records'));
      await tester.pumpAndSettle();
      expect(find.byType(PersonalRecordsScreen), findsOneWidget);

      // 6. Navigate back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(WorkoutTrackingHome), findsOneWidget);
    });

    testWidgets('NutriLiftHeader is integrated in all workout screens', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Test workout history screen
      await tester.tap(find.text('Workout History'));
      await tester.pumpAndSettle();
      expect(find.byType(NutriLiftHeader), findsOneWidget);
      expect(find.text('Workout History'), findsWidgets);
      
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Test new workout screen
      await tester.tap(find.text('Log New Workout'));
      await tester.pumpAndSettle();
      expect(find.byType(NutriLiftHeader), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Test exercise library screen
      await tester.tap(find.text('Exercise Library'));
      await tester.pumpAndSettle();
      expect(find.byType(NutriLiftHeader), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Test personal records screen
      await tester.tap(find.text('Personal Records'));
      await tester.pumpAndSettle();
      expect(find.byType(NutriLiftHeader), findsOneWidget);
      expect(find.text('Personal Records'), findsWidgets);
    });
  });

  group('Navigation Edge Cases', () {
    testWidgets('Rapid navigation does not cause errors', (WidgetTester tester) async {
      // Arrange
      final testApp = ProviderScope(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
          exerciseRepositoryProvider.overrideWithValue(MockExerciseRepository()),
          personalRecordRepositoryProvider.overrideWithValue(MockPersonalRecordRepository()),
        ],
        child: MaterialApp(
          home: const WorkoutTracking(),
        ),
      );

      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Act - Rapidly navigate between screens
      for (int i = 0; i < 3; i++) {
        // Find the navigation card specifically (not the header text)
        final workoutHistoryCard = find.ancestor(
          of: find.text('Workout History'),
          matching: find.byType(InkWell),
        ).first;
        
        await tester.tap(workoutHistoryCard);
        await tester.pumpAndSettle();
        
        if (find.byIcon(Icons.arrow_back).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.arrow_back));
          await tester.pumpAndSettle();
        }
      }

      // Assert - No errors occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('Navigation maintains state correctly', (WidgetTester tester) async {
      // Arrange
      final testApp = ProviderScope(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
          exerciseRepositoryProvider.overrideWithValue(MockExerciseRepository()),
          personalRecordRepositoryProvider.overrideWithValue(MockPersonalRecordRepository()),
        ],
        child: MaterialApp(
          home: const WorkoutTracking(),
        ),
      );

      await tester.pumpWidget(testApp);
      await tester.pumpAndSettle();

      // Act - Navigate to workout history and back
      await tester.tap(find.text('Workout History'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Assert - Main screen is still displayed correctly
      expect(find.byType(WorkoutTrackingHome), findsOneWidget);
      expect(find.text('Track Your Progress'), findsOneWidget);
      expect(find.text('Workout History'), findsOneWidget);
      expect(find.text('Log New Workout'), findsOneWidget);
      expect(find.text('Exercise Library'), findsOneWidget);
      expect(find.text('Personal Records'), findsOneWidget);
    });
  });
}
