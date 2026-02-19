import 'workout_repository.dart';
import '../models/workout_log.dart';
import '../models/workout_exercise.dart';
import '../models/workout_models.dart' show CreateWorkoutLogRequest;

/// Mock implementation of [WorkoutRepository] for testing and offline development.
/// 
/// This repository stores workout data in memory and provides mock data
/// for all repository methods. It simulates API behavior without requiring
/// a backend connection.
/// 
/// Validates: Requirements 7.9
class MockWorkoutRepository implements WorkoutRepository {
  final List<WorkoutLog> _workouts = [];
  int _nextId = 1;

  /// Creates a mock repository with optional pre-populated workout data.
  MockWorkoutRepository({List<WorkoutLog>? initialWorkouts}) {
    if (initialWorkouts != null) {
      _workouts.addAll(initialWorkouts);
      // Set next ID to be higher than any existing ID
      if (_workouts.isNotEmpty) {
        final maxId = _workouts
            .where((w) => w.id != null)
            .map((w) => w.id!)
            .fold(0, (max, id) => id > max ? id : max);
        _nextId = maxId + 1;
      }
    } else {
      // Add some default mock data
      _workouts.addAll(_generateMockWorkouts());
    }
  }

  @override
  Future<List<WorkoutLog>> getWorkoutHistory({
    DateTime? dateFrom,
    int? limit,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    var filtered = List<WorkoutLog>.from(_workouts);

    // Apply date filter
    if (dateFrom != null) {
      filtered = filtered.where((w) => w.date.isAfter(dateFrom) || w.date.isAtSameMomentAs(dateFrom)).toList();
    }

    // Sort by date descending (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    // Apply limit
    if (limit != null && limit < filtered.length) {
      filtered = filtered.take(limit).toList();
    }

    return filtered;
  }

  @override
  Future<WorkoutLog> logWorkout(CreateWorkoutLogRequest workout) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Convert request to WorkoutLog
    final newWorkout = WorkoutLog(
      id: _nextId++,
      user: 1, // Mock user ID
      customWorkoutId: workout.customWorkoutId != null ? int.tryParse(workout.customWorkoutId!) : null,
      workoutName: workout.workoutName,
      gym: workout.gymId != null ? int.tryParse(workout.gymId!) : null,
      gymName: workout.gymId != null ? 'Mock Gym' : null,
      date: DateTime.now(),
      duration: workout.durationMinutes,
      caloriesBurned: workout.caloriesBurned,
      notes: workout.notes,
      exercises: workout.exercises.map((e) {
        // Calculate total reps and weight for volume
        final totalReps = e.sets.fold<int>(0, (sum, set) => sum + (set.reps ?? 0));
        final avgWeight = e.sets.fold<double>(0, (sum, set) => sum + (set.weight ?? 0)) / e.sets.length;
        final volume = totalReps * avgWeight;
        
        return WorkoutExercise(
          id: _nextId++,
          exerciseId: int.parse(e.exerciseId),
          exerciseName: 'Exercise ${e.exerciseId}',
          sets: e.sets.length,
          reps: totalReps ~/ e.sets.length, // Average reps per set
          weight: avgWeight,
          volume: volume,
          order: e.order,
        );
      }).toList(),
      hasNewPrs: false, // Mock: randomly set PRs
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _workouts.add(newWorkout);
    return newWorkout;
  }

  @override
  Future<Map<String, dynamic>> getStatistics({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));

    var filtered = List<WorkoutLog>.from(_workouts);

    // Apply date filters
    if (dateFrom != null) {
      filtered = filtered.where((w) => w.date.isAfter(dateFrom) || w.date.isAtSameMomentAs(dateFrom)).toList();
    }
    if (dateTo != null) {
      filtered = filtered.where((w) => w.date.isBefore(dateTo) || w.date.isAtSameMomentAs(dateTo)).toList();
    }

    if (filtered.isEmpty) {
      return {
        'total_workouts': 0,
        'total_calories': 0.0,
        'total_duration': 0,
        'average_duration': 0.0,
        'average_calories': 0.0,
        'workouts_by_category': <String, int>{},
        'most_frequent_exercises': <Map<String, dynamic>>[],
        'workout_frequency': <String, int>{},
      };
    }

    final totalWorkouts = filtered.length;
    final totalCalories = filtered.fold<double>(0, (sum, w) => sum + w.caloriesBurned);
    final totalDuration = filtered.fold<int>(0, (sum, w) => sum + w.duration);
    final avgDuration = totalDuration / totalWorkouts;
    final avgCalories = totalCalories / totalWorkouts;

    // Calculate workouts by category (mock data)
    final workoutsByCategory = <String, int>{
      'Strength': (totalWorkouts * 0.6).round(),
      'Cardio': (totalWorkouts * 0.3).round(),
      'Bodyweight': (totalWorkouts * 0.1).round(),
    };

    // Calculate most frequent exercises
    final exerciseFrequency = <String, int>{};
    for (final workout in filtered) {
      for (final exercise in workout.exercises) {
        exerciseFrequency[exercise.exerciseName] = 
            (exerciseFrequency[exercise.exerciseName] ?? 0) + 1;
      }
    }
    final mostFrequent = exerciseFrequency.entries
        .map((e) => {'name': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    // Calculate workout frequency by month
    final workoutFrequency = <String, int>{};
    for (final workout in filtered) {
      final monthKey = '${workout.date.year}-${workout.date.month.toString().padLeft(2, '0')}';
      workoutFrequency[monthKey] = (workoutFrequency[monthKey] ?? 0) + 1;
    }

    return {
      'total_workouts': totalWorkouts,
      'total_calories': totalCalories,
      'total_duration': totalDuration,
      'average_duration': avgDuration,
      'average_calories': avgCalories,
      'workouts_by_category': workoutsByCategory,
      'most_frequent_exercises': mostFrequent.take(5).toList(),
      'workout_frequency': workoutFrequency,
    };
  }

  /// Clears all workouts from the mock repository.
  void clear() {
    _workouts.clear();
    _nextId = 1;
  }

  /// Adds a workout directly to the mock repository (for testing).
  void addWorkout(WorkoutLog workout) {
    _workouts.add(workout);
    if (workout.id != null && workout.id! >= _nextId) {
      _nextId = workout.id! + 1;
    }
  }

  /// Generates mock workout data for initial population.
  List<WorkoutLog> _generateMockWorkouts() {
    final now = DateTime.now();
    return [
      WorkoutLog(
        id: _nextId++,
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
            id: _nextId++,
            exerciseId: 1,
            exerciseName: 'Bench Press',
            sets: 3,
            reps: 10,
            weight: 100.0,
            volume: 3000.0,
            order: 0,
          ),
          WorkoutExercise(
            id: _nextId++,
            exerciseId: 2,
            exerciseName: 'Shoulder Press',
            sets: 4,
            reps: 8,
            weight: 80.0,
            volume: 2560.0,
            order: 1,
          ),
        ],
        hasNewPrs: true,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      WorkoutLog(
        id: _nextId++,
        user: 1,
        customWorkoutId: 2,
        workoutName: 'Leg Day',
        gym: null,
        gymName: null,
        date: now.subtract(const Duration(days: 4)),
        duration: 75,
        caloriesBurned: 520.0,
        notes: 'Tough leg session',
        exercises: [
          WorkoutExercise(
            id: _nextId++,
            exerciseId: 3,
            exerciseName: 'Squats',
            sets: 4,
            reps: 12,
            weight: 120.0,
            volume: 5760.0,
            order: 0,
          ),
          WorkoutExercise(
            id: _nextId++,
            exerciseId: 4,
            exerciseName: 'Leg Press',
            sets: 3,
            reps: 15,
            weight: 200.0,
            volume: 9000.0,
            order: 1,
          ),
        ],
        hasNewPrs: false,
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      WorkoutLog(
        id: _nextId++,
        user: 1,
        customWorkoutId: 3,
        workoutName: 'Pull Day',
        gym: 1,
        gymName: "Gold's Gym",
        date: now.subtract(const Duration(days: 6)),
        duration: 55,
        caloriesBurned: 420.0,
        notes: null,
        exercises: [
          WorkoutExercise(
            id: _nextId++,
            exerciseId: 5,
            exerciseName: 'Deadlift',
            sets: 3,
            reps: 8,
            weight: 150.0,
            volume: 3600.0,
            order: 0,
          ),
          WorkoutExercise(
            id: _nextId++,
            exerciseId: 6,
            exerciseName: 'Pull-ups',
            sets: 4,
            reps: 10,
            weight: 0.0,
            volume: 0.0,
            order: 1,
          ),
        ],
        hasNewPrs: false,
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
    ];
  }
}
