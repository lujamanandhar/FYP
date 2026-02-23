import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_exercise.dart';

/// Exercise Input Widget
/// 
/// Provides input fields for sets, reps, and weight for a single exercise.
/// Includes validation and remove functionality.
/// 
/// Validates: Requirements 2.4, 2.5, 2.6, 2.7
class ExerciseInputWidget extends StatefulWidget {
  final WorkoutExercise workoutExercise;
  final Function(WorkoutExercise) onUpdate;
  final VoidCallback onRemove;

  const ExerciseInputWidget({
    Key? key,
    required this.workoutExercise,
    required this.onUpdate,
    required this.onRemove,
  }) : super(key: key);

  @override
  State<ExerciseInputWidget> createState() => _ExerciseInputWidgetState();
}

class _ExerciseInputWidgetState extends State<ExerciseInputWidget> {
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _setsController = TextEditingController(
      text: widget.workoutExercise.sets.toString(),
    );
    _repsController = TextEditingController(
      text: widget.workoutExercise.reps.toString(),
    );
    _weightController = TextEditingController(
      text: widget.workoutExercise.weight.toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
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
                    widget.workoutExercise.exerciseName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onRemove,
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _setsController,
                    label: 'Sets',
                    min: 1,
                    max: 100,
                    onChanged: _updateSets,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _repsController,
                    label: 'Reps',
                    min: 1,
                    max: 100,
                    onChanged: _updateReps,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    min: 0.1,
                    max: 1000,
                    isDecimal: true,
                    onChanged: _updateWeight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Volume: ${_calculateVolume().toStringAsFixed(1)} kg',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required double min,
    required double max,
    bool isDecimal = false,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: [
        if (isDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        final number = double.tryParse(value);
        if (number == null) {
          return 'Invalid';
        }
        if (number < min || number > max) {
          return '$min-$max';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }

  void _updateSets(String value) {
    final sets = int.tryParse(value);
    if (sets != null && sets >= 1 && sets <= 100) {
      _notifyUpdate(sets: sets);
    }
  }

  void _updateReps(String value) {
    final reps = int.tryParse(value);
    if (reps != null && reps >= 1 && reps <= 100) {
      _notifyUpdate(reps: reps);
    }
  }

  void _updateWeight(String value) {
    final weight = double.tryParse(value);
    if (weight != null && weight >= 0.1 && weight <= 1000) {
      _notifyUpdate(weight: weight);
    }
  }

  void _notifyUpdate({int? sets, int? reps, double? weight}) {
    final updated = WorkoutExercise(
      id: widget.workoutExercise.id,
      exerciseId: widget.workoutExercise.exerciseId,
      exerciseName: widget.workoutExercise.exerciseName,
      sets: sets ?? widget.workoutExercise.sets,
      reps: reps ?? widget.workoutExercise.reps,
      weight: weight ?? widget.workoutExercise.weight,
      volume: _calculateVolume(sets: sets, reps: reps, weight: weight),
      order: widget.workoutExercise.order,
    );
    widget.onUpdate(updated);
  }

  double _calculateVolume({int? sets, int? reps, double? weight}) {
    final s = sets ?? widget.workoutExercise.sets;
    final r = reps ?? widget.workoutExercise.reps;
    final w = weight ?? widget.workoutExercise.weight;
    return s * r * w;
  }
}
