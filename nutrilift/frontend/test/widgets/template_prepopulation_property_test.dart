import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrilift/models/exercise.dart' as ex;
import 'package:nutrilift/models/workout_log.dart' as wl;
import 'package:nutrilift/models/workout_models.dart';
import 'package:nutrilift/providers/new_workout_provider.dart';
import 'package:nutrilift/providers/repository_providers.dart';
import 'package:nutrilift/repositories/workout_repository.dart';

// Mock repository
class MockWorkoutRepository implements WorkoutRepository {
  @override
  Future<wl.WorkoutLog> logWorkout(CreateWorkoutLogRequest request) async {
    return wl.WorkoutLog(
      id: 1,
      user: 1,
      customWorkoutId: null,
      workoutName: 'Test',
      gym: null,
      gymName: null,
      date: DateTime.now(),
      duration: 60,
      caloriesBurned: 450.0,
      notes: null,
      exercises: [],
      hasNewPrs: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<wl.WorkoutLog>> getWorkoutHistory({DateTime? dateFrom, int? limit}) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> getStatistics({DateTime? dateFrom, DateTime? dateTo}) async {
    return {};
  }
}

void main() {
  group('Property 4: Template Pre-population', () {
    test('template exercises are pre-populated in correct order', () {
      // Feature: workout-tracking-system, Property 4: Template Pre-population
      // For any workout template, when selected, the exercise list should be
      // pre-populated with all exercises from that template in the correct order.
      // **Validates: Requirements 2.2**

      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );

      final notifier = container.read(newWorkoutProvider.notifier);

      // Create template exercises
      final templateExercises = [
        ex.Exercise(
          id: 1,
          name: 'Bench Press',
          category: 'Strength',
          muscleGroup: 'Chest',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Chest exercise',
          instructions: 'Press the bar',
          imageUrl: null,
          videoUrl: null,
        ),
        ex.Exercise(
          id: 2,
          name: 'Incline Press',
          category: 'Strength',
          muscleGroup: 'Chest',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Upper chest exercise',
          instructions: 'Press on incline',
          imageUrl: null,
          videoUrl: null,
        ),
        ex.Exercise(
          id: 3,
          name: 'Chest Fly',
          category: 'Strength',
          muscleGroup: 'Chest',
          equipment: 'Free Weights',
          difficulty: 'Beginner',
          description: 'Chest isolation',
          instructions: 'Fly motion',
          imageUrl: null,
          videoUrl: null,
        ),
      ];

      // Load template exercises
      notifier.loadTemplateExercises(templateExercises);

      final state = container.read(newWorkoutProvider);

      // Verify all exercises are loaded
      expect(state.exercises.length, equals(3));

      // Verify exercises are in correct order
      expect(state.exercises[0].exercise.id, equals(1));
      expect(state.exercises[0].exercise.name, equals('Bench Press'));
      expect(state.exercises[0].order, equals(0));

      expect(state.exercises[1].exercise.id, equals(2));
      expect(state.exercises[1].exercise.name, equals('Incline Press'));
      expect(state.exercises[1].order, equals(1));

      expect(state.exercises[2].exercise.id, equals(3));
      expect(state.exercises[2].exercise.name, equals('Chest Fly'));
      expect(state.exercises[2].order, equals(2));

      // Verify each exercise has default sets
      for (final exercise in state.exercises) {
        expect(exercise.sets.length, equals(3)); // Default 3 sets
        for (final set in exercise.sets) {
          expect(set.reps, equals(10)); // Default reps
          expect(set.weight, equals(20.0)); // Default weight
        }
      }

      container.dispose();
    });

    test('empty template loads no exercises', () {
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );

      final notifier = container.read(newWorkoutProvider.notifier);

      // Load empty template
      notifier.loadTemplateExercises([]);

      final state = container.read(newWorkoutProvider);

      // Verify no exercises are loaded
      expect(state.exercises.length, equals(0));

      container.dispose();
    });

    test('template with single exercise loads correctly', () {
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );

      final notifier = container.read(newWorkoutProvider.notifier);

      // Create single exercise template
      final templateExercises = [
        ex.Exercise(
          id: 1,
          name: 'Squats',
          category: 'Strength',
          muscleGroup: 'Legs',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Leg exercise',
          instructions: 'Squat down',
          imageUrl: null,
          videoUrl: null,
        ),
      ];

      // Load template
      notifier.loadTemplateExercises(templateExercises);

      final state = container.read(newWorkoutProvider);

      // Verify exercise is loaded
      expect(state.exercises.length, equals(1));
      expect(state.exercises[0].exercise.name, equals('Squats'));
      expect(state.exercises[0].order, equals(0));
      expect(state.exercises[0].sets.length, equals(3));

      container.dispose();
    });

    test('template with many exercises maintains order', () {
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );

      final notifier = container.read(newWorkoutProvider.notifier);

      // Create template with 10 exercises
      final templateExercises = List.generate(10, (index) {
        return ex.Exercise(
          id: index + 1,
          name: 'Exercise ${index + 1}',
          category: 'Strength',
          muscleGroup: 'Chest',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Exercise $index',
          instructions: 'Do exercise $index',
          imageUrl: null,
          videoUrl: null,
        );
      });

      // Load template
      notifier.loadTemplateExercises(templateExercises);

      final state = container.read(newWorkoutProvider);

      // Verify all exercises are loaded in order
      expect(state.exercises.length, equals(10));
      for (int i = 0; i < 10; i++) {
        expect(state.exercises[i].exercise.id, equals(i + 1));
        expect(state.exercises[i].exercise.name, equals('Exercise ${i + 1}'));
        expect(state.exercises[i].order, equals(i));
      }

      container.dispose();
    });

    test('loading new template replaces existing exercises', () {
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );

      final notifier = container.read(newWorkoutProvider.notifier);

      // Load first template
      final template1 = [
        ex.Exercise(
          id: 1,
          name: 'Exercise 1',
          category: 'Strength',
          muscleGroup: 'Chest',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Exercise 1',
          instructions: 'Do exercise 1',
          imageUrl: null,
          videoUrl: null,
        ),
      ];
      notifier.loadTemplateExercises(template1);

      var state = container.read(newWorkoutProvider);
      expect(state.exercises.length, equals(1));
      expect(state.exercises[0].exercise.name, equals('Exercise 1'));

      // Load second template
      final template2 = [
        ex.Exercise(
          id: 2,
          name: 'Exercise 2',
          category: 'Strength',
          muscleGroup: 'Back',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Exercise 2',
          instructions: 'Do exercise 2',
          imageUrl: null,
          videoUrl: null,
        ),
        ex.Exercise(
          id: 3,
          name: 'Exercise 3',
          category: 'Strength',
          muscleGroup: 'Legs',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Exercise 3',
          instructions: 'Do exercise 3',
          imageUrl: null,
          videoUrl: null,
        ),
      ];
      notifier.loadTemplateExercises(template2);

      state = container.read(newWorkoutProvider);
      expect(state.exercises.length, equals(2));
      expect(state.exercises[0].exercise.name, equals('Exercise 2'));
      expect(state.exercises[1].exercise.name, equals('Exercise 3'));

      container.dispose();
    });
  });
}
