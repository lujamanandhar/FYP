// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Gym _$GymFromJson(Map<String, dynamic> json) => Gym(
  id: json['id'] as String,
  name: json['name'] as String,
  location: json['location'] as String,
  address: json['address'] as String?,
  rating: (json['rating'] as num).toDouble(),
  phone: json['phone'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GymToJson(Gym instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'location': instance.location,
  'address': instance.address,
  'rating': instance.rating,
  'phone': instance.phone,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

Exercise _$ExerciseFromJson(Map<String, dynamic> json) => Exercise(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  category: json['category'] as String,
  difficulty: json['difficulty'] as String,
  instructions: json['instructions'] as String?,
  videoUrl: json['videoUrl'] as String?,
  imageUrl: json['imageUrl'] as String?,
  caloriesPerMinute: (json['caloriesPerMinute'] as num).toDouble(),
  isCustom: json['isCustom'] as bool,
  createdBy: json['createdBy'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ExerciseToJson(Exercise instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'difficulty': instance.difficulty,
  'instructions': instance.instructions,
  'videoUrl': instance.videoUrl,
  'imageUrl': instance.imageUrl,
  'caloriesPerMinute': instance.caloriesPerMinute,
  'isCustom': instance.isCustom,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

WorkoutSet _$WorkoutSetFromJson(Map<String, dynamic> json) => WorkoutSet(
  setNumber: (json['setNumber'] as num).toInt(),
  reps: (json['reps'] as num?)?.toInt(),
  weight: (json['weight'] as num?)?.toDouble(),
  durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
  completed: json['completed'] as bool,
);

Map<String, dynamic> _$WorkoutSetToJson(WorkoutSet instance) =>
    <String, dynamic>{
      'setNumber': instance.setNumber,
      'reps': instance.reps,
      'weight': instance.weight,
      'durationSeconds': instance.durationSeconds,
      'completed': instance.completed,
    };

ExerciseSet _$ExerciseSetFromJson(Map<String, dynamic> json) => ExerciseSet(
  exerciseId: json['exerciseId'] as String,
  exerciseName: json['exerciseName'] as String,
  order: (json['order'] as num).toInt(),
  sets: (json['sets'] as List<dynamic>)
      .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
      .toList(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$ExerciseSetToJson(ExerciseSet instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'order': instance.order,
      'sets': instance.sets,
      'notes': instance.notes,
    };

WorkoutLog _$WorkoutLogFromJson(Map<String, dynamic> json) => WorkoutLog(
  id: json['id'] as String,
  workoutName: json['workoutName'] as String,
  customWorkoutId: json['customWorkoutId'] as String?,
  durationMinutes: (json['durationMinutes'] as num).toInt(),
  exercises: (json['exercises'] as List<dynamic>)
      .map((e) => ExerciseSet.fromJson(e as Map<String, dynamic>))
      .toList(),
  caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
  gym: json['gym'] == null
      ? null
      : Gym.fromJson(json['gym'] as Map<String, dynamic>),
  notes: json['notes'] as String?,
  loggedAt: DateTime.parse(json['loggedAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$WorkoutLogToJson(WorkoutLog instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workoutName': instance.workoutName,
      'customWorkoutId': instance.customWorkoutId,
      'durationMinutes': instance.durationMinutes,
      'exercises': instance.exercises,
      'caloriesBurned': instance.caloriesBurned,
      'gym': instance.gym,
      'notes': instance.notes,
      'loggedAt': instance.loggedAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

CustomWorkoutExercise _$CustomWorkoutExerciseFromJson(
  Map<String, dynamic> json,
) => CustomWorkoutExercise(
  exerciseId: json['exerciseId'] as String,
  exerciseName: json['exerciseName'] as String,
  order: (json['order'] as num).toInt(),
  sets: (json['sets'] as num).toInt(),
  reps: (json['reps'] as num).toInt(),
  durationSeconds: (json['durationSeconds'] as num).toInt(),
  restSeconds: (json['restSeconds'] as num).toInt(),
);

Map<String, dynamic> _$CustomWorkoutExerciseToJson(
  CustomWorkoutExercise instance,
) => <String, dynamic>{
  'exerciseId': instance.exerciseId,
  'exerciseName': instance.exerciseName,
  'order': instance.order,
  'sets': instance.sets,
  'reps': instance.reps,
  'durationSeconds': instance.durationSeconds,
  'restSeconds': instance.restSeconds,
};

CustomWorkout _$CustomWorkoutFromJson(Map<String, dynamic> json) =>
    CustomWorkout(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => CustomWorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      estimatedDuration: (json['estimatedDuration'] as num).toInt(),
      isPublic: json['isPublic'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CustomWorkoutToJson(CustomWorkout instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'category': instance.category,
      'exercises': instance.exercises,
      'estimatedDuration': instance.estimatedDuration,
      'isPublic': instance.isPublic,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

PersonalRecord _$PersonalRecordFromJson(Map<String, dynamic> json) =>
    PersonalRecord(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      recordType: json['recordType'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      workoutLogId: json['workoutLogId'] as String?,
      achievedAt: DateTime.parse(json['achievedAt'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$PersonalRecordToJson(PersonalRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'recordType': instance.recordType,
      'value': instance.value,
      'unit': instance.unit,
      'workoutLogId': instance.workoutLogId,
      'achievedAt': instance.achievedAt.toIso8601String(),
      'notes': instance.notes,
    };

CreateWorkoutLogRequest _$CreateWorkoutLogRequestFromJson(
  Map<String, dynamic> json,
) => CreateWorkoutLogRequest(
  workoutName: json['workoutName'] as String,
  customWorkoutId: json['customWorkoutId'] as String?,
  gymId: json['gymId'] as String?,
  durationMinutes: (json['durationMinutes'] as num).toInt(),
  caloriesBurned: (json['caloriesBurned'] as num).toDouble(),
  exercises: (json['exercises'] as List<dynamic>)
      .map((e) => ExerciseSetRequest.fromJson(e as Map<String, dynamic>))
      .toList(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$CreateWorkoutLogRequestToJson(
  CreateWorkoutLogRequest instance,
) => <String, dynamic>{
  'workoutName': instance.workoutName,
  'customWorkoutId': instance.customWorkoutId,
  'gymId': instance.gymId,
  'durationMinutes': instance.durationMinutes,
  'caloriesBurned': instance.caloriesBurned,
  'exercises': instance.exercises,
  'notes': instance.notes,
};

ExerciseSetRequest _$ExerciseSetRequestFromJson(Map<String, dynamic> json) =>
    ExerciseSetRequest(
      exerciseId: json['exerciseId'] as String,
      order: (json['order'] as num).toInt(),
      sets: (json['sets'] as List<dynamic>)
          .map((e) => WorkoutSetRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$ExerciseSetRequestToJson(ExerciseSetRequest instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'order': instance.order,
      'sets': instance.sets,
      'notes': instance.notes,
    };

WorkoutSetRequest _$WorkoutSetRequestFromJson(Map<String, dynamic> json) =>
    WorkoutSetRequest(
      setNumber: (json['setNumber'] as num).toInt(),
      reps: (json['reps'] as num?)?.toInt(),
      weight: (json['weight'] as num?)?.toDouble(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      completed: json['completed'] as bool? ?? true,
    );

Map<String, dynamic> _$WorkoutSetRequestToJson(WorkoutSetRequest instance) =>
    <String, dynamic>{
      'setNumber': instance.setNumber,
      'reps': instance.reps,
      'weight': instance.weight,
      'durationSeconds': instance.durationSeconds,
      'completed': instance.completed,
    };

CreateCustomWorkoutRequest _$CreateCustomWorkoutRequestFromJson(
  Map<String, dynamic> json,
) => CreateCustomWorkoutRequest(
  name: json['name'] as String,
  description: json['description'] as String?,
  category: json['category'] as String,
  exercises: (json['exercises'] as List<dynamic>)
      .map(
        (e) => CustomWorkoutExerciseRequest.fromJson(e as Map<String, dynamic>),
      )
      .toList(),
  estimatedDuration: (json['estimatedDuration'] as num).toInt(),
  isPublic: json['isPublic'] as bool? ?? false,
);

Map<String, dynamic> _$CreateCustomWorkoutRequestToJson(
  CreateCustomWorkoutRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'category': instance.category,
  'exercises': instance.exercises,
  'estimatedDuration': instance.estimatedDuration,
  'isPublic': instance.isPublic,
};

CustomWorkoutExerciseRequest _$CustomWorkoutExerciseRequestFromJson(
  Map<String, dynamic> json,
) => CustomWorkoutExerciseRequest(
  exerciseId: json['exerciseId'] as String,
  order: (json['order'] as num).toInt(),
  sets: (json['sets'] as num).toInt(),
  reps: (json['reps'] as num).toInt(),
  durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
  restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 60,
);

Map<String, dynamic> _$CustomWorkoutExerciseRequestToJson(
  CustomWorkoutExerciseRequest instance,
) => <String, dynamic>{
  'exerciseId': instance.exerciseId,
  'order': instance.order,
  'sets': instance.sets,
  'reps': instance.reps,
  'durationSeconds': instance.durationSeconds,
  'restSeconds': instance.restSeconds,
};
