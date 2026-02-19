import 'package:freezed_annotation/freezed_annotation.dart';

part 'personal_record.freezed.dart';
part 'personal_record.g.dart';

@freezed
class PersonalRecord with _$PersonalRecord {
  const factory PersonalRecord({
    required int id,
    @JsonKey(name: 'exercise') required int exerciseId,
    @JsonKey(name: 'exercise_name') required String exerciseName,
    @JsonKey(name: 'max_weight') required double maxWeight,
    @JsonKey(name: 'max_reps') required int maxReps,
    @JsonKey(name: 'max_volume') required double maxVolume,
    @JsonKey(name: 'achieved_date') required DateTime achievedDate,
    @JsonKey(name: 'improvement_percentage') double? improvementPercentage,
    @JsonKey(name: 'workout_log') int? workoutLogId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _PersonalRecord;

  factory PersonalRecord.fromJson(Map<String, dynamic> json) =>
      _$PersonalRecordFromJson(json);
}
