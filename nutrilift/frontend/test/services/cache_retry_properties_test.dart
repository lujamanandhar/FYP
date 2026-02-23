import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nutrilift/services/cache_service.dart';

/// Property-based tests for retry queue behavior
/// 
/// **Validates: Requirements 14.6**
/// 
/// Property 38: Network Failure Retry Queue
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

  group('Property 38: Network Failure Retry Queue', () {
    /// **Validates: Requirements 14.6**
    /// 
    /// For any operation that fails due to network issues, the system should
    /// queue the operation for automatic retry when network connectivity is restored.

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Failed operations are queued', () async {
      // Property test: For any failed operation, it should be added to the retry queue
      
      final random = Random();
      
      // Test with varying numbers of failed operations
      for (var testCase = 0; testCase < 10; testCase++) {
        final operationCount = random.nextInt(20) + 1; // 1-20 operations
        final operations = <QueuedOperation>[];
        
        for (var i = 0; i < operationCount; i++) {
          final operation = QueuedOperation(
            id: 'op_${testCase}_$i',
            operationType: ['log_workout', 'update_pr', 'sync_data'][random.nextInt(3)],
            data: {
              'workoutId': random.nextInt(1000),
              'timestamp': DateTime.now().toIso8601String(),
              'value': random.nextDouble() * 100,
            },
            timestamp: DateTime.now().subtract(Duration(seconds: i)),
            executeCallback: () async {
              // Simulated operation
            },
          );
          operations.add(operation);
          await cacheService.enqueueOperation(operation);
        }
        
        // Verify all operations were queued
        final queue = cacheService.getRetryQueue();
        expect(queue.length, equals(operationCount),
            reason: 'All $operationCount failed operations should be queued');
        
        // Verify operations maintain their order (FIFO)
        for (var i = 0; i < operationCount; i++) {
          expect(queue[i].id, equals(operations[i].id),
              reason: 'Operations should be queued in FIFO order');
        }
        
        // Verify operation metadata is preserved
        for (var i = 0; i < operationCount; i++) {
          expect(queue[i].operationType, equals(operations[i].operationType));
          expect(queue[i].data, equals(operations[i].data));
          expect(queue[i].retryCount, equals(0),
              reason: 'Initial retry count should be 0');
        }
        
        // Clear for next test case
        await cacheService.clearRetryQueue();
      }
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Queued operations are retried on success', () async {
      // Property test: For any queued operation that succeeds on retry, it should be removed from queue
      
      final random = Random();
      
      for (var testCase = 0; testCase < 10; testCase++) {
        final operationCount = random.nextInt(15) + 1; // 1-15 operations
        final executionCounts = List.filled(operationCount, 0);
        
        // Create operations that will succeed
        for (var i = 0; i < operationCount; i++) {
          final index = i;
          final operation = QueuedOperation(
            id: 'success_op_${testCase}_$i',
            operationType: 'log_workout',
            data: {'workoutId': random.nextInt(1000)},
            timestamp: DateTime.now(),
            executeCallback: () async {
              executionCounts[index]++;
              // Success - no exception thrown
            },
          );
          await cacheService.enqueueOperation(operation);
        }
        
        // Verify operations are queued
        expect(cacheService.getRetryQueue().length, equals(operationCount));
        
        // Retry all operations
        await cacheService.retryQueuedOperations();
        
        // Verify all operations were executed exactly once
        for (var i = 0; i < operationCount; i++) {
          expect(executionCounts[i], equals(1),
              reason: 'Each successful operation should execute exactly once');
        }
        
        // Verify queue is empty after successful retries
        expect(cacheService.getRetryQueue().length, equals(0),
            reason: 'Queue should be empty after all operations succeed');
        
        // Clear for next test case
        await cacheService.clearRetryQueue();
      }
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Failed operations retry up to max attempts', () async {
      // Property test: For any operation that continues to fail, it should retry up to maxRetries times
      
      final random = Random();
      
      for (var testCase = 0; testCase < 10; testCase++) {
        final maxRetries = random.nextInt(5) + 1; // 1-5 max retries
        var executionCount = 0;
        
        final operation = QueuedOperation(
          id: 'failing_op_$testCase',
          operationType: 'log_workout',
          data: {'workoutId': random.nextInt(1000)},
          timestamp: DateTime.now(),
          maxRetries: maxRetries,
          executeCallback: () async {
            executionCount++;
            throw Exception('Network error');
          },
        );
        
        await cacheService.enqueueOperation(operation);
        
        // Retry multiple times until max retries exceeded
        for (var attempt = 0; attempt < maxRetries + 2; attempt++) {
          await cacheService.retryQueuedOperations();
        }
        
        // Verify operation was attempted exactly maxRetries times
        expect(executionCount, equals(maxRetries),
            reason: 'Operation should be attempted exactly $maxRetries times');
        
        // Verify operation was removed from queue after max retries
        expect(cacheService.getRetryQueue().length, equals(0),
            reason: 'Operation should be removed after exceeding max retries');
        
        // Clear for next test case
        await cacheService.clearRetryQueue();
      }
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Operations processed in FIFO order', () async {
      // Property test: For any set of queued operations, they should be processed in FIFO order
      
      final random = Random();
      
      for (var testCase = 0; testCase < 10; testCase++) {
        final operationCount = random.nextInt(20) + 5; // 5-24 operations
        final executionOrder = <String>[];
        
        // Create operations with random delays
        for (var i = 0; i < operationCount; i++) {
          final operationId = 'fifo_op_${testCase}_$i';
          final operation = QueuedOperation(
            id: operationId,
            operationType: 'log_workout',
            data: {'index': i},
            timestamp: DateTime.now().subtract(Duration(seconds: operationCount - i)),
            executeCallback: () async {
              executionOrder.add(operationId);
            },
          );
          await cacheService.enqueueOperation(operation);
        }
        
        // Process all operations
        await cacheService.retryQueuedOperations();
        
        // Verify operations were executed in FIFO order
        expect(executionOrder.length, equals(operationCount));
        for (var i = 0; i < operationCount; i++) {
          expect(executionOrder[i], equals('fifo_op_${testCase}_$i'),
              reason: 'Operation $i should execute in FIFO order');
        }
        
        // Clear for next test case
        await cacheService.clearRetryQueue();
      }
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Queue stops on first failure', () async {
      // Property test: For any queue with a failing operation, processing should stop at the failure
      
      final random = Random();
      
      for (var testCase = 0; testCase < 10; testCase++) {
        final totalOperations = random.nextInt(15) + 5; // 5-19 operations
        final failureIndex = random.nextInt(totalOperations - 2) + 1; // Fail somewhere in the middle
        final executionOrder = <String>[];
        
        for (var i = 0; i < totalOperations; i++) {
          final operationId = 'stop_op_${testCase}_$i';
          final operation = QueuedOperation(
            id: operationId,
            operationType: 'log_workout',
            data: {'index': i},
            timestamp: DateTime.now(),
            executeCallback: () async {
              executionOrder.add(operationId);
              if (i == failureIndex) {
                throw Exception('Network error at operation $i');
              }
            },
          );
          await cacheService.enqueueOperation(operation);
        }
        
        // Process operations (should stop at failure)
        await cacheService.retryQueuedOperations();
        
        // Verify operations up to and including failure were executed
        expect(executionOrder.length, equals(failureIndex + 1),
            reason: 'Should execute operations up to and including the failure at index $failureIndex');
        
        // Verify operations after failure were not executed
        for (var i = 0; i <= failureIndex; i++) {
          expect(executionOrder[i], equals('stop_op_${testCase}_$i'));
        }
        
        // Verify remaining operations are still in queue
        final remainingQueue = cacheService.getRetryQueue();
        expect(remainingQueue.length, equals(totalOperations - failureIndex),
            reason: 'Failed operation and subsequent operations should remain in queue');
        
        // Clear for next test case
        await cacheService.clearRetryQueue();
      }
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Retry count increments on failure', () async {
      // Property test: For any operation that fails, its retry count should increment
      
      final random = Random();
      
      for (var testCase = 0; testCase < 10; testCase++) {
        final maxRetries = random.nextInt(5) + 3; // 3-7 max retries
        var executionCount = 0;
        
        final operation = QueuedOperation(
          id: 'retry_count_op_$testCase',
          operationType: 'log_workout',
          data: {'workoutId': random.nextInt(1000)},
          timestamp: DateTime.now(),
          maxRetries: maxRetries,
          executeCallback: () async {
            executionCount++;
            throw Exception('Network error');
          },
        );
        
        await cacheService.enqueueOperation(operation);
        
        // Verify initial retry count is 0
        expect(cacheService.getRetryQueue()[0].retryCount, equals(0));
        
        // Retry and check retry count increments
        for (var attempt = 1; attempt <= maxRetries; attempt++) {
          await cacheService.retryQueuedOperations();
          
          if (attempt < maxRetries) {
            // Operation should still be in queue with incremented retry count
            final queue = cacheService.getRetryQueue();
            expect(queue.length, equals(1),
                reason: 'Operation should remain in queue before max retries');
            expect(queue[0].retryCount, equals(attempt),
                reason: 'Retry count should be $attempt after $attempt attempts');
          } else {
            // After max retries, operation should be removed
            expect(cacheService.getRetryQueue().length, equals(0),
                reason: 'Operation should be removed after $maxRetries attempts');
          }
        }
        
        // Clear for next test case
        await cacheService.clearRetryQueue();
      }
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Queue persists across service instances', () async {
      // Property test: For any queued operations, they should persist and be loadable by new service instances
      
      final random = Random();
      
      for (var testCase = 0; testCase < 10; testCase++) {
        final operationCount = random.nextInt(10) + 1; // 1-10 operations
        final operationIds = <String>[];
        
        // Create and enqueue operations
        for (var i = 0; i < operationCount; i++) {
          final operationId = 'persist_op_${testCase}_$i';
          operationIds.add(operationId);
          
          final operation = QueuedOperation(
            id: operationId,
            operationType: ['log_workout', 'update_pr', 'sync_data'][random.nextInt(3)],
            data: {
              'workoutId': random.nextInt(1000),
              'value': random.nextDouble() * 100,
            },
            timestamp: DateTime.now(),
            retryCount: random.nextInt(3), // Random retry count
            maxRetries: random.nextInt(5) + 3,
            executeCallback: () async {},
          );
          
          await cacheService.enqueueOperation(operation);
        }
        
        // Verify operations are queued
        expect(cacheService.getRetryQueue().length, equals(operationCount));
        
        // Create new service instance and load queue
        final newCacheService = CacheService();
        await newCacheService.loadRetryQueue();
        
        // Verify all operations were loaded
        final loadedQueue = newCacheService.getRetryQueue();
        expect(loadedQueue.length, equals(operationCount),
            reason: 'All $operationCount operations should be loaded from persistence');
        
        // Verify operation IDs match
        for (var i = 0; i < operationCount; i++) {
          expect(loadedQueue[i].id, equals(operationIds[i]),
              reason: 'Loaded operation IDs should match original IDs');
        }
        
        // Clear for next test case
        await cacheService.clearRetryQueue();
        await newCacheService.clearRetryQueue();
      }
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Mixed success and failure operations', () async {
      // Property test: For any mix of successful and failing operations, successful ones are removed and failures remain
      
      final random = Random();
      
      for (var testCase = 0; testCase < 10; testCase++) {
        final totalOperations = random.nextInt(15) + 5; // 5-19 operations
        final successIndices = <int>{};
        final executionCounts = List.filled(totalOperations, 0);
        
        // Randomly decide which operations will succeed
        for (var i = 0; i < totalOperations; i++) {
          if (random.nextBool()) {
            successIndices.add(i);
          }
        }
        
        // Create operations
        for (var i = 0; i < totalOperations; i++) {
          final index = i;
          final willSucceed = successIndices.contains(i);
          
          final operation = QueuedOperation(
            id: 'mixed_op_${testCase}_$i',
            operationType: 'log_workout',
            data: {'index': i, 'willSucceed': willSucceed},
            timestamp: DateTime.now(),
            maxRetries: 3,
            executeCallback: () async {
              executionCounts[index]++;
              if (!willSucceed) {
                throw Exception('Network error');
              }
            },
          );
          
          await cacheService.enqueueOperation(operation);
        }
        
        // Process operations
        await cacheService.retryQueuedOperations();
        
        // Find first failure index
        var firstFailureIndex = -1;
        for (var i = 0; i < totalOperations; i++) {
          if (!successIndices.contains(i)) {
            firstFailureIndex = i;
            break;
          }
        }
        
        if (firstFailureIndex == -1) {
          // All operations succeeded
          expect(cacheService.getRetryQueue().length, equals(0),
              reason: 'Queue should be empty when all operations succeed');
        } else {
          // Some operations failed
          final expectedRemaining = totalOperations - firstFailureIndex;
          expect(cacheService.getRetryQueue().length, equals(expectedRemaining),
              reason: 'Failed operation and subsequent operations should remain in queue');
          
          // Verify successful operations before first failure were executed
          for (var i = 0; i < firstFailureIndex; i++) {
            expect(executionCounts[i], equals(1),
                reason: 'Operation $i before first failure should execute once');
          }
        }
        
        // Clear for next test case
        await cacheService.clearRetryQueue();
      }
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Empty queue operations are safe', () async {
      // Property test: For any operations on an empty queue, they should not cause errors
      
      for (var testCase = 0; testCase < 10; testCase++) {
        // Ensure queue is empty
        await cacheService.clearRetryQueue();
        expect(cacheService.getRetryQueue().length, equals(0));
        
        // Try to process empty queue (should not throw)
        await cacheService.retryQueuedOperations();
        expect(cacheService.getRetryQueue().length, equals(0));
        
        // Try to process multiple times
        await cacheService.retryQueuedOperations();
        await cacheService.retryQueuedOperations();
        expect(cacheService.getRetryQueue().length, equals(0));
        
        // Clear again (should not throw)
        await cacheService.clearRetryQueue();
        expect(cacheService.getRetryQueue().length, equals(0));
      }
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Operation data integrity preserved', () async {
      // Property test: For any operation data, it should be preserved exactly through queue and retry
      
      final random = Random();
      
      for (var testCase = 0; testCase < 10; testCase++) {
        // Create complex operation data
        final originalData = {
          'workoutId': random.nextInt(10000),
          'userId': random.nextInt(1000),
          'duration': random.nextInt(300) + 1,
          'caloriesBurned': random.nextDouble() * 1000,
          'exercises': List.generate(random.nextInt(10) + 1, (i) => {
            'exerciseId': random.nextInt(100),
            'sets': random.nextInt(10) + 1,
            'reps': random.nextInt(50) + 1,
            'weight': random.nextDouble() * 200,
          }),
          'timestamp': DateTime.now().toIso8601String(),
          'notes': 'Test workout ${random.nextInt(1000)}',
          'hasNewPrs': random.nextBool(),
        };
        
        Map<String, dynamic>? capturedData;
        
        final operation = QueuedOperation(
          id: 'data_integrity_op_$testCase',
          operationType: 'log_workout',
          data: originalData,
          timestamp: DateTime.now(),
          executeCallback: () async {
            // Capture the data when executed
            capturedData = cacheService.getRetryQueue().first.data;
          },
        );
        
        await cacheService.enqueueOperation(operation);
        
        // Verify data in queue matches original
        final queuedData = cacheService.getRetryQueue()[0].data;
        expect(queuedData, equals(originalData),
            reason: 'Queued data should match original data exactly');
        
        // Process operation
        await cacheService.retryQueuedOperations();
        
        // Verify data during execution matched original
        expect(capturedData, equals(originalData),
            reason: 'Data during execution should match original data exactly');
        
        // Clear for next test case
        await cacheService.clearRetryQueue();
      }
    });

    test('Feature: workout-tracking-system, Property 38: Network Failure Retry Queue - Concurrent enqueue operations', () async {
      // Property test: For any concurrent enqueue operations, all should be queued correctly
      
      final random = Random();
      
      for (var testCase = 0; testCase < 10; testCase++) {
        final operationCount = random.nextInt(20) + 10; // 10-29 operations
        final operations = <QueuedOperation>[];
        
        // Create operations
        for (var i = 0; i < operationCount; i++) {
          final operation = QueuedOperation(
            id: 'concurrent_op_${testCase}_$i',
            operationType: 'log_workout',
            data: {'index': i},
            timestamp: DateTime.now(),
            executeCallback: () async {},
          );
          operations.add(operation);
        }
        
        // Enqueue all operations concurrently
        await Future.wait(
          operations.map((op) => cacheService.enqueueOperation(op))
        );
        
        // Verify all operations were queued
        final queue = cacheService.getRetryQueue();
        expect(queue.length, equals(operationCount),
            reason: 'All $operationCount concurrent operations should be queued');
        
        // Verify all operation IDs are present (order may vary due to concurrency)
        final queuedIds = queue.map((op) => op.id).toSet();
        final expectedIds = operations.map((op) => op.id).toSet();
        expect(queuedIds, equals(expectedIds),
            reason: 'All operation IDs should be present in queue');
        
        // Clear for next test case
        await cacheService.clearRetryQueue();
      }
    });
  });
}
