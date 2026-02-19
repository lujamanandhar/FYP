import '../models/workout_log.dart';
import '../models/workout_models.dart' show CreateWorkoutLogRequest;

/// Repository interface for workout-related data operations.
/// 
/// This interface defines the contract for accessing workout data,
/// following the repository pattern to abstract data sources.
/// Implementations can be API-based, mock-based, or cache-based.
abstract class WorkoutRepository {
  /// Retrieves workout history for the authenticated user.
  /// 
  /// Parameters:
  /// - [dateFrom]: Optional filter to get workouts from this date onwards
  /// - [limit]: Optional limit on the number of workouts to return
  /// 
  /// Returns a list of [WorkoutLog] objects ordered by date descending.
  /// 
  /// Validates: Requirements 1.2, 1.7
  Future<List<WorkoutLog>> getWorkoutHistory({
    DateTime? dateFrom,
    int? limit,
  });

  /// Logs a new workout for the authenticated user.
  /// 
  /// Parameters:
  /// - [workout]: The workout log request containing all workout details
  /// 
  /// Returns the created [WorkoutLog] with server-generated fields
  /// (id, calculated calories, PR flags, timestamps).
  /// 
  /// Validates: Requirements 2.8, 2.9, 5.1, 14.1, 14.2
  Future<WorkoutLog> logWorkout(CreateWorkoutLogRequest workout);

  /// Retrieves aggregate statistics about the user's workouts.
  /// 
  /// Parameters:
  /// - [dateFrom]: Optional start date for statistics calculation
  /// - [dateTo]: Optional end date for statistics calculation
  /// 
  /// Returns a map containing:
  /// - total_workouts: Total number of workouts
  /// - total_calories: Total calories burned
  /// - total_duration: Total workout time in minutes
  /// - average_duration: Average workout duration
  /// - average_calories: Average calories per workout
  /// - workouts_by_category: Breakdown by exercise category
  /// - most_frequent_exercises: List of most performed exercises
  /// - workout_frequency: Workout count by time period
  /// 
  /// Validates: Requirements 5.5, 15.1, 15.2, 15.3, 15.4, 15.5
  Future<Map<String, dynamic>> getStatistics({
    DateTime? dateFrom,
    DateTime? dateTo,
  });
}
