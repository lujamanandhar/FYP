import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart';
import '../repositories/exercise_repository.dart';
import 'repository_providers.dart';

/// State notifier for managing exercise library data
/// 
/// This notifier manages the state of the exercise library, including
/// loading exercises and applying multiple filters (category, muscle group,
/// equipment, difficulty, search).
/// 
/// The state is an AsyncValue<List<Exercise>> which handles
/// loading, error, and data states automatically.
/// 
/// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
class ExerciseLibraryNotifier extends StateNotifier<AsyncValue<List<Exercise>>> {
  final ExerciseRepository _repository;
  
  // Store current filter parameters
  String? _currentCategory;
  String? _currentMuscleGroup;
  String? _currentEquipment;
  String? _currentDifficulty;
  String? _currentSearch;

  ExerciseLibraryNotifier(this._repository) : super(const AsyncValue.loading()) {
    // Load all exercises on initialization
    loadExercises();
  }

  /// Load exercises from the repository with optional filters
  /// 
  /// Parameters:
  /// - [category]: Filter by exercise category (Strength/Cardio/Bodyweight)
  /// - [muscleGroup]: Filter by muscle group (Chest/Back/Legs/Core/Arms/Shoulders/Full Body)
  /// - [equipment]: Filter by equipment type (Free Weights/Machines/Bodyweight/Resistance Bands/Cardio Equipment)
  /// - [difficulty]: Filter by difficulty level (Beginner/Intermediate/Advanced)
  /// - [search]: Filter by exercise name (case-insensitive substring match)
  /// 
  /// All filters are applied simultaneously (AND logic).
  /// 
  /// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.9
  Future<void> loadExercises({
    String? category,
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? search,
  }) async {
    // Store current filters
    _currentCategory = category;
    _currentMuscleGroup = muscleGroup;
    _currentEquipment = equipment;
    _currentDifficulty = difficulty;
    _currentSearch = search;
    
    // Set loading state
    state = const AsyncValue.loading();
    
    // Load data and update state
    state = await AsyncValue.guard(() => _repository.getExercises(
      category: category,
      muscleGroup: muscleGroup,
      equipment: equipment,
      difficulty: difficulty,
      search: search,
    ));
  }

  /// Apply category filter
  /// 
  /// Filters exercises by category while maintaining other active filters.
  /// Pass null to clear the category filter.
  /// 
  /// Validates: Requirements 3.2, 3.9
  Future<void> filterByCategory(String? category) async {
    await loadExercises(
      category: category,
      muscleGroup: _currentMuscleGroup,
      equipment: _currentEquipment,
      difficulty: _currentDifficulty,
      search: _currentSearch,
    );
  }

  /// Apply muscle group filter
  /// 
  /// Filters exercises by muscle group while maintaining other active filters.
  /// Pass null to clear the muscle group filter.
  /// 
  /// Validates: Requirements 3.3, 3.9
  Future<void> filterByMuscleGroup(String? muscleGroup) async {
    await loadExercises(
      category: _currentCategory,
      muscleGroup: muscleGroup,
      equipment: _currentEquipment,
      difficulty: _currentDifficulty,
      search: _currentSearch,
    );
  }

  /// Apply equipment filter
  /// 
  /// Filters exercises by equipment type while maintaining other active filters.
  /// Pass null to clear the equipment filter.
  /// 
  /// Validates: Requirements 3.4, 3.9
  Future<void> filterByEquipment(String? equipment) async {
    await loadExercises(
      category: _currentCategory,
      muscleGroup: _currentMuscleGroup,
      equipment: equipment,
      difficulty: _currentDifficulty,
      search: _currentSearch,
    );
  }

  /// Apply difficulty filter
  /// 
  /// Filters exercises by difficulty level while maintaining other active filters.
  /// Pass null to clear the difficulty filter.
  /// 
  /// Validates: Requirements 3.5, 3.9
  Future<void> filterByDifficulty(String? difficulty) async {
    await loadExercises(
      category: _currentCategory,
      muscleGroup: _currentMuscleGroup,
      equipment: _currentEquipment,
      difficulty: difficulty,
      search: _currentSearch,
    );
  }

  /// Apply search filter
  /// 
  /// Filters exercises by name (case-insensitive substring match)
  /// while maintaining other active filters.
  /// Pass null or empty string to clear the search filter.
  /// 
  /// Validates: Requirements 3.6, 3.9
  Future<void> search(String? searchTerm) async {
    // Treat empty string as null
    final normalizedSearch = (searchTerm?.isEmpty ?? true) ? null : searchTerm;
    
    await loadExercises(
      category: _currentCategory,
      muscleGroup: _currentMuscleGroup,
      equipment: _currentEquipment,
      difficulty: _currentDifficulty,
      search: normalizedSearch,
    );
  }

  /// Clear all filters
  /// 
  /// Resets all filters and loads all exercises.
  Future<void> clearAllFilters() async {
    await loadExercises();
  }

  /// Refresh exercises with current filters
  /// 
  /// Re-fetches exercise data using the same filters as the last load.
  /// This is useful for pull-to-refresh functionality.
  Future<void> refresh() async {
    await loadExercises(
      category: _currentCategory,
      muscleGroup: _currentMuscleGroup,
      equipment: _currentEquipment,
      difficulty: _currentDifficulty,
      search: _currentSearch,
    );
  }

  /// Get current active filters
  /// 
  /// Returns a map of currently active filters for UI display.
  Map<String, String?> get activeFilters => {
    'category': _currentCategory,
    'muscleGroup': _currentMuscleGroup,
    'equipment': _currentEquipment,
    'difficulty': _currentDifficulty,
    'search': _currentSearch,
  };

  /// Check if any filters are active
  /// 
  /// Returns true if at least one filter is applied.
  bool get hasActiveFilters =>
      _currentCategory != null ||
      _currentMuscleGroup != null ||
      _currentEquipment != null ||
      _currentDifficulty != null ||
      _currentSearch != null;
}

/// Provider for exercise library state
/// 
/// This provider creates and manages the ExerciseLibraryNotifier,
/// which handles loading and filtering exercises.
/// 
/// The state is automatically updated when exercises are loaded or filtered,
/// and all UI components watching this provider will rebuild.
/// 
/// Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6
final exerciseLibraryProvider = StateNotifierProvider<ExerciseLibraryNotifier, AsyncValue<List<Exercise>>>((ref) {
  final repository = ref.watch(exerciseRepositoryProvider);
  return ExerciseLibraryNotifier(repository);
});
