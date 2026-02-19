// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'personal_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PersonalRecord _$PersonalRecordFromJson(Map<String, dynamic> json) {
  return _PersonalRecord.fromJson(json);
}

/// @nodoc
mixin _$PersonalRecord {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'exercise')
  int get exerciseId => throw _privateConstructorUsedError;
  @JsonKey(name: 'exercise_name')
  String get exerciseName => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_weight')
  double get maxWeight => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_reps')
  int get maxReps => throw _privateConstructorUsedError;
  @JsonKey(name: 'max_volume')
  double get maxVolume => throw _privateConstructorUsedError;
  @JsonKey(name: 'achieved_date')
  DateTime get achievedDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'improvement_percentage')
  double? get improvementPercentage => throw _privateConstructorUsedError;
  @JsonKey(name: 'workout_log')
  int? get workoutLogId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this PersonalRecord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PersonalRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PersonalRecordCopyWith<PersonalRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonalRecordCopyWith<$Res> {
  factory $PersonalRecordCopyWith(
    PersonalRecord value,
    $Res Function(PersonalRecord) then,
  ) = _$PersonalRecordCopyWithImpl<$Res, PersonalRecord>;
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'exercise') int exerciseId,
    @JsonKey(name: 'exercise_name') String exerciseName,
    @JsonKey(name: 'max_weight') double maxWeight,
    @JsonKey(name: 'max_reps') int maxReps,
    @JsonKey(name: 'max_volume') double maxVolume,
    @JsonKey(name: 'achieved_date') DateTime achievedDate,
    @JsonKey(name: 'improvement_percentage') double? improvementPercentage,
    @JsonKey(name: 'workout_log') int? workoutLogId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$PersonalRecordCopyWithImpl<$Res, $Val extends PersonalRecord>
    implements $PersonalRecordCopyWith<$Res> {
  _$PersonalRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PersonalRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? exerciseId = null,
    Object? exerciseName = null,
    Object? maxWeight = null,
    Object? maxReps = null,
    Object? maxVolume = null,
    Object? achievedDate = null,
    Object? improvementPercentage = freezed,
    Object? workoutLogId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            exerciseId: null == exerciseId
                ? _value.exerciseId
                : exerciseId // ignore: cast_nullable_to_non_nullable
                      as int,
            exerciseName: null == exerciseName
                ? _value.exerciseName
                : exerciseName // ignore: cast_nullable_to_non_nullable
                      as String,
            maxWeight: null == maxWeight
                ? _value.maxWeight
                : maxWeight // ignore: cast_nullable_to_non_nullable
                      as double,
            maxReps: null == maxReps
                ? _value.maxReps
                : maxReps // ignore: cast_nullable_to_non_nullable
                      as int,
            maxVolume: null == maxVolume
                ? _value.maxVolume
                : maxVolume // ignore: cast_nullable_to_non_nullable
                      as double,
            achievedDate: null == achievedDate
                ? _value.achievedDate
                : achievedDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            improvementPercentage: freezed == improvementPercentage
                ? _value.improvementPercentage
                : improvementPercentage // ignore: cast_nullable_to_non_nullable
                      as double?,
            workoutLogId: freezed == workoutLogId
                ? _value.workoutLogId
                : workoutLogId // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PersonalRecordImplCopyWith<$Res>
    implements $PersonalRecordCopyWith<$Res> {
  factory _$$PersonalRecordImplCopyWith(
    _$PersonalRecordImpl value,
    $Res Function(_$PersonalRecordImpl) then,
  ) = __$$PersonalRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    @JsonKey(name: 'exercise') int exerciseId,
    @JsonKey(name: 'exercise_name') String exerciseName,
    @JsonKey(name: 'max_weight') double maxWeight,
    @JsonKey(name: 'max_reps') int maxReps,
    @JsonKey(name: 'max_volume') double maxVolume,
    @JsonKey(name: 'achieved_date') DateTime achievedDate,
    @JsonKey(name: 'improvement_percentage') double? improvementPercentage,
    @JsonKey(name: 'workout_log') int? workoutLogId,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$PersonalRecordImplCopyWithImpl<$Res>
    extends _$PersonalRecordCopyWithImpl<$Res, _$PersonalRecordImpl>
    implements _$$PersonalRecordImplCopyWith<$Res> {
  __$$PersonalRecordImplCopyWithImpl(
    _$PersonalRecordImpl _value,
    $Res Function(_$PersonalRecordImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PersonalRecord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? exerciseId = null,
    Object? exerciseName = null,
    Object? maxWeight = null,
    Object? maxReps = null,
    Object? maxVolume = null,
    Object? achievedDate = null,
    Object? improvementPercentage = freezed,
    Object? workoutLogId = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$PersonalRecordImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        exerciseId: null == exerciseId
            ? _value.exerciseId
            : exerciseId // ignore: cast_nullable_to_non_nullable
                  as int,
        exerciseName: null == exerciseName
            ? _value.exerciseName
            : exerciseName // ignore: cast_nullable_to_non_nullable
                  as String,
        maxWeight: null == maxWeight
            ? _value.maxWeight
            : maxWeight // ignore: cast_nullable_to_non_nullable
                  as double,
        maxReps: null == maxReps
            ? _value.maxReps
            : maxReps // ignore: cast_nullable_to_non_nullable
                  as int,
        maxVolume: null == maxVolume
            ? _value.maxVolume
            : maxVolume // ignore: cast_nullable_to_non_nullable
                  as double,
        achievedDate: null == achievedDate
            ? _value.achievedDate
            : achievedDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        improvementPercentage: freezed == improvementPercentage
            ? _value.improvementPercentage
            : improvementPercentage // ignore: cast_nullable_to_non_nullable
                  as double?,
        workoutLogId: freezed == workoutLogId
            ? _value.workoutLogId
            : workoutLogId // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PersonalRecordImpl implements _PersonalRecord {
  const _$PersonalRecordImpl({
    required this.id,
    @JsonKey(name: 'exercise') required this.exerciseId,
    @JsonKey(name: 'exercise_name') required this.exerciseName,
    @JsonKey(name: 'max_weight') required this.maxWeight,
    @JsonKey(name: 'max_reps') required this.maxReps,
    @JsonKey(name: 'max_volume') required this.maxVolume,
    @JsonKey(name: 'achieved_date') required this.achievedDate,
    @JsonKey(name: 'improvement_percentage') this.improvementPercentage,
    @JsonKey(name: 'workout_log') this.workoutLogId,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  });

  factory _$PersonalRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonalRecordImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'exercise')
  final int exerciseId;
  @override
  @JsonKey(name: 'exercise_name')
  final String exerciseName;
  @override
  @JsonKey(name: 'max_weight')
  final double maxWeight;
  @override
  @JsonKey(name: 'max_reps')
  final int maxReps;
  @override
  @JsonKey(name: 'max_volume')
  final double maxVolume;
  @override
  @JsonKey(name: 'achieved_date')
  final DateTime achievedDate;
  @override
  @JsonKey(name: 'improvement_percentage')
  final double? improvementPercentage;
  @override
  @JsonKey(name: 'workout_log')
  final int? workoutLogId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'PersonalRecord(id: $id, exerciseId: $exerciseId, exerciseName: $exerciseName, maxWeight: $maxWeight, maxReps: $maxReps, maxVolume: $maxVolume, achievedDate: $achievedDate, improvementPercentage: $improvementPercentage, workoutLogId: $workoutLogId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonalRecordImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.exerciseName, exerciseName) ||
                other.exerciseName == exerciseName) &&
            (identical(other.maxWeight, maxWeight) ||
                other.maxWeight == maxWeight) &&
            (identical(other.maxReps, maxReps) || other.maxReps == maxReps) &&
            (identical(other.maxVolume, maxVolume) ||
                other.maxVolume == maxVolume) &&
            (identical(other.achievedDate, achievedDate) ||
                other.achievedDate == achievedDate) &&
            (identical(other.improvementPercentage, improvementPercentage) ||
                other.improvementPercentage == improvementPercentage) &&
            (identical(other.workoutLogId, workoutLogId) ||
                other.workoutLogId == workoutLogId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    exerciseId,
    exerciseName,
    maxWeight,
    maxReps,
    maxVolume,
    achievedDate,
    improvementPercentage,
    workoutLogId,
    createdAt,
    updatedAt,
  );

  /// Create a copy of PersonalRecord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonalRecordImplCopyWith<_$PersonalRecordImpl> get copyWith =>
      __$$PersonalRecordImplCopyWithImpl<_$PersonalRecordImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonalRecordImplToJson(this);
  }
}

abstract class _PersonalRecord implements PersonalRecord {
  const factory _PersonalRecord({
    required final int id,
    @JsonKey(name: 'exercise') required final int exerciseId,
    @JsonKey(name: 'exercise_name') required final String exerciseName,
    @JsonKey(name: 'max_weight') required final double maxWeight,
    @JsonKey(name: 'max_reps') required final int maxReps,
    @JsonKey(name: 'max_volume') required final double maxVolume,
    @JsonKey(name: 'achieved_date') required final DateTime achievedDate,
    @JsonKey(name: 'improvement_percentage')
    final double? improvementPercentage,
    @JsonKey(name: 'workout_log') final int? workoutLogId,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$PersonalRecordImpl;

  factory _PersonalRecord.fromJson(Map<String, dynamic> json) =
      _$PersonalRecordImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'exercise')
  int get exerciseId;
  @override
  @JsonKey(name: 'exercise_name')
  String get exerciseName;
  @override
  @JsonKey(name: 'max_weight')
  double get maxWeight;
  @override
  @JsonKey(name: 'max_reps')
  int get maxReps;
  @override
  @JsonKey(name: 'max_volume')
  double get maxVolume;
  @override
  @JsonKey(name: 'achieved_date')
  DateTime get achievedDate;
  @override
  @JsonKey(name: 'improvement_percentage')
  double? get improvementPercentage;
  @override
  @JsonKey(name: 'workout_log')
  int? get workoutLogId;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of PersonalRecord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PersonalRecordImplCopyWith<_$PersonalRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
