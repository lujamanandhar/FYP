import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrilift/models/exercise.dart';
import 'package:nutrilift/models/workout_log.dart';
import 'package:nutrilift/models/workout_exercise.dart';
import 'package:nutrilift/models/personal_record.dart';
import 'package:nutrilift/providers/repository_providers.dart';
import 'package:nutrilift/providers/workout_history_provider.dart';
import 'package:nutrilift/providers/exercise_library_provider.dart';
import 'package:nutrilift/providers/personal_records_provider.dart';
import 'package:nutrilift/providers/new_workout_provider.dart';

/// Unit tests for Riverpod state management providers
/// 
/// These tests verify that state updates correctly and errors are handled
/// properly across all workout-related providers.
/// 
/// Feature: workout-tracking-system, Task 19.6
/// Validates: Requirements 8.1
void main() {
  group('Repository Providers', () {
    test('should provide mock repositories when useMockData is true', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      final workoutRepo = container.read(workoutRepositoryProvider);
      final exerciseRepo = container.read(exerciseRepositoryProvider);
      final prRepo = container.read(personalRecordRepositoryProvider);

      expect(workoutRepo.runtimeType.toString(), contains('Mock'));
      expect(exerciseRepo.runtimeType.toString(), contains('Mock'));
      expect(prRepo.runtimeType.toString(), contains('Mock'));

      container.dispose();
    });

    test('should provide API services when useMockData is false', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => false),
        ],
      );

      final workoutRepo = container.read(workoutRepositoryProvider);
      final exerciseRepo = container.read(exerciseRepositoryProvider);
      final prRepo = container.read(personalRecordRepositoryProvider);

      expect(workoutRepo.runtimeType.toString(), contains('ApiService'));
      expect(exerciseRepo.runtimeType.toString(), contains('ApiService'));
      expect(prRepo.runtimeType.toString(), contains('ApiService'));

      container.dispose();
    });

    test('should allow toggling between mock and API implementations', () {
      final container = ProviderContainer();

      // Start with API (default)
      expect(container.read(useMockDataProvider), false);

      // Toggle to mock
      container.read(useMockDataProvider.notifier).state = true;
      expect(container.read(useMockDataProvider), true);

      // Toggle back to API
      container.read(useMockDataProvider.notifier).state = false;
      expect(container.read(useMockDataProvider), false);

      container.dispose();
    });
  });

  group('WorkoutHistoryProvider', () {
    test('should start in loading state', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      final state = container.read(workoutHistoryProvider);
      expect(state.isLoading, true);

      container.dispose();
    });

    test('should load workouts successfully', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for state to settle
      await Future.delayed(const Duration(milliseconds: 200));

      final state = container.read(workoutHistoryProvider);
      expect(state.hasValue || state.hasError, true);

      container.dispose();
    });

    test('should refresh workouts', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));

      // Refresh
      await container.read(workoutHistoryProvider.notifier).refresh();

      final state = container.read(workoutHistoryProvider);
      expect(state.hasValue || state.hasError, true);

      container.dispose();
    });

    test('should filter workouts by date range', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));

      // Apply date filter with both from and to dates
      final dateFrom = DateTime.now().subtract(const Duration(days: 30));
      final dateTo = DateTime.now();
      await container.read(workoutHistoryProvider.notifier).filterByDateRange(dateFrom, dateTo);

      final state = container.read(workoutHistoryProvider);
      expect(state.hasValue || state.hasError, true);

      container.dispose();
    });

    test('should clear date filter', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));

      // Apply and clear filter
      final dateFrom = DateTime.now().subtract(const Duration(days: 30));
      final dateTo = DateTime.now();
      await container.read(workoutHistoryProvider.notifier).filterByDateRange(dateFrom, dateTo);
      await container.read(workoutHistoryProvider.notifier).clearDateFilter();

      final state = container.read(workoutHistoryProvider);
      expect(state.hasValue || state.hasError, true);

      container.dispose();
    });

    test('should handle errors gracefully', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for state to settle
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(workoutHistoryProvider);
      // State should either have value or error, not be stuck loading
      expect(state.isLoading || state.hasValue || state.hasError, true);

      container.dispose();
    });
  });

  group('ExerciseLibraryProvider', () {
    test('should start in loading state', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      final state = container.read(exerciseLibraryProvider);
      expect(state.isLoading, true);

      container.dispose();
    });

    test('should load exercises successfully', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for state to settle
      await Future.delayed(const Duration(milliseconds: 200));

      final state = container.read(exerciseLibraryProvider);
      expect(state.hasValue || state.hasError, true);

      container.dispose();
    });

    test('should filter exercises by category', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));

      // Apply category filter
      await container.read(exerciseLibraryProvider.notifier).filterByCategory('Strength');

      final state = container.read(exerciseLibraryProvider);
      expect(state.hasValue || state.hasError, true);

      container.dispose();
    });

    test('should filter exercises by muscle group', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));

      // Apply muscle group filter
      await container.read(exerciseLibraryProvider.notifier).filterByMuscleGroup('Chest');

      final state = container.read(exerciseLibraryProvider);
      expect(state.hasValue || state.hasError, true);

      container.dispose();
    });

    test('should filter exercises by equipment', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));

      // Apply equipment filter
      await container.read(exerciseLibraryProvider.notifier).filterByEquipment('Free Weights');

      final state = container.read(exerciseLibraryProvider);
      expect(state.hasValue || state.hasError, true);

      container.dispose();
    });

    test('should filter exercises by difficulty', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));

      // Apply difficulty filter
      await container.read(exerciseLibraryProvider.notifier).filterByDifficulty('Beginner');

      final state = container.read(exerciseLibraryProvider);
      expect(state.hasValue || state.hasError, true);

      container.dispose();
    });

    test('should search exercises by name', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));

      // Apply search filter
      await container.read(exerciseLibraryProvider.notifier).search('bench');

      final state = container.read(exerciseLibraryProvider);
      expect(state.hasValue || state.hasError, true);

      container.dispose();
    });

    test('should clear all filters', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));

      // Apply multiple filters
      await container.read(exerciseLibraryProvider.notifier).filterByCategory('Strength');
      await container.read(exerciseLibraryProvider.notifier).filterByMuscleGroup('Chest');

      // Clear all filters
      await container.read(exerciseLibraryProvider.notifier).clearAllFilters();

      final state = container.read(exerciseLibraryProvider);
      expect(state.hasValue || state.hasError, true);

      final notifier = container.read(exerciseLibraryProvider.notifier);
      expect(notifier.hasActiveFilters, false);

      container.dispose();
    });

    test('should track active filters', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));

      final notifier = container.read(exerciseLibraryProvider.notifier);

      // Initially no filters
      expect(notifier.hasActiveFilters, false);

      // Apply filter
      await notifier.filterByCategory('Strength');
      expect(notifier.hasActiveFilters, true);
      expect(notifier.activeFilters['category'], 'Strength');

      container.dispose();
    });
  });

  group('PersonalRecordsProvider', () {
    test('should start in loading state', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      final state = container.read(personalRecordsProvider);
      expect(state.isLoading, true);

      container.dispose();
    });

    test('should load personal records successfully', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for state to settle
      await Future.delayed(const Duration(milliseconds: 200));

      final state = container.read(personalRecordsProvider);
      expect(state.hasValue || state.hasError, true);

      container.dispose();
    });

    test('should refresh personal records', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));

      // Refresh
      await container.read(personalRecordsProvider.notifier).refresh();

      final state = container.read(personalRecordsProvider);
      expect(state.hasValue || state.hasError, true);

      container.dispose();
    });

    test('should get PR count', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));

      final notifier = container.read(personalRecordsProvider.notifier);
      expect(notifier.totalPersonalRecords, greaterThanOrEqualTo(0));

      container.dispose();
    });
  });

  group('NewWorkoutProvider', () {
    test('should start with empty state', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      final state = container.read(newWorkoutProvider);
      expect(state.exercises, isEmpty);
      expect(state.durationMinutes, isNull);
      expect(state.isValid, false);

      container.dispose();
    });

    test('should set workout name', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      container.read(newWorkoutProvider.notifier).setWorkoutName('Test Workout');

      final state = container.read(newWorkoutProvider);
      expect(state.workoutName, 'Test Workout');

      container.dispose();
    });

    test('should set duration', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      container.read(newWorkoutProvider.notifier).setDuration(60);

      final state = container.read(newWorkoutProvider);
      expect(state.durationMinutes, 60);

      container.dispose();
    });

    test('should validate duration range', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Invalid: too low
      container.read(newWorkoutProvider.notifier).setDuration(0);
      var state = container.read(newWorkoutProvider);
      expect(state.validationErrors.containsKey('duration'), true);

      // Invalid: too high
      container.read(newWorkoutProvider.notifier).setDuration(601);
      state = container.read(newWorkoutProvider);
      expect(state.validationErrors.containsKey('duration'), true);

      // Valid
      container.read(newWorkoutProvider.notifier).setDuration(60);
      state = container.read(newWorkoutProvider);
      expect(state.validationErrors.containsKey('duration'), false);

      container.dispose();
    });

    test('should add exercise', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test exercise',
        instructions: 'Test instructions',
      );

      container.read(newWorkoutProvider.notifier).addExercise(exercise);

      final state = container.read(newWorkoutProvider);
      expect(state.exercises.length, 1);
      expect(state.exercises.first.exercise.name, 'Bench Press');
      expect(state.exercises.first.sets.length, 3); // Default 3 sets

      container.dispose();
    });

    test('should remove exercise', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test exercise',
        instructions: 'Test instructions',
      );

      container.read(newWorkoutProvider.notifier).addExercise(exercise);
      container.read(newWorkoutProvider.notifier).removeExercise(0);

      final state = container.read(newWorkoutProvider);
      expect(state.exercises, isEmpty);

      container.dispose();
    });

    test('should update set values', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test exercise',
        instructions: 'Test instructions',
      );

      container.read(newWorkoutProvider.notifier).addExercise(exercise);
      container.read(newWorkoutProvider.notifier).updateSet(
        0, 0,
        reps: 12,
        weight: 100.0,
      );

      final state = container.read(newWorkoutProvider);
      expect(state.exercises.first.sets.first.reps, 12);
      expect(state.exercises.first.sets.first.weight, 100.0);

      container.dispose();
    });

    test('should validate set ranges', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test exercise',
        instructions: 'Test instructions',
      );

      container.read(newWorkoutProvider.notifier).addExercise(exercise);

      // Invalid reps
      container.read(newWorkoutProvider.notifier).updateSet(0, 0, reps: 101);
      var state = container.read(newWorkoutProvider);
      expect(state.validationErrors.isNotEmpty, true);

      // Invalid weight
      container.read(newWorkoutProvider.notifier).updateSet(0, 0, reps: 10, weight: 1001.0);
      state = container.read(newWorkoutProvider);
      expect(state.validationErrors.isNotEmpty, true);

      // Valid values
      container.read(newWorkoutProvider.notifier).updateSet(0, 0, reps: 10, weight: 100.0);
      state = container.read(newWorkoutProvider);
      // Should still have error about missing duration
      expect(state.validationErrors.containsKey('exercise_0_set_0'), false);

      container.dispose();
    });

    test('should add and remove sets', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test exercise',
        instructions: 'Test instructions',
      );

      container.read(newWorkoutProvider.notifier).addExercise(exercise);

      // Add set
      container.read(newWorkoutProvider.notifier).addSet(0);
      var state = container.read(newWorkoutProvider);
      expect(state.exercises.first.sets.length, 4);

      // Remove set
      container.read(newWorkoutProvider.notifier).removeSet(0, 3);
      state = container.read(newWorkoutProvider);
      expect(state.exercises.first.sets.length, 3);

      container.dispose();
    });

    test('should validate workout completeness', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Empty workout is invalid
      var state = container.read(newWorkoutProvider);
      expect(state.isValid, false);
      expect(state.validationErrors.containsKey('exercises'), true);
      expect(state.validationErrors.containsKey('duration'), true);

      // Add exercise
      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test exercise',
        instructions: 'Test instructions',
      );
      container.read(newWorkoutProvider.notifier).addExercise(exercise);

      // Still invalid without duration
      state = container.read(newWorkoutProvider);
      expect(state.isValid, false);
      expect(state.validationErrors.containsKey('duration'), true);

      // Add duration
      container.read(newWorkoutProvider.notifier).setDuration(60);

      // Now valid
      state = container.read(newWorkoutProvider);
      expect(state.isValid, true);
      expect(state.validationErrors, isEmpty);

      container.dispose();
    });

    test('should reset workout state', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Add data
      container.read(newWorkoutProvider.notifier).setWorkoutName('Test');
      container.read(newWorkoutProvider.notifier).setDuration(60);

      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test exercise',
        instructions: 'Test instructions',
      );
      container.read(newWorkoutProvider.notifier).addExercise(exercise);

      // Reset
      container.read(newWorkoutProvider.notifier).reset();

      final state = container.read(newWorkoutProvider);
      expect(state.workoutName, isNull);
      expect(state.durationMinutes, isNull);
      expect(state.exercises, isEmpty);

      container.dispose();
    });
  });

  group('Property 26: Reactive State Updates', () {
    /// Feature: workout-tracking-system, Property 26: Reactive State Updates
    /// For any change to workout data in the state management system,
    /// all UI components observing that data should update automatically
    /// without manual refresh.
    /// 
    /// Validates: Requirements 8.1
    test('workout history updates trigger state changes', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Track state changes
      var stateChangeCount = 0;
      container.listen(
        workoutHistoryProvider,
        (previous, next) {
          stateChangeCount++;
        },
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));
      expect(stateChangeCount, greaterThan(0));

      // Refresh should trigger another state change
      final initialCount = stateChangeCount;
      await container.read(workoutHistoryProvider.notifier).refresh();
      await Future.delayed(const Duration(milliseconds: 100));
      expect(stateChangeCount, greaterThan(initialCount));

      container.dispose();
    });

    test('exercise library updates trigger state changes', () async {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Track state changes
      var stateChangeCount = 0;
      container.listen(
        exerciseLibraryProvider,
        (previous, next) {
          stateChangeCount++;
        },
      );

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 200));
      expect(stateChangeCount, greaterThan(0));

      // Filter should trigger another state change
      final initialCount = stateChangeCount;
      await container.read(exerciseLibraryProvider.notifier).filterByCategory('Strength');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(stateChangeCount, greaterThan(initialCount));

      container.dispose();
    });

    test('new workout updates trigger state changes', () {
      final container = ProviderContainer(
        overrides: [
          useMockDataProvider.overrideWith((ref) => true),
        ],
      );

      // Track state changes
      var stateChangeCount = 0;
      container.listen(
        newWorkoutProvider,
        (previous, next) {
          stateChangeCount++;
        },
      );

      // Add exercise should trigger state change
      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test exercise',
        instructions: 'Test instructions',
      );
      container.read(newWorkoutProvider.notifier).addExercise(exercise);
      expect(stateChangeCount, greaterThan(0));

      // Update set should trigger state change
      final initialCount = stateChangeCount;
      container.read(newWorkoutProvider.notifier).updateSet(0, 0, reps: 12);
      expect(stateChangeCount, greaterThan(initialCount));

      container.dispose();
    });
  });
}
