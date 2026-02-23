import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrilift/providers/new_workout_provider.dart';
import 'package:nutrilift/providers/repository_providers.dart';
import 'package:nutrilift/repositories/mock_workout_repository.dart';
import 'package:nutrilift/models/exercise.dart' as ex;

void main() {
  group('Property 4: Template Pre-population', () {
    /// **Validates: Requirements 2.2**
    /// 
    /// Property 4: Template Pre-population
    /// For any workout template, when selected, the exercise list should be 
    /// pre-populated with all exercises from that template in the correct order.

    test(
        'Feature: workout-tracking-system, Property 4: Template Pre-population - Empty template',
        () {
      // Property test: Empty template should result in empty exercise list

      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(newWorkoutProvider.notifier);

      // Load empty template
      notifier.loadTemplateExercises([]);

      final state = container.read(newWorkoutProvider);

      // Assert - Should have no exercises
      expect(state.exercises.length, equals(0));
    });

    test(
        'Feature: workout-tracking-system, Property 4: Template Pre-population - Single exercise template',
        () {
      // Property test: Template with one exercise should populate one exercise

      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(newWorkoutProvider.notifier);

      // Create template with one exercise
      final templateExercises = [
        const ex.Exercise(
          id: 1,
          name: 'Bench Press',
          category: 'Strength',
          muscleGroup: 'Chest',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Test description',
          instructions: 'Test instructions',
        ),
      ];

      // Load template
      notifier.loadTemplateExercises(templateExercises);

      final state = container.read(newWorkoutProvider);

      // Assert - Should have exactly one exercise
      expect(state.exercises.length, equals(1));
      expect(state.exercises[0].exercise.name, equals('Bench Press'));
      expect(state.exercises[0].order, equals(0));
      expect(state.exercises[0].sets.length, equals(3)); // Default 3 sets
    });

    test(
        'Feature: workout-tracking-system, Property 4: Template Pre-population - Multiple exercises maintain order',
        () {
      // Property test: Template with multiple exercises should maintain order

      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(newWorkoutProvider.notifier);

      // Create template with multiple exercises in specific order
      final templateExercises = [
        const ex.Exercise(
          id: 1,
          name: 'Bench Press',
          category: 'Strength',
          muscleGroup: 'Chest',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Test description',
          instructions: 'Test instructions',
        ),
        const ex.Exercise(
          id: 2,
          name: 'Squats',
          category: 'Strength',
          muscleGroup: 'Legs',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Test description',
          instructions: 'Test instructions',
        ),
        const ex.Exercise(
          id: 3,
          name: 'Deadlift',
          category: 'Strength',
          muscleGroup: 'Back',
          equipment: 'Free Weights',
          difficulty: 'Advanced',
          description: 'Test description',
          instructions: 'Test instructions',
        ),
      ];

      // Load template
      notifier.loadTemplateExercises(templateExercises);

      final state = container.read(newWorkoutProvider);

      // Assert - Should have all exercises in correct order
      expect(state.exercises.length, equals(3));
      
      expect(state.exercises[0].exercise.name, equals('Bench Press'));
      expect(state.exercises[0].order, equals(0));
      
      expect(state.exercises[1].exercise.name, equals('Squats'));
      expect(state.exercises[1].order, equals(1));
      
      expect(state.exercises[2].exercise.name, equals('Deadlift'));
      expect(state.exercises[2].order, equals(2));
    });

    test(
        'Feature: workout-tracking-system, Property 4: Template Pre-population - All exercises have default sets',
        () {
      // Property test: All template exercises should have default sets

      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(newWorkoutProvider.notifier);

      // Create template with multiple exercises
      final templateExercises = [
        const ex.Exercise(
          id: 1,
          name: 'Bench Press',
          category: 'Strength',
          muscleGroup: 'Chest',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Test description',
          instructions: 'Test instructions',
        ),
        const ex.Exercise(
          id: 2,
          name: 'Squats',
          category: 'Strength',
          muscleGroup: 'Legs',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Test description',
          instructions: 'Test instructions',
        ),
      ];

      // Load template
      notifier.loadTemplateExercises(templateExercises);

      final state = container.read(newWorkoutProvider);

      // Assert - All exercises should have default sets
      for (var i = 0; i < state.exercises.length; i++) {
        final exercise = state.exercises[i];
        
        // Should have 3 default sets
        expect(exercise.sets.length, equals(3),
            reason: 'Exercise ${exercise.exercise.name} should have 3 sets');
        
        // Each set should have default values
        for (var j = 0; j < exercise.sets.length; j++) {
          final set = exercise.sets[j];
          expect(set.setNumber, equals(j + 1),
              reason: 'Set number should be ${j + 1}');
          expect(set.reps, equals(10),
              reason: 'Default reps should be 10');
          expect(set.weight, equals(0.0),
              reason: 'Default weight should be 0.0');
          expect(set.completed, equals(false),
              reason: 'Default completed should be false');
        }
      }
    });

    test(
        'Feature: workout-tracking-system, Property 4: Template Pre-population - Large template (10 exercises)',
        () {
      // Property test: Large templates should be handled correctly

      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(newWorkoutProvider.notifier);

      // Create template with 10 exercises
      final templateExercises = List.generate(
        10,
        (index) => ex.Exercise(
          id: index + 1,
          name: 'Exercise ${index + 1}',
          category: 'Strength',
          muscleGroup: 'Chest',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Test description',
          instructions: 'Test instructions',
        ),
      );

      // Load template
      notifier.loadTemplateExercises(templateExercises);

      final state = container.read(newWorkoutProvider);

      // Assert - Should have all 10 exercises in order
      expect(state.exercises.length, equals(10));
      
      for (var i = 0; i < 10; i++) {
        expect(state.exercises[i].exercise.name, equals('Exercise ${i + 1}'));
        expect(state.exercises[i].order, equals(i));
        expect(state.exercises[i].sets.length, equals(3));
      }
    });

    test(
        'Feature: workout-tracking-system, Property 4: Template Pre-population - Replacing existing exercises',
        () {
      // Property test: Loading a template should replace existing exercises

      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(newWorkoutProvider.notifier);

      // First, add an exercise manually
      notifier.addExercise(
        const ex.Exercise(
          id: 99,
          name: 'Manual Exercise',
          category: 'Strength',
          muscleGroup: 'Arms',
          equipment: 'Free Weights',
          difficulty: 'Beginner',
          description: 'Test description',
          instructions: 'Test instructions',
        ),
      );

      var state = container.read(newWorkoutProvider);
      expect(state.exercises.length, equals(1));
      expect(state.exercises[0].exercise.name, equals('Manual Exercise'));

      // Now load a template
      final templateExercises = [
        const ex.Exercise(
          id: 1,
          name: 'Template Exercise 1',
          category: 'Strength',
          muscleGroup: 'Chest',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Test description',
          instructions: 'Test instructions',
        ),
        const ex.Exercise(
          id: 2,
          name: 'Template Exercise 2',
          category: 'Strength',
          muscleGroup: 'Legs',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'Test description',
          instructions: 'Test instructions',
        ),
      ];

      notifier.loadTemplateExercises(templateExercises);

      state = container.read(newWorkoutProvider);

      // Assert - Should have replaced with template exercises
      expect(state.exercises.length, equals(2));
      expect(state.exercises[0].exercise.name, equals('Template Exercise 1'));
      expect(state.exercises[1].exercise.name, equals('Template Exercise 2'));
      
      // Manual exercise should be gone
      expect(
        state.exercises.any((e) => e.exercise.name == 'Manual Exercise'),
        equals(false),
      );
    });

    test(
        'Feature: workout-tracking-system, Property 4: Template Pre-population - Exercise count invariant',
        () {
      // Property test: Number of exercises in state should equal template size

      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(newWorkoutProvider.notifier);

      // Test with various template sizes
      final testSizes = [0, 1, 3, 5, 10, 15];

      for (final size in testSizes) {
        // Create template with specified size
        final templateExercises = List.generate(
          size,
          (index) => ex.Exercise(
            id: index + 1,
            name: 'Exercise ${index + 1}',
            category: 'Strength',
            muscleGroup: 'Chest',
            equipment: 'Free Weights',
            difficulty: 'Intermediate',
            description: 'Test description',
            instructions: 'Test instructions',
          ),
        );

        // Load template
        notifier.loadTemplateExercises(templateExercises);

        final state = container.read(newWorkoutProvider);

        // Assert - Exercise count should match template size
        expect(
          state.exercises.length,
          equals(size),
          reason: 'Template with $size exercises should result in $size exercises in state',
        );
      }
    });

    test(
        'Feature: workout-tracking-system, Property 4: Template Pre-population - Order preservation invariant',
        () {
      // Property test: Exercise order should match template order

      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(newWorkoutProvider.notifier);

      // Create template with exercises in specific order
      final exerciseNames = [
        'Bench Press',
        'Squats',
        'Deadlift',
        'Overhead Press',
        'Barbell Row',
      ];

      final templateExercises = exerciseNames
          .asMap()
          .entries
          .map(
            (entry) => ex.Exercise(
              id: entry.key + 1,
              name: entry.value,
              category: 'Strength',
              muscleGroup: 'Chest',
              equipment: 'Free Weights',
              difficulty: 'Intermediate',
              description: 'Test description',
              instructions: 'Test instructions',
            ),
          )
          .toList();

      // Load template
      notifier.loadTemplateExercises(templateExercises);

      final state = container.read(newWorkoutProvider);

      // Assert - Order should be preserved
      for (var i = 0; i < exerciseNames.length; i++) {
        expect(
          state.exercises[i].exercise.name,
          equals(exerciseNames[i]),
          reason: 'Exercise at position $i should be ${exerciseNames[i]}',
        );
        expect(
          state.exercises[i].order,
          equals(i),
          reason: 'Exercise order field should be $i',
        );
      }
    });
  });
}
