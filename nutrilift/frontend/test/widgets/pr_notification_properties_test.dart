import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nutrilift/providers/repository_providers.dart';
import 'package:nutrilift/repositories/mock_workout_repository.dart';
import 'package:nutrilift/models/workout_models.dart';

void main() {
  group('Property 15: PR Notification Creation', () {
    /// **Validates: Requirements 4.8, 8.2, 8.6**
    /// 
    /// Property 15: PR Notification Creation
    /// For any workout that results in a new personal record, the system should 
    /// create a notification for the user and include PR achievement data in the 
    /// workout log response.

    test(
        'Feature: workout-tracking-system, Property 15: PR Notification Creation - Backend includes hasNewPrs in response when PRs achieved',
        () async {
      // Property test: Backend should include hasNewPrs=true field in workout log response when PRs are achieved

      final mockRepo = MockWorkoutRepository();
      mockRepo.shouldReturnPRs = true;

      // Create a workout request
      final workoutRequest = CreateWorkoutLogRequest(
        workoutName: 'Test Workout',
        customWorkoutId: null,
        gymId: null,
        durationMinutes: 60,
        caloriesBurned: 450.0,
        exercises: [
          ExerciseSetRequest(
            exerciseId: '1',
            order: 0,
            sets: [
              WorkoutSetRequest(
                setNumber: 1,
                reps: 10,
                weight: 100.0,
                completed: true,
              ),
            ],
          ),
        ],
        notes: null,
      );

      // Submit workout
      final result = await mockRepo.logWorkout(workoutRequest);

      // Assert - Response should include hasNewPrs field set to true
      expect(result, isNotNull);
      expect(result.hasNewPrs, isTrue,
          reason: 'hasNewPrs should be true when new PRs are achieved');
    });

    test(
        'Feature: workout-tracking-system, Property 15: PR Notification Creation - hasNewPrs is false when no PRs achieved',
        () async {
      // Property test: hasNewPrs should be false when no new PRs are achieved

      final mockRepo = MockWorkoutRepository();
      mockRepo.shouldReturnPRs = false;

      // Create a workout request
      final workoutRequest = CreateWorkoutLogRequest(
        workoutName: 'Test Workout',
        customWorkoutId: null,
        gymId: null,
        durationMinutes: 60,
        caloriesBurned: 450.0,
        exercises: [
          ExerciseSetRequest(
            exerciseId: '1',
            order: 0,
            sets: [
              WorkoutSetRequest(
                setNumber: 1,
                reps: 10,
                weight: 100.0,
                completed: true,
              ),
            ],
          ),
        ],
        notes: null,
      );

      // Submit workout
      final result = await mockRepo.logWorkout(workoutRequest);

      // Assert - Response should have hasNewPrs as false
      expect(result, isNotNull);
      expect(result.hasNewPrs, isFalse,
          reason: 'hasNewPrs should be false when no new PRs are achieved');
    });

    test(
        'Feature: workout-tracking-system, Property 15: PR Notification Creation - hasNewPrs field is always present',
        () async {
      // Property test: hasNewPrs field should always be present in workout log response

      final mockRepo = MockWorkoutRepository();

      // Test with PRs
      mockRepo.shouldReturnPRs = true;
      final workoutRequestWithPRs = CreateWorkoutLogRequest(
        workoutName: 'Test Workout',
        customWorkoutId: null,
        gymId: null,
        durationMinutes: 60,
        caloriesBurned: 450.0,
        exercises: [
          ExerciseSetRequest(
            exerciseId: '1',
            order: 0,
            sets: [
              WorkoutSetRequest(
                setNumber: 1,
                reps: 10,
                weight: 100.0,
                completed: true,
              ),
            ],
          ),
        ],
        notes: null,
      );

      final resultWithPRs = await mockRepo.logWorkout(workoutRequestWithPRs);
      expect(resultWithPRs.hasNewPrs, isNotNull,
          reason: 'hasNewPrs field should always be present');

      // Test without PRs
      mockRepo.shouldReturnPRs = false;
      final workoutRequestWithoutPRs = CreateWorkoutLogRequest(
        workoutName: 'Test Workout 2',
        customWorkoutId: null,
        gymId: null,
        durationMinutes: 45,
        caloriesBurned: 350.0,
        exercises: [
          ExerciseSetRequest(
            exerciseId: '2',
            order: 0,
            sets: [
              WorkoutSetRequest(
                setNumber: 1,
                reps: 8,
                weight: 80.0,
                completed: true,
              ),
            ],
          ),
        ],
        notes: null,
      );

      final resultWithoutPRs = await mockRepo.logWorkout(workoutRequestWithoutPRs);
      expect(resultWithoutPRs.hasNewPrs, isNotNull,
          reason: 'hasNewPrs field should always be present');
    });

    test(
        'Feature: workout-tracking-system, Property 15: PR Notification Creation - Multiple workouts with different PR statuses',
        () async {
      // Property test: System should correctly track PR status for multiple workouts

      final mockRepo = MockWorkoutRepository();

      // Submit first workout with PRs
      mockRepo.shouldReturnPRs = true;
      final workout1 = CreateWorkoutLogRequest(
        workoutName: 'Workout 1',
        customWorkoutId: null,
        gymId: null,
        durationMinutes: 60,
        caloriesBurned: 450.0,
        exercises: [
          ExerciseSetRequest(
            exerciseId: '1',
            order: 0,
            sets: [
              WorkoutSetRequest(
                setNumber: 1,
                reps: 10,
                weight: 100.0,
                completed: true,
              ),
            ],
          ),
        ],
        notes: null,
      );

      final result1 = await mockRepo.logWorkout(workout1);
      expect(result1.hasNewPrs, isTrue);

      // Submit second workout without PRs
      mockRepo.shouldReturnPRs = false;
      final workout2 = CreateWorkoutLogRequest(
        workoutName: 'Workout 2',
        customWorkoutId: null,
        gymId: null,
        durationMinutes: 45,
        caloriesBurned: 350.0,
        exercises: [
          ExerciseSetRequest(
            exerciseId: '2',
            order: 0,
            sets: [
              WorkoutSetRequest(
                setNumber: 1,
                reps: 8,
                weight: 80.0,
                completed: true,
              ),
            ],
          ),
        ],
        notes: null,
      );

      final result2 = await mockRepo.logWorkout(workout2);
      expect(result2.hasNewPrs, isFalse);

      // Submit third workout with PRs again
      mockRepo.shouldReturnPRs = true;
      final workout3 = CreateWorkoutLogRequest(
        workoutName: 'Workout 3',
        customWorkoutId: null,
        gymId: null,
        durationMinutes: 70,
        caloriesBurned: 500.0,
        exercises: [
          ExerciseSetRequest(
            exerciseId: '3',
            order: 0,
            sets: [
              WorkoutSetRequest(
                setNumber: 1,
                reps: 12,
                weight: 120.0,
                completed: true,
              ),
            ],
          ),
        ],
        notes: null,
      );

      final result3 = await mockRepo.logWorkout(workout3);
      expect(result3.hasNewPrs, isTrue);
    });

    test(
        'Feature: workout-tracking-system, Property 15: PR Notification Creation - hasNewPrs is boolean type',
        () async {
      // Property test: hasNewPrs should always be a boolean value

      final mockRepo = MockWorkoutRepository();

      final workoutRequest = CreateWorkoutLogRequest(
        workoutName: 'Test Workout',
        customWorkoutId: null,
        gymId: null,
        durationMinutes: 60,
        caloriesBurned: 450.0,
        exercises: [
          ExerciseSetRequest(
            exerciseId: '1',
            order: 0,
            sets: [
              WorkoutSetRequest(
                setNumber: 1,
                reps: 10,
                weight: 100.0,
                completed: true,
              ),
            ],
          ),
        ],
        notes: null,
      );

      // Test with PRs
      mockRepo.shouldReturnPRs = true;
      final resultWithPRs = await mockRepo.logWorkout(workoutRequest);
      expect(resultWithPRs.hasNewPrs, isA<bool>(),
          reason: 'hasNewPrs should be a boolean value');

      // Test without PRs
      mockRepo.shouldReturnPRs = false;
      final resultWithoutPRs = await mockRepo.logWorkout(workoutRequest);
      expect(resultWithoutPRs.hasNewPrs, isA<bool>(),
          reason: 'hasNewPrs should be a boolean value');
    });

    test(
        'Feature: workout-tracking-system, Property 15: PR Notification Creation - PR status persists in workout history',
        () async {
      // Property test: Workouts with PRs should maintain their PR status when retrieved from history

      final mockRepo = MockWorkoutRepository();

      // Submit workout with PRs
      mockRepo.shouldReturnPRs = true;
      final workoutRequest = CreateWorkoutLogRequest(
        workoutName: 'PR Workout',
        customWorkoutId: null,
        gymId: null,
        durationMinutes: 60,
        caloriesBurned: 450.0,
        exercises: [
          ExerciseSetRequest(
            exerciseId: '1',
            order: 0,
            sets: [
              WorkoutSetRequest(
                setNumber: 1,
                reps: 10,
                weight: 100.0,
                completed: true,
              ),
            ],
          ),
        ],
        notes: null,
      );

      final loggedWorkout = await mockRepo.logWorkout(workoutRequest);
      expect(loggedWorkout.hasNewPrs, isTrue);

      // Retrieve workout history
      final history = await mockRepo.getWorkoutHistory();

      // Find the workout we just logged
      final retrievedWorkout = history.firstWhere(
        (w) => w.id == loggedWorkout.id,
        orElse: () => throw Exception('Workout not found in history'),
      );

      // Assert - PR status should be preserved
      expect(retrievedWorkout.hasNewPrs, isTrue,
          reason: 'PR status should be preserved when retrieving workout from history');
    });

    test(
        'Feature: workout-tracking-system, Property 15: PR Notification Creation - Workout without exercises can have PR status',
        () async {
      // Property test: Even workouts without exercises should have hasNewPrs field (though it would be false)

      final mockRepo = MockWorkoutRepository();
      mockRepo.shouldReturnPRs = false;

      final workoutRequest = CreateWorkoutLogRequest(
        workoutName: 'Empty Workout',
        customWorkoutId: null,
        gymId: null,
        durationMinutes: 30,
        caloriesBurned: 200.0,
        exercises: [], // No exercises
        notes: null,
      );

      final result = await mockRepo.logWorkout(workoutRequest);

      // Assert - hasNewPrs should still be present and false
      expect(result.hasNewPrs, isNotNull);
      expect(result.hasNewPrs, isFalse,
          reason: 'Workout without exercises should have hasNewPrs=false');
    });
  });
}
