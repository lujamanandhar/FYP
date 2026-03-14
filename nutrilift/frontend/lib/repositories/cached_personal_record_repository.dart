import '../models/personal_record.dart';
import '../services/personal_record_api_service.dart';
import '../services/workout_cache_service.dart';
import 'personal_record_repository.dart';

/// Cached implementation of [PersonalRecordRepository] that combines API calls with local caching.
/// 
/// This repository provides:
/// - Local caching of personal records for offline viewing
/// - Cache synchronization on startup
/// - Fallback to cached data when network is unavailable
/// - Client-side filtering of cached PRs
/// 
/// Validates: Requirements 8.5, 14.4, 14.5
class CachedPersonalRecordRepository implements PersonalRecordRepository {
  final PersonalRecordApiService _apiService;
  final WorkoutCacheService _cacheService;

  CachedPersonalRecordRepository(this._apiService, this._cacheService);

  @override
  Future<List<PersonalRecord>> getPersonalRecords() async {
    try {
      // Try to fetch from API
      final prs = await _apiService.getPersonalRecords();

      // Cache the results
      await _cacheService.cachePersonalRecords(prs);

      return prs;
    } catch (e) {
      // If API call fails, try to return cached data
      print('API call failed, attempting to use cached data: $e');

      final cachedPRs = await _cacheService.getCachedPersonalRecords();
      if (cachedPRs != null) {
        return cachedPRs;
      }

      // No cached data available, rethrow the error
      rethrow;
    }
  }

  @override
  Future<PersonalRecord?> getPersonalRecordForExercise(String exerciseId) async {
    try {
      // Try to fetch from API
      return await _apiService.getPersonalRecordForExercise(exerciseId);
    } catch (e) {
      // If API call fails, try to find in cached data
      print('API call failed, attempting to use cached data: $e');

      final cachedPRs = await _cacheService.getCachedPersonalRecords();
      if (cachedPRs != null) {
        final exerciseIdInt = int.tryParse(exerciseId);
        if (exerciseIdInt != null) {
          try {
            return cachedPRs.firstWhere(
              (pr) => pr.exerciseId == exerciseIdInt,
            );
          } catch (_) {
            // No matching PR found in cache
            return null;
          }
        }
      }

      // No cached data available, rethrow the error
      rethrow;
    }
  }

  /// Synchronize cached personal record data with the backend on app startup.
  /// 
  /// This method should be called when the app starts to ensure
  /// local cache is up-to-date with the backend.
  /// 
  /// Validates: Requirements 14.5
  Future<void> synchronizeCache() async {
    try {
      // Check if sync is needed
      if (!_cacheService.needsSync()) {
        print('Personal records cache is fresh, skipping sync');
        return;
      }

      print('Synchronizing personal records cache with backend...');

      // Fetch all personal records
      final prs = await _apiService.getPersonalRecords();
      await _cacheService.cachePersonalRecords(prs);

      print('Personal records cache synchronized successfully');
    } catch (e) {
      print('Failed to synchronize personal records cache: $e');
      // Don't throw - we can continue with stale cache
    }
  }

  /// Clear all cached personal record data
  Future<void> clearCache() async {
    await _cacheService.clearPersonalRecordsCache();
  }
}
