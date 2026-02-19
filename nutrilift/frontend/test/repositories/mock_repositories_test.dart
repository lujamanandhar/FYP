import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilift/repositories/mock_workout_repository.dart';
import 'package:nutrilift/repositories/mock_exercise_repository.dart';
import 'package:nutrilift/repositories/mock_personal_record_repository.dart';
import 'package:nutrilift/models/workout_log.dart';
import 'package:nutrilift/models/workout_exercise.dart';
import 'package:nutrilift/models/workout_models.dart';

void main() {
  group('MockWorkoutRepository', () {
    late MockWorkoutRepository repository;

    setUp(() {
      repository = MockWorkoutRepository();
    });

    test('should return workout history ordered by date descending', () async {
      final workouts = await repository.getWorkoutHistory();

      expect(workouts, isNotEmpty);
      // Verify ordering (newest first)
      for (int i = 0; i < workouts.length - 1; i++) {
        expect(
          workouts[i].date.isAfter(workouts[i + 1].date) ||
              workouts[i].date.isAtSameMomentAs(workouts[i + 1].date),
          isTrue,
          reason: 'Workouts should be ordered by date descending',
        );
      }
    });

    test('should filter workouts by date', () async {
      final dateFrom = DateTime.now().subtract(const Duration(days: 3));
      final workouts = await repository.getWorkoutHistory(dateFrom: dateFrom);

      for (final workout in workouts) {
        expect(
          workout.date.isAfter(dateFrom) ||
              workout.date.isAtSameMomentAs(dateFrom),
          isTrue,
          reason: 'All workouts should be after dateFrom',
        );
      }
    });

    test('should limit number of workouts returned', () async {
      final limit = 2;
      final workouts = await repository.getWorkoutHistory(limit: limit);

      expect(workouts.length, lessThanOrEqualTo(limit));
    });

    test('should log a new workout', () async {
      final request = CreateWorkoutLogRequest(
        workoutName: 'Test Workout',
        durationMinutes: 45,
        caloriesBurned: 300.0,
        exercises: [
          ExerciseSetRequest(
            exerciseId: '1',
            order: 0,
            sets: [
              WorkoutSetRequest(setNumber: 1, reps: 10, weight: 50.0),
              WorkoutSetRequest(setNumber: 2, reps: 10, weight: 50.0),
            ],
          ),
        ],
      );

      final workout = await repository.logWorkout(request);

      expect(workout.id, isNotNull);
      expect(workout.workoutName, equals('Test Workout'));
      expect(workout.duration, equals(45));
      expect(workout.exercises, isNotEmpty);
    });

    test('should calculate statistics correctly', () async {
      final stats = await repository.getStatistics();

      expect(stats['total_workouts'], greaterThan(0));
      expect(stats['total_calories'], greaterThan(0));
      expect(stats['total_duration'], greaterThan(0));
      expect(stats['average_duration'], greaterThan(0));
      expect(stats['average_calories'], greaterThan(0));
      expect(stats['workouts_by_category'], isNotEmpty);
      expect(stats['most_frequent_exercises'], isNotEmpty);
    });
  });

  group('MockExerciseRepository', () {
    late MockExerciseRepository repository;

    setUp(() {
      repository = MockExerciseRepository();
    });

    test('should return all exercises when no filters applied', () async {
      final exercises = await repository.getExercises();

      expect(exercises, isNotEmpty);
      expect(exercises.length, greaterThanOrEqualTo(20));
    });

    test('should filter exercises by category', () async {
      final exercises = await repository.getExercises(category: 'Strength');

      expect(exercises, isNotEmpty);
      for (final exercise in exercises) {
        expect(exercise.category, equals('Strength'));
      }
    });

    test('should filter exercises by muscle group', () async {
      final exercises = await repository.getExercises(muscleGroup: 'Chest');

      expect(exercises, isNotEmpty);
      for (final exercise in exercises) {
        expect(exercise.muscleGroup, equals('Chest'));
      }
    });

    test('should filter exercises by equipment', () async {
      final exercises =
          await repository.getExercises(equipment: 'Bodyweight');

      expect(exercises, isNotEmpty);
      for (final exercise in exercises) {
        expect(exercise.equipment, equals('Bodyweight'));
      }
    });

    test('should filter exercises by difficulty', () async {
      final exercises = await repository.getExercises(difficulty: 'Beginner');

      expect(exercises, isNotEmpty);
      for (final exercise in exercises) {
        expect(exercise.difficulty, equals('Beginner'));
      }
    });

    test('should search exercises by name', () async {
      final exercises = await repository.getExercises(search: 'press');

      expect(exercises, isNotEmpty);
      for (final exercise in exercises) {
        expect(
          exercise.name.toLowerCase().contains('press'),
          isTrue,
          reason: 'Exercise name should contain search term',
        );
      }
    });

    test('should combine multiple filters', () async {
      final exercises = await repository.getExercises(
        category: 'Strength',
        muscleGroup: 'Chest',
        difficulty: 'Beginner',
      );

      for (final exercise in exercises) {
        expect(exercise.category, equals('Strength'));
        expect(exercise.muscleGroup, equals('Chest'));
        expect(exercise.difficulty, equals('Beginner'));
      }
    });

    test('should get exercise by ID', () async {
      final exercise = await repository.getExerciseById('1');

      expect(exercise.id, equals(1));
      expect(exercise.name, isNotEmpty);
    });

    test('should throw exception for invalid exercise ID', () async {
      expect(
        () => repository.getExerciseById('999'),
        throwsException,
      );
    });
  });

  group('MockPersonalRecordRepository', () {
    late MockPersonalRecordRepository repository;

    setUp(() {
      repository = MockPersonalRecordRepository();
    });

    test('should return all personal records', () async {
      final prs = await repository.getPersonalRecords();

      expect(prs, isNotEmpty);
      expect(prs.length, greaterThanOrEqualTo(10));
    });

    test('should return personal records ordered by date descending',
        () async {
      final prs = await repository.getPersonalRecords();

      // Verify ordering (newest first)
      for (int i = 0; i < prs.length - 1; i++) {
        expect(
          prs[i].achievedDate.isAfter(prs[i + 1].achievedDate) ||
              prs[i].achievedDate.isAtSameMomentAs(prs[i + 1].achievedDate),
          isTrue,
          reason: 'PRs should be ordered by achieved date descending',
        );
      }
    });

    test('should get personal record for specific exercise', () async {
      final pr = await repository.getPersonalRecordForExercise('1');

      expect(pr, isNotNull);
      expect(pr!.exerciseId, equals(1));
      expect(pr.exerciseName, isNotEmpty);
      expect(pr.maxWeight, greaterThanOrEqualTo(0));
      expect(pr.maxReps, greaterThan(0));
      expect(pr.maxVolume, greaterThanOrEqualTo(0));
    });

    test('should return null for non-existent exercise', () async {
      final pr = await repository.getPersonalRecordForExercise('999');

      expect(pr, isNull);
    });

    test('should have improvement percentages', () async {
      final prs = await repository.getPersonalRecords();

      final prsWithImprovement =
          prs.where((pr) => pr.improvementPercentage != null).toList();
      expect(prsWithImprovement, isNotEmpty);

      for (final pr in prsWithImprovement) {
        expect(pr.improvementPercentage, greaterThan(0));
      }
    });
  });
}
