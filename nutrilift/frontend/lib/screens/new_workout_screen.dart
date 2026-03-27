import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/exercise.dart' as ex;
import '../models/workout_log.dart' as wl;
import '../providers/new_workout_provider.dart';
import '../providers/exercise_library_provider.dart';
import '../widgets/nutrilift_header.dart';
import '../widgets/rest_timer_dialog.dart';

/// New Workout Screen
/// 
/// Allows users to log new workouts with exercises, sets, reps, and weights.
/// Supports template selection, exercise search, and form validation.
/// Pass [repeatFrom] to pre-populate from a previous workout.
/// 
/// Validates: Requirements 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 8.2, 9.4, 9.5
class NewWorkoutScreen extends ConsumerStatefulWidget {
  final wl.WorkoutLog? repeatFrom;
  const NewWorkoutScreen({Key? key, this.repeatFrom}) : super(key: key);

  @override
  ConsumerState<NewWorkoutScreen> createState() => _NewWorkoutScreenState();
}

class _NewWorkoutScreenState extends ConsumerState<NewWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workoutNameController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  
  bool _showExerciseSearch = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load exercises for search
    Future.microtask(() {
      ref.read(exerciseLibraryProvider.notifier).loadExercises();
    });

    // Pre-populate from a previous workout if repeating
    if (widget.repeatFrom != null) {
      final prev = widget.repeatFrom!;
      _workoutNameController.text = prev.workoutName ?? '';
      _durationController.text = '${prev.duration}';
      _notesController.text = prev.notes ?? '';
      Future.microtask(() {
        final notifier = ref.read(newWorkoutProvider.notifier);
        notifier.setWorkoutName(prev.workoutName ?? '');
        notifier.setDuration(prev.duration);
        if (prev.notes != null) notifier.setNotes(prev.notes);
        // Re-add exercises from previous workout
        for (final e in prev.exercises) {
          // Build a minimal Exercise object from the workout exercise
          final exercise = ex.Exercise(
            id: e.exerciseId ?? 0,
            name: e.exerciseName ?? 'Exercise',
            description: '',
            category: 'STRENGTH',
            muscleGroup: 'FULL_BODY',
            equipment: 'BODYWEIGHT',
            difficulty: 'BEGINNER',
            instructions: '',
          );
          notifier.addExercise(exercise, defaultSets: e.sets ?? 3);
        }
      });
    }
  }

  @override
  void dispose() {
    _workoutNameController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(newWorkoutProvider);
    final exercisesAsync = ref.watch(exerciseLibraryProvider);

    return NutriLiftScaffold(
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Header with save button
                _buildHeader(context, workoutState),
                
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Workout name input
                        _buildWorkoutNameInput(workoutState),
                        const SizedBox(height: 16),
                        
                        // Duration input
                        _buildDurationInput(workoutState),
                        const SizedBox(height: 16),
                        
                        // Gym selection (optional)
                        _buildGymSelection(workoutState),
                        const SizedBox(height: 16),
                        
                        // Template selection (optional)
                        _buildTemplateSelection(workoutState),
                        const SizedBox(height: 24),
                        
                        // Exercises section
                        _buildExercisesSection(workoutState),
                        const SizedBox(height: 16),
                        
                        // Add exercise button
                        _buildAddExerciseButton(),
                        const SizedBox(height: 24),
                        
                        // Notes input
                        _buildNotesInput(workoutState),
                        const SizedBox(height: 100), // Space for save button
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Exercise search overlay
          if (_showExerciseSearch)
            _buildExerciseSearchOverlay(exercisesAsync),
          
          // Save button at bottom
          if (!_showExerciseSearch)
            _buildSaveButton(context, workoutState),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NewWorkoutState workoutState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Log Workout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (workoutState.isSubmitting)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.check, color: Color(0xFFE53935)),
              onPressed: workoutState.isValid ? () => _submitWorkout(context) : null,
            ),
        ],
      ),
    );
  }

  Widget _buildWorkoutNameInput(NewWorkoutState workoutState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workout Name *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _workoutNameController,
          decoration: InputDecoration(
            hintText: 'e.g., Push Day, Leg Day, Morning Workout',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            errorText: workoutState.validationErrors['workoutName'],
          ),
          onChanged: (value) {
            ref.read(newWorkoutProvider.notifier).setWorkoutName(value);
          },
        ),
      ],
    );
  }

  Widget _buildDurationInput(NewWorkoutState workoutState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Duration (minutes) *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: 'Enter duration (1-600 minutes)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            errorText: workoutState.validationErrors['duration'],
          ),
          onChanged: (value) {
            final duration = int.tryParse(value);
            if (duration != null) {
              ref.read(newWorkoutProvider.notifier).setDuration(duration);
            }
          },
        ),
      ],
    );
  }

  Widget _buildGymSelection(NewWorkoutState workoutState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gym (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: workoutState.gymId,
          decoration: InputDecoration(
            hintText: 'Select gym',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('No gym selected')),
            // TODO: Load gyms from API
            DropdownMenuItem(value: '1', child: Text('Home Gym')),
            DropdownMenuItem(value: '2', child: Text('Gold\'s Gym')),
          ],
          onChanged: (value) {
            ref.read(newWorkoutProvider.notifier).setGymId(value);
          },
        ),
      ],
    );
  }

  Widget _buildTemplateSelection(NewWorkoutState workoutState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workout Template (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: workoutState.customWorkoutId,
          decoration: InputDecoration(
            hintText: 'Select template',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('No template')),
            // TODO: Load templates from API
            DropdownMenuItem(value: '1', child: Text('Push Day')),
            DropdownMenuItem(value: '2', child: Text('Pull Day')),
            DropdownMenuItem(value: '3', child: Text('Leg Day')),
          ],
          onChanged: (value) {
            ref.read(newWorkoutProvider.notifier).setCustomWorkoutId(value);
            // TODO: Load template exercises when selected
          },
        ),
      ],
    );
  }

  Widget _buildExercisesSection(NewWorkoutState workoutState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Exercises *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${workoutState.exercises.length})',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        if (workoutState.validationErrors['exercises'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              workoutState.validationErrors['exercises']!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        const SizedBox(height: 12),
        if (workoutState.exercises.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const Center(
              child: Text(
                'No exercises added yet.\nTap "Add Exercise" to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...workoutState.exercises.asMap().entries.map((entry) {
            final index = entry.key;
            final exercise = entry.value;
            return ExerciseInputWidget(
              key: ValueKey('exercise_$index'),
              exercise: exercise,
              exerciseIndex: index,
              validationErrors: workoutState.validationErrors,
            );
          }).toList(),
      ],
    );
  }

  Widget _buildAddExerciseButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _showExerciseSearch = true;
            _searchQuery = '';
            _searchController.clear();
          });
        },
        icon: const Icon(Icons.add, color: Color(0xFFE53935)),
        label: const Text(
          'Add Exercise',
          style: TextStyle(color: Color(0xFFE53935)),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFFE53935)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesInput(NewWorkoutState workoutState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes (Optional)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add any notes about your workout...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onChanged: (value) {
            ref.read(newWorkoutProvider.notifier).setNotes(value.isEmpty ? null : value);
          },
        ),
      ],
    );
  }

  Widget _buildExerciseSearchOverlay(AsyncValue<List<ex.Exercise>> exercisesAsync) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Search header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() {
                      _showExerciseSearch = false;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search exercises...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Exercise list
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                final filtered = _searchQuery.isEmpty
                    ? exercises
                    : exercises.where((e) => 
                        e.name.toLowerCase().contains(_searchQuery)).toList();
                
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No exercises found'),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final exercise = filtered[index];
                    return _buildExerciseSearchItem(exercise);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading exercises: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSearchItem(ex.Exercise exercise) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: exercise.imageUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    exercise.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.fitness_center);
                    },
                  ),
                )
              : const Icon(Icons.fitness_center),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${exercise.muscleGroup} • ${exercise.difficulty}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: const Icon(Icons.add_circle, color: Color(0xFFE53935)),
        onTap: () {
          ref.read(newWorkoutProvider.notifier).addExercise(exercise);
          setState(() {
            _showExerciseSearch = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${exercise.name} added'),
              duration: const Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, NewWorkoutState workoutState) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: workoutState.isValid && !workoutState.isSubmitting
                ? () => _submitWorkout(context)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: workoutState.isSubmitting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Workout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitWorkout(BuildContext context) async {
    try {
      final workoutLog = await ref.read(newWorkoutProvider.notifier).submitWorkout();
      
      if (workoutLog != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Show PR notification if applicable
        if (workoutLog.hasNewPrs) {
          _showPRNotification(context);
        }
        
        // Navigate back
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPRNotification(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE53935),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'New Personal Record!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Congratulations! You\'ve achieved a new PR!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Awesome!',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Exercise Input Widget
/// 
/// Widget for inputting sets, reps, and weight for a single exercise.
/// Includes validation and the ability to add/remove sets.
/// 
/// Validates: Requirements 2.4, 2.5, 2.6, 2.7
class ExerciseInputWidget extends ConsumerStatefulWidget {
  final NewWorkoutExercise exercise;
  final int exerciseIndex;
  final Map<String, String> validationErrors;

  const ExerciseInputWidget({
    Key? key,
    required this.exercise,
    required this.exerciseIndex,
    required this.validationErrors,
  }) : super(key: key);

  @override
  ConsumerState<ExerciseInputWidget> createState() => _ExerciseInputWidgetState();
}

class _ExerciseInputWidgetState extends ConsumerState<ExerciseInputWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Exercise header
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.exercise.exercise.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        widget.exercise.exercise.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.fitness_center, size: 20);
                        },
                      ),
                    )
                  : const Icon(Icons.fitness_center, size: 20),
            ),
            title: Text(
              widget.exercise.exercise.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${widget.exercise.sets.length} sets',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ref.read(newWorkoutProvider.notifier).removeExercise(widget.exerciseIndex);
                  },
                ),
              ],
            ),
          ),
          
          // Sets list (expandable)
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  // Sets header
                  Row(
                    children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Set',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Reps',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Weight (kg)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 40), // Space for delete button
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Sets
                  ...widget.exercise.sets.asMap().entries.map((entry) {
                    final setIndex = entry.key;
                    final set = entry.value;
                    return _buildSetRow(setIndex, set);
                  }).toList(),
                  
                  const SizedBox(height: 8),
                  
                  // Add set button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ref.read(newWorkoutProvider.notifier).addSet(widget.exerciseIndex);
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Set'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSetRow(int setIndex, NewWorkoutSet set) {
    final errorKey = 'exercise_${widget.exerciseIndex}_set_$setIndex';
    final hasError = widget.validationErrors.containsKey(errorKey);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Set number
              Expanded(
                flex: 1,
                child: Text(
                  '${set.setNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              
              // Reps input
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: set.reps?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: '10',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  onChanged: (value) {
                    final reps = int.tryParse(value);
                    ref.read(newWorkoutProvider.notifier).updateSet(
                      widget.exerciseIndex,
                      setIndex,
                      reps: reps,
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Weight input
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: set.weight?.toString() ?? '',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                  ],
                  decoration: InputDecoration(
                    hintText: '20.0',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  onChanged: (value) {
                    final weight = double.tryParse(value);
                    ref.read(newWorkoutProvider.notifier).updateSet(
                      widget.exerciseIndex,
                      setIndex,
                      weight: weight,
                    );
                  },
                ),
              ),
              
              // Done set button (triggers rest timer)
              IconButton(
                icon: Icon(
                  set.completed ? Icons.check_circle : Icons.check_circle_outline,
                  size: 20,
                  color: set.completed ? Colors.green : Colors.grey,
                ),
                onPressed: () {
                  ref.read(newWorkoutProvider.notifier).updateSet(
                    widget.exerciseIndex,
                    setIndex,
                    completed: !set.completed,
                  );
                  if (!set.completed) {
                    // Show rest timer when marking set as done
                    showRestTimer(context);
                  }
                },
              ),

              // Delete set button
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: widget.exercise.sets.length > 1
                    ? () {
                        ref.read(newWorkoutProvider.notifier).removeSet(
                          widget.exerciseIndex,
                          setIndex,
                        );
                      }
                    : null,
                color: Colors.red,
              ),
            ],
          ),
          
          // Validation error
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: Text(
                widget.validationErrors[errorKey]!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
