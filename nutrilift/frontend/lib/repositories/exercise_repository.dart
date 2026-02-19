import '../models/exercise.dart';

/// Repository interface for exercise-related data operations.
/// 
/// This interface defines the contract for accessing exercise library data,
/// following the repository pattern to abstract data sources.
/// Implementations can be API-based, mock-based, or cache-based.
abstract class ExerciseRepository {
  /// Retrieves exercises from the library with optional filtering.
  /// 
  /// Parameters:
  /// - [category]: Optional filter by exercise category (Strength, Cardio, Bodyweight)
  /// - [muscleGroup]: Optional filter by target muscle group (Chest, Back, Legs, Core, Arms, Shoulders, Full Body)
  /// - [equipment]: Optional filter by required equipment (Free Weights, Machines, Bodyweight, Resistance Bands, Cardio Equipment)
  /// - [difficulty]: Optional filter by difficulty level (Beginner, Intermediate, Advanced)
  /// - [search]: Optional search term to filter by exercise name
  /// 
  /// Returns a list of [Exercise] objects matching all applied filters.
  /// Multiple filters are combined with AND logic.
  /// 
  /// Validates: Requirements 3.2, 3.3, 3.4, 3.5, 3.6, 3.9
  Future<List<Exercise>> getExercises({
    String? category,
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? search,
  });

  /// Retrieves a single exercise by its unique identifier.
  /// 
  /// Parameters:
  /// - [id]: The unique identifier of the exercise
  /// 
  /// Returns the [Exercise] object with complete details including
  /// description, instructions, image URL, and video URL.
  /// 
  /// Throws an exception if the exercise is not found.
  /// 
  /// Validates: Requirements 3.7
  Future<Exercise> getExerciseById(String id);
}
