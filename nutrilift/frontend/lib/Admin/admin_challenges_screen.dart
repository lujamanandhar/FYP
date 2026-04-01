import 'package:flutter/material.dart';
import '../widgets/nutrilift_header.dart';
import 'admin_service.dart';

class AdminChallengesScreen extends StatefulWidget {
  const AdminChallengesScreen({Key? key}) : super(key: key);

  @override
  State<AdminChallengesScreen> createState() => _AdminChallengesScreenState();
}

class _AdminChallengesScreenState extends State<AdminChallengesScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _challenges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() => _isLoading = true);
    try {
      final response = await _adminService.getChallenges();
      setState(() {
        _challenges = response['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOfficial(String challengeId, bool currentValue) async {
    try {
      await _adminService.updateChallenge(challengeId, isOfficial: !currentValue);
      _loadChallenges();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (_) => _CreateChallengeDialog(
        adminService: _adminService,
        onCreated: _loadChallenges,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Challenge Management',
      showBackButton: true,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        backgroundColor: const Color(0xFFE53935),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadChallenges,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: _challenges.length,
                itemBuilder: (context, index) {
                  final c = _challenges[index];
                  final isPaid = c['is_paid'] == true;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPaid
                            ? const Color(0xFF60BB46)
                            : const Color(0xFFFFEBEE),
                        child: Icon(
                          isPaid ? Icons.lock : Icons.emoji_events,
                          color: isPaid ? Colors.white : const Color(0xFFE53935),
                          size: 20,
                        ),
                      ),
                      title: Text(c['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${c['challenge_type']} • ${c['unit']}'),
                          if (isPaid)
                            Text(
                              'NPR ${c['price']} — ${c['prize_description'] ?? ''}',
                              style: const TextStyle(
                                  color: Color(0xFF60BB46), fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c['is_official'] == true)
                            const Icon(Icons.verified, color: Colors.blue, size: 18),
                          IconButton(
                            icon: Icon(
                              c['is_official'] == true ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () => _toggleOfficial(c['id'], c['is_official'] == true),
                            tooltip: 'Toggle Official',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _CreateChallengeDialog extends StatefulWidget {
  final AdminService adminService;
  final VoidCallback onCreated;
  const _CreateChallengeDialog({required this.adminService, required this.onCreated});

  @override
  State<_CreateChallengeDialog> createState() => _CreateChallengeDialogState();
}

class _CreateChallengeDialogState extends State<_CreateChallengeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _goalValue = TextEditingController(text: '30');
  final _price = TextEditingController(text: '0');
  final _prizeDescription = TextEditingController();
  final _tasksController = TextEditingController();

  String _type = 'workout';
  String _unit = 'days';
  bool _isOfficial = true;
  bool _isPaid = false;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final tasks = _tasksController.text
          .split('\n')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await widget.adminService.createChallenge(
        name: _name.text.trim(),
        description: _description.text.trim(),
        challengeType: _type,
        goalValue: double.tryParse(_goalValue.text) ?? 30,
        unit: _unit,
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
        isOfficial: _isOfficial,
        isPaid: _isPaid,
        price: double.tryParse(_price.text) ?? 0,
        currency: 'NPR',
        prizeDescription: _prizeDescription.text.trim(),
        tasks: tasks,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Challenge created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create Official Challenge',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Challenge Name *', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description *', border: OutlineInputBorder()),
                maxLines: 2,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Type + Unit row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                      items: ['workout', 'nutrition', 'mixed']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                      items: ['days', 'kcal', 'reps']
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Goal value
              TextFormField(
                controller: _goalValue,
                decoration: const InputDecoration(labelText: 'Goal Value *', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Date pickers
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('Start: ${_startDate.day}/${_startDate.month}/${_startDate.year}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(false),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text('End: ${_endDate.day}/${_endDate.month}/${_endDate.year}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Daily tasks
              TextFormField(
                controller: _tasksController,
                decoration: const InputDecoration(
                  labelText: 'Daily Tasks (one per line)',
                  hintText: 'e.g.\n30 push-ups\n10 min run',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),

              // Official toggle
              SwitchListTile(
                value: _isOfficial,
                onChanged: (v) => setState(() => _isOfficial = v),
                title: const Text('Official Challenge'),
                subtitle: const Text('Shown with verified badge'),
                activeColor: const Color(0xFFE53935),
                contentPadding: EdgeInsets.zero,
              ),

              // Paid toggle
              SwitchListTile(
                value: _isPaid,
                onChanged: (v) => setState(() => _isPaid = v),
                title: const Text('Paid Challenge (eSewa)'),
                subtitle: const Text('Requires payment to join'),
                activeColor: const Color(0xFF60BB46),
                contentPadding: EdgeInsets.zero,
              ),

              // Payment fields
              if (_isPaid) ...[
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(
                    labelText: 'Price (NPR) *',
                    prefixText: 'NPR ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => _isPaid && (v!.isEmpty || double.tryParse(v) == null)
                      ? 'Enter valid price'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _prizeDescription,
                  decoration: const InputDecoration(
                    labelText: 'Prize Description',
                    hintText: 'e.g. Gift hamper + NutriLift voucher worth NPR 2000',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
              ],

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                    ),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Create Challenge'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
