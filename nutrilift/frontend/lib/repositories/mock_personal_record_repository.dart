import 'personal_record_repository.dart';
import '../models/personal_record.dart';

/// Mock implementation of [PersonalRecordRepository] for testing and offline development.
/// 
/// This repository provides mock personal record data without requiring
/// a backend connection. It includes sample PRs for various exercises
/// with realistic values and improvement percentages.
/// 
/// Validates: Requirements 7.9
class MockPersonalRecordRepository implements PersonalRecordRepository {
  final List<PersonalRecord> _personalRecords = [];

  /// Creates a mock repository with pre-populated personal record data.
  MockPersonalRecordRepository() {
    _personalRecords.addAll(_generateMockPersonalRecords());
  }

  @override
  Future<List<PersonalRecord>> getPersonalRecords() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 250));

    // Return all personal records sorted by achieved date (newest first)
    final sorted = List<PersonalRecord>.from(_personalRecords);
    sorted.sort((a, b) => b.achievedDate.compareTo(a.achievedDate));
    return sorted;
  }

  @override
  Future<PersonalRecord?> getPersonalRecordForExercise(String exerciseId) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 150));

    final id = int.tryParse(exerciseId);
    if (id == null) {
      return null;
    }

    try {
      return _personalRecords.firstWhere(
        (pr) => pr.exerciseId == id,
      );
    } catch (e) {
      return null;
    }
  }

  /// Adds a personal record to the mock repository (for testing).
  void addPersonalRecord(PersonalRecord pr) {
    // Remove existing PR for the same exercise if it exists
    _personalRecords.removeWhere((existing) => existing.exerciseId == pr.exerciseId);
    _personalRecords.add(pr);
  }

  /// Updates an existing personal record or adds it if not found.
  void updatePersonalRecord(PersonalRecord pr) {
    final index = _personalRecords.indexWhere((existing) => existing.id == pr.id);
    if (index != -1) {
      _personalRecords[index] = pr;
    } else {
      _personalRecords.add(pr);
    }
  }

  /// Clears all personal records and resets to default mock data.
  void reset() {
    _personalRecords.clear();
    _personalRecords.addAll(_generateMockPersonalRecords());
  }

  /// Clears all personal records.
  void clear() {
    _personalRecords.clear();
  }

  /// Generates mock personal record data.
  List<PersonalRecord> _generateMockPersonalRecords() {
    final now = DateTime.now();
    return [
      PersonalRecord(
        id: 1,
        exerciseId: 1,
        exerciseName: 'Bench Press',
        maxWeight: 120.0,
        maxReps: 12,
        maxVolume: 4320.0,
        achievedDate: now.subtract(const Duration(days: 2)),
        improvementPercentage: 15.5,
        workoutLogId: 1,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      PersonalRecord(
        id: 2,
        exerciseId: 9,
        exerciseName: 'Squats',
        maxWeight: 150.0,
        maxReps: 10,
        maxVolume: 4500.0,
        achievedDate: now.subtract(const Duration(days: 4)),
        improvementPercentage: 10.2,
        workoutLogId: 2,
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      PersonalRecord(
        id: 3,
        exerciseId: 5,
        exerciseName: 'Deadlift',
        maxWeight: 180.0,
        maxReps: 5,
        maxVolume: 2700.0,
        achievedDate: now.subtract(const Duration(days: 6)),
        improvementPercentage: 8.3,
        workoutLogId: 3,
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
      PersonalRecord(
        id: 4,
        exerciseId: 6,
        exerciseName: 'Pull-ups',
        maxWeight: 0.0,
        maxReps: 15,
        maxVolume: 15.0,
        achievedDate: now.subtract(const Duration(days: 8)),
        improvementPercentage: 25.0,
        workoutLogId: 4,
        createdAt: now.subtract(const Duration(days: 50)),
        updatedAt: now.subtract(const Duration(days: 8)),
      ),
      PersonalRecord(
        id: 5,
        exerciseId: 17,
        exerciseName: 'Shoulder Press',
        maxWeight: 80.0,
        maxReps: 8,
        maxVolume: 2560.0,
        achievedDate: now.subtract(const Duration(days: 10)),
        improvementPercentage: 12.0,
        workoutLogId: 5,
        createdAt: now.subtract(const Duration(days: 40)),
        updatedAt: now.subtract(const Duration(days: 10)),
      ),
      PersonalRecord(
        id: 6,
        exerciseId: 13,
        exerciseName: 'Barbell Curl',
        maxWeight: 50.0,
        maxReps: 10,
        maxVolume: 1500.0,
        achievedDate: now.subtract(const Duration(days: 12)),
        improvementPercentage: 18.5,
        workoutLogId: 6,
        createdAt: now.subtract(const Duration(days: 35)),
        updatedAt: now.subtract(const Duration(days: 12)),
      ),
      PersonalRecord(
        id: 7,
        exerciseId: 10,
        exerciseName: 'Leg Press',
        maxWeight: 200.0,
        maxReps: 15,
        maxVolume: 9000.0,
        achievedDate: now.subtract(const Duration(days: 15)),
        improvementPercentage: 5.8,
        workoutLogId: 7,
        createdAt: now.subtract(const Duration(days: 55)),
        updatedAt: now.subtract(const Duration(days: 15)),
      ),
      PersonalRecord(
        id: 8,
        exerciseId: 7,
        exerciseName: 'Barbell Row',
        maxWeight: 100.0,
        maxReps: 8,
        maxVolume: 2400.0,
        achievedDate: now.subtract(const Duration(days: 18)),
        improvementPercentage: 14.3,
        workoutLogId: 8,
        createdAt: now.subtract(const Duration(days: 65)),
        updatedAt: now.subtract(const Duration(days: 18)),
      ),
      PersonalRecord(
        id: 9,
        exerciseId: 14,
        exerciseName: 'Tricep Dips',
        maxWeight: 0.0,
        maxReps: 20,
        maxVolume: 20.0,
        achievedDate: now.subtract(const Duration(days: 20)),
        improvementPercentage: 33.3,
        workoutLogId: 9,
        createdAt: now.subtract(const Duration(days: 70)),
        updatedAt: now.subtract(const Duration(days: 20)),
      ),
      PersonalRecord(
        id: 10,
        exerciseId: 12,
        exerciseName: 'Romanian Deadlift',
        maxWeight: 130.0,
        maxReps: 10,
        maxVolume: 3900.0,
        achievedDate: now.subtract(const Duration(days: 22)),
        improvementPercentage: 8.9,
        workoutLogId: 10,
        createdAt: now.subtract(const Duration(days: 75)),
        updatedAt: now.subtract(const Duration(days: 22)),
      ),
      PersonalRecord(
        id: 11,
        exerciseId: 18,
        exerciseName: 'Lateral Raise',
        maxWeight: 20.0,
        maxReps: 12,
        maxVolume: 720.0,
        achievedDate: now.subtract(const Duration(days: 25)),
        improvementPercentage: 20.0,
        workoutLogId: 11,
        createdAt: now.subtract(const Duration(days: 80)),
        updatedAt: now.subtract(const Duration(days: 25)),
      ),
      PersonalRecord(
        id: 12,
        exerciseId: 3,
        exerciseName: 'Push-ups',
        maxWeight: 0.0,
        maxReps: 50,
        maxVolume: 50.0,
        achievedDate: now.subtract(const Duration(days: 28)),
        improvementPercentage: 42.9,
        workoutLogId: 12,
        createdAt: now.subtract(const Duration(days: 85)),
        updatedAt: now.subtract(const Duration(days: 28)),
      ),
      PersonalRecord(
        id: 13,
        exerciseId: 20,
        exerciseName: 'Plank',
        maxWeight: 0.0,
        maxReps: 180, // seconds
        maxVolume: 180.0,
        achievedDate: now.subtract(const Duration(days: 30)),
        improvementPercentage: 50.0,
        workoutLogId: 13,
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now.subtract(const Duration(days: 30)),
      ),
      PersonalRecord(
        id: 14,
        exerciseId: 30,
        exerciseName: 'Kettlebell Swing',
        maxWeight: 32.0,
        maxReps: 20,
        maxVolume: 1920.0,
        achievedDate: now.subtract(const Duration(days: 35)),
        improvementPercentage: 28.0,
        workoutLogId: 14,
        createdAt: now.subtract(const Duration(days: 95)),
        updatedAt: now.subtract(const Duration(days: 35)),
      ),
      PersonalRecord(
        id: 15,
        exerciseId: 11,
        exerciseName: 'Lunges',
        maxWeight: 0.0,
        maxReps: 30,
        maxVolume: 30.0,
        achievedDate: now.subtract(const Duration(days: 40)),
        improvementPercentage: 15.4,
        workoutLogId: 15,
        createdAt: now.subtract(const Duration(days: 100)),
        updatedAt: now.subtract(const Duration(days: 40)),
      ),
    ];
  }
}
