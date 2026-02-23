import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/nutrilift_header.dart';
import '../providers/new_workout_provider.dart';
import '../models/exercise.dart';
import 'exercise_library_screen.dart';

/// New Workout Screen
/// 
/// Allows users to log a new workout with exercises, sets, reps, and weights.
/// Features:
/// - Workout template selection
/// - Exercise search and addition
/// - Input validation
/// - Optimistic UI updates
/// 
/// Validates: Requirements 2.1, 2.5
class NewWorkoutScreen extends ConsumerStatefulWidget {
  const NewWorkoutScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NewWorkoutScreen> createState() => _NewWorkoutScreenState();
}

class _NewWorkoutScreenState extends ConsumerState<NewWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newWorkoutState = ref.watch(newWorkoutProvider);

    return NutriLiftScaffold(
      title: 'Log Workout',
      showBackButton: true,
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDurationField(),
            const SizedBox(height: 16),
            _buildNotesField(),
            const SizedBox(height: 24),
            _buildExercisesSection(),
            const SizedBox(height: 16),
            _buildAddExerciseButton(),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationField() {
    return TextFormField(
      controller: _durationController,
      decoration: InputDecoration(
        labelText: 'Duration (minutes)',
        hintText: 'Enter workout duration',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter duration';
        }
        final duration = int.tryParse(value);
        if (duration == null) {
          return 'Please enter a valid number';
        }
        if (duration < 1 || duration > 600) {
          return 'Duration must be between 1 and 600 minutes';
        }
        return null;
      },
    );
  }

  Widget _buildNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: InputDecoration(
        labelText: 'Notes (optional)',
        hintText: 'Add any notes about your workout',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
      ),
      maxLines: 3,
    );
  }

  Widget _buildExercisesSection() {
    final exercises = ref.watch(newWorkoutProvider).exercises;

    if (exercises.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.fitness_center,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No exercises added yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap the button below to add exercises',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exercises',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...exercises.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          return Card(
            key: ValueKey(exercise.exercise.id),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.exercise.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          ref.read(newWorkoutProvider.notifier).removeExercise(index);
                        },
                        color: Colors.red,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...exercise.sets.asMap().entries.map((setEntry) {
                    final setIndex = setEntry.key;
                    final set = setEntry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text('Set ${set.setNumber}:'),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: set.reps?.toString() ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Reps',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                final reps = int.tryParse(value);
                                if (reps != null) {
                                  ref.read(newWorkoutProvider.notifier).updateSet(
                                    index,
                                    setIndex,
                                    reps: reps,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              initialValue: set.weight?.toString() ?? '',
                              decoration: const InputDecoration(
                                labelText: 'Weight (kg)',
                                isDense: true,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) {
                                final weight = double.tryParse(value);
                                if (weight != null) {
                                  ref.read(newWorkoutProvider.notifier).updateSet(
                                    index,
                                    setIndex,
                                    weight: weight,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          ref.read(newWorkoutProvider.notifier).addSet(index);
                        },
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Set'),
                      ),
                      if (exercise.sets.length > 1)
                        TextButton.icon(
                          onPressed: () {
                            ref.read(newWorkoutProvider.notifier).removeSet(
                              index,
                              exercise.sets.length - 1,
                            );
                          },
                          icon: const Icon(Icons.remove, size: 16),
                          label: const Text('Remove Set'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAddExerciseButton() {
    return OutlinedButton.icon(
      onPressed: _navigateToExerciseLibrary,
      icon: const Icon(Icons.add),
      label: const Text('Add Exercise'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFE53935),
        side: const BorderSide(color: Color(0xFFE53935)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _handleSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        disabledBackgroundColor: Colors.grey[300],
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Log Workout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Future<void> _navigateToExerciseLibrary() async {
    final selectedExercise = await Navigator.push<Exercise>(
      context,
      MaterialPageRoute(
        builder: (context) => const ExerciseLibraryScreen(selectionMode: true),
      ),
    );

    if (selectedExercise != null) {
      ref.read(newWorkoutProvider.notifier).addExercise(selectedExercise);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final exercises = ref.read(newWorkoutProvider).exercises;
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final duration = int.parse(_durationController.text);
      final notes = _notesController.text.trim();

      // Set duration and notes in provider
      ref.read(newWorkoutProvider.notifier).setDuration(duration);
      if (notes.isNotEmpty) {
        ref.read(newWorkoutProvider.notifier).setNotes(notes);
      }

      // Submit workout
      final result = await ref.read(newWorkoutProvider.notifier).submitWorkout();

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout logged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
