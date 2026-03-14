import '../models/exercise.dart';
import '../services/exercise_api_service.dart';
import '../services/workout_cache_service.dart';
import 'exercise_repository.dart';

/// Cached implementation of [ExerciseRepository] that combines API calls with local caching.
/// 
/// This repository provides:
/// - Local caching of exercise library for offline viewing
/// - Cache synchronization on startup
/// - Fallback to cached data when network is unavailable
/// - Client-side filtering of cached exercises
/// 
/// Validates: Requirements 8.5, 14.4, 14.5
class CachedExerciseRepository implements ExerciseRepository {
  final ExerciseApiService _apiService;
  final WorkoutCacheService _cacheService;

  CachedExerciseRepository(this._apiService, this._cacheService);

  @override
  Future<List<Exercise>> getExercises({
    String? category,
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? search,
  }) async {
    try {
      // Try to fetch from API
      final exercises = await _apiService.getExercises(
        category: category,
        muscleGroup: muscleGroup,
        equipment: equipment,
        difficulty: difficulty,
        search: search,
      );

      // Cache the full exercise list (without filters) if no filters applied
      if (category == null &&
          muscleGroup == null &&
          equipment == null &&
          difficulty == null &&
          search == null) {
        await _cacheService.cacheExercises(exercises);
      }

      return exercises;
    } catch (e) {
      // If API call fails, try to return cached data with client-side filtering
      print('API call failed, attempting to use cached data: $e');

      final cachedExercises = await _cacheService.getCachedExercises();
      if (cachedExercises != null) {
        return _filterExercises(
          cachedExercises,
          category: category,
          muscleGroup: muscleGroup,
          equipment: equipment,
          difficulty: difficulty,
          search: search,
        );
      }

      // No cached data available, rethrow the error
      rethrow;
    }
  }

  @override
  Future<Exercise> getExerciseById(String id) async {
    try {
      // Try to fetch from API
      return await _apiService.getExerciseById(id);
    } catch (e) {
      // If API call fails, try to find in cached data
      print('API call failed, attempting to use cached data: $e');

      final cachedExercises = await _cacheService.getCachedExercises();
      if (cachedExercises != null) {
        final exerciseId = int.tryParse(id);
        if (exerciseId != null) {
          final exercise = cachedExercises.firstWhere(
            (e) => e.id == exerciseId,
            orElse: () => throw NotFoundException('Exercise not found in cache'),
          );
          return exercise;
        }
      }

      // No cached data available, rethrow the error
      rethrow;
    }
  }

  /// Apply client-side filters to cached exercises
  List<Exercise> _filterExercises(
    List<Exercise> exercises, {
    String? category,
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? search,
  }) {
    var filtered = exercises;

    if (category != null) {
      filtered = filtered
          .where((e) => e.category.toLowerCase() == category.toLowerCase())
          .toList();
    }

    if (muscleGroup != null) {
      filtered = filtered
          .where((e) => e.muscleGroup.toLowerCase() == muscleGroup.toLowerCase())
          .toList();
    }

    if (equipment != null) {
      filtered = filtered
          .where((e) => e.equipment.toLowerCase() == equipment.toLowerCase())
          .toList();
    }

    if (difficulty != null) {
      filtered = filtered
          .where((e) => e.difficulty.toLowerCase() == difficulty.toLowerCase())
          .toList();
    }

    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      filtered = filtered
          .where((e) => e.name.toLowerCase().contains(searchLower))
          .toList();
    }

    return filtered;
  }

  /// Synchronize cached exercise data with the backend on app startup.
  /// 
  /// This method should be called when the app starts to ensure
  /// local cache is up-to-date with the backend.
  /// 
  /// Validates: Requirements 14.5
  Future<void> synchronizeCache() async {
    try {
      // Check if sync is needed
      if (!_cacheService.needsSync()) {
        print('Exercise cache is fresh, skipping sync');
        return;
      }

      print('Synchronizing exercise cache with backend...');

      // Fetch all exercises (no filters)
      final exercises = await _apiService.getExercises();
      await _cacheService.cacheExercises(exercises);

      print('Exercise cache synchronized successfully');
    } catch (e) {
      print('Failed to synchronize exercise cache: $e');
      // Don't throw - we can continue with stale cache
    }
  }

  /// Clear all cached exercise data
  Future<void> clearCache() async {
    await _cacheService.clearExercisesCache();
  }
}

/// Exception thrown when an exercise is not found
class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);

  @override
  String toString() => message;
}
