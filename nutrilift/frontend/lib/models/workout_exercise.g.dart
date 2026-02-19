// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutExerciseImpl _$$WorkoutExerciseImplFromJson(
  Map<String, dynamic> json,
) => _$WorkoutExerciseImpl(
  id: (json['id'] as num?)?.toInt(),
  exerciseId: (json['exercise'] as num).toInt(),
  exerciseName: json['exercise_name'] as String,
  sets: (json['sets'] as num).toInt(),
  reps: (json['reps'] as num).toInt(),
  weight: (json['weight'] as num).toDouble(),
  volume: (json['volume'] as num).toDouble(),
  order: (json['order'] as num).toInt(),
);

Map<String, dynamic> _$$WorkoutExerciseImplToJson(
  _$WorkoutExerciseImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'exercise': instance.exerciseId,
  'exercise_name': instance.exerciseName,
  'sets': instance.sets,
  'reps': instance.reps,
  'weight': instance.weight,
  'volume': instance.volume,
  'order': instance.order,
};
