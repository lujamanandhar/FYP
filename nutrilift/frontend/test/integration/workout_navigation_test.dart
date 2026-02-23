import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../lib/WorkoutTracking/workout_tracking.dart';
import '../../lib/screens/workout_history_screen.dart';
import '../../lib/screens/new_workout_screen.dart';
import '../../lib/screens/exercise_library_screen.dart';
import '../../lib/screens/personal_records_screen.dart';
import '../../lib/widgets/nutrilift_header.dart';
import '../../lib/repositories/mock_workout_repository.dart';
import '../../lib/repositories/mock_exercise_repository.dart';
import '../../lib/repositories/mock_personal_record_repository.dart';
import '../../lib/providers/repository_providers.dart';

void main() {
  group('Workout Navigation Integration Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
          exerciseRepositoryProvider.overrideWithValue(MockExerciseRepository()),
          personalRecordRepositoryProvider.overrideWithValue(MockPersonalRecordRepository()),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createTestApp(Widget home) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: home,
          theme: ThemeData(
            primaryColor: const Color(0xFFE53935),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE53935),
              primary: const Color(0xFFE53935),
            ),
          ),
        ),
      );
    }

    testWidgets('WorkoutHome displays all quick action cards', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const WorkoutTracking()));
      await tester.pumpAndSettle();

      // Verify all quick action cards are present
      expect(find.text('New Workout'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Exercise Library'), findsOneWidget);
      expect(find.text('Personal Records'), findsOneWidget);
    });

    testWidgets('Navigate from WorkoutHome to WorkoutHistoryScreen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const WorkoutTracking()));
      await tester.pumpAndSettle();

      // Find and tap the History quick action card
      final historyCard = find.text('History');
      expect(historyCard, findsOneWidget);

      await tester.tap(historyCard);
      await tester.pumpAndSettle();

      // Verify we're on the WorkoutHistoryScreen
      expect(find.byType(WorkoutHistoryScreen), findsOneWidget);
      expect(find.text('Workout History'), findsOneWidget);
    });

    testWidgets('Navigate from drawer menu to WorkoutHistoryScreen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          appBar: NutriLiftHeader(showDrawer: true),
          endDrawer: NutriLiftDrawer(),
          body: Center(child: Text('Test Screen')),
        ),
      ));
      await tester.pumpAndSettle();

      // Open the drawer
      final menuButton = find.byIcon(Icons.menu);
      expect(menuButton, findsOneWidget);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Find and tap Workout History in drawer
      final workoutHistoryItem = find.text('Workout History');
      expect(workoutHistoryItem, findsOneWidget);
      await tester.tap(workoutHistoryItem);
      await tester.pumpAndSettle();

      // Verify we're on the WorkoutHistoryScreen
      expect(find.byType(WorkoutHistoryScreen), findsOneWidget);
    });

    testWidgets('Navigate from drawer menu to NewWorkoutScreen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          appBar: NutriLiftHeader(showDrawer: true),
          endDrawer: NutriLiftDrawer(),
          body: Center(child: Text('Test Screen')),
        ),
      ));
      await tester.pumpAndSettle();

      // Open the drawer
      final menuButton = find.byIcon(Icons.menu);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Find and tap New Workout in drawer
      final newWorkoutItem = find.text('New Workout');
      expect(newWorkoutItem, findsOneWidget);
      await tester.tap(newWorkoutItem);
      await tester.pumpAndSettle();

      // Verify we're on the NewWorkoutScreen
      expect(find.byType(NewWorkoutScreen), findsOneWidget);
    });

    testWidgets('Navigate from drawer menu to ExerciseLibraryScreen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          appBar: NutriLiftHeader(showDrawer: true),
          endDrawer: NutriLiftDrawer(),
          body: Center(child: Text('Test Screen')),
        ),
      ));
      await tester.pumpAndSettle();

      // Open the drawer
      final menuButton = find.byIcon(Icons.menu);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Find and tap Exercise Library in drawer
      final exerciseLibraryItem = find.text('Exercise Library');
      expect(exerciseLibraryItem, findsOneWidget);
      await tester.tap(exerciseLibraryItem);
      await tester.pumpAndSettle();

      // Verify we're on the ExerciseLibraryScreen
      expect(find.byType(ExerciseLibraryScreen), findsOneWidget);
    });

    testWidgets('Navigate from drawer menu to PersonalRecordsScreen', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          appBar: NutriLiftHeader(showDrawer: true),
          endDrawer: NutriLiftDrawer(),
          body: Center(child: Text('Test Screen')),
        ),
      ));
      await tester.pumpAndSettle();

      // Open the drawer
      final menuButton = find.byIcon(Icons.menu);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Find and tap Personal Records in drawer
      final prItem = find.text('Personal Records');
      expect(prItem, findsOneWidget);
      await tester.tap(prItem);
      await tester.pumpAndSettle();

      // Verify we're on the PersonalRecordsScreen
      expect(find.byType(PersonalRecordsScreen), findsOneWidget);
    });

    testWidgets('All workout screens have NutriLiftHeader', (WidgetTester tester) async {
      // Test WorkoutHistoryScreen
      await tester.pumpWidget(createTestApp(const WorkoutHistoryScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(NutriLiftHeader), findsOneWidget);

      // Test NewWorkoutScreen
      await tester.pumpWidget(createTestApp(const NewWorkoutScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(NutriLiftHeader), findsOneWidget);

      // Test ExerciseLibraryScreen
      await tester.pumpWidget(createTestApp(const ExerciseLibraryScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(NutriLiftHeader), findsOneWidget);

      // Test PersonalRecordsScreen
      await tester.pumpWidget(createTestApp(const PersonalRecordsScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(NutriLiftHeader), findsOneWidget);
    });

    testWidgets('Red theme is applied to MaterialApp', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const WorkoutTracking()));
      await tester.pumpAndSettle();

      // Verify theme is applied
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme?.primaryColor, const Color(0xFFE53935));
      expect(materialApp.theme?.colorScheme.primary, const Color(0xFFE53935));
    });

    testWidgets('Drawer menu contains all workout navigation items', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(
        const Scaffold(
          appBar: NutriLiftHeader(showDrawer: true),
          endDrawer: NutriLiftDrawer(),
          body: Center(child: Text('Test Screen')),
        ),
      ));
      await tester.pumpAndSettle();

      // Open the drawer
      final menuButton = find.byIcon(Icons.menu);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Verify all workout menu items are present
      expect(find.text('Workout History'), findsOneWidget);
      expect(find.text('New Workout'), findsOneWidget);
      expect(find.text('Exercise Library'), findsOneWidget);
      expect(find.text('Personal Records'), findsOneWidget);
    });

    testWidgets('WorkoutHistoryScreen has FAB for new workout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const WorkoutHistoryScreen()));
      await tester.pumpAndSettle();

      // Verify FAB is present
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('WorkoutHome has proper layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const WorkoutTracking()));
      await tester.pumpAndSettle();

      // Verify main title
      expect(find.text('Workout Tracking'), findsOneWidget);
      
      // Verify subtitle
      expect(find.text('Track your workouts, view history, and monitor your progress'), findsOneWidget);
      
      // Verify workout templates section
      expect(find.text('Workout Templates'), findsOneWidget);
    });
  });
}
