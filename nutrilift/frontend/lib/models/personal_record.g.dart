// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PersonalRecordImpl _$$PersonalRecordImplFromJson(Map<String, dynamic> json) =>
    _$PersonalRecordImpl(
      id: (json['id'] as num).toInt(),
      exerciseId: (json['exercise'] as num).toInt(),
      exerciseName: json['exercise_name'] as String,
      maxWeight: (json['max_weight'] as num).toDouble(),
      maxReps: (json['max_reps'] as num).toInt(),
      maxVolume: (json['max_volume'] as num).toDouble(),
      achievedDate: DateTime.parse(json['achieved_date'] as String),
      improvementPercentage: (json['improvement_percentage'] as num?)
          ?.toDouble(),
      workoutLogId: (json['workout_log'] as num?)?.toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$PersonalRecordImplToJson(
  _$PersonalRecordImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'exercise': instance.exerciseId,
  'exercise_name': instance.exerciseName,
  'max_weight': instance.maxWeight,
  'max_reps': instance.maxReps,
  'max_volume': instance.maxVolume,
  'achieved_date': instance.achievedDate.toIso8601String(),
  'improvement_percentage': instance.improvementPercentage,
  'workout_log': instance.workoutLogId,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};
