// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutLogImpl _$$WorkoutLogImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutLogImpl(
      id: (json['id'] as num?)?.toInt(),
      user: (json['user'] as num?)?.toInt(),
      customWorkoutId: (json['custom_workout'] as num?)?.toInt(),
      workoutName: json['workout_name'] as String?,
      gym: (json['gym'] as num?)?.toInt(),
      gymName: json['gym_name'] as String?,
      date: DateTime.parse(json['date'] as String),
      duration: (json['duration'] as num).toInt(),
      caloriesBurned: (json['calories_burned'] as num).toDouble(),
      notes: json['notes'] as String?,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNewPrs: json['has_new_prs'] as bool,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$WorkoutLogImplToJson(_$WorkoutLogImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'custom_workout': instance.customWorkoutId,
      'workout_name': instance.workoutName,
      'gym': instance.gym,
      'gym_name': instance.gymName,
      'date': instance.date.toIso8601String(),
      'duration': instance.duration,
      'calories_burned': instance.caloriesBurned,
      'notes': instance.notes,
      'exercises': instance.exercises,
      'has_new_prs': instance.hasNewPrs,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
