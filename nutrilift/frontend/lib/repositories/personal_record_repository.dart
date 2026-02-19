import '../models/personal_record.dart';

/// Repository interface for personal record data operations.
/// 
/// This interface defines the contract for accessing personal record data,
/// following the repository pattern to abstract data sources.
/// Implementations can be API-based, mock-based, or cache-based.
abstract class PersonalRecordRepository {
  /// Retrieves all personal records for the authenticated user.
  /// 
  /// Returns a list of [PersonalRecord] objects containing the user's
  /// maximum achievements for each exercise they have performed.
  /// Each record includes:
  /// - Exercise information (id, name)
  /// - Record type (max_weight, max_reps, max_volume)
  /// - Achievement value and unit
  /// - Date achieved
  /// - Associated workout log reference
  /// 
  /// Personal records are automatically updated by the backend when
  /// new workouts exceed previous records.
  /// 
  /// Validates: Requirements 4.6, 5.4
  Future<List<PersonalRecord>> getPersonalRecords();

  /// Retrieves the personal record for a specific exercise.
  /// 
  /// Parameters:
  /// - [exerciseId]: The unique identifier of the exercise
  /// 
  /// Returns the [PersonalRecord] for the specified exercise,
  /// or null if no record exists for that exercise.
  /// 
  /// This is useful for displaying PR information when viewing
  /// exercise details or when logging a workout with that exercise.
  /// 
  /// Validates: Requirements 4.4
  Future<PersonalRecord?> getPersonalRecordForExercise(String exerciseId);
}
