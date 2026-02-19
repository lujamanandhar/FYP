import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_exercise.freezed.dart';
part 'workout_exercise.g.dart';

@freezed
class WorkoutExercise with _$WorkoutExercise {
  const factory WorkoutExercise({
    int? id,
    @JsonKey(name: 'exercise') required int exerciseId,
    @JsonKey(name: 'exercise_name') required String exerciseName,
    required int sets,
    required int reps,
    required double weight,
    required double volume,
    required int order,
  }) = _WorkoutExercise;

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutExerciseFromJson(json);
}
