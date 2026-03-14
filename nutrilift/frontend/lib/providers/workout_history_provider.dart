import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/workout_log.dart';
import '../repositories/workout_repository.dart';
import 'repository_providers.dart';

/// State notifier for managing workout history data
/// 
/// This notifier manages the state of workout history, including
/// loading, refreshing, and filtering workouts by date range.
/// 
/// The state is an AsyncValue<List<WorkoutLog>> which handles
/// loading, error, and data states automatically.
/// 
/// Validates: Requirements 1.1, 1.5, 8.1
class WorkoutHistoryNotifier extends StateNotifier<AsyncValue<List<WorkoutLog>>> {
  final WorkoutRepository _repository;
  
  // Store current filter parameters for refresh
  DateTime? _currentDateFrom;
  int? _currentLimit;

  WorkoutHistoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    // Load workouts on initialization
    loadWorkouts();
  }

  /// Load workouts from the repository
  /// 
  /// Parameters:
  /// - [dateFrom]: Optional filter to get workouts from this date onwards
  /// - [limit]: Optional limit on the number of workouts to return
  /// 
  /// Sets the state to loading, then updates with data or error.
  /// Stores filter parameters for refresh functionality.
  /// 
  /// Validates: Requirements 1.1, 1.2, 1.7
  Future<void> loadWorkouts({DateTime? dateFrom, int? limit}) async {
    // Store current filters for refresh
    _currentDateFrom = dateFrom;
    _currentLimit = limit;
    
    // Set loading state
    if (mounted) {
      state = const AsyncValue.loading();
    }
    
    // Load data and update state
    final result = await AsyncValue.guard(() => _repository.getWorkoutHistory(
      dateFrom: dateFrom,
      limit: limit,
    ));
    
    if (mounted) {
      state = result;
    }
  }

  /// Refresh workout history with current filters
  /// 
  /// Re-fetches workout data using the same filters as the last load.
  /// This is useful for pull-to-refresh functionality.
  /// 
  /// Validates: Requirements 1.5, 8.1, 8.3
  Future<void> refresh() async {
    await loadWorkouts(
      dateFrom: _currentDateFrom,
      limit: _currentLimit,
    );
  }

  /// Apply date range filter to workout history
  /// 
  /// Filters workouts to only show those within the specified date range.
  /// If dateTo is provided, filters workouts on the client side.
  /// 
  /// Validates: Requirements 1.2
  Future<void> filterByDateRange(DateTime? dateFrom, DateTime? dateTo) async {
    // Store the date range for filtering
    _currentDateFrom = dateFrom;
    
    // Load workouts from the backend with dateFrom filter
    await loadWorkouts(dateFrom: dateFrom, limit: _currentLimit);
    
    // If dateTo is specified, filter the results client-side
    if (dateTo != null && state is AsyncData<List<WorkoutLog>>) {
      final currentState = state as AsyncData<List<WorkoutLog>>;
      final filteredWorkouts = currentState.value
          .where((workout) => workout.date.isBefore(dateTo.add(const Duration(days: 1))))
          .toList();
      
      if (mounted) {
        state = AsyncValue.data(filteredWorkouts);
      }
    }
  }

  /// Clear date range filter
  /// 
  /// Resets the date filter to show all workouts.
  Future<void> clearDateFilter() async {
    await loadWorkouts(limit: _currentLimit);
  }

  /// Load more workouts for pagination
  /// 
  /// Appends additional workouts to the current list.
  /// Used for infinite scroll functionality.
  /// 
  /// Validates: Requirements 12.2
  Future<void> loadMore() async {
    final currentState = state;
    
    // Only load more if we have data
    if (currentState is AsyncData<List<WorkoutLog>>) {
      final currentWorkouts = currentState.value;
      
      // Don't load more if we have no workouts or less than the limit
      if (currentWorkouts.isEmpty || 
          (_currentLimit != null && currentWorkouts.length < _currentLimit!)) {
        return;
      }

      try {
        // Get the date of the oldest workout
        final oldestDate = currentWorkouts.last.date;
        
        // Load more workouts before this date
        final moreWorkouts = await _repository.getWorkoutHistory(
          dateFrom: _currentDateFrom,
          limit: _currentLimit,
        );

        // Filter out workouts we already have and append new ones
        final newWorkouts = moreWorkouts
            .where((w) => w.date.isBefore(oldestDate))
            .toList();

        if (newWorkouts.isNotEmpty && mounted) {
          state = AsyncValue.data([...currentWorkouts, ...newWorkouts]);
        }
      } catch (error, stackTrace) {
        // Don't replace the current data on error, just log it
        // The UI can show a "failed to load more" message
        if (mounted) {
          state = AsyncValue.error(error, stackTrace);
        }
      }
    }
  }
}

/// Provider for workout history state
/// 
/// This provider creates and manages the WorkoutHistoryNotifier,
/// which handles loading, refreshing, and filtering workout history.
/// 
/// The state is automatically updated when workouts are loaded,
/// and all UI components watching this provider will rebuild.
/// 
/// Validates: Requirements 1.1, 1.5, 8.1
final workoutHistoryProvider = StateNotifierProvider<WorkoutHistoryNotifier, AsyncValue<List<WorkoutLog>>>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  return WorkoutHistoryNotifier(repository);
});
