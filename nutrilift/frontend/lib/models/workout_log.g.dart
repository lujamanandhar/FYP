// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$WorkoutLogImpl _$$WorkoutLogImplFromJson(Map<String, dynamic> json) =>
    _$WorkoutLogImpl(
      id: (json['id'] as num?)?.toInt(),
      user: json['user'] == null ? null : (json['user'] is num ? (json['user'] as num).toInt() : null),
      customWorkoutId: (json['custom_workout'] as num?)?.toInt(),
      workoutName: json['workout_name'] as String?,
      gym: json['gym'] == null ? null : (json['gym'] is num ? (json['gym'] as num).toInt() : (json['gym'] is Map ? (json['gym']['id'] as num?)?.toInt() : null)),
      gymName: json['gym_name'] as String? ?? (json['gym'] is Map ? json['gym']['name'] as String? : null),
      // Backend returns 'date' (aliased from logged_at) and 'duration' (aliased from duration_minutes)
      date: DateTime.parse(((json['date'] ?? json['logged_at']) as String)),
      duration: ((json['duration'] ?? json['duration_minutes']) as num).toInt(),
      // calories_burned may come as a string from Django DecimalField serialization
      caloriesBurned: double.parse(json['calories_burned'].toString()),
      notes: json['notes'] as String?,
      // Backend returns exercises under 'workout_exercises'
      // WorkoutLogExercise objects have 'exercise_id' not 'exercise', skip those
      exercises: ((json['workout_exercises'] ?? const []) as List<dynamic>)
          .where((e) => e is Map && (e['exercise'] != null))
          .map((e) => WorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNewPrs: json['has_new_prs'] as bool? ?? false,
      createdAt: json['logged_at'] == null
          ? null
          : DateTime.parse(json['logged_at'] as String),
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
      'workout_exercises': instance.exercises,
      'has_new_prs': instance.hasNewPrs,
      'logged_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
