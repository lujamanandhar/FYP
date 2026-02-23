import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrilift/screens/new_workout_screen.dart';
import 'package:nutrilift/providers/new_workout_provider.dart';
import 'package:nutrilift/providers/exercise_library_provider.dart';
import 'package:nutrilift/providers/repository_providers.dart';
import 'package:nutrilift/repositories/mock_workout_repository.dart';
import 'package:nutrilift/repositories/mock_exercise_repository.dart';
import 'package:nutrilift/models/exercise.dart' as ex;
import 'package:nutrilift/widgets/exercise_input_widget.dart';

/// Helper to build the widget with mock repositories
Widget buildTestWidget({
  MockWorkoutRepository? customWorkoutRepo,
  MockExerciseRepository? customExerciseRepo,
}) {
  return ProviderScope(
    overrides: [
      workoutRepositoryProvider.overrideWithValue(
        customWorkoutRepo ?? MockWorkoutRepository(),
      ),
      exerciseRepositoryProvider.overrideWithValue(
        customExerciseRepo ?? MockExerciseRepository(),
      ),
    ],
    child: const MaterialApp(home: NewWorkoutScreen()),
  );
}

void main() {
  group('NewWorkoutScreen Widget Tests', () {

    testWidgets('should display all form fields', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show all form sections
      expect(find.text('Workout Template (Optional)'), findsOneWidget);
      expect(find.text('Gym (Optional)'), findsOneWidget);
      expect(find.text('Duration (minutes) *'), findsOneWidget);
      expect(find.text('Exercises *'), findsOneWidget);
      expect(find.text('Notes (Optional)'), findsOneWidget);
      expect(find.text('Save Workout'), findsOneWidget);
    });

    testWidgets('should show empty state when no exercises added',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should show empty state message
      expect(
        find.text('No exercises added yet.\nTap "Add Exercise" to get started.'),
        findsOneWidget,
      );
    });

    testWidgets('should have Add Exercise button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should have Add Exercise button
      expect(find.text('Add Exercise'), findsOneWidget);
    });

    testWidgets('should validate duration input', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find duration input field
      final durationField = find.widgetWithText(TextFormField, 'Enter duration (1-600 minutes)');
      expect(durationField, findsOneWidget);

      // Enter invalid duration (too high)
      await tester.enterText(durationField, '700');
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.text('Save Workout'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error
      expect(find.text('Duration must be between 1 and 600 minutes'), findsOneWidget);
    });

    testWidgets('should show validation error when no exercises added',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter valid duration
      final durationField = find.widgetWithText(TextFormField, 'Enter duration (1-600 minutes)');
      await tester.enterText(durationField, '60');
      await tester.pumpAndSettle();

      // Try to save without exercises
      await tester.tap(find.text('Save Workout'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error dialog
      expect(find.text('Validation Errors'), findsOneWidget);
      expect(find.text('At least one exercise is required'), findsOneWidget);
    });

    testWidgets('should open exercise selection dialog when Add Exercise tapped',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Add Exercise button
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      // Assert - Should show exercise selection dialog
      expect(find.text('Select Exercise'), findsOneWidget);
      expect(find.text('Search exercises...'), findsOneWidget);
    });

    testWidgets('should display template dropdown', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should have template dropdown
      expect(find.text('Select a template'), findsOneWidget);
    });

    testWidgets('should display gym dropdown', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should have gym dropdown
      expect(find.text('Select a gym'), findsOneWidget);
    });

    testWidgets('should have notes input field', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Assert - Should have notes field
      expect(find.text('Add any notes about your workout...'), findsOneWidget);
    });
  });

  group('Property 6: Exercise Addition to Workout', () {
    /// **Validates: Requirements 2.4, 3.8**
    /// 
    /// Property 6: Exercise Addition to Workout
    /// For any workout being created, adding an exercise should increase 
    /// the workout's exercise list length by exactly one.

    testWidgets(
        'Feature: workout-tracking-system, Property 6: Exercise Addition to Workout',
        (WidgetTester tester) async {
      // Property test: Adding an exercise should increase list length by 1

      final mockExerciseRepo = MockExerciseRepository();

      await tester.pumpWidget(buildTestWidget(
        customExerciseRepo: mockExerciseRepo,
      ));
      await tester.pumpAndSettle();

      // Initial state: no exercises
      expect(
        find.text('No exercises added yet.\nTap "Add Exercise" to get started.'),
        findsOneWidget,
      );

      // Open exercise selection dialog
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      // Wait for exercises to load
      await tester.pump(const Duration(milliseconds: 500));

      // Select first exercise (Bench Press)
      final benchPressItem = find.text('Bench Press').first;
      await tester.tap(benchPressItem);
      await tester.pumpAndSettle();

      // Assert - Exercise should be added
      expect(find.byType(ExerciseInputWidget), findsOneWidget);
      expect(find.text('Bench Press'), findsOneWidget);

      // Add another exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // Select second exercise (Squats)
      final squatsItem = find.text('Squats').first;
      await tester.tap(squatsItem);
      await tester.pumpAndSettle();

      // Assert - Should now have 2 exercises
      expect(find.byType(ExerciseInputWidget), findsNWidgets(2));
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squats'), findsOneWidget);
    });
  });

  group('Property 29: Incomplete Workout Validation', () {
    /// **Validates: Requirements 9.4, 9.5**
    /// 
    /// Property 29: Incomplete Workout Validation
    /// For any workout submission attempt, if the workout has no exercises 
    /// or is missing required fields (duration), the system should display 
    /// validation errors and prevent submission.

    testWidgets(
        'Feature: workout-tracking-system, Property 29: Incomplete Workout Validation - Missing duration',
        (WidgetTester tester) async {
      // Property test: Missing duration should prevent submission

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Try to save without entering duration
      await tester.tap(find.text('Save Workout'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error
      expect(find.text('Duration is required'), findsOneWidget);
    });

    testWidgets(
        'Feature: workout-tracking-system, Property 29: Incomplete Workout Validation - Missing exercises',
        (WidgetTester tester) async {
      // Property test: Missing exercises should prevent submission

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter valid duration
      final durationField = find.widgetWithText(TextFormField, 'Enter duration (1-600 minutes)');
      await tester.enterText(durationField, '60');
      await tester.pumpAndSettle();

      // Try to save without exercises
      await tester.tap(find.text('Save Workout'));
      await tester.pumpAndSettle();

      // Assert - Should show validation error dialog
      expect(find.text('Validation Errors'), findsOneWidget);
      expect(find.text('At least one exercise is required'), findsOneWidget);
    });

    testWidgets(
        'Feature: workout-tracking-system, Property 29: Incomplete Workout Validation - Invalid duration range',
        (WidgetTester tester) async {
      // Property test: Duration outside valid range should prevent submission

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Test cases for invalid durations
      final invalidDurations = [0, -1, 601, 1000];

      for (final duration in invalidDurations) {
        // Enter invalid duration
        final durationField = find.widgetWithText(TextFormField, 'Enter duration (1-600 minutes)');
        await tester.enterText(durationField, duration.toString());
        await tester.pumpAndSettle();

        // Try to save
        await tester.tap(find.text('Save Workout'));
        await tester.pumpAndSettle();

        // Assert - Should show validation error
        expect(
          find.text('Duration must be between 1 and 600 minutes'),
          findsOneWidget,
          reason: 'Duration $duration should be rejected',
        );

        // Clear for next iteration
        await tester.enterText(durationField, '');
        await tester.pumpAndSettle();
      }
    });

    testWidgets(
        'Feature: workout-tracking-system, Property 29: Incomplete Workout Validation - Valid duration accepted',
        (WidgetTester tester) async {
      // Property test: Valid durations should be accepted

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Test cases for valid durations
      final validDurations = [1, 30, 60, 120, 300, 600];

      for (final duration in validDurations) {
        // Enter valid duration
        final durationField = find.widgetWithText(TextFormField, 'Enter duration (1-600 minutes)');
        await tester.enterText(durationField, duration.toString());
        await tester.pumpAndSettle();

        // Try to save (will fail due to missing exercises, but duration should be valid)
        await tester.tap(find.text('Save Workout'));
        await tester.pumpAndSettle();

        // Assert - Should NOT show duration validation error
        expect(
          find.text('Duration must be between 1 and 600 minutes'),
          findsNothing,
          reason: 'Duration $duration should be accepted',
        );

        // Should show exercises error instead
        expect(find.text('At least one exercise is required'), findsOneWidget);

        // Close dialog
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        // Clear for next iteration
        await tester.enterText(durationField, '');
        await tester.pumpAndSettle();
      }
    });
  });

  group('ExerciseInputWidget Tests', () {
    testWidgets('should display exercise name', (WidgetTester tester) async {
      // Arrange
      final exercise = ex.Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test description',
        instructions: 'Test instructions',
      );

      final workoutExercise = NewWorkoutExercise(
        exercise: exercise,
        order: 0,
        sets: [
          const NewWorkoutSet(setNumber: 1, reps: 10, weight: 100.0),
        ],
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseInputWidget(
                exerciseIndex: 0,
                exercise: workoutExercise,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Bench Press'), findsOneWidget);
    });

    testWidgets('should display sets with reps and weight inputs',
        (WidgetTester tester) async {
      // Arrange
      final exercise = ex.Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test description',
        instructions: 'Test instructions',
      );

      final workoutExercise = NewWorkoutExercise(
        exercise: exercise,
        order: 0,
        sets: [
          const NewWorkoutSet(setNumber: 1, reps: 10, weight: 100.0),
          const NewWorkoutSet(setNumber: 2, reps: 8, weight: 110.0),
        ],
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseInputWidget(
                exerciseIndex: 0,
                exercise: workoutExercise,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Set 1'), findsOneWidget);
      expect(find.text('Set 2'), findsOneWidget);
      expect(find.text('Reps'), findsNWidgets(2));
      expect(find.text('Weight (kg)'), findsNWidgets(2));
    });

    testWidgets('should have Add Set button', (WidgetTester tester) async {
      // Arrange
      final exercise = ex.Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test description',
        instructions: 'Test instructions',
      );

      final workoutExercise = NewWorkoutExercise(
        exercise: exercise,
        order: 0,
        sets: [
          const NewWorkoutSet(setNumber: 1, reps: 10, weight: 100.0),
        ],
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseInputWidget(
                exerciseIndex: 0,
                exercise: workoutExercise,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Add Set'), findsOneWidget);
    });

    testWidgets('should have remove exercise button',
        (WidgetTester tester) async {
      // Arrange
      final exercise = ex.Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test description',
        instructions: 'Test instructions',
      );

      final workoutExercise = NewWorkoutExercise(
        exercise: exercise,
        order: 0,
        sets: [
          const NewWorkoutSet(setNumber: 1, reps: 10, weight: 100.0),
        ],
      );

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ExerciseInputWidget(
                exerciseIndex: 0,
                exercise: workoutExercise,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Should have close button
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('ExerciseSelectionDialog Tests', () {
    testWidgets('should display search bar', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseRepositoryProvider.overrideWithValue(MockExerciseRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExerciseSelectionDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Select Exercise'), findsOneWidget);
      expect(find.text('Search exercises...'), findsOneWidget);
    });

    testWidgets('should display exercises from repository',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseRepositoryProvider.overrideWithValue(MockExerciseRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExerciseSelectionDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Wait for exercises to load
      await tester.pump(const Duration(milliseconds: 500));

      // Assert - Should show exercises
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squats'), findsOneWidget);
    });

    testWidgets('should have close button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exerciseRepositoryProvider.overrideWithValue(MockExerciseRepository()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExerciseSelectionDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
