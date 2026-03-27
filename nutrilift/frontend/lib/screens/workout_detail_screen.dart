import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout_log.dart';
import '../models/workout_exercise.dart';
import '../widgets/nutrilift_header.dart';
import 'new_workout_screen.dart';

const Color _kRed = Color(0xFFE53935);

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutLog workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final exercises = workout.exercises;
    final dateStr = DateFormat('EEEE, MMM d yyyy • h:mm a').format(
      workout.createdAt ?? DateTime.now(),
    );

    return NutriLiftScaffold(
      title: workout.workoutName ?? 'Workout',
      showBackButton: true,
      showDrawer: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Summary card ──────────────────────────────────────
            _SummaryCard(workout: workout, dateStr: dateStr),
            const SizedBox(height: 20),

            // ── Exercises ─────────────────────────────────────────
            if (exercises.isNotEmpty) ...[
              const Text('Exercises',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              ...exercises.map((e) => _ExerciseCard(exercise: e)),
            ],
            const SizedBox(height: 20),

            // ── Notes ─────────────────────────────────────────────
            if (workout.notes != null && workout.notes!.isNotEmpty) ...[
              const Text('Notes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(workout.notes!,
                    style: const TextStyle(fontSize: 14, height: 1.5)),
              ),
              const SizedBox(height: 20),
            ],

            // ── Repeat button ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NewWorkoutScreen(repeatFrom: workout),
                  ),
                ),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Repeat This Workout',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final WorkoutLog workout;
  final String dateStr;
  const _SummaryCard({required this.workout, required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kRed, Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _kRed.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (workout.hasNewPrs)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFC107),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.emoji_events_rounded, size: 14, color: Colors.black87),
                SizedBox(width: 4),
                Text('New Personal Record!',
                    style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ]),
            ),
          Text(dateStr,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: '${workout.duration} min'),
              _StatItem(
                  icon: Icons.local_fire_department_outlined,
                  label: 'Calories',
                  value: '${workout.caloriesBurned.toStringAsFixed(0)} kcal'),
              _StatItem(
                  icon: Icons.fitness_center_rounded,
                  label: 'Exercises',
                  value: '${workout.exercises.length}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 22),
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label,
          style: const TextStyle(color: Colors.white60, fontSize: 11)),
    ]);
  }
}

class _ExerciseCard extends StatelessWidget {
  final WorkoutExercise exercise;
  const _ExerciseCard({required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fitness_center, color: _kRed, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                exercise.exerciseName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          // Sets header
          Row(children: [
            _SetHeader('Sets'),
            _SetHeader('Reps'),
            _SetHeader('Weight'),
            _SetHeader('Volume'),
          ]),
          const Divider(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              _SetCell('${exercise.sets}'),
              _SetCell('${exercise.reps}'),
              _SetCell('${exercise.weight} kg'),
              _SetCell('${exercise.volume.toStringAsFixed(0)}'),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SetHeader extends StatelessWidget {
  final String text;
  const _SetHeader(this.text);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Text(text,
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w600)),
      );
}

class _SetCell extends StatelessWidget {
  final String text;
  const _SetCell(this.text);
  @override
  Widget build(BuildContext context) => Expanded(
        child: Text(text,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      );
}
