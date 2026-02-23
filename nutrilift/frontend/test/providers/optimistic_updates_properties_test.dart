import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrilift/providers/new_workout_provider.dart';
import 'package:nutrilift/providers/workout_history_provider.dart';
import 'package:nutrilift/providers/repository_providers.dart';
import 'package:nutrilift/repositories/mock_workout_repository.dart';
import 'package:nutrilift/models/exercise.dart' as ex;
import 'package:nutrilift/models/workout_log.dart';

void main() {
  group('Property 25: Optimistic UI Updates', () {
    /// **Validates: Requirements 7.8**
    /// 
    /// Property 25: Optimistic UI Updates
    /// For any workout logging operation, the UI should update immediately 
    /// (optimistically) before receiving API confirmation, and should rollback 
    /// if the API call fails.

    test(
        'Feature: workout-tracking-system, Property 25: Optimistic UI Updates - Immediate UI update on workout submission',
        () async {
      // Property test: UI should update immediately when workout is submitted

      final mockRepo = MockWorkoutRepository();
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Setup: Create a workout
      final newWorkoutNotifier = container.read(newWorkoutProvider.notifier);
      
      newWorkoutNotifier.addExercise(
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
      );
      newWorkoutNotifier.setDuration(60);

      // Get initial workout history count
      final historyNotifier = container.read(workoutHistoryProvider.notifier);
      await historyNotifier.loadWorkouts();
      
      final initialState = container.read(workoutHistoryProvider);
      final initialCount = initialState.when(
        data: (workouts) => workouts.length,
        loading: () => 0,
        error: (_, __) => 0,
      );

      // Submit workout (this should add optimistic workout immediately)
      final submitFuture = newWorkoutNotifier.submitWorkout();
      
      // Wait for the synchronous part to execute (one microtask)
      await Future.microtask(() {});

      // The optimistic update should now be visible
      final optimisticState = container.read(workoutHistoryProvider);
      final optimisticCount = optimisticState.when(
        data: (workouts) => workouts.length,
        loading: () => 0,
        error: (_, __) => 0,
      );

      // Assert - Workout should be added immediately (optimistically)
      expect(
        optimisticCount,
        equals(initialCount + 1),
        reason: 'Workout should be added to history immediately (optimistically)',
      );

      // Wait for API call to complete
      await submitFuture;

      // Final state should still have the workout
      final finalState = container.read(workoutHistoryProvider);
      final finalCount = finalState.when(
        data: (workouts) => workouts.length,
        loading: () => 0,
        error: (_, __) => 0,
      );

      expect(
        finalCount,
        equals(initialCount + 1),
        reason: 'Workout should remain in history after API success',
      );
    });

    test(
        'Feature: workout-tracking-system, Property 25: Optimistic UI Updates - Rollback on API failure',
        () async {
      // Property test: Optimistic update should be rolled back if API fails

      final mockRepo = MockWorkoutRepository();
      // Configure mock to fail
      mockRepo.shouldFailLogWorkout = true;
      
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Setup: Create a workout
      final newWorkoutNotifier = container.read(newWorkoutProvider.notifier);
      
      newWorkoutNotifier.addExercise(
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
      );
      newWorkoutNotifier.setDuration(60);

      // Get initial workout history count
      final historyNotifier = container.read(workoutHistoryProvider.notifier);
      await historyNotifier.loadWorkouts();
      
      final initialState = container.read(workoutHistoryProvider);
      final initialCount = initialState.when(
        data: (workouts) => workouts.length,
        loading: () => 0,
        error: (_, __) => 0,
      );

      // Submit workout (this should add optimistic workout immediately)
      try {
        await newWorkoutNotifier.submitWorkout();
        fail('Should have thrown an exception');
      } catch (e) {
        // Expected to fail
      }

      // Check final state - optimistic workout should be rolled back
      final finalState = container.read(workoutHistoryProvider);
      final finalCount = finalState.when(
        data: (workouts) => workouts.length,
        loading: () => 0,
        error: (_, __) => 0,
      );

      // Assert - Workout should be removed (rolled back)
      expect(
        finalCount,
        equals(initialCount),
        reason: 'Optimistic workout should be rolled back on API failure',
      );
    });

    test(
        'Feature: workout-tracking-system, Property 25: Optimistic UI Updates - Optimistic workout has negative ID',
        () async {
      // Property test: Optimistic workouts should have negative IDs to distinguish them

      final mockRepo = MockWorkoutRepository();
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Setup: Create a workout
      final newWorkoutNotifier = container.read(newWorkoutProvider.notifier);
      
      newWorkoutNotifier.addExercise(
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
      );
      newWorkoutNotifier.setDuration(60);

      // Get initial workout history
      final historyNotifier = container.read(workoutHistoryProvider.notifier);
      await historyNotifier.loadWorkouts();

      // Submit workout
      final submitFuture = newWorkoutNotifier.submitWorkout();

      // Check immediately - optimistic workout should have negative ID
      await Future.delayed(const Duration(milliseconds: 10));
      
      final optimisticState = container.read(workoutHistoryProvider);
      
      optimisticState.when(
        data: (workouts) {
          if (workouts.isNotEmpty) {
            final newestWorkout = workouts.first;
            // Optimistic workout should have negative ID
            expect(
              newestWorkout.id != null && newestWorkout.id! < 0,
              isTrue,
              reason: 'Optimistic workout should have negative ID',
            );
          }
        },
        loading: () {},
        error: (_, __) {},
      );

      // Wait for API call to complete
      await submitFuture;

      // After API success, workout should have positive ID
      final finalState = container.read(workoutHistoryProvider);
      
      finalState.when(
        data: (workouts) {
          if (workouts.isNotEmpty) {
            final newestWorkout = workouts.first;
            // Real workout should have positive ID
            expect(
              newestWorkout.id != null && newestWorkout.id! > 0,
              isTrue,
              reason: 'Real workout should have positive ID after API success',
            );
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    });

    test(
        'Feature: workout-tracking-system, Property 25: Optimistic UI Updates - Optimistic workout appears at top of list',
        () async {
      // Property test: Optimistic workout should appear at the top (newest first)

      final mockRepo = MockWorkoutRepository();
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Setup: Load existing workouts
      final historyNotifier = container.read(workoutHistoryProvider.notifier);
      await historyNotifier.loadWorkouts();
      
      final initialState = container.read(workoutHistoryProvider);
      String? firstWorkoutNameBefore;
      initialState.when(
        data: (workouts) {
          if (workouts.isNotEmpty) {
            firstWorkoutNameBefore = workouts.first.workoutName;
          }
        },
        loading: () {},
        error: (_, __) {},
      );

      // Create a new workout with a unique name
      final newWorkoutNotifier = container.read(newWorkoutProvider.notifier);
      newWorkoutNotifier.setWorkoutName('New Optimistic Workout');
      newWorkoutNotifier.addExercise(
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
      );
      newWorkoutNotifier.setDuration(60);

      // Submit workout
      final submitFuture = newWorkoutNotifier.submitWorkout();

      // Check immediately - new workout should be at top
      await Future.delayed(const Duration(milliseconds: 10));
      
      final optimisticState = container.read(workoutHistoryProvider);
      
      optimisticState.when(
        data: (workouts) {
          if (workouts.isNotEmpty) {
            final firstWorkout = workouts.first;
            expect(
              firstWorkout.workoutName,
              equals('New Optimistic Workout'),
              reason: 'Optimistic workout should appear at top of list',
            );
          }
        },
        loading: () {},
        error: (_, __) {},
      );

      // Wait for API call to complete
      await submitFuture;

      // After API success, workout should still be at top
      final finalState = container.read(workoutHistoryProvider);
      
      finalState.when(
        data: (workouts) {
          if (workouts.isNotEmpty) {
            final firstWorkout = workouts.first;
            expect(
              firstWorkout.workoutName,
              equals('New Optimistic Workout'),
              reason: 'Workout should remain at top after API success',
            );
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    });

    test(
        'Feature: workout-tracking-system, Property 25: Optimistic UI Updates - Multiple optimistic updates',
        () async {
      // Property test: Multiple optimistic updates should all be added

      final mockRepo = MockWorkoutRepository();
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Get initial workout history count
      final historyNotifier = container.read(workoutHistoryProvider.notifier);
      await historyNotifier.loadWorkouts();
      
      final initialState = container.read(workoutHistoryProvider);
      final initialCount = initialState.when(
        data: (workouts) => workouts.length,
        loading: () => 0,
        error: (_, __) => 0,
      );

      // Submit multiple workouts
      final futures = <Future<WorkoutLog?>>[];
      
      for (var i = 0; i < 3; i++) {
        final newWorkoutNotifier = container.read(newWorkoutProvider.notifier);
        newWorkoutNotifier.setWorkoutName('Workout $i');
        newWorkoutNotifier.addExercise(
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
        );
        newWorkoutNotifier.setDuration(60);
        
        futures.add(newWorkoutNotifier.submitWorkout());
        
        // Small delay between submissions
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Check immediately - all workouts should be added optimistically
      await Future.delayed(const Duration(milliseconds: 10));
      
      final optimisticState = container.read(workoutHistoryProvider);
      final optimisticCount = optimisticState.when(
        data: (workouts) => workouts.length,
        loading: () => 0,
        error: (_, __) => 0,
      );

      // Assert - All workouts should be added
      expect(
        optimisticCount,
        equals(initialCount + 3),
        reason: 'All 3 workouts should be added optimistically',
      );

      // Wait for all API calls to complete
      await Future.wait(futures);

      // Final state should still have all workouts
      final finalState = container.read(workoutHistoryProvider);
      final finalCount = finalState.when(
        data: (workouts) => workouts.length,
        loading: () => 0,
        error: (_, __) => 0,
      );

      expect(
        finalCount,
        equals(initialCount + 3),
        reason: 'All 3 workouts should remain after API success',
      );
    });

    test(
        'Feature: workout-tracking-system, Property 25: Optimistic UI Updates - Optimistic workout contains all exercise data',
        () async {
      // Property test: Optimistic workout should contain all exercise information

      final mockRepo = MockWorkoutRepository();
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Setup: Create a workout with multiple exercises
      final newWorkoutNotifier = container.read(newWorkoutProvider.notifier);
      
      newWorkoutNotifier.addExercise(
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
      );
      
      newWorkoutNotifier.addExercise(
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
      );
      
      newWorkoutNotifier.setDuration(60);

      // Get initial workout history
      final historyNotifier = container.read(workoutHistoryProvider.notifier);
      await historyNotifier.loadWorkouts();

      // Submit workout
      final submitFuture = newWorkoutNotifier.submitWorkout();

      // Check immediately - optimistic workout should have all exercises
      await Future.delayed(const Duration(milliseconds: 10));
      
      final optimisticState = container.read(workoutHistoryProvider);
      
      optimisticState.when(
        data: (workouts) {
          if (workouts.isNotEmpty) {
            final newestWorkout = workouts.first;
            
            // Should have 2 exercises
            expect(
              newestWorkout.exercises.length,
              equals(2),
              reason: 'Optimistic workout should have all exercises',
            );
            
            // Check exercise names
            expect(
              newestWorkout.exercises[0].exerciseName,
              equals('Bench Press'),
            );
            expect(
              newestWorkout.exercises[1].exerciseName,
              equals('Squats'),
            );
            
            // Should have duration
            expect(
              newestWorkout.duration,
              equals(60),
            );
            
            // Should have estimated calories
            expect(
              newestWorkout.caloriesBurned > 0,
              isTrue,
              reason: 'Optimistic workout should have estimated calories',
            );
          }
        },
        loading: () {},
        error: (_, __) {},
      );

      // Wait for API call to complete
      await submitFuture;
    });

    test(
        'Feature: workout-tracking-system, Property 25: Optimistic UI Updates - Workout data preserved after replacement',
        () async {
      // Property test: Core workout data should be preserved when optimistic workout is replaced

      final mockRepo = MockWorkoutRepository();
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Setup: Create a workout
      final newWorkoutNotifier = container.read(newWorkoutProvider.notifier);
      newWorkoutNotifier.setWorkoutName('Test Workout');
      newWorkoutNotifier.addExercise(
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
      );
      newWorkoutNotifier.setDuration(45);

      // Get initial workout history
      final historyNotifier = container.read(workoutHistoryProvider.notifier);
      await historyNotifier.loadWorkouts();

      // Submit workout
      await newWorkoutNotifier.submitWorkout();

      // Check final state - workout data should be preserved
      final finalState = container.read(workoutHistoryProvider);
      
      finalState.when(
        data: (workouts) {
          if (workouts.isNotEmpty) {
            final newestWorkout = workouts.first;
            
            // Core data should be preserved
            expect(
              newestWorkout.workoutName,
              equals('Test Workout'),
              reason: 'Workout name should be preserved',
            );
            
            expect(
              newestWorkout.duration,
              equals(45),
              reason: 'Duration should be preserved',
            );
            
            expect(
              newestWorkout.exercises.length,
              equals(1),
              reason: 'Exercise count should be preserved',
            );
            
            expect(
              newestWorkout.exercises[0].exerciseName,
              equals('Bench Press'),
              reason: 'Exercise name should be preserved',
            );
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    });

    test(
        'Feature: workout-tracking-system, Property 25: Optimistic UI Updates - No duplicate workouts after success',
        () async {
      // Property test: After API success, there should be no duplicate workouts

      final mockRepo = MockWorkoutRepository();
      final container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // Setup: Create a workout with unique name
      final newWorkoutNotifier = container.read(newWorkoutProvider.notifier);
      newWorkoutNotifier.setWorkoutName('Unique Workout Name');
      newWorkoutNotifier.addExercise(
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
      );
      newWorkoutNotifier.setDuration(60);

      // Get initial workout history
      final historyNotifier = container.read(workoutHistoryProvider.notifier);
      await historyNotifier.loadWorkouts();

      // Submit workout
      await newWorkoutNotifier.submitWorkout();

      // Check final state - should not have duplicates
      final finalState = container.read(workoutHistoryProvider);
      
      finalState.when(
        data: (workouts) {
          // Count workouts with the unique name
          final matchingWorkouts = workouts
              .where((w) => w.workoutName == 'Unique Workout Name')
              .toList();
          
          expect(
            matchingWorkouts.length,
            equals(1),
            reason: 'Should have exactly one workout with the unique name (no duplicates)',
          );
        },
        loading: () {},
        error: (_, __) {},
      );
    });
  });
}
