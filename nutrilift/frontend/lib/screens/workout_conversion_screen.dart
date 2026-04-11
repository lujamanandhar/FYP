import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import '../services/dio_client.dart';

class WorkoutConversionScreen extends StatefulWidget {
  final String? sessionId;
  final String exerciseName;
  final String exerciseType;
  final int totalReps;
  final double initialWeight;
  final int initialSets;

  const WorkoutConversionScreen({
    Key? key,
    required this.sessionId,
    required this.exerciseName,
    required this.exerciseType,
    required this.totalReps,
    this.initialWeight = 0,
    this.initialSets = 1,
  }) : super(key: key);

  @override
  State<WorkoutConversionScreen> createState() => _WorkoutConversionScreenState();
}

class _WorkoutConversionScreenState extends State<WorkoutConversionScreen> {
  final _formKey = GlobalKey<FormState>();
  final DioClient _dioClient = DioClient();
  bool _saving = false;

  late TextEditingController _nameController;
  late TextEditingController _setsController;
  late TextEditingController _weightController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: '${widget.exerciseName} Session');
    _setsController = TextEditingController(text: '${widget.initialSets}');
    _weightController = TextEditingController(text: '${widget.initialWeight}');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    _dioClient.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      if (widget.sessionId != null) {
        await _dioClient.dio.post(
          '/workouts/rep-sessions/${widget.sessionId}/convert-to-workout/',
          data: {
            'workout_name': _nameController.text.trim(),
            'sets': int.tryParse(_setsController.text) ?? 1,
            'weight': double.tryParse(_weightController.text) ?? 0,
            'notes': _notesController.text.trim(),
          },
        );
      }

      if (mounted) {
        showCenterToast(context, 'Workout saved successfully!');
        // Go back to home
        Navigator.popUntil(context, (r) => r.isFirst);
      }
    } catch (e) {
      if (mounted) {
        showCenterToast(context, 'Failed to save: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Save Workout'),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary chip
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _chip(Icons.fitness_center, widget.exerciseName),
                    _chip(Icons.repeat, '${widget.totalReps} reps'),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _field(
                controller: _nameController,
                label: 'Workout Name',
                icon: Icons.label_outline,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(
                  child: _field(
                    controller: _setsController,
                    label: 'Sets',
                    icon: Icons.layers_outlined,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1) return 'Min 1';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    icon: Icons.monitor_weight_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n < 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              _field(
                controller: _notesController,
                label: 'Notes (optional)',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),

              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Saving...' : 'Save Workout',
                    style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Row(children: [
      Icon(icon, size: 18, color: const Color(0xFFE53935)),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFE53935)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE53935)),
        ),
      ),
    );
  }
}
