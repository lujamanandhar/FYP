import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrilift/models/exercise.dart' as ex;
import 'package:nutrilift/models/workout_log.dart' as wl;
import 'package:nutrilift/models/workout_models.dart';
import 'package:nutrilift/screens/new_workout_screen.dart';
import 'package:nutrilift/providers/new_workout_provider.dart';
import 'package:nutrilift/providers/exercise_library_provider.dart';
import 'package:nutrilift/providers/repository_providers.dart';
import 'package:nutrilift/repositories/workout_repository.dart';
import 'package:nutrilift/repositories/exercise_repository.dart';

// Mock repositories
class MockWorkoutRepository implements WorkoutRepository {
  final List<wl.WorkoutLog> _workouts = [];
  bool shouldFail = false;

  @override
  Future<wl.WorkoutLog> logWorkout(CreateWorkoutLogRequest request) async {
    if (shouldFail) {
      throw Exception('Failed to log workout');
    }
    
    final workout = wl.WorkoutLog(
      id: 1,
      user: 1,
      customWorkoutId: request.customWorkoutId != null ? int.tryParse(request.customWorkoutId!) : null,
      workoutName: request.workoutName,
      gym: request.gymId != null ? int.tryParse(request.gymId!) : null,
      gymName: null,
      date: DateTime.now(),
      duration: request.durationMinutes,
      caloriesBurned: 450.0,
      notes: request.notes,
      exercises: [],
      hasNewPrs: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _workouts.add(workout);
    return workout;
  }

  @override
  Future<List<wl.WorkoutLog>> getWorkoutHistory({DateTime? dateFrom, int? limit}) async {
    return _workouts;
  }

  @override
  Future<Map<String, dynamic>> getStatistics({DateTime? dateFrom, DateTime? dateTo}) async {
    return {};
  }
}


class MockExerciseRepository implements ExerciseRepository {
  final List<ex.Exercise> _exercises = [
    ex.Exercise(
      id: 1,
      name: 'Bench Press',
      category: 'Strength',
      muscleGroup: 'Chest',
      equipment: 'Free Weights',
      difficulty: 'Intermediate',
      description: 'A compound upper body exercise',
      instructions: 'Lie on bench, lower bar to chest, press up',
      imageUrl: null,
      videoUrl: null,
    ),
    ex.Exercise(
      id: 2,
      name: 'Squats',
      category: 'Strength',
      muscleGroup: 'Legs',
      equipment: 'Free Weights',
      difficulty: 'Intermediate',
      description: 'A compound lower body exercise',
      instructions: 'Stand with feet shoulder-width apart, squat down',
      imageUrl: null,
      videoUrl: null,
    ),
    ex.Exercise(
      id: 3,
      name: 'Pull-ups',
      category: 'Strength',
      muscleGroup: 'Back',
      equipment: 'Bodyweight',
      difficulty: 'Advanced',
      description: 'A bodyweight back exercise',
      instructions: 'Hang from bar, pull yourself up',
      imageUrl: null,
      videoUrl: null,
    ),
  ];

  @override
  Future<List<ex.Exercise>> getExercises({
    String? category,
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? search,
  }) async {
    return _exercises;
  }

  @override
  Future<ex.Exercise> getExerciseById(String id) async {
    return _exercises.firstWhere((e) => e.id.toString() == id);
  }
}

void main() {
  late MockWorkoutRepository mockWorkoutRepository;
  late MockExerciseRepository mockExerciseRepository;

  setUp(() {
    mockWorkoutRepository = MockWorkoutRepository();
    mockExerciseRepository = MockExerciseRepository();
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(mockWorkoutRepository),
        exerciseRepositoryProvider.overrideWithValue(mockExerciseRepository),
      ],
      child: const MaterialApp(
        home: NewWorkoutScreen(),
      ),
    );
  }


  group('NewWorkoutScreen Widget Tests', () {
    testWidgets('displays all required form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Check for duration input
      expect(find.text('Duration (minutes) *'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Enter duration (1-600 minutes)'), findsOneWidget);

      // Check for gym selection
      expect(find.text('Gym (Optional)'), findsOneWidget);

      // Check for template selection
      expect(find.text('Workout Template (Optional)'), findsOneWidget);

      // Check for exercises section
      expect(find.text('Exercises *'), findsOneWidget);

      // Check for add exercise button
      expect(find.text('Add Exercise'), findsOneWidget);

      // Check for notes input
      expect(find.text('Notes (Optional)'), findsOneWidget);

      // Check for save button
      expect(find.text('Save Workout'), findsOneWidget);
    });

    testWidgets('validates duration input range (1-600)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find duration input
      final durationField = find.widgetWithText(TextFormField, 'Enter duration (1-600 minutes)');

      // Test invalid duration (0)
      await tester.enterText(durationField, '0');
      await tester.pumpAndSettle();
      expect(find.text('Duration must be between 1 and 600 minutes'), findsOneWidget);

      // Test invalid duration (601)
      await tester.enterText(durationField, '601');
      await tester.pumpAndSettle();
      expect(find.text('Duration must be between 1 and 600 minutes'), findsOneWidget);

      // Test valid duration
      await tester.enterText(durationField, '60');
      await tester.pumpAndSettle();
      expect(find.text('Duration must be between 1 and 600 minutes'), findsNothing);
    });

    testWidgets('validates at least one exercise is required', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially no exercises
      expect(find.text('No exercises added yet.\nTap "Add Exercise" to get started.'), findsOneWidget);
      expect(find.text('At least one exercise is required'), findsOneWidget);

      // Save button should be disabled
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Workout');
      expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNull);
    });
  });


  group('Property 6: Exercise Addition to Workout', () {
    testWidgets('can add exercises to workout', (WidgetTester tester) async {
      // Feature: workout-tracking-system, Property 6: Exercise Addition to Workout
      // For any workout being created, when a user adds an exercise,
      // the exercise should be added to the current workout with input fields
      // for sets, reps, and weight.
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap add exercise button
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      // Should show exercise search overlay
      expect(find.text('Search exercises...'), findsOneWidget);

      // Should show exercises
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squats'), findsOneWidget);
      expect(find.text('Pull-ups'), findsOneWidget);

      // Tap on Bench Press
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Should close search and show exercise in list
      expect(find.text('Search exercises...'), findsNothing);
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('3 sets'), findsOneWidget);

      // Should show set inputs
      expect(find.text('Set'), findsOneWidget);
      expect(find.text('Reps'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);
    });

    testWidgets('can add multiple exercises', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add first exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Add second exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Squats'));
      await tester.pumpAndSettle();

      // Should show both exercises
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squats'), findsOneWidget);
      expect(find.text('(2)'), findsOneWidget); // Exercise count
    });

    testWidgets('can remove exercises from workout', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Should show exercise
      expect(find.text('Bench Press'), findsOneWidget);

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Should remove exercise
      expect(find.text('Bench Press'), findsNothing);
      expect(find.text('No exercises added yet.\nTap "Add Exercise" to get started.'), findsOneWidget);
    });
  });


  group('Property 29: Incomplete Workout Validation', () {
    testWidgets('prevents submission without exercises', (WidgetTester tester) async {
      // Feature: workout-tracking-system, Property 29: Incomplete Workout Validation
      // For any workout submission attempt, if the workout has no exercises
      // or is missing required fields (duration), the system should display
      // validation errors and prevent submission.
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter valid duration
      final durationField = find.widgetWithText(TextFormField, 'Enter duration (1-600 minutes)');
      await tester.enterText(durationField, '60');
      await tester.pumpAndSettle();

      // Save button should still be disabled (no exercises)
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Workout');
      expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNull);
      expect(find.text('At least one exercise is required'), findsOneWidget);
    });

    testWidgets('prevents submission without duration', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Save button should be disabled (no duration)
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Workout');
      expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNull);
    });

    testWidgets('allows submission with valid data', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter valid duration
      final durationField = find.widgetWithText(TextFormField, 'Enter duration (1-600 minutes)');
      await tester.enterText(durationField, '60');
      await tester.pumpAndSettle();

      // Add exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Save button should be enabled
      final saveButton = find.widgetWithText(ElevatedButton, 'Save Workout');
      expect(tester.widget<ElevatedButton>(saveButton).onPressed, isNotNull);
    });
  });

  group('Exercise Input Validation', () {
    testWidgets('validates reps range (1-100)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Find reps input (first set)
      final repsFields = find.widgetWithText(TextFormField, '10');
      expect(repsFields, findsWidgets);

      // Test invalid reps (0)
      await tester.enterText(repsFields.first, '0');
      await tester.pumpAndSettle();
      expect(find.text('Reps must be between 1 and 100'), findsOneWidget);

      // Test invalid reps (101)
      await tester.enterText(repsFields.first, '101');
      await tester.pumpAndSettle();
      expect(find.text('Reps must be between 1 and 100'), findsOneWidget);

      // Test valid reps
      await tester.enterText(repsFields.first, '10');
      await tester.pumpAndSettle();
      expect(find.text('Reps must be between 1 and 100'), findsNothing);
    });

    testWidgets('validates weight range (0.1-1000)', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Find weight input (first set)
      final weightFields = find.widgetWithText(TextFormField, '20.0');
      expect(weightFields, findsWidgets);

      // Test invalid weight (0)
      await tester.enterText(weightFields.first, '0');
      await tester.pumpAndSettle();
      expect(find.text('Weight must be between 0.1 and 1000 kg'), findsOneWidget);

      // Test invalid weight (1001)
      await tester.enterText(weightFields.first, '1001');
      await tester.pumpAndSettle();
      expect(find.text('Weight must be between 0.1 and 1000 kg'), findsOneWidget);

      // Test valid weight
      await tester.enterText(weightFields.first, '100');
      await tester.pumpAndSettle();
      expect(find.text('Weight must be between 0.1 and 1000 kg'), findsNothing);
    });
  });


  group('Set Management', () {
    testWidgets('can add sets to exercise', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Should have 3 sets by default
      expect(find.text('3 sets'), findsOneWidget);

      // Tap add set button
      await tester.tap(find.text('Add Set'));
      await tester.pumpAndSettle();

      // Should have 4 sets
      expect(find.text('4 sets'), findsOneWidget);
    });

    testWidgets('can remove sets from exercise', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Should have 3 sets by default
      expect(find.text('3 sets'), findsOneWidget);

      // Tap remove set button (first one)
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Should have 2 sets
      expect(find.text('2 sets'), findsOneWidget);
    });

    testWidgets('cannot remove last set', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Add exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Remove sets until only one left
      final removeButtons = find.byIcon(Icons.remove_circle_outline);
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();
      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      // Should have 1 set
      expect(find.text('1 sets'), findsOneWidget);

      // Remove button should be disabled
      final lastRemoveButton = tester.widget<IconButton>(removeButtons.first);
      expect(lastRemoveButton.onPressed, isNull);
    });
  });

  group('Exercise Search', () {
    testWidgets('can search exercises by name', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap add exercise button
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      // Should show all exercises
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squats'), findsOneWidget);
      expect(find.text('Pull-ups'), findsOneWidget);

      // Search for "bench"
      final searchField = find.widgetWithText(TextField, 'Search exercises...');
      await tester.enterText(searchField, 'bench');
      await tester.pumpAndSettle();

      // Should only show Bench Press
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squats'), findsNothing);
      expect(find.text('Pull-ups'), findsNothing);
    });

    testWidgets('search is case insensitive', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap add exercise button
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      // Search for "BENCH" (uppercase)
      final searchField = find.widgetWithText(TextField, 'Search exercises...');
      await tester.enterText(searchField, 'BENCH');
      await tester.pumpAndSettle();

      // Should still find Bench Press
      expect(find.text('Bench Press'), findsOneWidget);
    });

    testWidgets('can close exercise search', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap add exercise button
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      // Should show search
      expect(find.text('Search exercises...'), findsOneWidget);

      // Tap back button
      final backButtons = find.byIcon(Icons.arrow_back);
      await tester.tap(backButtons.last); // Last one is in the search overlay
      await tester.pumpAndSettle();

      // Should close search
      expect(find.text('Search exercises...'), findsNothing);
    });
  });

  group('Workout Submission', () {
    testWidgets('shows success message on successful submission', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter valid data
      final durationField = find.widgetWithText(TextFormField, 'Enter duration (1-600 minutes)');
      await tester.enterText(durationField, '60');
      await tester.pumpAndSettle();

      // Add exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.text('Save Workout'));
      await tester.pumpAndSettle();

      // Should show success message
      expect(find.text('Workout logged successfully!'), findsOneWidget);
    });

    testWidgets('shows error message on failed submission', (WidgetTester tester) async {
      mockWorkoutRepository.shouldFail = true;
      
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter valid data
      final durationField = find.widgetWithText(TextFormField, 'Enter duration (1-600 minutes)');
      await tester.enterText(durationField, '60');
      await tester.pumpAndSettle();

      // Add exercise
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bench Press'));
      await tester.pumpAndSettle();

      // Tap save button
      await tester.tap(find.text('Save Workout'));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.textContaining('Error logging workout'), findsOneWidget);
    });
  });
}
