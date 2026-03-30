import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/nutrilift_header.dart';
import '../models/workout_models.dart';
import '../providers/repository_providers.dart';
import '../providers/workout_history_provider.dart';
import '../providers/personal_records_provider.dart';
import 'guided_workout_plans.dart';

const Color _kRed = Color(0xFFE53935);
const Color _kGreen = Color(0xFF4CAF50);

class GuidedWorkoutPlayerScreen extends ConsumerStatefulWidget {
  final GuidedPlan plan;
  const GuidedWorkoutPlayerScreen({super.key, required this.plan});

  @override
  ConsumerState<GuidedWorkoutPlayerScreen> createState() =>
      _GuidedWorkoutPlayerScreenState();
}

enum _Phase { exercise, rest, done }

class _GuidedWorkoutPlayerScreenState
    extends ConsumerState<GuidedWorkoutPlayerScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  _Phase _phase = _Phase.exercise;
  int _secondsLeft = 0;
  bool _paused = false;
  Timer? _timer;
  int _totalElapsed = 0; // total seconds elapsed
  late AnimationController _pulseController;

  GuidedExercise get _current =>
      widget.plan.exercises[_currentIndex];

  bool get _isTimedExercise => _current.durationSeconds > 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _startExercise();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startExercise() {
    _phase = _Phase.exercise;
    _secondsLeft = _isTimedExercise ? _current.durationSeconds : 0;
    if (_isTimedExercise) _startTimer();
  }

  void _startRest() {
    _phase = _Phase.rest;
    _secondsLeft = _current.restSeconds;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_paused) return;
      setState(() {
        _totalElapsed++;
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
          _onTimerEnd();
        }
      });
    });
  }

  void _onTimerEnd() {
    if (_phase == _Phase.exercise) {
      _startRest();
    } else if (_phase == _Phase.rest) {
      _nextExercise();
    }
  }

  void _nextExercise() {
    _timer?.cancel();
    if (_currentIndex < widget.plan.exercises.length - 1) {
      setState(() {
        _currentIndex++;
        _startExercise();
      });
    } else {
      setState(() => _phase = _Phase.done);
    }
  }

  void _prevExercise() {
    _timer?.cancel();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _startExercise();
      });
    }
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
  }

  void _skipRest() {
    if (_phase == _Phase.rest) {
      _timer?.cancel();
      _nextExercise();
    }
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _Phase.done) {
      return _WorkoutCompleteScreen(
        plan: widget.plan,
        totalSeconds: _totalElapsed,
      );
    }

    final ex = _current;
    final isRest = _phase == _Phase.rest;
    final progress = _currentIndex / widget.plan.exercises.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showQuitDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.close_rounded,
                          color: Colors.grey[700], size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.plan.name,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12)),
                        Text(
                          '${_currentIndex + 1} / ${widget.plan.exercises.length}',
                          style: const TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Text(_formatTime(_totalElapsed),
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13)),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isRest ? _kGreen : _kRed),
                ),
              ),
            ),

            const Spacer(),

            // ── Phase label ───────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                isRest ? 'Rest' : 'Exercise',
                key: ValueKey(isRest),
                style: TextStyle(
                  color: isRest ? _kGreen : _kRed,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Exercise name ─────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                isRest ? 'Get ready for next exercise' : ex.name,
                key: ValueKey('$_currentIndex-$isRest'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Muscle group tag
            if (!isRest)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _kRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kRed.withOpacity(0.3)),
                ),
                child: Text(ex.muscleGroup,
                    style: const TextStyle(
                        color: _kRed, fontSize: 12, fontWeight: FontWeight.w600)),
              ),

            const SizedBox(height: 32),

            // ── Timer / Reps display ──────────────────────────────
            if (_isTimedExercise || isRest)
              _CircularTimer(
                secondsLeft: _secondsLeft,
                totalSeconds: isRest
                    ? ex.restSeconds
                    : ex.durationSeconds,
                isRest: isRest,
                paused: _paused,
              )
            else
              _RepsDisplay(reps: ex.reps),

            const SizedBox(height: 24),

            // Instruction
            if (!isRest)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  ex.instruction,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 13, height: 1.5),
                ),
              ),

            const Spacer(),

            // ── Controls ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous
                  _ControlBtn(
                    icon: Icons.skip_previous_rounded,
                    label: 'Prev',
                    onTap: _currentIndex > 0 ? _prevExercise : null,
                    size: 52,
                  ),

                  // Pause / Resume (big center button)
                  GestureDetector(
                    onTap: _togglePause,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isRest ? _kGreen : _kRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isRest ? _kGreen : _kRed)
                                .withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),

                  // Next / Skip rest
                  _ControlBtn(
                    icon: isRest
                        ? Icons.fast_forward_rounded
                        : Icons.skip_next_rounded,
                    label: isRest ? 'Skip Rest' : 'Next',
                    onTap: isRest ? _skipRest : _nextExercise,
                    size: 52,
                  ),
                ],
              ),
            ),

            // Next exercise preview
            if (!isRest &&
                _currentIndex < widget.plan.exercises.length - 1)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(children: [
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Text('Next: ',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 12)),
                  Text(
                    widget.plan.exercises[_currentIndex + 1].name,
                    style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  void _showQuitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quit Workout?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: _kRed),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
  }
}

// ── Circular timer ─────────────────────────────────────────────────────────────
class _CircularTimer extends StatelessWidget {
  final int secondsLeft;
  final int totalSeconds;
  final bool isRest;
  final bool paused;

  const _CircularTimer({
    required this.secondsLeft,
    required this.totalSeconds,
    required this.isRest,
    required this.paused,
  });

  @override
  Widget build(BuildContext context) {
    final progress =
        totalSeconds > 0 ? secondsLeft / totalSeconds : 0.0;
    final color = isRest ? _kGreen : _kRed;
    final m = secondsLeft ~/ 60;
    final s = secondsLeft % 60;
    final timeStr =
        '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 10,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(timeStr,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 38)),
            if (paused)
              Text('PAUSED',
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      letterSpacing: 1)),
          ]),
        ],
      ),
    );
  }
}

// ── Reps display ───────────────────────────────────────────────────────────────
class _RepsDisplay extends StatelessWidget {
  final int reps;
  const _RepsDisplay({required this.reps});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('$reps',
          style: const TextStyle(
              color: _kRed,
              fontWeight: FontWeight.bold,
              fontSize: 72)),
      Text('REPS',
          style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              letterSpacing: 2,
              fontWeight: FontWeight.w600)),
    ]);
  }
}

// ── Control button ─────────────────────────────────────────────────────────────
class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: enabled ? Colors.grey[200] : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
          ),
          child: Icon(icon,
              color: enabled ? Colors.black87 : Colors.grey[400], size: 26),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                color: enabled ? Colors.grey[700] : Colors.grey[400],
                fontSize: 11)),
      ]),
    );
  }
}

// ── Workout complete screen ────────────────────────────────────────────────────
class _WorkoutCompleteScreen extends ConsumerStatefulWidget {
  final GuidedPlan plan;
  final int totalSeconds;

  const _WorkoutCompleteScreen({
    required this.plan,
    required this.totalSeconds,
  });

  @override
  ConsumerState<_WorkoutCompleteScreen> createState() =>
      _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState
    extends ConsumerState<_WorkoutCompleteScreen> {
  bool _saving = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _saveWorkout();
  }

  Future<void> _saveWorkout() async {
    try {
      final repo = ref.read(workoutRepositoryProvider);
      final durationMinutes =
          (widget.totalSeconds / 60).ceil().clamp(1, 600);

      // Guided workouts are bodyweight — send empty exercises list.
      // The workout is logged by name/duration/calories only.
      // PRs are not tracked for guided workouts since they use bodyweight only.
      final request = CreateWorkoutLogRequest(
        workoutName: widget.plan.name,
        durationMinutes: durationMinutes,
        caloriesBurned: _estimatedCalories.toDouble(),
        exercises: [],
        notes: '${widget.plan.totalExercises} exercises completed via guided workout',
      );

      await repo.logWorkout(request);

      // Invalidate providers so the home screen refreshes when we pop back
      ref.invalidate(workoutHistoryProvider);
      ref.invalidate(personalRecordsProvider);

      if (mounted) setState(() { _saving = false; _saved = true; });
    } catch (e) {
      print('GuidedWorkout save error: $e');
      if (mounted) setState(() { _saving = false; _saved = false; });
    }
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m}m ${sec}s';
  }

  int get _estimatedCalories {
    final multiplier = widget.plan.difficulty == 'Beginner'
        ? 6
        : widget.plan.difficulty == 'Intermediate'
            ? 8
            : 11;
    return ((widget.totalSeconds / 60) * multiplier).round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: _kRed.withOpacity(0.3), width: 2),
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 64,
                  color: _kRed,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Workout Complete!',
                  style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 28)),
              const SizedBox(height: 8),
              Text(widget.plan.name,
                  style: TextStyle(
                      color: Colors.grey[600], fontSize: 15)),
              const SizedBox(height: 8),
              // Save status
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (_saving) ...[
                  const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kRed)),
                  const SizedBox(width: 8),
                  Text('Saving to history...',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ] else if (_saved) ...[
                  const Icon(Icons.check_circle_rounded,
                      color: _kGreen, size: 16),
                  const SizedBox(width: 6),
                  const Text('Saved to workout history',
                      style: TextStyle(color: _kGreen, fontSize: 12)),
                ] else ...[
                  const Icon(Icons.info_outline,
                      color: Colors.orange, size: 16),
                  const SizedBox(width: 6),
                  const Text('Could not save — check connection',
                      style: TextStyle(color: Colors.orange, fontSize: 12)),
                ],
              ]),
              const SizedBox(height: 32),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CompleteStat(
                      icon: Icons.timer_rounded,
                      label: 'Duration',
                      value: _formatTime(widget.totalSeconds),
                      color: _kRed),
                  _CompleteStat(
                      icon: Icons.fitness_center_rounded,
                      label: 'Exercises',
                      value: '${widget.plan.totalExercises}',
                      color: Colors.orange),
                  _CompleteStat(
                      icon: Icons.local_fire_department_rounded,
                      label: 'Est. Calories',
                      value: '$_estimatedCalories kcal',
                      color: Colors.amber),
                ],
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Invalidate providers to force fresh data load
                    ref.invalidate(workoutHistoryProvider);
                    ref.invalidate(personalRecordsProvider);
                    
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  ref.invalidate(workoutHistoryProvider);
                  ref.invalidate(personalRecordsProvider);
                  
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text('Do Another Workout',
                    style: TextStyle(color: Colors.grey[600])),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompleteStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _CompleteStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(height: 8),
      Text(value,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label,
          style: TextStyle(color: Colors.grey[600], fontSize: 11)),
    ]);
  }
}
