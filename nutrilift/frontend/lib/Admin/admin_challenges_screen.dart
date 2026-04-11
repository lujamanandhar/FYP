import 'package:flutter/material.dart';
import '../widgets/center_toast.dart';
import 'admin_service.dart';
import '../Challenge_Community/challenge_leaderboard_screen.dart';

const _kRed = Color(0xFFE53935);
const _kBg = Color(0xFFF5F6FA);

class AdminChallengesScreen extends StatefulWidget {
  const AdminChallengesScreen({Key? key}) : super(key: key);

  @override
  State<AdminChallengesScreen> createState() => _AdminChallengesScreenState();
}

class _AdminChallengesScreenState extends State<AdminChallengesScreen> {
  final AdminService _adminService = AdminService();
  List<dynamic> _challenges = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChallenges();
  }

  Future<void> _loadChallenges() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await _adminService.getChallenges();
      setState(() {
        _challenges = response['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _toggleOfficial(String challengeId, bool currentValue) async {
    try {
      await _adminService.updateChallenge(challengeId, isOfficial: !currentValue);
      _loadChallenges();
      showCenterToast(context, currentValue ? 'Removed official status' : 'Marked as official');
    } catch (e) {
      if (mounted) showCenterToast(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _showLeaderboard(Map<String, dynamic> challenge) async {
    final endDate = challenge['end_date'] != null
        ? DateTime.tryParse(challenge['end_date']) ?? DateTime.now()
        : DateTime.now();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeLeaderboardScreen(
          challengeId: challenge['id'],
          challengeName: challenge['name'] ?? '',
          endDate: endDate,
          isAdmin: true,
          prizeDescription: challenge['prize_description'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kBg,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: _kRed))
              : _error != null
                  ? _ErrorRetry(onRetry: _loadChallenges)
                  : _challenges.isEmpty
                      ? const Center(child: Text('No challenges yet', style: TextStyle(color: Colors.grey)))
                      : RefreshIndicator(
                          color: _kRed,
                          onRefresh: _loadChallenges,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: _challenges.length,
                            itemBuilder: (context, index) {
                              final c = _challenges[index];
                              return _ChallengeCard(
                                challenge: c,
                                onToggleOfficial: () => _toggleOfficial(c['id'], c['is_official'] == true),
                                onViewLeaderboard: () => _showLeaderboard(c),
                              );
                            },
                          ),
                        ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.extended(
              heroTag: 'admin_challenges_fab',
              onPressed: () => showDialog(
                context: context,
                builder: (_) => _CreateChallengeDialog(adminService: _adminService, onCreated: _loadChallenges),
              ),
              backgroundColor: _kRed,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final VoidCallback onToggleOfficial;
  final VoidCallback onViewLeaderboard;
  const _ChallengeCard({required this.challenge, required this.onToggleOfficial, required this.onViewLeaderboard});

  Color get _typeColor {
    switch (challenge['challenge_type']) {
      case 'nutrition': return const Color(0xFF10B981);
      case 'workout': return const Color(0xFF3B82F6);
      default: return const Color(0xFF8B5CF6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = challenge['is_paid'] == true;
    final isOfficial = challenge['is_official'] == true;
    final type = challenge['challenge_type'] ?? '';
    final endDate = challenge['end_date'] != null ? DateTime.tryParse(challenge['end_date']) : null;
    final hasEnded = endDate != null && endDate.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        border: hasEnded && isPaid ? Border.all(color: const Color(0xFFEF4444), width: 1.5) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(type.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _typeColor)),
                ),
                const SizedBox(width: 8),
                if (isPaid)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(8)),
                    child: const Text('PAID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                  ),
                if (hasEnded) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('ENDED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: onToggleOfficial,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isOfficial ? const Color(0xFFEFF6FF) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isOfficial ? const Color(0xFF3B82F6) : Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isOfficial ? Icons.verified : Icons.verified_outlined,
                            size: 14, color: isOfficial ? const Color(0xFF3B82F6) : Colors.grey),
                        const SizedBox(width: 4),
                        Text(isOfficial ? 'Official' : 'Make Official',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                color: isOfficial ? const Color(0xFF3B82F6) : Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(challenge['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              '${challenge['goal_value']} ${challenge['unit']}',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            if (isPaid && challenge['prize_description'] != null && challenge['prize_description'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.card_giftcard, size: 14, color: Color(0xFFD97706)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(challenge['prize_description'], style: const TextStyle(fontSize: 12, color: Color(0xFFD97706))),
                  ),
                ],
              ),
            ],
            // Leaderboard button — always show for paid challenges, highlight if ended
            if (isPaid) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onViewLeaderboard,
                  icon: Icon(
                    hasEnded ? Icons.emoji_events : Icons.leaderboard,
                    size: 16,
                    color: hasEnded ? const Color(0xFFEF4444) : _kRed,
                  ),
                  label: Text(
                    hasEnded ? 'View Leaderboard & Award Prize' : 'View Leaderboard',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasEnded ? const Color(0xFFEF4444) : _kRed,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: hasEnded ? const Color(0xFFEF4444) : _kRed),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          const Text('Failed to load', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── Create Challenge Dialog ────────────────────────────────────────────────────

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
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _kRed)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final tasks = _tasksController.text.split('\n').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
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
        showCenterToast(context, 'Challenge created!');
      }
    } catch (e) {
      if (mounted) showCenterToast(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _field(String label, {String? hint}) => InputDecoration(
    labelText: label, hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kRed)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: _kRed),
                  const SizedBox(width: 8),
                  const Text('Create Challenge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              TextFormField(controller: _name, decoration: _field('Challenge Name *'), validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _description, decoration: _field('Description *'), maxLines: 2, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: _field('Type'),
                    items: ['workout', 'nutrition', 'mixed'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: _field('Unit'),
                    items: ['days', 'kcal', 'reps', 'km', 'minutes'].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              TextFormField(controller: _goalValue, decoration: _field('Goal Value *'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today, size: 14, color: _kRed),
                    label: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}', style: const TextStyle(color: _kRed)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: _kRed)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.calendar_today, size: 14, color: _kRed),
                    label: Text('${_endDate.day}/${_endDate.month}/${_endDate.year}', style: const TextStyle(color: _kRed)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: _kRed)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              TextFormField(controller: _tasksController, decoration: _field('Daily Tasks', hint: 'One per line\ne.g. 30 push-ups'), maxLines: 3),
              const SizedBox(height: 8),

              SwitchListTile(value: _isOfficial, onChanged: (v) => setState(() => _isOfficial = v),
                  title: const Text('Official Challenge', style: TextStyle(fontSize: 14)),
                  activeColor: _kRed, contentPadding: EdgeInsets.zero),
              SwitchListTile(value: _isPaid, onChanged: (v) => setState(() => _isPaid = v),
                  title: const Text('Paid (eSewa)', style: TextStyle(fontSize: 14)),
                  activeColor: const Color(0xFF10B981), contentPadding: EdgeInsets.zero),

              if (_isPaid) ...[
                const SizedBox(height: 8),
                TextFormField(controller: _price, decoration: _field('Price (NPR)', hint: '500'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextFormField(controller: _prizeDescription, decoration: _field('Prize Description'), maxLines: 2),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
