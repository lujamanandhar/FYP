import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrilift/services/cache_service.dart';
import 'package:nutrilift/models/workout_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CacheService cacheService;

  setUp(() async {
    // Clear all shared preferences before each test
    SharedPreferences.setMockInitialValues({});
    cacheService = CacheService();
  });

  tearDown(() async {
    await cacheService.clearAllCache();
  });

  group('CacheService - Workout History', () {
    test('should cache and retrieve workout history', () async {
      // Arrange
      final workouts = [
        WorkoutLog(
          id: '1',
          workoutName: 'Push Day',
          durationMinutes: 60,
          exercises: [],
          caloriesBurned: 450.0,
          loggedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        WorkoutLog(
          id: '2',
          workoutName: 'Leg Day',
          durationMinutes: 75,
          exercises: [],
          caloriesBurned: 520.0,
          loggedAt: DateTime.now().subtract(const Duration(days: 1)),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      await cacheService.cacheWorkoutHistory(workouts);
      final cached = await cacheService.getCachedWorkoutHistory();

      // Assert
      expect(cached, isNotNull);
      expect(cached!.length, equals(2));
      expect(cached[0].id, equals('1'));
      expect(cached[0].workoutName, equals('Push Day'));
      expect(cached[1].id, equals('2'));
      expect(cached[1].workoutName, equals('Leg Day'));
    });

    test('should return null when no workout history is cached', () async {
      // Act
      final cached = await cacheService.getCachedWorkoutHistory();

      // Assert
      expect(cached, isNull);
    });

    test('should add single workout to cache', () async {
      // Arrange
      final existingWorkout = WorkoutLog(
        id: '1',
        workoutName: 'Push Day',
        durationMinutes: 60,
        exercises: [],
        caloriesBurned: 450.0,
        loggedAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      );
      await cacheService.cacheWorkoutHistory([existingWorkout]);

      final newWorkout = WorkoutLog(
        id: '2',
        workoutName: 'Leg Day',
        durationMinutes: 75,
        exercises: [],
        caloriesBurned: 520.0,
        loggedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await cacheService.addWorkoutToCache(newWorkout);
      final cached = await cacheService.getCachedWorkoutHistory();

      // Assert
      expect(cached, isNotNull);
      expect(cached!.length, equals(2));
      expect(cached[0].id, equals('2')); // New workout should be first
      expect(cached[1].id, equals('1'));
    });

    test('should clear workout history cache', () async {
      // Arrange
      final workouts = [
        WorkoutLog(
          id: '1',
          workoutName: 'Push Day',
          durationMinutes: 60,
          exercises: [],
          caloriesBurned: 450.0,
          loggedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await cacheService.cacheWorkoutHistory(workouts);

      // Act
      await cacheService.clearWorkoutHistoryCache();
      final cached = await cacheService.getCachedWorkoutHistory();

      // Assert
      expect(cached, isNull);
    });

    test('should handle corrupted workout history cache gracefully', () async {
      // Arrange - manually set corrupted data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_workout_history', 'invalid json data');

      // Act
      final cached = await cacheService.getCachedWorkoutHistory();

      // Assert
      expect(cached, isNull);
      // Verify cache was cleared after attempting to read corrupted data
      final cachedAfter = await cacheService.getCachedWorkoutHistory();
      expect(cachedAfter, isNull);
    });
  });

  group('CacheService - Exercises', () {
    test('should cache and retrieve exercises', () async {
      // Arrange
      final exercises = [
        Exercise(
          id: '1',
          name: 'Bench Press',
          category: 'Strength',
          difficulty: 'Intermediate',
          caloriesPerMinute: 8.5,
          isCustom: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Exercise(
          id: '2',
          name: 'Squats',
          category: 'Strength',
          difficulty: 'Intermediate',
          caloriesPerMinute: 9.0,
          isCustom: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      await cacheService.cacheExercises(exercises);
      final cached = await cacheService.getCachedExercises();

      // Assert
      expect(cached, isNotNull);
      expect(cached!.length, equals(2));
      expect(cached[0].name, equals('Bench Press'));
      expect(cached[1].name, equals('Squats'));
    });

    test('should return null when no exercises are cached', () async {
      // Act
      final cached = await cacheService.getCachedExercises();

      // Assert
      expect(cached, isNull);
    });

    test('should clear exercises cache', () async {
      // Arrange
      final exercises = [
        Exercise(
          id: '1',
          name: 'Bench Press',
          category: 'Strength',
          difficulty: 'Intermediate',
          caloriesPerMinute: 8.5,
          isCustom: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await cacheService.cacheExercises(exercises);

      // Act
      await cacheService.clearExercisesCache();
      final cached = await cacheService.getCachedExercises();

      // Assert
      expect(cached, isNull);
    });

    test('should handle corrupted exercises cache gracefully', () async {
      // Arrange
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_exercises', 'invalid json');

      // Act
      final cached = await cacheService.getCachedExercises();

      // Assert
      expect(cached, isNull);
      // Verify cache was cleared after attempting to read corrupted data
      final cachedAfter = await cacheService.getCachedExercises();
      expect(cachedAfter, isNull);
    });
  });

  group('CacheService - Personal Records', () {
    test('should cache and retrieve personal records', () async {
      // Arrange
      final records = [
        PersonalRecord(
          id: '1',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          recordType: 'max_weight',
          value: 120.0,
          unit: 'kg',
          achievedAt: DateTime.now(),
        ),
        PersonalRecord(
          id: '2',
          exerciseId: 'ex2',
          exerciseName: 'Squats',
          recordType: 'max_weight',
          value: 150.0,
          unit: 'kg',
          achievedAt: DateTime.now(),
        ),
      ];

      // Act
      await cacheService.cachePersonalRecords(records);
      final cached = await cacheService.getCachedPersonalRecords();

      // Assert
      expect(cached, isNotNull);
      expect(cached!.length, equals(2));
      expect(cached[0].exerciseName, equals('Bench Press'));
      expect(cached[1].exerciseName, equals('Squats'));
    });

    test('should return null when no personal records are cached', () async {
      // Act
      final cached = await cacheService.getCachedPersonalRecords();

      // Assert
      expect(cached, isNull);
    });

    test('should update single personal record in cache', () async {
      // Arrange
      final records = [
        PersonalRecord(
          id: '1',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          recordType: 'max_weight',
          value: 120.0,
          unit: 'kg',
          achievedAt: DateTime.now(),
        ),
      ];
      await cacheService.cachePersonalRecords(records);

      final updatedRecord = PersonalRecord(
        id: '1',
        exerciseId: 'ex1',
        exerciseName: 'Bench Press',
        recordType: 'max_weight',
        value: 125.0, // Updated value
        unit: 'kg',
        achievedAt: DateTime.now(),
      );

      // Act
      await cacheService.updatePersonalRecordInCache(updatedRecord);
      final cached = await cacheService.getCachedPersonalRecords();

      // Assert
      expect(cached, isNotNull);
      expect(cached!.length, equals(1));
      expect(cached[0].value, equals(125.0));
    });

    test('should add new personal record if not exists in cache', () async {
      // Arrange
      final existingRecord = PersonalRecord(
        id: '1',
        exerciseId: 'ex1',
        exerciseName: 'Bench Press',
        recordType: 'max_weight',
        value: 120.0,
        unit: 'kg',
        achievedAt: DateTime.now(),
      );
      await cacheService.cachePersonalRecords([existingRecord]);

      final newRecord = PersonalRecord(
        id: '2',
        exerciseId: 'ex2',
        exerciseName: 'Squats',
        recordType: 'max_weight',
        value: 150.0,
        unit: 'kg',
        achievedAt: DateTime.now(),
      );

      // Act
      await cacheService.updatePersonalRecordInCache(newRecord);
      final cached = await cacheService.getCachedPersonalRecords();

      // Assert
      expect(cached, isNotNull);
      expect(cached!.length, equals(2));
    });

    test('should clear personal records cache', () async {
      // Arrange
      final records = [
        PersonalRecord(
          id: '1',
          exerciseId: 'ex1',
          exerciseName: 'Bench Press',
          recordType: 'max_weight',
          value: 120.0,
          unit: 'kg',
          achievedAt: DateTime.now(),
        ),
      ];
      await cacheService.cachePersonalRecords(records);

      // Act
      await cacheService.clearPersonalRecordsCache();
      final cached = await cacheService.getCachedPersonalRecords();

      // Assert
      expect(cached, isNull);
    });
  });

  group('CacheService - Custom Workouts', () {
    test('should cache and retrieve custom workouts', () async {
      // Arrange
      final workouts = [
        CustomWorkout(
          id: '1',
          name: 'My Push Workout',
          category: 'Strength',
          exercises: [],
          estimatedDuration: 60,
          isPublic: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      await cacheService.cacheCustomWorkouts(workouts);
      final cached = await cacheService.getCachedCustomWorkouts();

      // Assert
      expect(cached, isNotNull);
      expect(cached!.length, equals(1));
      expect(cached[0].name, equals('My Push Workout'));
    });

    test('should return null when no custom workouts are cached', () async {
      // Act
      final cached = await cacheService.getCachedCustomWorkouts();

      // Assert
      expect(cached, isNull);
    });

    test('should clear custom workouts cache', () async {
      // Arrange
      final workouts = [
        CustomWorkout(
          id: '1',
          name: 'My Push Workout',
          category: 'Strength',
          exercises: [],
          estimatedDuration: 60,
          isPublic: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await cacheService.cacheCustomWorkouts(workouts);

      // Act
      await cacheService.clearCustomWorkoutsCache();
      final cached = await cacheService.getCachedCustomWorkouts();

      // Assert
      expect(cached, isNull);
    });
  });

  group('CacheService - Cache Management', () {
    test('should update and retrieve last sync time', () async {
      // Arrange
      final workouts = [
        WorkoutLog(
          id: '1',
          workoutName: 'Push Day',
          durationMinutes: 60,
          exercises: [],
          caloriesBurned: 450.0,
          loggedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      await cacheService.cacheWorkoutHistory(workouts);
      final lastSync = await cacheService.getLastSyncTime();

      // Assert
      expect(lastSync, isNotNull);
      expect(lastSync!.isBefore(DateTime.now()), isTrue);
      expect(lastSync.isAfter(DateTime.now().subtract(const Duration(seconds: 5))), isTrue);
    });

    test('should return null when no sync time exists', () async {
      // Act
      final lastSync = await cacheService.getLastSyncTime();

      // Assert
      expect(lastSync, isNull);
    });

    test('should indicate cache needs refresh when no sync time', () async {
      // Act
      final needsRefresh = await cacheService.needsRefresh();

      // Assert
      expect(needsRefresh, isTrue);
    });

    test('should indicate cache needs refresh when older than max age', () async {
      // Arrange
      final prefs = await SharedPreferences.getInstance();
      final oldTime = DateTime.now().subtract(const Duration(hours: 2));
      await prefs.setString('last_sync_timestamp', oldTime.toIso8601String());

      // Act
      final needsRefresh = await cacheService.needsRefresh(maxAge: const Duration(hours: 1));

      // Assert
      expect(needsRefresh, isTrue);
    });

    test('should indicate cache does not need refresh when recent', () async {
      // Arrange
      final workouts = [
        WorkoutLog(
          id: '1',
          workoutName: 'Push Day',
          durationMinutes: 60,
          exercises: [],
          caloriesBurned: 450.0,
          loggedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await cacheService.cacheWorkoutHistory(workouts);

      // Act
      final needsRefresh = await cacheService.needsRefresh(maxAge: const Duration(hours: 1));

      // Assert
      expect(needsRefresh, isFalse);
    });

    test('should detect when cached data exists', () async {
      // Arrange
      final exercises = [
        Exercise(
          id: '1',
          name: 'Bench Press',
          category: 'Strength',
          difficulty: 'Intermediate',
          caloriesPerMinute: 8.5,
          isCustom: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await cacheService.cacheExercises(exercises);

      // Act
      final hasCached = await cacheService.hasCachedData();

      // Assert
      expect(hasCached, isTrue);
    });

    test('should detect when no cached data exists', () async {
      // Act
      final hasCached = await cacheService.hasCachedData();

      // Assert
      expect(hasCached, isFalse);
    });

    test('should clear all cache', () async {
      // Arrange
      final workouts = [
        WorkoutLog(
          id: '1',
          workoutName: 'Push Day',
          durationMinutes: 60,
          exercises: [],
          caloriesBurned: 450.0,
          loggedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final exercises = [
        Exercise(
          id: '1',
          name: 'Bench Press',
          category: 'Strength',
          difficulty: 'Intermediate',
          caloriesPerMinute: 8.5,
          isCustom: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await cacheService.cacheWorkoutHistory(workouts);
      await cacheService.cacheExercises(exercises);

      // Act
      await cacheService.clearAllCache();

      // Assert
      expect(await cacheService.getCachedWorkoutHistory(), isNull);
      expect(await cacheService.getCachedExercises(), isNull);
      expect(await cacheService.hasCachedData(), isFalse);
      expect(await cacheService.getLastSyncTime(), isNull);
    });

    test('should provide accurate cache statistics', () async {
      // Arrange
      final workouts = [
        WorkoutLog(
          id: '1',
          workoutName: 'Push Day',
          durationMinutes: 60,
          exercises: [],
          caloriesBurned: 450.0,
          loggedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        WorkoutLog(
          id: '2',
          workoutName: 'Leg Day',
          durationMinutes: 75,
          exercises: [],
          caloriesBurned: 520.0,
          loggedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      final exercises = [
        Exercise(
          id: '1',
          name: 'Bench Press',
          category: 'Strength',
          difficulty: 'Intermediate',
          caloriesPerMinute: 8.5,
          isCustom: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      await cacheService.cacheWorkoutHistory(workouts);
      await cacheService.cacheExercises(exercises);

      // Act
      final stats = await cacheService.getCacheStats();

      // Assert
      expect(stats['workoutHistoryCount'], equals(2));
      expect(stats['exercisesCount'], equals(1));
      expect(stats['personalRecordsCount'], equals(0));
      expect(stats['customWorkoutsCount'], equals(0));
      expect(stats['hasCachedData'], isTrue);
      expect(stats['needsRefresh'], isFalse);
      expect(stats['lastSyncTime'], isNotNull);
    });
  });

  group('CacheService - Singleton Pattern', () {
    test('should return same instance', () {
      // Act
      final instance1 = CacheService();
      final instance2 = CacheService();

      // Assert
      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('CacheService - Retry Queue', () {
    test('should enqueue failed operation', () async {
      // Arrange
      var executionCount = 0;
      final operation = QueuedOperation(
        id: 'op1',
        operationType: 'log_workout',
        data: {'workoutId': '123'},
        timestamp: DateTime.now(),
        executeCallback: () async {
          executionCount++;
        },
      );

      // Act
      await cacheService.enqueueOperation(operation);
      final queue = cacheService.getRetryQueue();

      // Assert
      expect(queue.length, equals(1));
      expect(queue[0].id, equals('op1'));
      expect(queue[0].operationType, equals('log_workout'));
      expect(executionCount, equals(0)); // Not executed yet
    });

    test('should process retry queue and execute operations', () async {
      // Arrange
      var executionCount = 0;
      final operation = QueuedOperation(
        id: 'op1',
        operationType: 'log_workout',
        data: {'workoutId': '123'},
        timestamp: DateTime.now(),
        executeCallback: () async {
          executionCount++;
        },
      );
      await cacheService.enqueueOperation(operation);

      // Act
      await cacheService.retryQueuedOperations();

      // Assert
      expect(executionCount, equals(1));
      expect(cacheService.getRetryQueue().length, equals(0)); // Queue should be empty after success
    });

    test('should retry failed operations up to max retries', () async {
      // Arrange
      var executionCount = 0;
      final operation = QueuedOperation(
        id: 'op1',
        operationType: 'log_workout',
        data: {'workoutId': '123'},
        timestamp: DateTime.now(),
        maxRetries: 3,
        executeCallback: () async {
          executionCount++;
          throw Exception('Network error');
        },
      );
      await cacheService.enqueueOperation(operation);

      // Act - Try to process multiple times
      await cacheService.retryQueuedOperations();
      await cacheService.retryQueuedOperations();
      await cacheService.retryQueuedOperations();
      await cacheService.retryQueuedOperations(); // Should exceed max retries

      // Assert
      expect(executionCount, equals(3)); // Should try exactly maxRetries times
      expect(cacheService.getRetryQueue().length, equals(0)); // Should be removed after max retries
    });

    test('should process multiple operations in FIFO order', () async {
      // Arrange
      final executionOrder = <String>[];
      
      final op1 = QueuedOperation(
        id: 'op1',
        operationType: 'log_workout',
        data: {'workoutId': '1'},
        timestamp: DateTime.now(),
        executeCallback: () async {
          executionOrder.add('op1');
        },
      );
      
      final op2 = QueuedOperation(
        id: 'op2',
        operationType: 'log_workout',
        data: {'workoutId': '2'},
        timestamp: DateTime.now(),
        executeCallback: () async {
          executionOrder.add('op2');
        },
      );
      
      final op3 = QueuedOperation(
        id: 'op3',
        operationType: 'log_workout',
        data: {'workoutId': '3'},
        timestamp: DateTime.now(),
        executeCallback: () async {
          executionOrder.add('op3');
        },
      );

      // Act
      await cacheService.enqueueOperation(op1);
      await cacheService.enqueueOperation(op2);
      await cacheService.enqueueOperation(op3);
      await cacheService.retryQueuedOperations();

      // Assert
      expect(executionOrder, equals(['op1', 'op2', 'op3']));
      expect(cacheService.getRetryQueue().length, equals(0));
    });

    test('should stop processing queue when operation fails', () async {
      // Arrange
      final executionOrder = <String>[];
      
      final op1 = QueuedOperation(
        id: 'op1',
        operationType: 'log_workout',
        data: {'workoutId': '1'},
        timestamp: DateTime.now(),
        executeCallback: () async {
          executionOrder.add('op1');
        },
      );
      
      final op2 = QueuedOperation(
        id: 'op2',
        operationType: 'log_workout',
        data: {'workoutId': '2'},
        timestamp: DateTime.now(),
        executeCallback: () async {
          executionOrder.add('op2');
          throw Exception('Network error');
        },
      );
      
      final op3 = QueuedOperation(
        id: 'op3',
        operationType: 'log_workout',
        data: {'workoutId': '3'},
        timestamp: DateTime.now(),
        executeCallback: () async {
          executionOrder.add('op3');
        },
      );

      // Act
      await cacheService.enqueueOperation(op1);
      await cacheService.enqueueOperation(op2);
      await cacheService.enqueueOperation(op3);
      await cacheService.retryQueuedOperations();

      // Assert
      expect(executionOrder, equals(['op1', 'op2'])); // op3 should not execute
      expect(cacheService.getRetryQueue().length, equals(2)); // op2 and op3 remain
      expect(cacheService.getRetryQueue()[0].id, equals('op2')); // Failed op is still first
    });

    test('should clear retry queue', () async {
      // Arrange
      final operation = QueuedOperation(
        id: 'op1',
        operationType: 'log_workout',
        data: {'workoutId': '123'},
        timestamp: DateTime.now(),
        executeCallback: () async {},
      );
      await cacheService.enqueueOperation(operation);

      // Act
      await cacheService.clearRetryQueue();

      // Assert
      expect(cacheService.getRetryQueue().length, equals(0));
    });

    test('should persist and load retry queue', () async {
      // Arrange
      final operation = QueuedOperation(
        id: 'op1',
        operationType: 'log_workout',
        data: {'workoutId': '123'},
        timestamp: DateTime.now(),
        executeCallback: () async {},
      );
      await cacheService.enqueueOperation(operation);

      // Act - Create new instance and load queue
      final newCacheService = CacheService();
      await newCacheService.loadRetryQueue();

      // Assert
      final queue = newCacheService.getRetryQueue();
      expect(queue.length, equals(1));
      expect(queue[0].id, equals('op1'));
      expect(queue[0].operationType, equals('log_workout'));
      expect(queue[0].data['workoutId'], equals('123'));
    });

    test('should include queued operations count in cache stats', () async {
      // Arrange
      final operation = QueuedOperation(
        id: 'op1',
        operationType: 'log_workout',
        data: {'workoutId': '123'},
        timestamp: DateTime.now(),
        executeCallback: () async {},
      );
      await cacheService.enqueueOperation(operation);

      // Act
      final stats = await cacheService.getCacheStats();

      // Assert
      expect(stats['queuedOperationsCount'], equals(1));
    });

    test('QueuedOperation should serialize to JSON', () {
      // Arrange
      final timestamp = DateTime.now();
      final operation = QueuedOperation(
        id: 'op1',
        operationType: 'log_workout',
        data: {'workoutId': '123', 'duration': 60},
        timestamp: timestamp,
        retryCount: 2,
        maxRetries: 5,
        executeCallback: () async {},
      );

      // Act
      final json = operation.toJson();

      // Assert
      expect(json['id'], equals('op1'));
      expect(json['operationType'], equals('log_workout'));
      expect(json['data']['workoutId'], equals('123'));
      expect(json['data']['duration'], equals(60));
      expect(json['timestamp'], equals(timestamp.toIso8601String()));
      expect(json['retryCount'], equals(2));
      expect(json['maxRetries'], equals(5));
    });

    test('QueuedOperation should deserialize from JSON', () {
      // Arrange
      final timestamp = DateTime.now();
      final json = {
        'id': 'op1',
        'operationType': 'log_workout',
        'data': {'workoutId': '123', 'duration': 60},
        'timestamp': timestamp.toIso8601String(),
        'retryCount': 2,
        'maxRetries': 5,
      };

      // Act
      final operation = QueuedOperation.fromJson(json);

      // Assert
      expect(operation.id, equals('op1'));
      expect(operation.operationType, equals('log_workout'));
      expect(operation.data['workoutId'], equals('123'));
      expect(operation.data['duration'], equals(60));
      expect(operation.timestamp, equals(timestamp));
      expect(operation.retryCount, equals(2));
      expect(operation.maxRetries, equals(5));
    });
  });
}
