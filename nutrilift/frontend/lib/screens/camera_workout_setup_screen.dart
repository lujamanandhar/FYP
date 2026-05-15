import 'package:flutter/material.dart';
import 'guided_workout_plans.dart';
import 'camera_workout_player_screen.dart';

const Color _kRed = Color(0xFFE53935);

/// Shown before a camera workout — lets user configure sets & reps per exercise.
class CameraWorkoutSetupScreen extends StatefulWidget {
  final GuidedPlan plan;
  const CameraWorkoutSetupScreen({super.key, required this.plan});

  @override
  State<CameraWorkoutSetupScreen> createState() => _CameraWorkoutSetupScreenState();
}

class _CameraWorkoutSetupScreenState extends State<CameraWorkoutSetupScreen> {
  // sets[i] and reps[i] for each exercise
  late List<int> _sets;
  late List<int> _reps;

  @override
  void initState() {
    super.initState();
    _sets = List.generate(widget.plan.exercises.length, (_) => 3);
    _reps = widget.plan.exercises.map((e) => e.reps > 0 ? e.reps : 10).toList();
  }

  void _startWorkout() {
    // Build the exercise config list
    final config = List.generate(widget.plan.exercises.length, (i) => CameraExerciseConfig(
      exercise: widget.plan.exercises[i],
      sets: _sets[i],
      reps: _reps[i],
    ));

    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => CameraWorkoutPlayerScreen(
        plan: widget.plan,
        exerciseConfigs: config,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.plan.name),
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            color: _kRed,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Configure Your Workout',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Set the number of sets and reps for each exercise.',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13)),
            ]),
          ),

          // Exercise config list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.plan.exercises.length,
              itemBuilder: (_, i) => _ExerciseConfigCard(
                exercise: widget.plan.exercises[i],
                sets: _sets[i],
                reps: _reps[i],
                onSetsChanged: (v) => setState(() => _sets[i] = v),
                onRepsChanged: (v) => setState(() => _reps[i] = v),
              ),
            ),
          ),

          // Start button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startWorkout,
                icon: const Icon(Icons.videocam_rounded),
                label: const Text('Start Camera Workout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseConfigCard extends StatelessWidget {
  final GuidedExercise exercise;
  final int sets;
  final int reps;
  final ValueChanged<int> onSetsChanged;
  final ValueChanged<int> onRepsChanged;

  const _ExerciseConfigCard({
    required this.exercise,
    required this.sets,
    required this.reps,
    required this.onSetsChanged,
    required this.onRepsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.fitness_center_rounded, color: _kRed, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
            Text(exercise.muscleGroup, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ])),
          // Camera supported badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 12),
              SizedBox(width: 4),
              Text('Tracked', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _StepperField(label: 'Sets', value: sets, min: 1, max: 10, onChanged: onSetsChanged)),
          const SizedBox(width: 16),
          Expanded(child: _StepperField(label: 'Reps', value: reps, min: 1, max: 50, onChanged: onRepsChanged)),
        ]),
        const SizedBox(height: 8),
        Text('Total: $sets sets × $reps reps = ${sets * reps} reps',
            style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ]),
    );
  }
}

class _StepperField extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _StepperField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
            iconSize: 18,
            color: value > min ? _kRed : Colors.grey[300],
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          Expanded(child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
            iconSize: 18,
            color: value < max ? _kRed : Colors.grey[300],
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ]),
      ),
    ]);
  }
}
