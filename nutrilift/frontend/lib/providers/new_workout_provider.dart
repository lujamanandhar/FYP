import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart' as ex;
import '../models/workout_models.dart';
import '../models/workout_log.dart' as wl;
import '../repositories/workout_repository.dart';
import 'repository_providers.dart';

/// State class for a workout being created
/// 
/// Holds all the data for a workout that is being built,
/// including exercises, sets, reps, weights, and metadata.
class NewWorkoutState {
  final String? workoutName;
  final String? customWorkoutId;
  final String? gymId;
  final int? durationMinutes;
  final String? notes;
  final List<NewWorkoutExercise> exercises;
  final Map<String, String> validationErrors;
  final bool isSubmitting;

  const NewWorkoutState({
    this.workoutName,
    this.customWorkoutId,
    this.gymId,
    this.durationMinutes,
    this.notes,
    this.exercises = const [],
    this.validationErrors = const {},
    this.isSubmitting = false,
  });

  NewWorkoutState copyWith({
    String? workoutName,
    String? customWorkoutId,
    String? gymId,
    int? durationMinutes,
    String? notes,
    List<NewWorkoutExercise>? exercises,
    Map<String, String>? validationErrors,
    bool? isSubmitting,
  }) {
    return NewWorkoutState(
      workoutName: workoutName ?? this.workoutName,
      customWorkoutId: customWorkoutId ?? this.customWorkoutId,
      gymId: gymId ?? this.gymId,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      exercises: exercises ?? this.exercises,
      validationErrors: validationErrors ?? this.validationErrors,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  /// Check if the workout is valid for submission
  bool get isValid {
    return validationErrors.isEmpty &&
        exercises.isNotEmpty &&
        durationMinutes != null &&
        durationMinutes! >= 1 &&
        durationMinutes! <= 600;
  }
}

/// Class representing an exercise in a workout being created
class NewWorkoutExercise {
  final ex.Exercise exercise;
  final int order;
  final List<NewWorkoutSet> sets;
  final String? notes;

  const NewWorkoutExercise({
    required this.exercise,
    required this.order,
    required this.sets,
    this.notes,
  });

  NewWorkoutExercise copyWith({
    ex.Exercise? exercise,
    int? order,
    List<NewWorkoutSet>? sets,
    String? notes,
  }) {
    return NewWorkoutExercise(
      exercise: exercise ?? this.exercise,
      order: order ?? this.order,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }
}

/// Class representing a set in an exercise
class NewWorkoutSet {
  final int setNumber;
  final int? reps;
  final double? weight;
  final int? durationSeconds;
  final bool completed;

  const NewWorkoutSet({
    required this.setNumber,
    this.reps,
    this.weight,
    this.durationSeconds,
    this.completed = false,
  });

  NewWorkoutSet copyWith({
    int? setNumber,
    int? reps,
    double? weight,
    int? durationSeconds,
    bool? completed,
  }) {
    return NewWorkoutSet(
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
    );
  }

  /// Validate the set data
  /// Returns error message if invalid, null if valid
  String? validate() {
    if (reps != null && (reps! < 1 || reps! > 100)) {
      return 'Reps must be between 1 and 100';
    }
    if (weight != null && (weight! < 0.1 || weight! > 1000)) {
      return 'Weight must be between 0.1 and 1000 kg';
    }
    return null;
  }
}

/// State notifier for managing a workout being created
/// 
/// This notifier manages the state of a workout that is being built,
/// including adding/removing exercises, updating sets/reps/weights,
/// and validating the workout before submission.
/// 
/// Validates: Requirements 2.2, 2.4, 2.5, 2.6, 2.7
class NewWorkoutNotifier extends StateNotifier<NewWorkoutState> {
  final WorkoutRepository _repository;

  NewWorkoutNotifier(this._repository) : super(const NewWorkoutState());

  /// Set workout name
  void setWorkoutName(String name) {
    state = state.copyWith(workoutName: name);
    _validateWorkout();
  }

  /// Set custom workout template ID
  /// 
  /// When a template is selected, exercises should be pre-populated
  /// by calling loadTemplateExercises separately.
  /// 
  /// Validates: Requirements 2.2
  void setCustomWorkoutId(String? id) {
    state = state.copyWith(customWorkoutId: id);
  }

  /// Set gym ID
  void setGymId(String? id) {
    state = state.copyWith(gymId: id);
  }

  /// Set workout duration in minutes
  /// 
  /// Validates that duration is between 1 and 600 minutes.
  /// 
  /// Validates: Requirements 2.5, 9.1
  void setDuration(int minutes) {
    state = state.copyWith(durationMinutes: minutes);
    _validateWorkout();
  }

  /// Set workout notes
  void setNotes(String? notes) {
    state = state.copyWith(notes: notes);
  }

  /// Add an exercise to the workout
  /// 
  /// Creates a new exercise entry with default sets.
  /// The exercise is added at the end of the list.
  /// 
  /// Validates: Requirements 2.4, 3.8
  void addExercise(ex.Exercise exercise, {int defaultSets = 3}) {
    final exercises = List<NewWorkoutExercise>.from(state.exercises);
    
    // Create default sets for the exercise
    final sets = List.generate(
      defaultSets,
      (index) => NewWorkoutSet(
        setNumber: index + 1,
        reps: 10, // Default reps
        weight: 0.0, // Default weight
        completed: false,
      ),
    );

    exercises.add(NewWorkoutExercise(
      exercise: exercise,
      order: exercises.length,
      sets: sets,
    ));

    state = state.copyWith(exercises: exercises);
    _validateWorkout();
  }

  /// Remove an exercise from the workout
  /// 
  /// Removes the exercise at the specified index and reorders remaining exercises.
  void removeExercise(int index) {
    if (index < 0 || index >= state.exercises.length) return;

    final exercises = List<NewWorkoutExercise>.from(state.exercises);
    exercises.removeAt(index);

    // Reorder remaining exercises
    final reordered = exercises.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();

    state = state.copyWith(exercises: reordered);
    _validateWorkout();
  }

  /// Update an exercise's sets, reps, or weight
  /// 
  /// Updates the exercise at the specified index with new data.
  /// 
  /// Validates: Requirements 2.5, 2.6, 2.7
  void updateExercise(int exerciseIndex, {
    List<NewWorkoutSet>? sets,
    String? notes,
  }) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercises = List<NewWorkoutExercise>.from(state.exercises);
    exercises[exerciseIndex] = exercises[exerciseIndex].copyWith(
      sets: sets,
      notes: notes,
    );

    state = state.copyWith(exercises: exercises);
    _validateWorkout();
  }

  /// Update a specific set within an exercise
  /// 
  /// Updates the set at the specified indices with new values.
  /// 
  /// Validates: Requirements 2.5, 2.6, 2.7, 9.2, 9.3
  void updateSet(int exerciseIndex, int setIndex, {
    int? reps,
    double? weight,
    int? durationSeconds,
    bool? completed,
  }) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= exercise.sets.length) return;

    final sets = List<NewWorkoutSet>.from(exercise.sets);
    sets[setIndex] = sets[setIndex].copyWith(
      reps: reps,
      weight: weight,
      durationSeconds: durationSeconds,
      completed: completed,
    );

    updateExercise(exerciseIndex, sets: sets);
  }

  /// Add a set to an exercise
  /// 
  /// Adds a new set to the exercise at the specified index.
  void addSet(int exerciseIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    final sets = List<NewWorkoutSet>.from(exercise.sets);
    
    // Copy values from the last set if available
    final lastSet = sets.isNotEmpty ? sets.last : null;
    
    sets.add(NewWorkoutSet(
      setNumber: sets.length + 1,
      reps: lastSet?.reps ?? 10,
      weight: lastSet?.weight ?? 0.0,
      completed: false,
    ));

    updateExercise(exerciseIndex, sets: sets);
  }

  /// Remove a set from an exercise
  /// 
  /// Removes the set at the specified indices and renumbers remaining sets.
  void removeSet(int exerciseIndex, int setIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= state.exercises.length) return;

    final exercise = state.exercises[exerciseIndex];
    if (setIndex < 0 || setIndex >= exercise.sets.length) return;
    if (exercise.sets.length <= 1) return; // Keep at least one set

    final sets = List<NewWorkoutSet>.from(exercise.sets);
    sets.removeAt(setIndex);

    // Renumber sets
    final renumbered = sets.asMap().entries.map((entry) {
      return entry.value.copyWith(setNumber: entry.key + 1);
    }).toList();

    updateExercise(exerciseIndex, sets: renumbered);
  }

  /// Validate the workout
  /// 
  /// Checks all validation rules and updates the validation errors map.
  /// 
  /// Validates: Requirements 2.5, 2.6, 2.7, 9.1, 9.2, 9.3, 9.4, 9.5
  void _validateWorkout() {
    final errors = <String, String>{};

    // Validate duration
    if (state.durationMinutes == null) {
      errors['duration'] = 'Duration is required';
    } else if (state.durationMinutes! < 1 || state.durationMinutes! > 600) {
      errors['duration'] = 'Duration must be between 1 and 600 minutes';
    }

    // Validate exercises
    if (state.exercises.isEmpty) {
      errors['exercises'] = 'At least one exercise is required';
    }

    // Validate each exercise's sets
    for (var i = 0; i < state.exercises.length; i++) {
      final exercise = state.exercises[i];
      for (var j = 0; j < exercise.sets.length; j++) {
        final set = exercise.sets[j];
        final setError = set.validate();
        if (setError != null) {
          errors['exercise_${i}_set_$j'] = setError;
        }
      }
    }

    state = state.copyWith(validationErrors: errors);
  }

  /// Submit the workout
  /// 
  /// Validates the workout and submits it to the repository.
  /// Returns the created workout log on success, or throws an exception on failure.
  /// 
  /// Validates: Requirements 2.8, 2.9, 5.1, 14.1, 14.2
  Future<wl.WorkoutLog?> submitWorkout() async {
    _validateWorkout();

    if (!state.isValid) {
      return null;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      // Convert to CreateWorkoutLogRequest
      final request = CreateWorkoutLogRequest(
        workoutName: state.workoutName ?? 'Workout',
        customWorkoutId: state.customWorkoutId,
        gymId: state.gymId,
        durationMinutes: state.durationMinutes!,
        caloriesBurned: 0.0, // Will be calculated by backend
        exercises: state.exercises.map((exercise) {
          return ExerciseSetRequest(
            exerciseId: exercise.exercise.id.toString(),
            order: exercise.order,
            sets: exercise.sets.map((set) {
              return WorkoutSetRequest(
                setNumber: set.setNumber,
                reps: set.reps,
                weight: set.weight,
                durationSeconds: set.durationSeconds,
                completed: set.completed,
              );
            }).toList(),
            notes: exercise.notes,
          );
        }).toList(),
        notes: state.notes,
      );

      final workoutLog = await _repository.logWorkout(request);
      
      // Reset state after successful submission
      reset();
      
      return workoutLog;
    } catch (e) {
      state = state.copyWith(isSubmitting: false);
      rethrow;
    }
  }

  /// Reset the workout state
  /// 
  /// Clears all workout data and starts fresh.
  void reset() {
    state = const NewWorkoutState();
  }

  /// Load exercises from a template
  /// 
  /// Pre-populates the exercise list with exercises from a workout template.
  /// This is called after setCustomWorkoutId when a template is selected.
  /// 
  /// Validates: Requirements 2.2
  void loadTemplateExercises(List<ex.Exercise> templateExercises) {
    final exercises = templateExercises.asMap().entries.map((entry) {
      final index = entry.key;
      final exercise = entry.value;
      
      // Create default sets for each exercise
      final sets = List.generate(
        3, // Default 3 sets
        (setIndex) => NewWorkoutSet(
          setNumber: setIndex + 1,
          reps: 10, // Default reps
          weight: 0.0, // Default weight
          completed: false,
        ),
      );

      return NewWorkoutExercise(
        exercise: exercise,
        order: index,
        sets: sets,
      );
    }).toList();

    state = state.copyWith(exercises: exercises);
    _validateWorkout();
  }
}

/// Provider for new workout state
/// 
/// This provider creates and manages the NewWorkoutNotifier,
/// which handles building a new workout with exercises, sets, and validation.
/// 
/// The state is automatically updated when workout data changes,
/// and all UI components watching this provider will rebuild.
/// 
/// Validates: Requirements 2.2, 2.4, 2.5, 2.6, 2.7
final newWorkoutProvider = StateNotifierProvider<NewWorkoutNotifier, NewWorkoutState>((ref) {
  final repository = ref.watch(workoutRepositoryProvider);
  return NewWorkoutNotifier(repository);
});
