import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/personal_record.dart';
import '../repositories/personal_record_repository.dart';
import 'repository_providers.dart';

/// State notifier for managing personal records data
/// 
/// This notifier manages the state of personal records, including
/// loading and refreshing PRs for the authenticated user.
/// 
/// The state is an AsyncValue<List<PersonalRecord>> which handles
/// loading, error, and data states automatically.
/// 
/// Validates: Requirements 4.1, 4.6
class PersonalRecordsNotifier extends StateNotifier<AsyncValue<List<PersonalRecord>>> {
  final PersonalRecordRepository _repository;

  PersonalRecordsNotifier(this._repository) : super(const AsyncValue.loading()) {
    // Load personal records on initialization
    loadPersonalRecords();
  }

  /// Load personal records from the repository
  /// 
  /// Fetches all personal records for the authenticated user.
  /// Sets the state to loading, then updates with data or error.
  /// 
  /// Validates: Requirements 4.1, 4.6
  Future<void> loadPersonalRecords() async {
    // Set loading state
    state = const AsyncValue.loading();
    
    // Load data and update state
    state = await AsyncValue.guard(() => _repository.getPersonalRecords());
  }

  /// Refresh personal records
  /// 
  /// Re-fetches personal record data from the repository.
  /// This is useful for pull-to-refresh functionality or after
  /// logging a new workout that might have created new PRs.
  /// 
  /// Validates: Requirements 4.1, 8.1, 8.3
  Future<void> refresh() async {
    await loadPersonalRecords();
  }

  /// Get personal record for a specific exercise
  /// 
  /// Returns the PR for the given exercise ID, or null if not found.
  /// This is useful for displaying PR information on exercise detail screens.
  /// 
  /// Validates: Requirements 4.1
  PersonalRecord? getPersonalRecordForExercise(int exerciseId) {
    final currentState = state;
    
    if (currentState is AsyncData<List<PersonalRecord>>) {
      try {
        return currentState.value.firstWhere(
          (pr) => pr.exerciseId == exerciseId,
        );
      } catch (e) {
        // No PR found for this exercise
        return null;
      }
    }
    
    return null;
  }

  /// Check if user has a PR for a specific exercise
  /// 
  /// Returns true if the user has achieved a personal record
  /// for the given exercise.
  bool hasPersonalRecordForExercise(int exerciseId) {
    return getPersonalRecordForExercise(exerciseId) != null;
  }

  /// Get PRs sorted by achievement date (newest first)
  /// 
  /// Returns personal records ordered by when they were achieved,
  /// with the most recent PRs first.
  List<PersonalRecord>? getPersonalRecordsByDate() {
    final currentState = state;
    
    if (currentState is AsyncData<List<PersonalRecord>>) {
      final prs = List<PersonalRecord>.from(currentState.value);
      prs.sort((a, b) => b.achievedDate.compareTo(a.achievedDate));
      return prs;
    }
    
    return null;
  }

  /// Get PRs with improvements (showing progress)
  /// 
  /// Returns only personal records that have improvement data
  /// (i.e., records that show progress over previous PRs).
  List<PersonalRecord>? getPersonalRecordsWithImprovements() {
    final currentState = state;
    
    if (currentState is AsyncData<List<PersonalRecord>>) {
      return currentState.value
          .where((pr) => pr.improvementPercentage != null && pr.improvementPercentage! > 0)
          .toList();
    }
    
    return null;
  }

  /// Get count of total personal records
  /// 
  /// Returns the total number of PRs the user has achieved.
  int get totalPersonalRecords {
    final currentState = state;
    
    if (currentState is AsyncData<List<PersonalRecord>>) {
      return currentState.value.length;
    }
    
    return 0;
  }
}

/// Provider for personal records state
/// 
/// This provider creates and manages the PersonalRecordsNotifier,
/// which handles loading and refreshing personal records.
/// 
/// The state is automatically updated when PRs are loaded,
/// and all UI components watching this provider will rebuild.
/// 
/// Validates: Requirements 4.1, 4.6
final personalRecordsProvider = StateNotifierProvider<PersonalRecordsNotifier, AsyncValue<List<PersonalRecord>>>((ref) {
  final repository = ref.watch(personalRecordRepositoryProvider);
  return PersonalRecordsNotifier(repository);
});

/// Provider to get a specific personal record by exercise ID
/// 
/// This is a computed provider that returns the PR for a specific exercise.
/// It watches the personalRecordsProvider and filters for the requested exercise.
/// 
/// Usage: ref.watch(personalRecordByExerciseProvider(exerciseId))
final personalRecordByExerciseProvider = Provider.family<PersonalRecord?, int>((ref, exerciseId) {
  final notifier = ref.watch(personalRecordsProvider.notifier);
  return notifier.getPersonalRecordForExercise(exerciseId);
});
