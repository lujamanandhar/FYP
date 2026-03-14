import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/workout_log.dart';
import '../models/exercise.dart';
import '../models/personal_record.dart';

/// Represents a queued operation that failed due to network issues
class QueuedOperation {
  final String id;
  final String type; // 'log_workout', 'update_pr', etc.
  final Map<String, dynamic> data;
  final DateTime queuedAt;
  final int retryCount;

  QueuedOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.queuedAt,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'data': data,
    'queuedAt': queuedAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory QueuedOperation.fromJson(Map<String, dynamic> json) => QueuedOperation(
    id: json['id'] as String,
    type: json['type'] as String,
    data: json['data'] as Map<String, dynamic>,
    queuedAt: DateTime.parse(json['queuedAt'] as String),
    retryCount: json['retryCount'] as int? ?? 0,
  );

  QueuedOperation copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    DateTime? queuedAt,
    int? retryCount,
  }) => QueuedOperation(
    id: id ?? this.id,
    type: type ?? this.type,
    data: data ?? this.data,
    queuedAt: queuedAt ?? this.queuedAt,
    retryCount: retryCount ?? this.retryCount,
  );
}

/// Cache service for workout-related data using SharedPreferences.
/// 
/// Provides local caching for workouts, exercises, and personal records
/// to support offline viewing and improve performance.
/// 
/// Also manages a retry queue for operations that fail due to network issues.
/// 
/// Validates: Requirements 8.5, 14.4, 14.5, 14.6
class WorkoutCacheService {
  static const String _workoutHistoryKey = 'workout_history';
  static const String _exercisesKey = 'exercises';
  static const String _personalRecordsKey = 'personal_records';
  static const String _lastSyncKey = 'last_sync_time';
  static const String _retryQueueKey = 'retry_queue';
  
  final SharedPreferences _prefs;

  WorkoutCacheService(this._prefs);

  /// Factory constructor to create an instance with SharedPreferences
  static Future<WorkoutCacheService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return WorkoutCacheService(prefs);
  }

  // ==================== Workout History Caching ====================

  /// Cache workout history locally
  Future<void> cacheWorkoutHistory(List<WorkoutLog> workouts) async {
    try {
      final jsonList = workouts.map((w) => w.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_workoutHistoryKey, jsonString);
      await _updateLastSyncTime();
    } catch (e) {
      print('Error caching workout history: $e');
    }
  }

  /// Retrieve cached workout history
  Future<List<WorkoutLog>?> getCachedWorkoutHistory() async {
    try {
      final jsonString = _prefs.getString(_workoutHistoryKey);
      if (jsonString == null) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => WorkoutLog.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error retrieving cached workout history: $e');
      return null;
    }
  }

  /// Add a single workout to the cache
  Future<void> addWorkoutToCache(WorkoutLog workout) async {
    try {
      final cached = await getCachedWorkoutHistory() ?? [];
      cached.insert(0, workout); // Add to beginning (newest first)
      await cacheWorkoutHistory(cached);
    } catch (e) {
      print('Error adding workout to cache: $e');
    }
  }

  /// Clear workout history cache
  Future<void> clearWorkoutHistoryCache() async {
    await _prefs.remove(_workoutHistoryKey);
  }

  // ==================== Exercise Caching ====================

  /// Cache exercises locally
  Future<void> cacheExercises(List<Exercise> exercises) async {
    try {
      final jsonList = exercises.map((e) => e.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_exercisesKey, jsonString);
      await _updateLastSyncTime();
    } catch (e) {
      print('Error caching exercises: $e');
    }
  }

  /// Retrieve cached exercises
  Future<List<Exercise>?> getCachedExercises() async {
    try {
      final jsonString = _prefs.getString(_exercisesKey);
      if (jsonString == null) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => Exercise.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error retrieving cached exercises: $e');
      return null;
    }
  }

  /// Clear exercises cache
  Future<void> clearExercisesCache() async {
    await _prefs.remove(_exercisesKey);
  }

  // ==================== Personal Records Caching ====================

  /// Cache personal records locally
  Future<void> cachePersonalRecords(List<PersonalRecord> prs) async {
    try {
      final jsonList = prs.map((pr) => pr.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_personalRecordsKey, jsonString);
      await _updateLastSyncTime();
    } catch (e) {
      print('Error caching personal records: $e');
    }
  }

  /// Retrieve cached personal records
  Future<List<PersonalRecord>?> getCachedPersonalRecords() async {
    try {
      final jsonString = _prefs.getString(_personalRecordsKey);
      if (jsonString == null) return null;

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => PersonalRecord.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error retrieving cached personal records: $e');
      return null;
    }
  }

  /// Clear personal records cache
  Future<void> clearPersonalRecordsCache() async {
    await _prefs.remove(_personalRecordsKey);
  }

  // ==================== Sync Management ====================

  /// Update the last sync timestamp
  Future<void> _updateLastSyncTime() async {
    await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Get the last sync timestamp
  DateTime? getLastSyncTime() {
    final syncTimeString = _prefs.getString(_lastSyncKey);
    if (syncTimeString == null) return null;
    
    try {
      return DateTime.parse(syncTimeString);
    } catch (e) {
      print('Error parsing last sync time: $e');
      return null;
    }
  }

  /// Check if cache needs synchronization (older than specified duration)
  bool needsSync({Duration maxAge = const Duration(hours: 1)}) {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return true;
    
    return DateTime.now().difference(lastSync) > maxAge;
  }

  /// Clear all workout-related caches
  Future<void> clearAllCaches() async {
    await Future.wait([
      clearWorkoutHistoryCache(),
      clearExercisesCache(),
      clearPersonalRecordsCache(),
      _prefs.remove(_lastSyncKey),
    ]);
  }

  /// Check if any cached data exists
  bool hasCachedData() {
    return _prefs.containsKey(_workoutHistoryKey) ||
           _prefs.containsKey(_exercisesKey) ||
           _prefs.containsKey(_personalRecordsKey);
  }

  // ==================== Retry Queue Management ====================

  /// Queue an operation for retry when network is restored
  /// 
  /// Validates: Requirements 14.6
  Future<void> queueOperation({
    required String type,
    required Map<String, dynamic> data,
  }) async {
    try {
      final operations = await getQueuedOperations();
      final newOperation = QueuedOperation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        data: data,
        queuedAt: DateTime.now(),
      );
      
      operations.add(newOperation);
      await _saveQueuedOperations(operations);
    } catch (e) {
      print('Error queueing operation: $e');
    }
  }

  /// Get all queued operations
  Future<List<QueuedOperation>> getQueuedOperations() async {
    try {
      final jsonString = _prefs.getString(_retryQueueKey);
      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => QueuedOperation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error retrieving queued operations: $e');
      return [];
    }
  }

  /// Save queued operations to storage
  Future<void> _saveQueuedOperations(List<QueuedOperation> operations) async {
    try {
      final jsonList = operations.map((op) => op.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _prefs.setString(_retryQueueKey, jsonString);
    } catch (e) {
      print('Error saving queued operations: $e');
    }
  }

  /// Remove an operation from the queue
  Future<void> removeQueuedOperation(String operationId) async {
    try {
      final operations = await getQueuedOperations();
      operations.removeWhere((op) => op.id == operationId);
      await _saveQueuedOperations(operations);
    } catch (e) {
      print('Error removing queued operation: $e');
    }
  }

  /// Increment retry count for an operation
  Future<void> incrementRetryCount(String operationId) async {
    try {
      final operations = await getQueuedOperations();
      final index = operations.indexWhere((op) => op.id == operationId);
      
      if (index != -1) {
        operations[index] = operations[index].copyWith(
          retryCount: operations[index].retryCount + 1,
        );
        await _saveQueuedOperations(operations);
      }
    } catch (e) {
      print('Error incrementing retry count: $e');
    }
  }

  /// Clear all queued operations
  Future<void> clearRetryQueue() async {
    await _prefs.remove(_retryQueueKey);
  }

  /// Check if there are any queued operations
  bool hasQueuedOperations() {
    return _prefs.containsKey(_retryQueueKey);
  }

  /// Get count of queued operations
  Future<int> getQueuedOperationCount() async {
    final operations = await getQueuedOperations();
    return operations.length;
  }
}
