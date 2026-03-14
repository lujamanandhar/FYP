import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrilift/models/workout_log.dart';
import 'package:nutrilift/models/workout_exercise.dart';
import 'package:nutrilift/models/exercise.dart';
import 'package:nutrilift/models/personal_record.dart';
import 'package:nutrilift/services/workout_cache_service.dart';
import 'package:nutrilift/repositories/cached_workout_repository.dart';
import 'package:nutrilift/repositories/cached_exercise_repository.dart';
import 'package:nutrilift/repositories/cached_personal_record_repository.dart';
import 'package:nutrilift/services/workout_api_service.dart';
import 'package:nutrilift/services/exercise_api_service.dart';
import 'package:nutrilift/services/personal_record_api_service.dart';
import 'package:nutrilift/services/dio_client.dart';
import 'package:dio/dio.dart';

void main() {
  group('Property 28: Data Caching (Frontend Portion)', () {
    /// **Validates: Requirements 8.5, 12.6, 12.7, 14.4, 15.10**
    /// 
    /// Property 28: Data Caching
    /// 
    /// For any data fetched from the backend (workouts, exercises, PRs, statistics),
    /// the system should cache it locally and serve cached data when offline or for
    /// improved performance.

    late WorkoutCacheService cacheService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      cacheService = WorkoutCacheService(prefs);
    });

    test('Feature: workout-tracking-system, Property 28: Data Caching - Workout history caching and retrieval', () async {
      // Property test: For any list of workouts, caching and retrieval should preserve data
      
      final now = DateTime.now();
      final workouts = [
        WorkoutLog(
          id: 1,
          user: 1,
          customWorkoutId: 1,
          workoutName: 'Push Day',
          gym: 1,
          gymName: "Gold's Gym",
          date: now.subtract(const Duration(days: 2)),
          duration: 60,
          caloriesBurned: 450.5,
          notes: 'Great workout!',
          exercises: [
            WorkoutExercise(
              id: 1,
              exerciseId: 1,
              exerciseName: 'Bench Press',
              sets: 3,
              reps: 10,
              weight: 100.0,
              volume: 3000.0,
              order: 0,
            ),
          ],
          hasNewPrs: true,
          createdAt: now.subtract(const Duration(days: 2)),
          updatedAt: now.subtract(const Duration(days: 2)),
        ),
        WorkoutLog(
          id: 2,
          user: 1,
          customWorkoutId: 2,
          workoutName: 'Leg Day',
          gym: null,
          gymName: null,
          date: now.subtract(const Duration(days: 4)),
          duration: 75,
          caloriesBurned: 520.0,
          notes: null,
          exercises: [
            WorkoutExercise(
              id: 2,
              exerciseId: 3,
              exerciseName: 'Squats',
              sets: 4,
              reps: 12,
              weight: 120.0,
              volume: 5760.0,
              order: 0,
            ),
          ],
          hasNewPrs: false,
          createdAt: now.subtract(const Duration(days: 4)),
          updatedAt: now.subtract(const Duration(days: 4)),
        ),
      ];

      // Cache the workouts
      await cacheService.cacheWorkoutHistory(workouts);

      // Retrieve cached workouts
      final cachedWorkouts = await cacheService.getCachedWorkoutHistory();

      // Verify data integrity
      expect(cachedWorkouts, isNotNull);
      expect(cachedWorkouts!.length, equals(workouts.length));
      
      for (int i = 0; i < workouts.length; i++) {
        expect(cachedWorkouts[i].id, equals(workouts[i].id));
        expect(cachedWorkouts[i].workoutName, equals(workouts[i].workoutName));
        expect(cachedWorkouts[i].duration, equals(workouts[i].duration));
        expect(cachedWorkouts[i].caloriesBurned, equals(workouts[i].caloriesBurned));
        expect(cachedWorkouts[i].hasNewPrs, equals(workouts[i].hasNewPrs));
        expect(cachedWorkouts[i].exercises.length, equals(workouts[i].exercises.length));
      }
    });

    test('Feature: workout-tracking-system, Property 28: Data Caching - Exercise library caching and retrieval', () async {
      // Property test: For any list of exercises, caching and retrieval should preserve data
      
      final exercises = [
        Exercise(
          id: 1,
          name: 'Bench Press',
          category: 'Strength',
          muscleGroup: 'Chest',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'A compound upper body exercise',
          instructions: 'Lie on bench, lower bar to chest, press up',
          imageUrl: 'https://example.com/bench-press.jpg',
          videoUrl: 'https://youtube.com/watch?v=...',
        ),
        Exercise(
          id: 2,
          name: 'Squats',
          category: 'Strength',
          muscleGroup: 'Legs',
          equipment: 'Free Weights',
          difficulty: 'Intermediate',
          description: 'A compound lower body exercise',
          instructions: 'Stand with bar on shoulders, squat down, stand up',
          imageUrl: 'https://example.com/squats.jpg',
          videoUrl: null,
        ),
        Exercise(
          id: 3,
          name: 'Push-ups',
          category: 'Bodyweight',
          muscleGroup: 'Chest',
          equipment: 'Bodyweight',
          difficulty: 'Beginner',
          description: 'A bodyweight upper body exercise',
          instructions: 'Start in plank, lower body, push up',
          imageUrl: null,
          videoUrl: null,
        ),
      ];

      // Cache the exercises
      await cacheService.cacheExercises(exercises);

      // Retrieve cached exercises
      final cachedExercises = await cacheService.getCachedExercises();

      // Verify data integrity
      expect(cachedExercises, isNotNull);
      expect(cachedExercises!.length, equals(exercises.length));
      
      for (int i = 0; i < exercises.length; i++) {
        expect(cachedExercises[i].id, equals(exercises[i].id));
        expect(cachedExercises[i].name, equals(exercises[i].name));
        expect(cachedExercises[i].category, equals(exercises[i].category));
        expect(cachedExercises[i].muscleGroup, equals(exercises[i].muscleGroup));
        expect(cachedExercises[i].equipment, equals(exercises[i].equipment));
        expect(cachedExercises[i].difficulty, equals(exercises[i].difficulty));
      }
    });

    test('Feature: workout-tracking-system, Property 28: Data Caching - Personal records caching and retrieval', () async {
      // Property test: For any list of PRs, caching and retrieval should preserve data
      
      final now = DateTime.now();
      final prs = [
        PersonalRecord(
          id: 1,
          exerciseId: 1,
          exerciseName: 'Bench Press',
          maxWeight: 120.0,
          maxReps: 12,
          maxVolume: 4320.0,
          achievedDate: now.subtract(const Duration(days: 5)),
          improvementPercentage: 15.5,
        ),
        PersonalRecord(
          id: 2,
          exerciseId: 3,
          exerciseName: 'Squats',
          maxWeight: 150.0,
          maxReps: 10,
          maxVolume: 4500.0,
          achievedDate: now.subtract(const Duration(days: 7)),
          improvementPercentage: 10.2,
        ),
        PersonalRecord(
          id: 3,
          exerciseId: 5,
          exerciseName: 'Deadlift',
          maxWeight: 180.0,
          maxReps: 5,
          maxVolume: 2700.0,
          achievedDate: now.subtract(const Duration(days: 9)),
          improvementPercentage: null,
        ),
      ];

      // Cache the PRs
      await cacheService.cachePersonalRecords(prs);

      // Retrieve cached PRs
      final cachedPRs = await cacheService.getCachedPersonalRecords();

      // Verify data integrity
      expect(cachedPRs, isNotNull);
      expect(cachedPRs!.length, equals(prs.length));
      
      for (int i = 0; i < prs.length; i++) {
        expect(cachedPRs[i].id, equals(prs[i].id));
        expect(cachedPRs[i].exerciseId, equals(prs[i].exerciseId));
        expect(cachedPRs[i].exerciseName, equals(prs[i].exerciseName));
        expect(cachedPRs[i].maxWeight, equals(prs[i].maxWeight));
        expect(cachedPRs[i].maxReps, equals(prs[i].maxReps));
        expect(cachedPRs[i].maxVolume, equals(prs[i].maxVolume));
        expect(cachedPRs[i].improvementPercentage, equals(prs[i].improvementPercentage));
      }
    });

    test('Feature: workout-tracking-system, Property 28: Data Caching - Cache persistence across sessions', () async {
      // Property test: For any cached data, it should persist across service instances
      
      final now = DateTime.now();
      final workout = WorkoutLog(
        id: 1,
        user: 1,
        date: now,
        duration: 60,
        caloriesBurned: 450.0,
        exercises: [],
        hasNewPrs: false,
      );

      // Cache with first instance
      await cacheService.cacheWorkoutHistory([workout]);

      // Create new instance with same SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final newCacheService = WorkoutCacheService(prefs);

      // Retrieve with new instance
      final cachedWorkouts = await newCacheService.getCachedWorkoutHistory();

      // Verify data persisted
      expect(cachedWorkouts, isNotNull);
      expect(cachedWorkouts!.length, equals(1));
      expect(cachedWorkouts[0].id, equals(workout.id));
    });

    test('Feature: workout-tracking-system, Property 28: Data Caching - Empty cache returns null', () async {
      // Property test: For any empty cache, retrieval should return null
      
      final cachedWorkouts = await cacheService.getCachedWorkoutHistory();
      final cachedExercises = await cacheService.getCachedExercises();
      final cachedPRs = await cacheService.getCachedPersonalRecords();

      expect(cachedWorkouts, isNull);
      expect(cachedExercises, isNull);
      expect(cachedPRs, isNull);
      expect(cacheService.hasCachedData(), isFalse);
    });

    test('Feature: workout-tracking-system, Property 28: Data Caching - Cache clearing removes all data', () async {
      // Property test: For any cached data, clearing should remove it completely
      
      final now = DateTime.now();
      final workout = WorkoutLog(
        id: 1,
        user: 1,
        date: now,
        duration: 60,
        caloriesBurned: 450.0,
        exercises: [],
        hasNewPrs: false,
      );

      // Cache data
      await cacheService.cacheWorkoutHistory([workout]);
      expect(cacheService.hasCachedData(), isTrue);

      // Clear cache
      await cacheService.clearAllCaches();

      // Verify cache is empty
      final cachedWorkouts = await cacheService.getCachedWorkoutHistory();
      expect(cachedWorkouts, isNull);
      expect(cacheService.hasCachedData(), isFalse);
    });

    test('Feature: workout-tracking-system, Property 28: Data Caching - Last sync time tracking', () async {
      // Property test: For any cache operation, last sync time should be updated
      
      final now = DateTime.now();
      final workout = WorkoutLog(
        id: 1,
        user: 1,
        date: now,
        duration: 60,
        caloriesBurned: 450.0,
        exercises: [],
        hasNewPrs: false,
      );

      // Initially no sync time
      expect(cacheService.getLastSyncTime(), isNull);
      expect(cacheService.needsSync(), isTrue);

      // Cache data
      await cacheService.cacheWorkoutHistory([workout]);

      // Verify sync time was set
      final syncTime = cacheService.getLastSyncTime();
      expect(syncTime, isNotNull);
      expect(syncTime!.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
      expect(cacheService.needsSync(), isFalse);
    });

    test('Feature: workout-tracking-system, Property 28: Data Caching - Cache age detection', () async {
      // Property test: For any cached data, age should be correctly detected
      
      final now = DateTime.now();
      final workout = WorkoutLog(
        id: 1,
        user: 1,
        date: now,
        duration: 60,
        caloriesBurned: 450.0,
        exercises: [],
        hasNewPrs: false,
      );

      // Cache data
      await cacheService.cacheWorkoutHistory([workout]);

      // Fresh cache should not need sync
      expect(cacheService.needsSync(maxAge: const Duration(hours: 1)), isFalse);

      // Wait a bit to ensure time passes
      await Future.delayed(const Duration(milliseconds: 10));

      // Should need sync with very short max age
      expect(cacheService.needsSync(maxAge: const Duration(milliseconds: 1)), isTrue);
    });

    test('Feature: workout-tracking-system, Property 28: Data Caching - Adding single workout to cache', () async {
      // Property test: For any new workout, it should be added to existing cache
      
      final now = DateTime.now();
      final existingWorkout = WorkoutLog(
        id: 1,
        user: 1,
        date: now.subtract(const Duration(days: 1)),
        duration: 60,
        caloriesBurned: 450.0,
        exercises: [],
        hasNewPrs: false,
      );

      final newWorkout = WorkoutLog(
        id: 2,
        user: 1,
        date: now,
        duration: 45,
        caloriesBurned: 380.0,
        exercises: [],
        hasNewPrs: true,
      );

      // Cache initial workout
      await cacheService.cacheWorkoutHistory([existingWorkout]);

      // Add new workout
      await cacheService.addWorkoutToCache(newWorkout);

      // Retrieve and verify
      final cachedWorkouts = await cacheService.getCachedWorkoutHistory();
      expect(cachedWorkouts, isNotNull);
      expect(cachedWorkouts!.length, equals(2));
      expect(cachedWorkouts[0].id, equals(newWorkout.id)); // Newest first
      expect(cachedWorkouts[1].id, equals(existingWorkout.id));
    });
  });

  group('Property 37: Cache Synchronization on Startup', () {
    /// **Validates: Requirements 14.5**
    /// 
    /// Property 37: Cache Synchronization on Startup
    /// 
    /// For any app startup, the system should synchronize local cached data
    /// with backend data to ensure consistency.

    late WorkoutCacheService cacheService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      cacheService = WorkoutCacheService(prefs);
    });

    test('Feature: workout-tracking-system, Property 37: Cache Synchronization - Sync updates stale cache', () async {
      // Property test: For any stale cache, synchronization should update it
      
      // This test verifies the cache service's sync detection logic
      // In a real scenario, the repository would call the API and update the cache
      
      final now = DateTime.now();
      final oldWorkout = WorkoutLog(
        id: 1,
        user: 1,
        date: now.subtract(const Duration(days: 10)),
        duration: 60,
        caloriesBurned: 450.0,
        exercises: [],
        hasNewPrs: false,
      );

      // Cache old data
      await cacheService.cacheWorkoutHistory([oldWorkout]);

      // Verify cache exists
      expect(cacheService.hasCachedData(), isTrue);
      
      // Initially cache is fresh
      expect(cacheService.needsSync(maxAge: const Duration(hours: 1)), isFalse);

      // Wait a bit to ensure time passes
      await Future.delayed(const Duration(milliseconds: 10));

      // After time passes, cache should be stale
      expect(cacheService.needsSync(maxAge: const Duration(milliseconds: 1)), isTrue);
    });

    test('Feature: workout-tracking-system, Property 37: Cache Synchronization - Fresh cache skips sync', () async {
      // Property test: For any fresh cache, synchronization should be skipped
      
      final now = DateTime.now();
      final workout = WorkoutLog(
        id: 1,
        user: 1,
        date: now,
        duration: 60,
        caloriesBurned: 450.0,
        exercises: [],
        hasNewPrs: false,
      );

      // Cache fresh data
      await cacheService.cacheWorkoutHistory([workout]);

      // Verify cache is fresh
      expect(cacheService.needsSync(maxAge: const Duration(hours: 1)), isFalse);
    });

    test('Feature: workout-tracking-system, Property 37: Cache Synchronization - Empty cache triggers sync', () async {
      // Property test: For any empty cache, synchronization should be triggered
      
      // Empty cache should always need sync
      expect(cacheService.hasCachedData(), isFalse);
      expect(cacheService.needsSync(), isTrue);
    });

    test('Feature: workout-tracking-system, Property 37: Cache Synchronization - Multiple data types sync independently', () async {
      // Property test: For any combination of cached data types, each should sync independently
      
      final now = DateTime.now();
      
      // Cache only workouts
      final workout = WorkoutLog(
        id: 1,
        user: 1,
        date: now,
        duration: 60,
        caloriesBurned: 450.0,
        exercises: [],
        hasNewPrs: false,
      );
      await cacheService.cacheWorkoutHistory([workout]);

      // Verify workouts are cached
      final cachedWorkouts = await cacheService.getCachedWorkoutHistory();
      expect(cachedWorkouts, isNotNull);

      // But exercises and PRs are not
      final cachedExercises = await cacheService.getCachedExercises();
      final cachedPRs = await cacheService.getCachedPersonalRecords();
      expect(cachedExercises, isNull);
      expect(cachedPRs, isNull);

      // Overall cache exists
      expect(cacheService.hasCachedData(), isTrue);
    });

    test('Feature: workout-tracking-system, Property 37: Cache Synchronization - Sync time updates after cache operations', () async {
      // Property test: For any cache write operation, sync time should be updated
      
      final now = DateTime.now();
      
      // Initially no sync time
      expect(cacheService.getLastSyncTime(), isNull);

      // Cache workout
      final workout = WorkoutLog(
        id: 1,
        user: 1,
        date: now,
        duration: 60,
        caloriesBurned: 450.0,
        exercises: [],
        hasNewPrs: false,
      );
      await cacheService.cacheWorkoutHistory([workout]);
      final syncTime1 = cacheService.getLastSyncTime();
      expect(syncTime1, isNotNull);

      // Small delay
      await Future.delayed(const Duration(milliseconds: 10));

      // Cache exercise
      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'Test',
        instructions: 'Test',
      );
      await cacheService.cacheExercises([exercise]);
      final syncTime2 = cacheService.getLastSyncTime();
      
      // Sync time should be updated
      expect(syncTime2, isNotNull);
      expect(syncTime2!.isAfter(syncTime1!), isTrue);
    });
  });

  group('Property 38: Network Failure Retry Queue', () {
    /// **Validates: Requirements 14.6**
    /// 
    /// Property 38: Network Failure Retry Queue
    /// 
    /// For any operation that fails due to network issues, the system should queue
    /// the operation for automatic retry when network connectivity is restored.

    late WorkoutCacheService cacheService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      cacheService = WorkoutCacheService(prefs);
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Queue operation for retry', () async {
      // Property test: For any failed operation, it should be queued with correct metadata
      
      final operationData = {
        'workoutName': 'Push Day',
        'durationMinutes': 60,
        'caloriesBurned': 450.5,
        'exercises': [],
      };

      // Queue an operation
      await cacheService.queueOperation(
        type: 'log_workout',
        data: operationData,
      );

      // Verify operation was queued
      final queuedOps = await cacheService.getQueuedOperations();
      expect(queuedOps.length, equals(1));
      expect(queuedOps[0].type, equals('log_workout'));
      expect(queuedOps[0].data['workoutName'], equals('Push Day'));
      expect(queuedOps[0].retryCount, equals(0));
      expect(queuedOps[0].queuedAt.isBefore(DateTime.now().add(const Duration(seconds: 1))), isTrue);
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Multiple operations queued in order', () async {
      // Property test: For any sequence of failed operations, they should be queued in order
      
      final operation1 = {'workoutName': 'Push Day', 'duration': 60};
      final operation2 = {'workoutName': 'Leg Day', 'duration': 75};
      final operation3 = {'workoutName': 'Pull Day', 'duration': 55};

      // Queue multiple operations
      await cacheService.queueOperation(type: 'log_workout', data: operation1);
      await Future.delayed(const Duration(milliseconds: 10));
      await cacheService.queueOperation(type: 'log_workout', data: operation2);
      await Future.delayed(const Duration(milliseconds: 10));
      await cacheService.queueOperation(type: 'log_workout', data: operation3);

      // Verify all operations are queued
      final queuedOps = await cacheService.getQueuedOperations();
      expect(queuedOps.length, equals(3));
      expect(queuedOps[0].data['workoutName'], equals('Push Day'));
      expect(queuedOps[1].data['workoutName'], equals('Leg Day'));
      expect(queuedOps[2].data['workoutName'], equals('Pull Day'));
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Remove operation after successful retry', () async {
      // Property test: For any successfully retried operation, it should be removed from queue
      
      final operationData = {'workoutName': 'Push Day', 'duration': 60};

      // Queue an operation
      await cacheService.queueOperation(type: 'log_workout', data: operationData);
      
      final queuedOps = await cacheService.getQueuedOperations();
      expect(queuedOps.length, equals(1));
      
      final operationId = queuedOps[0].id;

      // Remove operation (simulating successful retry)
      await cacheService.removeQueuedOperation(operationId);

      // Verify operation was removed
      final remainingOps = await cacheService.getQueuedOperations();
      expect(remainingOps.length, equals(0));
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Increment retry count on failure', () async {
      // Property test: For any failed retry attempt, retry count should be incremented
      
      final operationData = {'workoutName': 'Push Day', 'duration': 60};

      // Queue an operation
      await cacheService.queueOperation(type: 'log_workout', data: operationData);
      
      var queuedOps = await cacheService.getQueuedOperations();
      expect(queuedOps[0].retryCount, equals(0));
      
      final operationId = queuedOps[0].id;

      // Increment retry count (simulating failed retry)
      await cacheService.incrementRetryCount(operationId);

      // Verify retry count was incremented
      queuedOps = await cacheService.getQueuedOperations();
      expect(queuedOps[0].retryCount, equals(1));

      // Increment again
      await cacheService.incrementRetryCount(operationId);
      queuedOps = await cacheService.getQueuedOperations();
      expect(queuedOps[0].retryCount, equals(2));
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Clear all queued operations', () async {
      // Property test: For any queued operations, clearing should remove all
      
      // Queue multiple operations
      await cacheService.queueOperation(type: 'log_workout', data: {'name': 'Workout 1'});
      await cacheService.queueOperation(type: 'log_workout', data: {'name': 'Workout 2'});
      await cacheService.queueOperation(type: 'log_workout', data: {'name': 'Workout 3'});

      var queuedOps = await cacheService.getQueuedOperations();
      expect(queuedOps.length, equals(3));

      // Clear queue
      await cacheService.clearRetryQueue();

      // Verify queue is empty
      queuedOps = await cacheService.getQueuedOperations();
      expect(queuedOps.length, equals(0));
      expect(cacheService.hasQueuedOperations(), isFalse);
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Queue persistence across sessions', () async {
      // Property test: For any queued operations, they should persist across service instances
      
      final operationData = {'workoutName': 'Push Day', 'duration': 60};

      // Queue with first instance
      await cacheService.queueOperation(type: 'log_workout', data: operationData);

      // Create new instance with same SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final newCacheService = WorkoutCacheService(prefs);

      // Retrieve with new instance
      final queuedOps = await newCacheService.getQueuedOperations();

      // Verify operation persisted
      expect(queuedOps.length, equals(1));
      expect(queuedOps[0].type, equals('log_workout'));
      expect(queuedOps[0].data['workoutName'], equals('Push Day'));
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Get queued operation count', () async {
      // Property test: For any number of queued operations, count should be accurate
      
      // Initially empty
      expect(await cacheService.getQueuedOperationCount(), equals(0));

      // Add operations
      await cacheService.queueOperation(type: 'log_workout', data: {'name': 'Workout 1'});
      expect(await cacheService.getQueuedOperationCount(), equals(1));

      await cacheService.queueOperation(type: 'log_workout', data: {'name': 'Workout 2'});
      expect(await cacheService.getQueuedOperationCount(), equals(2));

      await cacheService.queueOperation(type: 'log_workout', data: {'name': 'Workout 3'});
      expect(await cacheService.getQueuedOperationCount(), equals(3));

      // Remove one
      final ops = await cacheService.getQueuedOperations();
      await cacheService.removeQueuedOperation(ops[0].id);
      
      // Verify count decreased
      final remainingCount = await cacheService.getQueuedOperationCount();
      expect(remainingCount, equals(2));
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Empty queue returns empty list', () async {
      // Property test: For any empty queue, retrieval should return empty list
      
      final queuedOps = await cacheService.getQueuedOperations();
      expect(queuedOps, isEmpty);
      expect(cacheService.hasQueuedOperations(), isFalse);
      expect(await cacheService.getQueuedOperationCount(), equals(0));
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Operation data integrity', () async {
      // Property test: For any queued operation, data should be preserved exactly
      
      final complexOperationData = {
        'workoutName': 'Complex Workout',
        'customWorkoutId': '123',
        'gymId': '456',
        'durationMinutes': 90,
        'caloriesBurned': 650.75,
        'exercises': [
          {
            'exerciseId': '1',
            'order': 0,
            'sets': [
              {'setNumber': 1, 'reps': 10, 'weight': 100.0, 'completed': true},
              {'setNumber': 2, 'reps': 8, 'weight': 105.0, 'completed': true},
            ],
          },
          {
            'exerciseId': '2',
            'order': 1,
            'sets': [
              {'setNumber': 1, 'reps': 12, 'weight': 80.0, 'completed': true},
            ],
          },
        ],
        'notes': 'Great workout with PRs!',
      };

      // Queue the operation
      await cacheService.queueOperation(
        type: 'log_workout',
        data: complexOperationData,
      );

      // Retrieve and verify data integrity
      final queuedOps = await cacheService.getQueuedOperations();
      expect(queuedOps.length, equals(1));
      
      final retrievedData = queuedOps[0].data;
      expect(retrievedData['workoutName'], equals('Complex Workout'));
      expect(retrievedData['customWorkoutId'], equals('123'));
      expect(retrievedData['gymId'], equals('456'));
      expect(retrievedData['durationMinutes'], equals(90));
      expect(retrievedData['caloriesBurned'], equals(650.75));
      expect(retrievedData['notes'], equals('Great workout with PRs!'));
      expect(retrievedData['exercises'], isA<List>());
      expect((retrievedData['exercises'] as List).length, equals(2));
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Different operation types', () async {
      // Property test: For any operation type, it should be queued correctly
      
      await cacheService.queueOperation(
        type: 'log_workout',
        data: {'workoutName': 'Push Day'},
      );
      
      await cacheService.queueOperation(
        type: 'update_pr',
        data: {'exerciseId': '1', 'maxWeight': 120.0},
      );
      
      await cacheService.queueOperation(
        type: 'delete_workout',
        data: {'workoutId': '123'},
      );

      final queuedOps = await cacheService.getQueuedOperations();
      expect(queuedOps.length, equals(3));
      expect(queuedOps[0].type, equals('log_workout'));
      expect(queuedOps[1].type, equals('update_pr'));
      expect(queuedOps[2].type, equals('delete_workout'));
    });
  });
}
