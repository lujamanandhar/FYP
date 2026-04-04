import 'package:flutter/material.dart';
import '../services/dio_client.dart';
import 'workout_conversion_screen.dart';

class SessionReviewScreen extends StatefulWidget {
  final String? sessionId;
  final String exerciseName;
  final String exerciseType;
  final int totalReps;
  final double confidence;

  const SessionReviewScreen({
    Key? key,
    required this.sessionId,
    required this.exerciseName,
    required this.exerciseType,
    required this.totalReps,
    required this.confidence,
  }) : super(key: key);

  @override
  State<SessionReviewScreen> createState() => _SessionReviewScreenState();
}

class _SessionReviewScreenState extends State<SessionReviewScreen> {
  late int _adjustedReps;
  late TextEditingController _repsController;
  final TextEditingController _weightController = TextEditingController(text: '0');
  final TextEditingController _setsController = TextEditingController(text: '1');
  final DioClient _dioClient = DioClient();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _adjustedReps = widget.totalReps;
    _repsController = TextEditingController(text: widget.totalReps.toString());
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _setsController.dispose();
    _dioClient.dispose();
    super.dispose();
  }

  Color get _confidenceColor {
    if (widget.confidence > 0.8) return Colors.green;
    if (widget.confidence > 0.6) return Colors.orange;
    return Colors.red;
  }

  Future<void> _discard() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discard session?'),
        content: const Text('This will permanently delete this session and all rep data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (widget.sessionId != null) {
      try {
        await _dioClient.dio.delete('/workouts/rep-sessions/${widget.sessionId}/');
      } catch (e) {
        debugPrint('Error deleting session: $e');
      }
    }

    if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _convertToWorkout() async {
    // Update rep count if adjusted
    if (widget.sessionId != null && _adjustedReps != widget.totalReps) {
      try {
        await _dioClient.dio.patch(
          '/workouts/rep-sessions/${widget.sessionId}/',
          data: {'total_reps': _adjustedReps},
        );
      } catch (e) {
        debugPrint('Error updating reps: $e');
      }
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutConversionScreen(
            sessionId: widget.sessionId,
            exerciseName: widget.exerciseName,
            exerciseType: widget.exerciseType,
            totalReps: _adjustedReps,
            initialWeight: double.tryParse(_weightController.text) ?? 0,
            initialSets: int.tryParse(_setsController.text) ?? 1,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowConfidence = widget.confidence < 0.7;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Session Summary'),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise name
            Text(
              widget.exerciseName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Stats row
            Row(
              children: [
                _statCard('Reps', '${widget.totalReps}', Icons.fitness_center, const Color(0xFFE53935)),
                const SizedBox(width: 12),
                _statCard(
                  'Confidence',
                  '${(widget.confidence * 100).toInt()}%',
                  Icons.track_changes,
                  _confidenceColor,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Low confidence warning
            if (lowConfidence)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Low confidence detected. Please review your rep count before saving.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  ),
                ]),
              ),

            if (lowConfidence) const SizedBox(height: 16),

            // Adjust reps
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Adjust Rep Count',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  const Text('Correct any counting errors before saving.',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_adjustedReps > 0) {
                            setState(() {
                              _adjustedReps--;
                              _repsController.text = _adjustedReps.toString();
                            });
                          }
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        color: const Color(0xFFE53935),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _repsController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(border: InputBorder.none),
                          onChanged: (v) {
                            final n = int.tryParse(v);
                            if (n != null && n >= 0) setState(() => _adjustedReps = n);
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _adjustedReps++;
                            _repsController.text = _adjustedReps.toString();
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        color: const Color(0xFFE53935),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Weight and sets input
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Exercise Details',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _setsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Sets',
                          prefixIcon: const Icon(Icons.layers_outlined, color: Color(0xFFE53935)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE53935)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Weight (kg)',
                          prefixIcon: const Icon(Icons.monitor_weight_outlined, color: Color(0xFFE53935)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE53935)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),

            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _adjustedReps > 0 ? _convertToWorkout : null,
              icon: const Icon(Icons.save_alt),
              label: const Text('Save as Workout', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 12),

            // Discard button
            OutlinedButton.icon(
              onPressed: _discard,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Discard Session'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
