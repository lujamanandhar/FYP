import 'package:flutter_test/flutter_test.dart';
import 'package:nutrilift/models/exercise.dart';
import 'package:nutrilift/models/workout_exercise.dart';
import 'package:nutrilift/models/workout_log.dart';
import 'package:nutrilift/models/personal_record.dart';

void main() {
  group('Exercise Model Tests', () {
    test('Exercise fromJson should deserialize correctly', () {
      final json = {
        'id': 1,
        'name': 'Bench Press',
        'category': 'Strength',
        'muscle_group': 'Chest',
        'equipment': 'Free Weights',
        'difficulty': 'Intermediate',
        'description': 'A compound upper body exercise',
        'instructions': 'Lie on bench, lower bar to chest, press up',
        'image_url': 'https://example.com/bench-press.jpg',
        'video_url': 'https://youtube.com/watch?v=...',
        'created_at': '2024-01-15T10:30:00Z',
        'updated_at': '2024-01-15T10:30:00Z',
      };

      final exercise = Exercise.fromJson(json);

      expect(exercise.id, 1);
      expect(exercise.name, 'Bench Press');
      expect(exercise.category, 'Strength');
      expect(exercise.muscleGroup, 'Chest');
      expect(exercise.equipment, 'Free Weights');
      expect(exercise.difficulty, 'Intermediate');
      expect(exercise.description, 'A compound upper body exercise');
      expect(exercise.instructions, 'Lie on bench, lower bar to chest, press up');
      expect(exercise.imageUrl, 'https://example.com/bench-press.jpg');
      expect(exercise.videoUrl, 'https://youtube.com/watch?v=...');
      expect(exercise.createdAt, isNotNull);
      expect(exercise.updatedAt, isNotNull);
    });

    test('Exercise toJson should serialize correctly', () {
      final exercise = Exercise(
        id: 1,
        name: 'Bench Press',
        category: 'Strength',
        muscleGroup: 'Chest',
        equipment: 'Free Weights',
        difficulty: 'Intermediate',
        description: 'A compound upper body exercise',
        instructions: 'Lie on bench, lower bar to chest, press up',
        imageUrl: 'https://example.com/bench-press.jpg',
        videoUrl: 'https://youtube.com/watch?v=...',
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
        updatedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final json = exercise.toJson();

      expect(json['id'], 1);
      expect(json['name'], 'Bench Press');
      expect(json['category'], 'Strength');
      expect(json['muscle_group'], 'Chest');
      expect(json['equipment'], 'Free Weights');
      expect(json['difficulty'], 'Intermediate');
      expect(json['description'], 'A compound upper body exercise');
      expect(json['instructions'], 'Lie on bench, lower bar to chest, press up');
      expect(json['image_url'], 'https://example.com/bench-press.jpg');
      expect(json['video_url'], 'https://youtube.com/watch?v=...');
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNotNull);
    });

    test('Exercise should handle null optional fields', () {
      final json = {
        'id': 1,
        'name': 'Push-ups',
        'category': 'Bodyweight',
        'muscle_group': 'Chest',
        'equipment': 'Bodyweight',
        'difficulty': 'Beginner',
        'description': 'Basic bodyweight exercise',
        'instructions': 'Lower body to ground, push up',
      };

      final exercise = Exercise.fromJson(json);

      expect(exercise.id, 1);
      expect(exercise.name, 'Push-ups');
      expect(exercise.imageUrl, isNull);
      expect(exercise.videoUrl, isNull);
      expect(exercise.createdAt, isNull);
      expect(exercise.updatedAt, isNull);
    });
  });

  group('WorkoutExercise Model Tests', () {
    test('WorkoutExercise fromJson should deserialize correctly', () {
      final json = {
        'id': 456,
        'exercise': 1,
        'exercise_name': 'Bench Press',
        'sets': 3,
        'reps': 10,
        'weight': 100.0,
        'volume': 3000.0,
        'order': 0,
      };

      final workoutExercise = WorkoutExercise.fromJson(json);

      expect(workoutExercise.id, 456);
      expect(workoutExercise.exerciseId, 1);
      expect(workoutExercise.exerciseName, 'Bench Press');
      expect(workoutExercise.sets, 3);
      expect(workoutExercise.reps, 10);
      expect(workoutExercise.weight, 100.0);
      expect(workoutExercise.volume, 3000.0);
      expect(workoutExercise.order, 0);
    });

    test('WorkoutExercise toJson should serialize correctly', () {
      final workoutExercise = WorkoutExercise(
        id: 456,
        exerciseId: 1,
        exerciseName: 'Bench Press',
        sets: 3,
        reps: 10,
        weight: 100.0,
        volume: 3000.0,
        order: 0,
      );

      final json = workoutExercise.toJson();

      expect(json['id'], 456);
      expect(json['exercise'], 1);
      expect(json['exercise_name'], 'Bench Press');
      expect(json['sets'], 3);
      expect(json['reps'], 10);
      expect(json['weight'], 100.0);
      expect(json['volume'], 3000.0);
      expect(json['order'], 0);
    });

    test('WorkoutExercise should handle null id', () {
      final json = {
        'exercise': 1,
        'exercise_name': 'Bench Press',
        'sets': 3,
        'reps': 10,
        'weight': 100.0,
        'volume': 3000.0,
        'order': 0,
      };

      final workoutExercise = WorkoutExercise.fromJson(json);

      expect(workoutExercise.id, isNull);
      expect(workoutExercise.exerciseId, 1);
    });
  });

  group('WorkoutLog Model Tests', () {
    test('WorkoutLog fromJson should deserialize correctly', () {
      final json = {
        'id': 123,
        'user': 1,
        'custom_workout': 1,
        'workout_name': 'Push Day',
        'gym': 2,
        'gym_name': 'Gold\'s Gym',
        'date': '2024-01-15T10:30:00Z',
        'duration': 60,
        'calories_burned': 450.50,
        'notes': 'Great workout!',
        'exercises': [
          {
            'id': 456,
            'exercise': 1,
            'exercise_name': 'Bench Press',
            'sets': 3,
            'reps': 10,
            'weight': 100.0,
            'volume': 3000.0,
            'order': 0,
          }
        ],
        'has_new_prs': true,
        'created_at': '2024-01-15T10:30:00Z',
        'updated_at': '2024-01-15T10:30:00Z',
      };

      final workoutLog = WorkoutLog.fromJson(json);

      expect(workoutLog.id, 123);
      expect(workoutLog.user, 1);
      expect(workoutLog.customWorkoutId, 1);
      expect(workoutLog.workoutName, 'Push Day');
      expect(workoutLog.gym, 2);
      expect(workoutLog.gymName, 'Gold\'s Gym');
      expect(workoutLog.date, DateTime.parse('2024-01-15T10:30:00Z'));
      expect(workoutLog.duration, 60);
      expect(workoutLog.caloriesBurned, 450.50);
      expect(workoutLog.notes, 'Great workout!');
      expect(workoutLog.exercises.length, 1);
      expect(workoutLog.exercises[0].exerciseName, 'Bench Press');
      expect(workoutLog.hasNewPrs, true);
      expect(workoutLog.createdAt, isNotNull);
      expect(workoutLog.updatedAt, isNotNull);
    });

    test('WorkoutLog toJson should serialize correctly', () {
      final workoutLog = WorkoutLog(
        id: 123,
        user: 1,
        customWorkoutId: 1,
        workoutName: 'Push Day',
        gym: 2,
        gymName: 'Gold\'s Gym',
        date: DateTime.parse('2024-01-15T10:30:00Z'),
        duration: 60,
        caloriesBurned: 450.50,
        notes: 'Great workout!',
        exercises: [
          WorkoutExercise(
            id: 456,
            exerciseId: 1,
            exerciseName: 'Bench Press',
            sets: 3,
            reps: 10,
            weight: 100.0,
            volume: 3000.0,
            order: 0,
          )
        ],
        hasNewPrs: true,
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
        updatedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final json = workoutLog.toJson();

      expect(json['id'], 123);
      expect(json['user'], 1);
      expect(json['custom_workout'], 1);
      expect(json['workout_name'], 'Push Day');
      expect(json['gym'], 2);
      expect(json['gym_name'], 'Gold\'s Gym');
      expect(json['date'], isNotNull);
      expect(json['duration'], 60);
      expect(json['calories_burned'], 450.50);
      expect(json['notes'], 'Great workout!');
      expect(json['exercises'], isList);
      expect(json['has_new_prs'], true);
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNotNull);
    });

    test('WorkoutLog should handle null optional fields', () {
      final json = {
        'date': '2024-01-15T10:30:00Z',
        'duration': 60,
        'calories_burned': 450.50,
        'exercises': [],
        'has_new_prs': false,
      };

      final workoutLog = WorkoutLog.fromJson(json);

      expect(workoutLog.id, isNull);
      expect(workoutLog.user, isNull);
      expect(workoutLog.customWorkoutId, isNull);
      expect(workoutLog.workoutName, isNull);
      expect(workoutLog.gym, isNull);
      expect(workoutLog.gymName, isNull);
      expect(workoutLog.notes, isNull);
      expect(workoutLog.exercises, isEmpty);
      expect(workoutLog.hasNewPrs, false);
      expect(workoutLog.createdAt, isNull);
      expect(workoutLog.updatedAt, isNull);
    });
  });

  group('PersonalRecord Model Tests', () {
    test('PersonalRecord fromJson should deserialize correctly', () {
      final json = {
        'id': 1,
        'exercise': 1,
        'exercise_name': 'Bench Press',
        'max_weight': 120.0,
        'max_reps': 12,
        'max_volume': 4320.0,
        'achieved_date': '2024-01-15T10:30:00Z',
        'improvement_percentage': 15.5,
        'workout_log': 123,
        'created_at': '2024-01-15T10:30:00Z',
        'updated_at': '2024-01-15T10:30:00Z',
      };

      final personalRecord = PersonalRecord.fromJson(json);

      expect(personalRecord.id, 1);
      expect(personalRecord.exerciseId, 1);
      expect(personalRecord.exerciseName, 'Bench Press');
      expect(personalRecord.maxWeight, 120.0);
      expect(personalRecord.maxReps, 12);
      expect(personalRecord.maxVolume, 4320.0);
      expect(personalRecord.achievedDate, DateTime.parse('2024-01-15T10:30:00Z'));
      expect(personalRecord.improvementPercentage, 15.5);
      expect(personalRecord.workoutLogId, 123);
      expect(personalRecord.createdAt, isNotNull);
      expect(personalRecord.updatedAt, isNotNull);
    });

    test('PersonalRecord toJson should serialize correctly', () {
      final personalRecord = PersonalRecord(
        id: 1,
        exerciseId: 1,
        exerciseName: 'Bench Press',
        maxWeight: 120.0,
        maxReps: 12,
        maxVolume: 4320.0,
        achievedDate: DateTime.parse('2024-01-15T10:30:00Z'),
        improvementPercentage: 15.5,
        workoutLogId: 123,
        createdAt: DateTime.parse('2024-01-15T10:30:00Z'),
        updatedAt: DateTime.parse('2024-01-15T10:30:00Z'),
      );

      final json = personalRecord.toJson();

      expect(json['id'], 1);
      expect(json['exercise'], 1);
      expect(json['exercise_name'], 'Bench Press');
      expect(json['max_weight'], 120.0);
      expect(json['max_reps'], 12);
      expect(json['max_volume'], 4320.0);
      expect(json['achieved_date'], isNotNull);
      expect(json['improvement_percentage'], 15.5);
      expect(json['workout_log'], 123);
      expect(json['created_at'], isNotNull);
      expect(json['updated_at'], isNotNull);
    });

    test('PersonalRecord should handle null optional fields', () {
      final json = {
        'id': 1,
        'exercise': 1,
        'exercise_name': 'Bench Press',
        'max_weight': 120.0,
        'max_reps': 12,
        'max_volume': 4320.0,
        'achieved_date': '2024-01-15T10:30:00Z',
      };

      final personalRecord = PersonalRecord.fromJson(json);

      expect(personalRecord.id, 1);
      expect(personalRecord.exerciseId, 1);
      expect(personalRecord.exerciseName, 'Bench Press');
      expect(personalRecord.improvementPercentage, isNull);
      expect(personalRecord.workoutLogId, isNull);
      expect(personalRecord.createdAt, isNull);
      expect(personalRecord.updatedAt, isNull);
    });
  });
}
