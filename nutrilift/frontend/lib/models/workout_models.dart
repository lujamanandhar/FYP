import 'package:json_annotation/json_annotation.dart';

part 'workout_models.g.dart';

@JsonSerializable()
class Gym {
  final String id;
  final String name;
  final String location;
  final String? address;
  final double rating;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  Gym({
    required this.id,
    required this.name,
    required this.location,
    this.address,
    required this.rating,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Gym.fromJson(Map<String, dynamic> json) => _$GymFromJson(json);
  Map<String, dynamic> toJson() => _$GymToJson(this);
}

@JsonSerializable()
class Exercise {
  final String id;
  final String name;
  final String? description;
  final String category;
  final String difficulty;
  final String? instructions;
  final String? videoUrl;
  final String? imageUrl;
  final double caloriesPerMinute;
  final bool isCustom;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Exercise({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.difficulty,
    this.instructions,
    this.videoUrl,
    this.imageUrl,
    required this.caloriesPerMinute,
    required this.isCustom,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseToJson(this);
}

@JsonSerializable()
class WorkoutSet {
  final int setNumber;
  final int? reps;
  final double? weight;
  final int? durationSeconds;
  final bool completed;

  WorkoutSet({
    required this.setNumber,
    this.reps,
    this.weight,
    this.durationSeconds,
    required this.completed,
  });

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => _$WorkoutSetFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutSetToJson(this);
}

@JsonSerializable()
class ExerciseSet {
  final String exerciseId;
  final String exerciseName;
  final int order;
  final List<WorkoutSet> sets;
  final String? notes;

  ExerciseSet({
    required this.exerciseId,
    required this.exerciseName,
    required this.order,
    required this.sets,
    this.notes,
  });

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => _$ExerciseSetFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseSetToJson(this);
}

@JsonSerializable()
class WorkoutLog {
  final String id;
  final String workoutName;
  final String? customWorkoutId;
  final int durationMinutes;
  final List<ExerciseSet> exercises;
  final double caloriesBurned;
  final Gym? gym;
  final String? notes;
  final DateTime loggedAt;
  final DateTime updatedAt;

  WorkoutLog({
    required this.id,
    required this.workoutName,
    this.customWorkoutId,
    required this.durationMinutes,
    required this.exercises,
    required this.caloriesBurned,
    this.gym,
    this.notes,
    required this.loggedAt,
    required this.updatedAt,
  });

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => _$WorkoutLogFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutLogToJson(this);
}

@JsonSerializable()
class CustomWorkoutExercise {
  final String exerciseId;
  final String exerciseName;
  final int order;
  final int sets;
  final int reps;
  final int durationSeconds;
  final int restSeconds;

  CustomWorkoutExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.order,
    required this.sets,
    required this.reps,
    required this.durationSeconds,
    required this.restSeconds,
  });

  factory CustomWorkoutExercise.fromJson(Map<String, dynamic> json) => 
      _$CustomWorkoutExerciseFromJson(json);
  Map<String, dynamic> toJson() => _$CustomWorkoutExerciseToJson(this);
}

@JsonSerializable()
class CustomWorkout {
  final String id;
  final String name;
  final String? description;
  final String category;
  final List<CustomWorkoutExercise> exercises;
  final int estimatedDuration;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomWorkout({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.exercises,
    required this.estimatedDuration,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomWorkout.fromJson(Map<String, dynamic> json) => 
      _$CustomWorkoutFromJson(json);
  Map<String, dynamic> toJson() => _$CustomWorkoutToJson(this);
}

@JsonSerializable()
class PersonalRecord {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final String recordType;
  final double value;
  final String unit;
  final String? workoutLogId;
  final DateTime achievedAt;
  final String? notes;

  PersonalRecord({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.recordType,
    required this.value,
    required this.unit,
    this.workoutLogId,
    required this.achievedAt,
    this.notes,
  });

  factory PersonalRecord.fromJson(Map<String, dynamic> json) => 
      _$PersonalRecordFromJson(json);
  Map<String, dynamic> toJson() => _$PersonalRecordToJson(this);
}

// Request models for creating/updating data

@JsonSerializable()
class CreateWorkoutLogRequest {
  final String workoutName;
  final String? customWorkoutId;
  final String? gymId;
  final int durationMinutes;
  final double caloriesBurned;
  final List<ExerciseSetRequest> exercises;
  final String? notes;

  CreateWorkoutLogRequest({
    required this.workoutName,
    this.customWorkoutId,
    this.gymId,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.exercises,
    this.notes,
  });

  factory CreateWorkoutLogRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateWorkoutLogRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateWorkoutLogRequestToJson(this);
}

@JsonSerializable()
class ExerciseSetRequest {
  final String exerciseId;
  final int order;
  final List<WorkoutSetRequest> sets;
  final String? notes;

  ExerciseSetRequest({
    required this.exerciseId,
    required this.order,
    required this.sets,
    this.notes,
  });

  factory ExerciseSetRequest.fromJson(Map<String, dynamic> json) => 
      _$ExerciseSetRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ExerciseSetRequestToJson(this);
}

@JsonSerializable()
class WorkoutSetRequest {
  final int setNumber;
  final int? reps;
  final double? weight;
  final int? durationSeconds;
  final bool completed;

  WorkoutSetRequest({
    required this.setNumber,
    this.reps,
    this.weight,
    this.durationSeconds,
    this.completed = true,
  });

  factory WorkoutSetRequest.fromJson(Map<String, dynamic> json) => 
      _$WorkoutSetRequestFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutSetRequestToJson(this);
}

@JsonSerializable()
class CreateCustomWorkoutRequest {
  final String name;
  final String? description;
  final String category;
  final List<CustomWorkoutExerciseRequest> exercises;
  final int estimatedDuration;
  final bool isPublic;

  CreateCustomWorkoutRequest({
    required this.name,
    this.description,
    required this.category,
    required this.exercises,
    required this.estimatedDuration,
    this.isPublic = false,
  });

  factory CreateCustomWorkoutRequest.fromJson(Map<String, dynamic> json) => 
      _$CreateCustomWorkoutRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateCustomWorkoutRequestToJson(this);
}

@JsonSerializable()
class CustomWorkoutExerciseRequest {
  final String exerciseId;
  final int order;
  final int sets;
  final int reps;
  final int durationSeconds;
  final int restSeconds;

  CustomWorkoutExerciseRequest({
    required this.exerciseId,
    required this.order,
    required this.sets,
    required this.reps,
    this.durationSeconds = 0,
    this.restSeconds = 60,
  });

  factory CustomWorkoutExerciseRequest.fromJson(Map<String, dynamic> json) => 
      _$CustomWorkoutExerciseRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CustomWorkoutExerciseRequestToJson(this);
}
