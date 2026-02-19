// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

WorkoutLog _$WorkoutLogFromJson(Map<String, dynamic> json) {
  return _WorkoutLog.fromJson(json);
}

/// @nodoc
mixin _$WorkoutLog {
  int? get id => throw _privateConstructorUsedError;
  int? get user => throw _privateConstructorUsedError;
  @JsonKey(name: 'custom_workout')
  int? get customWorkoutId => throw _privateConstructorUsedError;
  @JsonKey(name: 'workout_name')
  String? get workoutName => throw _privateConstructorUsedError;
  int? get gym => throw _privateConstructorUsedError;
  @JsonKey(name: 'gym_name')
  String? get gymName => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  int get duration => throw _privateConstructorUsedError;
  @JsonKey(name: 'calories_burned')
  double get caloriesBurned => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  List<WorkoutExercise> get exercises => throw _privateConstructorUsedError;
  @JsonKey(name: 'has_new_prs')
  bool get hasNewPrs => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this WorkoutLog to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkoutLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkoutLogCopyWith<WorkoutLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutLogCopyWith<$Res> {
  factory $WorkoutLogCopyWith(
    WorkoutLog value,
    $Res Function(WorkoutLog) then,
  ) = _$WorkoutLogCopyWithImpl<$Res, WorkoutLog>;
  @useResult
  $Res call({
    int? id,
    int? user,
    @JsonKey(name: 'custom_workout') int? customWorkoutId,
    @JsonKey(name: 'workout_name') String? workoutName,
    int? gym,
    @JsonKey(name: 'gym_name') String? gymName,
    DateTime date,
    int duration,
    @JsonKey(name: 'calories_burned') double caloriesBurned,
    String? notes,
    List<WorkoutExercise> exercises,
    @JsonKey(name: 'has_new_prs') bool hasNewPrs,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$WorkoutLogCopyWithImpl<$Res, $Val extends WorkoutLog>
    implements $WorkoutLogCopyWith<$Res> {
  _$WorkoutLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkoutLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? user = freezed,
    Object? customWorkoutId = freezed,
    Object? workoutName = freezed,
    Object? gym = freezed,
    Object? gymName = freezed,
    Object? date = null,
    Object? duration = null,
    Object? caloriesBurned = null,
    Object? notes = freezed,
    Object? exercises = null,
    Object? hasNewPrs = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int?,
            user: freezed == user
                ? _value.user
                : user // ignore: cast_nullable_to_non_nullable
                      as int?,
            customWorkoutId: freezed == customWorkoutId
                ? _value.customWorkoutId
                : customWorkoutId // ignore: cast_nullable_to_non_nullable
                      as int?,
            workoutName: freezed == workoutName
                ? _value.workoutName
                : workoutName // ignore: cast_nullable_to_non_nullable
                      as String?,
            gym: freezed == gym
                ? _value.gym
                : gym // ignore: cast_nullable_to_non_nullable
                      as int?,
            gymName: freezed == gymName
                ? _value.gymName
                : gymName // ignore: cast_nullable_to_non_nullable
                      as String?,
            date: null == date
                ? _value.date
                : date // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            duration: null == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as int,
            caloriesBurned: null == caloriesBurned
                ? _value.caloriesBurned
                : caloriesBurned // ignore: cast_nullable_to_non_nullable
                      as double,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            exercises: null == exercises
                ? _value.exercises
                : exercises // ignore: cast_nullable_to_non_nullable
                      as List<WorkoutExercise>,
            hasNewPrs: null == hasNewPrs
                ? _value.hasNewPrs
                : hasNewPrs // ignore: cast_nullable_to_non_nullable
                      as bool,
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
abstract class _$$WorkoutLogImplCopyWith<$Res>
    implements $WorkoutLogCopyWith<$Res> {
  factory _$$WorkoutLogImplCopyWith(
    _$WorkoutLogImpl value,
    $Res Function(_$WorkoutLogImpl) then,
  ) = __$$WorkoutLogImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? id,
    int? user,
    @JsonKey(name: 'custom_workout') int? customWorkoutId,
    @JsonKey(name: 'workout_name') String? workoutName,
    int? gym,
    @JsonKey(name: 'gym_name') String? gymName,
    DateTime date,
    int duration,
    @JsonKey(name: 'calories_burned') double caloriesBurned,
    String? notes,
    List<WorkoutExercise> exercises,
    @JsonKey(name: 'has_new_prs') bool hasNewPrs,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$WorkoutLogImplCopyWithImpl<$Res>
    extends _$WorkoutLogCopyWithImpl<$Res, _$WorkoutLogImpl>
    implements _$$WorkoutLogImplCopyWith<$Res> {
  __$$WorkoutLogImplCopyWithImpl(
    _$WorkoutLogImpl _value,
    $Res Function(_$WorkoutLogImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of WorkoutLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? user = freezed,
    Object? customWorkoutId = freezed,
    Object? workoutName = freezed,
    Object? gym = freezed,
    Object? gymName = freezed,
    Object? date = null,
    Object? duration = null,
    Object? caloriesBurned = null,
    Object? notes = freezed,
    Object? exercises = null,
    Object? hasNewPrs = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$WorkoutLogImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int?,
        user: freezed == user
            ? _value.user
            : user // ignore: cast_nullable_to_non_nullable
                  as int?,
        customWorkoutId: freezed == customWorkoutId
            ? _value.customWorkoutId
            : customWorkoutId // ignore: cast_nullable_to_non_nullable
                  as int?,
        workoutName: freezed == workoutName
            ? _value.workoutName
            : workoutName // ignore: cast_nullable_to_non_nullable
                  as String?,
        gym: freezed == gym
            ? _value.gym
            : gym // ignore: cast_nullable_to_non_nullable
                  as int?,
        gymName: freezed == gymName
            ? _value.gymName
            : gymName // ignore: cast_nullable_to_non_nullable
                  as String?,
        date: null == date
            ? _value.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        duration: null == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as int,
        caloriesBurned: null == caloriesBurned
            ? _value.caloriesBurned
            : caloriesBurned // ignore: cast_nullable_to_non_nullable
                  as double,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        exercises: null == exercises
            ? _value._exercises
            : exercises // ignore: cast_nullable_to_non_nullable
                  as List<WorkoutExercise>,
        hasNewPrs: null == hasNewPrs
            ? _value.hasNewPrs
            : hasNewPrs // ignore: cast_nullable_to_non_nullable
                  as bool,
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
class _$WorkoutLogImpl implements _WorkoutLog {
  const _$WorkoutLogImpl({
    this.id,
    this.user,
    @JsonKey(name: 'custom_workout') this.customWorkoutId,
    @JsonKey(name: 'workout_name') this.workoutName,
    this.gym,
    @JsonKey(name: 'gym_name') this.gymName,
    required this.date,
    required this.duration,
    @JsonKey(name: 'calories_burned') required this.caloriesBurned,
    this.notes,
    required final List<WorkoutExercise> exercises,
    @JsonKey(name: 'has_new_prs') required this.hasNewPrs,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  }) : _exercises = exercises;

  factory _$WorkoutLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutLogImplFromJson(json);

  @override
  final int? id;
  @override
  final int? user;
  @override
  @JsonKey(name: 'custom_workout')
  final int? customWorkoutId;
  @override
  @JsonKey(name: 'workout_name')
  final String? workoutName;
  @override
  final int? gym;
  @override
  @JsonKey(name: 'gym_name')
  final String? gymName;
  @override
  final DateTime date;
  @override
  final int duration;
  @override
  @JsonKey(name: 'calories_burned')
  final double caloriesBurned;
  @override
  final String? notes;
  final List<WorkoutExercise> _exercises;
  @override
  List<WorkoutExercise> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  @JsonKey(name: 'has_new_prs')
  final bool hasNewPrs;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'WorkoutLog(id: $id, user: $user, customWorkoutId: $customWorkoutId, workoutName: $workoutName, gym: $gym, gymName: $gymName, date: $date, duration: $duration, caloriesBurned: $caloriesBurned, notes: $notes, exercises: $exercises, hasNewPrs: $hasNewPrs, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutLogImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.customWorkoutId, customWorkoutId) ||
                other.customWorkoutId == customWorkoutId) &&
            (identical(other.workoutName, workoutName) ||
                other.workoutName == workoutName) &&
            (identical(other.gym, gym) || other.gym == gym) &&
            (identical(other.gymName, gymName) || other.gymName == gymName) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.caloriesBurned, caloriesBurned) ||
                other.caloriesBurned == caloriesBurned) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            const DeepCollectionEquality().equals(
              other._exercises,
              _exercises,
            ) &&
            (identical(other.hasNewPrs, hasNewPrs) ||
                other.hasNewPrs == hasNewPrs) &&
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
    user,
    customWorkoutId,
    workoutName,
    gym,
    gymName,
    date,
    duration,
    caloriesBurned,
    notes,
    const DeepCollectionEquality().hash(_exercises),
    hasNewPrs,
    createdAt,
    updatedAt,
  );

  /// Create a copy of WorkoutLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutLogImplCopyWith<_$WorkoutLogImpl> get copyWith =>
      __$$WorkoutLogImplCopyWithImpl<_$WorkoutLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutLogImplToJson(this);
  }
}

abstract class _WorkoutLog implements WorkoutLog {
  const factory _WorkoutLog({
    final int? id,
    final int? user,
    @JsonKey(name: 'custom_workout') final int? customWorkoutId,
    @JsonKey(name: 'workout_name') final String? workoutName,
    final int? gym,
    @JsonKey(name: 'gym_name') final String? gymName,
    required final DateTime date,
    required final int duration,
    @JsonKey(name: 'calories_burned') required final double caloriesBurned,
    final String? notes,
    required final List<WorkoutExercise> exercises,
    @JsonKey(name: 'has_new_prs') required final bool hasNewPrs,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$WorkoutLogImpl;

  factory _WorkoutLog.fromJson(Map<String, dynamic> json) =
      _$WorkoutLogImpl.fromJson;

  @override
  int? get id;
  @override
  int? get user;
  @override
  @JsonKey(name: 'custom_workout')
  int? get customWorkoutId;
  @override
  @JsonKey(name: 'workout_name')
  String? get workoutName;
  @override
  int? get gym;
  @override
  @JsonKey(name: 'gym_name')
  String? get gymName;
  @override
  DateTime get date;
  @override
  int get duration;
  @override
  @JsonKey(name: 'calories_burned')
  double get caloriesBurned;
  @override
  String? get notes;
  @override
  List<WorkoutExercise> get exercises;
  @override
  @JsonKey(name: 'has_new_prs')
  bool get hasNewPrs;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of WorkoutLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkoutLogImplCopyWith<_$WorkoutLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
