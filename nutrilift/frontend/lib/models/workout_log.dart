import 'package:freezed_annotation/freezed_annotation.dart';
import 'workout_exercise.dart';

part 'workout_log.freezed.dart';
part 'workout_log.g.dart';

@freezed
class WorkoutLog with _$WorkoutLog {
  const factory WorkoutLog({
    int? id,
    int? user,
    @JsonKey(name: 'custom_workout') int? customWorkoutId,
    @JsonKey(name: 'workout_name') String? workoutName,
    int? gym,
    @JsonKey(name: 'gym_name') String? gymName,
    // Backend returns 'date' (aliased from logged_at) and 'duration' (aliased from duration_minutes)
    required DateTime date,
    required int duration,
    @JsonKey(name: 'calories_burned') required double caloriesBurned,
    String? notes,
    // Backend returns exercises under 'workout_exercises'
    @JsonKey(name: 'workout_exercises') required List<WorkoutExercise> exercises,
    @JsonKey(name: 'has_new_prs') required bool hasNewPrs,
    @JsonKey(name: 'logged_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _WorkoutLog;

  factory WorkoutLog.fromJson(Map<String, dynamic> json) =>
      _$WorkoutLogFromJson(json);
}
