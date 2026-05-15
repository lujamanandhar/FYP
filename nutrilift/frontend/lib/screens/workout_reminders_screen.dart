import 'package:flutter/material.dart';
import '../services/workout_reminder_service.dart';
import '../widgets/nutrilift_header.dart';

const _kRed = Color(0xFFE53935);

class WorkoutRemindersScreen extends StatefulWidget {
  const WorkoutRemindersScreen({Key? key}) : super(key: key);

  @override
  State<WorkoutRemindersScreen> createState() => _WorkoutRemindersScreenState();
}

class _WorkoutRemindersScreenState extends State<WorkoutRemindersScreen> {
  final _service = WorkoutReminderService();
  List<WorkoutReminder> _reminders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _service.loadReminders();
    if (mounted) setState(() { _reminders = list; _loading = false; });
  }

  Future<void> _addOrEdit({WorkoutReminder? existing}) async {
    final result = await showModalBottomSheet<WorkoutReminder>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReminderFormSheet(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await _service.addReminder(result);
    } else {
      await _service.updateReminder(result);
    }
    _load();
  }

  Future<void> _delete(WorkoutReminder r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: Text('Delete "${r.label}"?'),
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
    await _service.deleteReminder(r.id);
    _load();
  }

  Future<void> _toggle(WorkoutReminder r, bool enabled) async {
    await _service.toggleReminder(r.id, enabled);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Workout Reminders',
      showBackButton: true,
      showDrawer: false,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kRed))
          : Column(
              children: [
                // Info banner
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _kRed.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kRed.withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.notifications_active_outlined, color: _kRed, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Set weekly reminders to stay consistent with your workouts.',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: _reminders.isEmpty
                      ? _EmptyState(onAdd: () => _addOrEdit())
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _reminders.length,
                          itemBuilder: (_, i) => _ReminderTile(
                            reminder: _reminders[i],
                            onToggle: (v) => _toggle(_reminders[i], v),
                            onEdit: () => _addOrEdit(existing: _reminders[i]),
                            onDelete: () => _delete(_reminders[i]),
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        backgroundColor: _kRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Add Reminder', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.alarm_add_rounded, size: 52, color: _kRed),
          ),
          const SizedBox(height: 20),
          const Text('No Reminders Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Add a reminder to get notified when it\'s time to work out.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Reminder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Reminder tile ─────────────────────────────────────────────────────────────

class _ReminderTile extends StatelessWidget {
  final WorkoutReminder reminder;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderTile({
    required this.reminder,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            // Time display
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                reminder.timeString,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: reminder.enabled ? Colors.black87 : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                reminder.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: reminder.enabled ? _kRed : Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                Icon(Icons.repeat_rounded, size: 13, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  reminder.daysString,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ]),
            ]),
            const Spacer(),
            // Actions
            Column(children: [
              Switch(
                value: reminder.enabled,
                onChanged: onToggle,
                activeColor: _kRed,
              ),
              Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  color: Colors.blue,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ]),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Reminder form sheet ───────────────────────────────────────────────────────

class _ReminderFormSheet extends StatefulWidget {
  final WorkoutReminder? existing;
  const _ReminderFormSheet({this.existing});

  @override
  State<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends State<_ReminderFormSheet> {
  late TextEditingController _labelCtrl;
  late TimeOfDay _time;
  late Set<int> _selectedDays;

  static const _dayNames = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _labelCtrl = TextEditingController(text: ex?.label ?? 'Workout Reminder');
    _time = ex?.time ?? const TimeOfDay(hour: 7, minute: 0);
    _selectedDays = ex != null ? Set<int>.from(ex.days) : {1, 3, 5}; // Mon/Wed/Fri default
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (_labelCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a label')),
      );
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one day')),
      );
      return;
    }
    final reminder = WorkoutReminder(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelCtrl.text.trim(),
      time: _time,
      days: _selectedDays.toList()..sort(),
      enabled: widget.existing?.enabled ?? true,
    );
    Navigator.pop(context, reminder);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(isEdit ? 'Edit Reminder' : 'New Reminder',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),

            // Label
            const Text('Label', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _labelCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Morning Workout',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),

            // Time picker
            const Text('Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  const Icon(Icons.access_time_rounded, color: _kRed, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    WorkoutReminder(id: '', label: '', time: _time, days: const [], enabled: true).timeString,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Day selector
            const Text('Repeat on', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _dayNames.entries.map((e) {
                final selected = _selectedDays.contains(e.key);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedDays.remove(e.key);
                    } else {
                      _selectedDays.add(e.key);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected ? _kRed : Colors.grey[100],
                      shape: BoxShape.circle,
                      border: Border.all(color: selected ? _kRed : Colors.grey[300]!),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      e.value,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEdit ? 'Save Changes' : 'Set Reminder',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
