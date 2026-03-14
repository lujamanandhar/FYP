import '../models/workout_log.dart';
import '../models/workout_models.dart' show CreateWorkoutLogRequest;
import '../services/workout_api_service.dart';
import '../services/workout_cache_service.dart';
import 'workout_repository.dart';
import 'dart:io';
import 'package:dio/dio.dart';

/// Cached implementation of [WorkoutRepository] that combines API calls with local caching.
/// 
/// This repository provides:
/// - Local caching of workout history for offline viewing
/// - Cache synchronization on startup
/// - Optimistic updates for workout logging
/// - Fallback to cached data when network is unavailable
/// - Retry queue for failed operations due to network issues
/// 
/// Validates: Requirements 8.5, 14.4, 14.5, 14.6
class CachedWorkoutRepository implements WorkoutRepository {
  final WorkoutApiService _apiService;
  final WorkoutCacheService _cacheService;

  CachedWorkoutRepository(this._apiService, this._cacheService);

  @override
  Future<List<WorkoutLog>> getWorkoutHistory({
    DateTime? dateFrom,
    int? limit,
  }) async {
    try {
      // Try to fetch from API
      final workouts = await _apiService.getWorkoutHistory(
        dateFrom: dateFrom,
        limit: limit,
      );

      // Cache the results
      await _cacheService.cacheWorkoutHistory(workouts);

      return workouts;
    } catch (e) {
      // If API call fails, try to return cached data
      print('API call failed, attempting to use cached data: $e');
      
      final cachedWorkouts = await _cacheService.getCachedWorkoutHistory();
      if (cachedWorkouts != null) {
        // Apply filters to cached data
        var filtered = cachedWorkouts;
        
        if (dateFrom != null) {
          filtered = filtered
              .where((w) => w.date.isAfter(dateFrom) || w.date.isAtSameMomentAs(dateFrom))
              .toList();
        }
        
        if (limit != null && limit < filtered.length) {
          filtered = filtered.take(limit).toList();
        }
        
        return filtered;
      }

      // No cached data available, rethrow the error
      rethrow;
    }
  }

  @override
  Future<WorkoutLog> logWorkout(CreateWorkoutLogRequest workout) async {
    try {
      // Log workout via API
      final loggedWorkout = await _apiService.logWorkout(workout);

      // Add to cache for immediate availability
      await _cacheService.addWorkoutToCache(loggedWorkout);

      return loggedWorkout;
    } catch (e) {
      // Check if this is a network failure
      if (_isNetworkError(e)) {
        print('Network error detected, queueing workout for retry: $e');
        
        // Queue the operation for retry when network is restored
        await _cacheService.queueOperation(
          type: 'log_workout',
          data: workout.toJson(),
        );
        
        // Rethrow to let the UI know the operation failed
        rethrow;
      }
      
      // For non-network errors, just rethrow
      print('Failed to log workout: $e');
      rethrow;
    }
  }

  /// Check if an error is a network-related error
  bool _isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
             error.type == DioExceptionType.sendTimeout ||
             error.type == DioExceptionType.receiveTimeout ||
             error.type == DioExceptionType.connectionError ||
             error.error is SocketException;
    }
    
    if (error is SocketException) {
      return true;
    }
    
    return false;
  }

  /// Retry all queued operations
  /// 
  /// This should be called when network connectivity is restored.
  /// 
  /// Validates: Requirements 14.6
  Future<void> retryQueuedOperations() async {
    final operations = await _cacheService.getQueuedOperations();
    
    if (operations.isEmpty) {
      print('No queued operations to retry');
      return;
    }
    
    print('Retrying ${operations.length} queued operations...');
    
    for (final operation in operations) {
      try {
        await _retryOperation(operation);
        
        // If successful, remove from queue
        await _cacheService.removeQueuedOperation(operation.id);
        print('Successfully retried operation ${operation.id}');
      } catch (e) {
        print('Failed to retry operation ${operation.id}: $e');
        
        // Increment retry count
        await _cacheService.incrementRetryCount(operation.id);
        
        // If retry count exceeds threshold, consider removing
        if (operation.retryCount >= 5) {
          print('Operation ${operation.id} exceeded max retries, removing from queue');
          await _cacheService.removeQueuedOperation(operation.id);
        }
      }
    }
  }

  /// Retry a specific queued operation
  Future<void> _retryOperation(QueuedOperation operation) async {
    switch (operation.type) {
      case 'log_workout':
        final request = CreateWorkoutLogRequest.fromJson(operation.data);
        final loggedWorkout = await _apiService.logWorkout(request);
        await _cacheService.addWorkoutToCache(loggedWorkout);
        break;
      
      default:
        print('Unknown operation type: ${operation.type}');
    }
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    // Statistics are always fetched fresh from the API
    // They are calculated on the backend and not cached locally
    return await _apiService.getStatistics(
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  /// Synchronize cached data with the backend on app startup.
  /// 
  /// This method should be called when the app starts to ensure
  /// local cache is up-to-date with the backend.
  /// 
  /// Also retries any queued operations from previous network failures.
  /// 
  /// Validates: Requirements 14.5, 14.6
  Future<void> synchronizeCache() async {
    try {
      // Check if sync is needed
      if (!_cacheService.needsSync()) {
        print('Cache is fresh, skipping sync');
      } else {
        print('Synchronizing workout cache with backend...');

        // Fetch latest workout history
        final workouts = await _apiService.getWorkoutHistory();
        await _cacheService.cacheWorkoutHistory(workouts);

        print('Workout cache synchronized successfully');
      }
      
      // Retry any queued operations now that we have network
      await retryQueuedOperations();
    } catch (e) {
      print('Failed to synchronize workout cache: $e');
      // Don't throw - we can continue with stale cache
    }
  }

  /// Clear all cached workout data
  Future<void> clearCache() async {
    await _cacheService.clearWorkoutHistoryCache();
  }

  /// Check if cached data is available
  bool hasCachedData() {
    return _cacheService.hasCachedData();
  }
}
