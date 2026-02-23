import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrilift/services/cache_service.dart';

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
    await cacheService.clearRetryQueue();
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
