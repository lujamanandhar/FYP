import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache Service
/// 
/// Provides local caching functionality for workout data.
/// Supports offline viewing and synchronization.
/// 
/// Validates: Requirements 8.5, 14.4, 14.5
class CacheService {
  static const String _workoutHistoryKey = 'workout_history';
  static const String _exercisesKey = 'exercises';
  static const String _personalRecordsKey = 'personal_records';
  static const String _queueKey = 'operation_queue';

  final SharedPreferences _prefs;

  CacheService(this._prefs);

  /// Cache workout history
  Future<void> cacheWorkoutHistory(List<Map<String, dynamic>> workouts) async {
    final json = jsonEncode(workouts);
    await _prefs.setString(_workoutHistoryKey, json);
  }

  /// Get cached workout history
  List<Map<String, dynamic>>? getCachedWorkoutHistory() {
    final json = _prefs.getString(_workoutHistoryKey);
    if (json == null) return null;
    
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Cache exercises
  Future<void> cacheExercises(List<Map<String, dynamic>> exercises) async {
    final json = jsonEncode(exercises);
    await _prefs.setString(_exercisesKey, json);
  }

  /// Get cached exercises
  List<Map<String, dynamic>>? getCachedExercises() {
    final json = _prefs.getString(_exercisesKey);
    if (json == null) return null;
    
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Cache personal records
  Future<void> cachePersonalRecords(List<Map<String, dynamic>> prs) async {
    final json = jsonEncode(prs);
    await _prefs.setString(_personalRecordsKey, json);
  }

  /// Get cached personal records
  List<Map<String, dynamic>>? getCachedPersonalRecords() {
    final json = _prefs.getString(_personalRecordsKey);
    if (json == null) return null;
    
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  /// Queue an operation for retry
  Future<void> queueOperation(QueuedOperation operation) async {
    final queue = getQueuedOperations();
    queue.add(operation);
    await _saveQueue(queue);
  }

  /// Get all queued operations
  List<QueuedOperation> getQueuedOperations() {
    final json = _prefs.getString(_queueKey);
    if (json == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded
          .map((item) => QueuedOperation.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Remove an operation from the queue
  Future<void> removeQueuedOperation(String id) async {
    final queue = getQueuedOperations();
    queue.removeWhere((op) => op.id == id);
    await _saveQueue(queue);
  }

  /// Clear all queued operations
  Future<void> clearQueue() async {
    await _prefs.remove(_queueKey);
  }

  /// Save the operation queue
  Future<void> _saveQueue(List<QueuedOperation> queue) async {
    final json = jsonEncode(queue.map((op) => op.toJson()).toList());
    await _prefs.setString(_queueKey, json);
  }

  /// Clear all cached data
  Future<void> clearAll() async {
    await _prefs.remove(_workoutHistoryKey);
    await _prefs.remove(_exercisesKey);
    await _prefs.remove(_personalRecordsKey);
    await _prefs.remove(_queueKey);
  }
}

/// Queued Operation
/// 
/// Represents an operation that failed and needs to be retried.
class QueuedOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  QueuedOperation({
    required this.id,
    required this.type,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  factory QueuedOperation.fromJson(Map<String, dynamic> json) {
    return QueuedOperation(
      id: json['id'] as String,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      timestamp: DateTime.parse(json['timestamp'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  QueuedOperation copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return QueuedOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
