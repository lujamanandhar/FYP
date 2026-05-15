import 'package:flutter/material.dart';
import 'admin_service.dart';

const _kRed = Color(0xFFE53935);

// ── Dropdown options matching backend choices ─────────────────────────────────
const _categories = ['STRENGTH', 'CARDIO', 'BODYWEIGHT'];
const _muscleGroups = ['CHEST', 'BACK', 'LEGS', 'CORE', 'ARMS', 'SHOULDERS', 'FULL_BODY'];
const _equipments = ['FREE_WEIGHTS', 'MACHINES', 'BODYWEIGHT', 'RESISTANCE_BANDS', 'CARDIO_EQUIPMENT'];
const _difficulties = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'];

String _label(String v) => v.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase()).join(' ');

class AdminExercisesScreen extends StatefulWidget {
  const AdminExercisesScreen({Key? key}) : super(key: key);

  @override
  State<AdminExercisesScreen> createState() => _AdminExercisesScreenState();
}

class _AdminExercisesScreenState extends State<AdminExercisesScreen> {
  final _service = AdminService();
  List<AdminExercise> _exercises = [];
  List<AdminExercise> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _categoryFilter = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _service.getExercises();
      if (mounted) {
        setState(() {
          _exercises = list;
          _loading = false;
        });
        _applyFilter();
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _exercises.where((ex) {
        final matchSearch = q.isEmpty || ex.name.toLowerCase().contains(q) || ex.muscleGroup.toLowerCase().contains(q);
        final matchCat = _categoryFilter.isEmpty || ex.category == _categoryFilter;
        return matchSearch && matchCat;
      }).toList();
    });
  }

  void _openForm({AdminExercise? exercise}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ExerciseFormSheet(exercise: exercise, service: _service),
    );
    if (result == true) _load();
  }

  Future<void> _delete(AdminExercise ex) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Exercise?'),
        content: Text('Delete "${ex.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _service.deleteExercise(ex.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search + filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search exercises...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: _categoryFilter.isEmpty ? null : _categoryFilter,
              hint: const Text('All', style: TextStyle(fontSize: 13)),
              underline: const SizedBox(),
              items: [
                const DropdownMenuItem(value: '', child: Text('All')),
                ..._categories.map((c) => DropdownMenuItem(value: c, child: Text(_label(c), style: const TextStyle(fontSize: 13)))),
              ],
              onChanged: (v) { setState(() => _categoryFilter = v ?? ''); _applyFilter(); },
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),

        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('${_filtered.length} exercises', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ),
        ),
        const SizedBox(height: 4),

        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _kRed))
              : _error != null
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 8),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _load, child: const Text('Retry')),
                    ]))
                  : _filtered.isEmpty
                      ? const Center(child: Text('No exercises found'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _ExerciseTile(
                            exercise: _filtered[i],
                            onEdit: () => _openForm(exercise: _filtered[i]),
                            onDelete: () => _delete(_filtered[i]),
                          ),
                        ),
        ),
      ],
    );
  }
}

// ── Exercise tile ─────────────────────────────────────────────────────────────

class _ExerciseTile extends StatelessWidget {
  final AdminExercise exercise;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ExerciseTile({required this.exercise, required this.onEdit, required this.onDelete});

  Color _diffColor() {
    switch (exercise.difficulty) {
      case 'BEGINNER': return Colors.green;
      case 'INTERMEDIATE': return Colors.orange;
      case 'ADVANCED': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _kRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_categoryIcon(exercise.category), color: _kRed, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _chip(_label(exercise.muscleGroup), Colors.blue),
                    _chip(_label(exercise.equipment), Colors.purple),
                    _chip(_label(exercise.difficulty), _diffColor()),
                    if (!exercise.isCustom)
                      _chip('Official', Colors.teal),
                  ]),
                  if (exercise.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(exercise.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ],
              ),
            ),
            Column(children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
                color: Colors.blue,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 4),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: onDelete,
                color: Colors.red,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
  );

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'STRENGTH': return Icons.fitness_center_rounded;
      case 'CARDIO': return Icons.directions_run_rounded;
      case 'BODYWEIGHT': return Icons.accessibility_new_rounded;
      default: return Icons.sports_gymnastics_rounded;
    }
  }
}

// ── Exercise form sheet ───────────────────────────────────────────────────────

class _ExerciseFormSheet extends StatefulWidget {
  final AdminExercise? exercise;
  final AdminService service;

  const _ExerciseFormSheet({this.exercise, required this.service});

  @override
  State<_ExerciseFormSheet> createState() => _ExerciseFormSheetState();
}

class _ExerciseFormSheetState extends State<_ExerciseFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _instructionsCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _videoUrlCtrl;
  late TextEditingController _caloriesCtrl;
  late String _category;
  late String _muscleGroup;
  late String _equipment;
  late String _difficulty;
  bool _saving = false;

  bool get _isEdit => widget.exercise != null;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _nameCtrl = TextEditingController(text: ex?.name ?? '');
    _descCtrl = TextEditingController(text: ex?.description ?? '');
    _instructionsCtrl = TextEditingController(text: ex?.instructions ?? '');
    _imageUrlCtrl = TextEditingController(text: ex?.imageUrl ?? '');
    _videoUrlCtrl = TextEditingController(text: ex?.videoUrl ?? '');
    _caloriesCtrl = TextEditingController(text: (ex?.caloriesPerMinute ?? 5.0).toString());
    _category = ex?.category ?? _categories.first;
    _muscleGroup = ex?.muscleGroup ?? _muscleGroups.first;
    _equipment = ex?.equipment ?? _equipments.first;
    _difficulty = ex?.difficulty ?? _difficulties.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _instructionsCtrl.dispose();
    _imageUrlCtrl.dispose();
    _videoUrlCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final calories = double.tryParse(_caloriesCtrl.text.trim()) ?? 5.0;
      if (_isEdit) {
        await widget.service.updateExercise(
          widget.exercise!.id,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _category,
          muscleGroup: _muscleGroup,
          equipment: _equipment,
          difficulty: _difficulty,
          instructions: _instructionsCtrl.text.trim(),
          imageUrl: _imageUrlCtrl.text.trim(),
          videoUrl: _videoUrlCtrl.text.trim(),
          caloriesPerMinute: calories,
        );
      } else {
        await widget.service.createExercise(
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          category: _category,
          muscleGroup: _muscleGroup,
          equipment: _equipment,
          difficulty: _difficulty,
          instructions: _instructionsCtrl.text.trim(),
          imageUrl: _imageUrlCtrl.text.trim(),
          videoUrl: _videoUrlCtrl.text.trim(),
          caloriesPerMinute: calories,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle + title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                Row(children: [
                  Text(_isEdit ? 'Edit Exercise' : 'Add Exercise',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ]),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _field('Exercise Name *', _nameCtrl, validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 14),
                    _field('Description', _descCtrl, maxLines: 2),
                    const SizedBox(height: 14),

                    // Dropdowns row 1
                    Row(children: [
                      Expanded(child: _dropdown('Category', _categories, _category, (v) => setState(() => _category = v!))),
                      const SizedBox(width: 12),
                      Expanded(child: _dropdown('Difficulty', _difficulties, _difficulty, (v) => setState(() => _difficulty = v!))),
                    ]),
                    const SizedBox(height: 14),

                    // Dropdowns row 2
                    Row(children: [
                      Expanded(child: _dropdown('Muscle Group', _muscleGroups, _muscleGroup, (v) => setState(() => _muscleGroup = v!))),
                      const SizedBox(width: 12),
                      Expanded(child: _dropdown('Equipment', _equipments, _equipment, (v) => setState(() => _equipment = v!))),
                    ]),
                    const SizedBox(height: 14),

                    // Instructions — most important field
                    _field(
                      'How to Perform (Instructions) *',
                      _instructionsCtrl,
                      maxLines: 6,
                      hint: 'Step-by-step instructions...\n1. Starting position\n2. Movement\n3. Return',
                      validator: (v) => v!.trim().isEmpty ? 'Instructions are required' : null,
                    ),
                    const SizedBox(height: 14),

                    _field('Calories per Minute', _caloriesCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Enter a valid number';
                          return null;
                        }),
                    const SizedBox(height: 14),

                    _field('Image URL (optional)', _imageUrlCtrl, hint: 'https://...'),
                    const SizedBox(height: 14),
                    _field('Video URL (optional)', _videoUrlCtrl, hint: 'https://youtube.com/...'),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(_isEdit ? 'Save Changes' : 'Create Exercise',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
        ),
      ]);

  Widget _dropdown(String label, List<String> options, String value, ValueChanged<String?> onChanged) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(_label(o), style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ]);
}
