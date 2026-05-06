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
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChallenges();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200
        && !_isLoadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadChallenges({String? search}) async {
    final q = search ?? _searchController.text;
    setState(() { _isLoading = true; _error = null; _currentPage = 1; });
    try {
      final response = await _adminService.getChallenges(search: q, page: 1);
      setState(() {
        _challenges = response['results'] ?? [];
        _hasMore = response['next'] != null;
        _currentPage = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final response = await _adminService.getChallenges(
        search: _searchController.text,
        page: _currentPage + 1,
      );
      setState(() {
        _challenges.addAll(response['results'] ?? []);
        _hasMore = response['next'] != null;
        _currentPage++;
        _isLoadingMore = false;
      });
    } catch (_) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _toggleOfficial(Map<String, dynamic> c) async {
    try {
      await _adminService.updateChallenge(c['id'], isOfficial: !(c['is_official'] == true));
      _loadChallenges(search: _searchController.text);
      if (mounted) showCenterToast(context, c['is_official'] == true ? 'Removed official status' : 'Marked as official');
    } catch (e) {
      if (mounted) showCenterToast(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> c) async {
    final isActive = c['is_active'] == true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isActive ? 'Deactivate Challenge' : 'Activate Challenge'),
        content: Text(isActive
            ? 'Users will no longer be able to join this challenge.'
            : 'This challenge will become visible and joinable again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.orange : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text(isActive ? 'Deactivate' : 'Activate'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _adminService.updateChallenge(c['id'], isActive: !isActive);
      _loadChallenges(search: _searchController.text);
      if (mounted) showCenterToast(context, isActive ? 'Challenge deactivated' : 'Challenge activated');
    } catch (e) {
      if (mounted) showCenterToast(context, 'Error: $e', isError: true);
    }
  }

  Future<void> _deleteChallenge(Map<String, dynamic> c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Delete "${c['name']}"? This cannot be undone and will remove all participant data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _adminService.deleteChallenge(c['id']);
      _loadChallenges(search: _searchController.text);
      if (mounted) showCenterToast(context, 'Challenge deleted');
    } catch (e) {
      if (mounted) showCenterToast(context, 'Error: $e', isError: true);
    }
  }

  void _editChallenge(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (_) => _EditChallengeDialog(
        adminService: _adminService,
        challenge: c,
        onSaved: () => _loadChallenges(search: _searchController.text),
      ),
    );
  }

  void _showLeaderboard(Map<String, dynamic> c) {
    final endDate = c['end_date'] != null
        ? DateTime.tryParse(c['end_date']) ?? DateTime.now()
        : DateTime.now();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChallengeLeaderboardScreen(
          challengeId: c['id'],
          challengeName: c['name'] ?? '',
          endDate: endDate,
          isAdmin: true,
          prizeDescription: c['prize_description'],
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
          Column(
            children: [
              // Search bar
              Container(
                color: _kRed,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => _loadChallenges(search: v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search challenges...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.2),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Count
              if (!_isLoading && _error == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                  child: Row(
                    children: [
                      Text('${_challenges.length} challenge${_challenges.length != 1 ? 's' : ''}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: _kRed))
                    : _error != null
                        ? _ErrorRetry(onRetry: () => _loadChallenges(search: _searchController.text))
                        : _challenges.isEmpty
                            ? const Center(child: Text('No challenges found', style: TextStyle(color: Colors.grey)))
                            : RefreshIndicator(
                                color: _kRed,
                                onRefresh: () => _loadChallenges(search: _searchController.text),
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                                  itemCount: _challenges.length + (_isLoadingMore ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == _challenges.length) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                        child: Center(child: CircularProgressIndicator(color: _kRed, strokeWidth: 2)),
                                      );
                                    }
                                    final c = _challenges[index];
                                    return _ChallengeCard(
                                      challenge: c,
                                      onToggleOfficial: () => _toggleOfficial(c),
                                      onToggleActive: () => _toggleActive(c),
                                      onEdit: () => _editChallenge(c),
                                      onDelete: () => _deleteChallenge(c),
                                      onViewLeaderboard: () => _showLeaderboard(c),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),

          // FAB
          Positioned(
            bottom: 16, right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: FloatingActionButton.extended(
                  heroTag: 'admin_challenges_fab',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => _CreateChallengeDialog(
                      adminService: _adminService,
                      onCreated: () => _loadChallenges(search: _searchController.text),
                    ),
                  ),
                  backgroundColor: _kRed,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Challenge card ────────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final VoidCallback onToggleOfficial;
  final VoidCallback onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewLeaderboard;

  const _ChallengeCard({
    required this.challenge,
    required this.onToggleOfficial,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
    required this.onViewLeaderboard,
  });

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
    final isActive = challenge['is_active'] != false; // default true
    final type = challenge['challenge_type'] ?? '';
    final endDate = challenge['end_date'] != null ? DateTime.tryParse(challenge['end_date']) : null;
    final hasEnded = endDate != null && endDate.isBefore(DateTime.now());
    final participantCount = challenge['participant_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        border: !isActive
            ? Border.all(color: Colors.grey[300]!, width: 1.5)
            : hasEnded && isPaid
                ? Border.all(color: const Color(0xFFEF4444), width: 1.5)
                : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: type badge + status badges + official toggle
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: _typeColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                  child: Text(type.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _typeColor)),
                ),
                const SizedBox(width: 6),
                if (isPaid)
                  _SmallBadge('PAID', const Color(0xFFFEF3C7), const Color(0xFFD97706)),
                if (!isActive) ...[
                  const SizedBox(width: 6),
                  _SmallBadge('INACTIVE', const Color(0xFFF3F4F6), Colors.grey),
                ],
                if (hasEnded) ...[
                  const SizedBox(width: 6),
                  _SmallBadge('ENDED', const Color(0xFFFEE2E2), const Color(0xFFEF4444)),
                ],
                const Spacer(),
                // Official toggle
                GestureDetector(
                  onTap: onToggleOfficial,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isOfficial ? const Color(0xFFEFF6FF) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isOfficial ? const Color(0xFF3B82F6) : Colors.grey[300]!),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(isOfficial ? Icons.verified : Icons.verified_outlined,
                          size: 14, color: isOfficial ? const Color(0xFF3B82F6) : Colors.grey),
                      const SizedBox(width: 4),
                      Text(isOfficial ? 'Official' : 'Make Official',
                          style: TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600,
                              color: isOfficial ? const Color(0xFF3B82F6) : Colors.grey[600])),
                    ]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Name + goal
            Text(challenge['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('${challenge['goal_value']} ${challenge['unit']}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(width: 12),
                Icon(Icons.people_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('$participantCount participant${participantCount != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),

            // Prize description
            if (isPaid && (challenge['prize_description'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.card_giftcard, size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(challenge['prize_description'],
                      style: const TextStyle(fontSize: 12, color: Color(0xFFD97706))),
                ),
              ]),
            ],

            const SizedBox(height: 12),

            // Action buttons row
            Row(
              children: [
                // Leaderboard (all challenges)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewLeaderboard,
                    icon: Icon(Icons.leaderboard, size: 14,
                        color: hasEnded && isPaid ? const Color(0xFFEF4444) : _kRed),
                    label: Text(
                      hasEnded && isPaid ? 'Award Prize' : 'Leaderboard',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600,
                          color: hasEnded && isPaid ? const Color(0xFFEF4444) : _kRed),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: hasEnded && isPaid ? const Color(0xFFEF4444) : _kRed),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Active toggle
                _IconBtn(
                  icon: isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  color: isActive ? Colors.orange : Colors.green,
                  tooltip: isActive ? 'Deactivate' : 'Activate',
                  onTap: onToggleActive,
                ),
                const SizedBox(width: 6),
                // Edit
                _IconBtn(
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF3B82F6),
                  tooltip: 'Edit',
                  onTap: onEdit,
                ),
                const SizedBox(width: 6),
                // Delete
                _IconBtn(
                  icon: Icons.delete_outline,
                  color: Colors.red,
                  tooltip: 'Delete',
                  onTap: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _SmallBadge(this.label, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
  );
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.color, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: color),
      ),
    ),
  );
}

class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, size: 48, color: Colors.red),
      const SizedBox(height: 12),
      const Text('Failed to load', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
        child: const Text('Retry'),
      ),
    ]),
  );
}

// ── Edit Challenge Dialog ─────────────────────────────────────────────────────

class _EditChallengeDialog extends StatefulWidget {
  final AdminService adminService;
  final Map<String, dynamic> challenge;
  final VoidCallback onSaved;
  const _EditChallengeDialog({required this.adminService, required this.challenge, required this.onSaved});

  @override
  State<_EditChallengeDialog> createState() => _EditChallengeDialogState();
}

class _EditChallengeDialogState extends State<_EditChallengeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _goalValue;
  late TextEditingController _price;
  late TextEditingController _prizeDescription;
  late String _type;
  late String _unit;
  late bool _isOfficial;
  late bool _isPaid;
  late bool _isActive;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.challenge;
    _name = TextEditingController(text: c['name'] ?? '');
    _description = TextEditingController(text: c['description'] ?? '');
    _goalValue = TextEditingController(text: '${c['goal_value'] ?? 30}');
    _price = TextEditingController(text: '${c['price'] ?? 0}');
    _prizeDescription = TextEditingController(text: c['prize_description'] ?? '');
    _type = c['challenge_type'] ?? 'workout';
    _unit = c['unit'] ?? 'days';
    _isOfficial = c['is_official'] == true;
    _isPaid = c['is_paid'] == true;
    _isActive = c['is_active'] != false;
    _startDate = c['start_date'] != null ? DateTime.tryParse(c['start_date']) ?? DateTime.now() : DateTime.now();
    _endDate = c['end_date'] != null ? DateTime.tryParse(c['end_date']) ?? DateTime.now().add(const Duration(days: 30)) : DateTime.now().add(const Duration(days: 30));
  }

  @override
  void dispose() {
    _name.dispose(); _description.dispose(); _goalValue.dispose();
    _price.dispose(); _prizeDescription.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
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
      await widget.adminService.editChallenge(
        widget.challenge['id'],
        name: _name.text.trim(),
        description: _description.text.trim(),
        challengeType: _type,
        goalValue: double.tryParse(_goalValue.text) ?? 30,
        unit: _unit,
        startDate: _startDate.toIso8601String(),
        endDate: _endDate.toIso8601String(),
        isOfficial: _isOfficial,
        isActive: _isActive,
        isPaid: _isPaid,
        price: double.tryParse(_price.text) ?? 0,
        prizeDescription: _prizeDescription.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        showCenterToast(context, 'Challenge updated');
      }
    } catch (e) {
      if (mounted) showCenterToast(context, 'Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _field(String label) => InputDecoration(
    labelText: label,
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
              Row(children: [
                const Icon(Icons.edit_rounded, color: _kRed),
                const SizedBox(width: 8),
                const Text('Edit Challenge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
              const Divider(),
              const SizedBox(height: 8),

              TextFormField(controller: _name, decoration: _field('Challenge Name *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _description, decoration: _field('Description *'),
                  maxLines: 2, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    decoration: _field('Type'),
                    items: ['workout', 'nutrition', 'mixed']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    decoration: _field('Unit'),
                    items: ['days', 'kcal', 'reps', 'km', 'minutes']
                        .map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              TextFormField(controller: _goalValue, decoration: _field('Goal Value *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today, size: 14, color: _kRed),
                    label: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        style: const TextStyle(color: _kRed)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: _kRed)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.calendar_today, size: 14, color: _kRed),
                    label: Text('${_endDate.day}/${_endDate.month}/${_endDate.year}',
                        style: const TextStyle(color: _kRed)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: _kRed)),
                  ),
                ),
              ]),
              const SizedBox(height: 4),

              SwitchListTile(value: _isOfficial, onChanged: (v) => setState(() => _isOfficial = v),
                  title: const Text('Official Challenge', style: TextStyle(fontSize: 14)),
                  activeColor: _kRed, contentPadding: EdgeInsets.zero),
              SwitchListTile(value: _isActive, onChanged: (v) => setState(() => _isActive = v),
                  title: const Text('Active (visible & joinable)', style: TextStyle(fontSize: 14)),
                  activeColor: Colors.green, contentPadding: EdgeInsets.zero),
              SwitchListTile(value: _isPaid, onChanged: (v) => setState(() => _isPaid = v),
                  title: const Text('Paid (eSewa)', style: TextStyle(fontSize: 14)),
                  activeColor: const Color(0xFF10B981), contentPadding: EdgeInsets.zero),

              if (_isPaid) ...[
                const SizedBox(height: 8),
                TextFormField(controller: _price, decoration: _field('Price (NPR)'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextFormField(controller: _prizeDescription, decoration: _field('Prize Description'),
                    maxLines: 2),
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
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Create Challenge Dialog ───────────────────────────────────────────────────

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
  final List<Map<String, String>> _tasks = [];
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

  void _addTask() {
    showDialog(
      context: context,
      builder: (_) => _AddTaskDialog(
        onAdd: (label, type) => setState(() => _tasks.add({'label': label, 'type': type})),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
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
        tasks: _tasks,
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
              Row(children: [
                const Icon(Icons.emoji_events_rounded, color: _kRed),
                const SizedBox(width: 8),
                const Text('Create Challenge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
              const Divider(),
              const SizedBox(height: 8),

              TextFormField(controller: _name, decoration: _field('Challenge Name *'),
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _description, decoration: _field('Description *'),
                  maxLines: 2, validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _type, decoration: _field('Type'),
                    items: ['workout', 'nutrition', 'mixed']
                        .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setState(() => _type = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit, decoration: _field('Unit'),
                    items: ['days', 'kcal', 'reps', 'km', 'minutes']
                        .map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unit = v!),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              TextFormField(controller: _goalValue, decoration: _field('Goal Value *'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              const SizedBox(height: 12),

              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(true),
                    icon: const Icon(Icons.calendar_today, size: 14, color: _kRed),
                    label: Text('${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        style: const TextStyle(color: _kRed)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: _kRed)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(false),
                    icon: const Icon(Icons.calendar_today, size: 14, color: _kRed),
                    label: Text('${_endDate.day}/${_endDate.month}/${_endDate.year}',
                        style: const TextStyle(color: _kRed)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: _kRed)),
                  ),
                ),
              ]),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daily Tasks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  TextButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add, size: 16, color: _kRed),
                    label: const Text('Add Task', style: TextStyle(color: _kRed, fontSize: 12)),
                  ),
                ],
              ),
              if (_tasks.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50], borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Text('No tasks added yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              else
                ..._tasks.asMap().entries.map((e) {
                  final i = e.key; final task = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50], borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(children: [
                      Expanded(child: Text(task['label'] ?? '', style: const TextStyle(fontSize: 13))),
                      GestureDetector(
                        onTap: () => setState(() => _tasks.removeAt(i)),
                        child: const Icon(Icons.close, size: 16, color: Colors.grey),
                      ),
                    ]),
                  );
                }),
              const SizedBox(height: 8),

              SwitchListTile(value: _isOfficial, onChanged: (v) => setState(() => _isOfficial = v),
                  title: const Text('Official Challenge', style: TextStyle(fontSize: 14)),
                  activeColor: _kRed, contentPadding: EdgeInsets.zero),
              SwitchListTile(value: _isPaid, onChanged: (v) => setState(() => _isPaid = v),
                  title: const Text('Paid (eSewa)', style: TextStyle(fontSize: 14)),
                  activeColor: const Color(0xFF10B981), contentPadding: EdgeInsets.zero),

              if (_isPaid) ...[
                const SizedBox(height: 8),
                TextFormField(controller: _price, decoration: _field('Price (NPR)', hint: '500'),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                TextFormField(controller: _prizeDescription, decoration: _field('Prize Description'),
                    maxLines: 2),
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
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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

// ── Add Task Dialog ───────────────────────────────────────────────────────────

class _AddTaskDialog extends StatefulWidget {
  final void Function(String label, String type) onAdd;
  const _AddTaskDialog({required this.onAdd});

  @override
  State<_AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<_AddTaskDialog> {
  final _labelCtrl = TextEditingController();
  String _taskType = 'manual';

  @override
  void dispose() { _labelCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Daily Task', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _labelCtrl,
            decoration: InputDecoration(
              labelText: 'Task description *',
              hintText: 'e.g. 30 Push-ups',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _kRed)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            _TypeChip('Manual', 'manual', _taskType, Colors.grey[600]!,
                () => setState(() => _taskType = 'manual')),
            const SizedBox(width: 8),
            _TypeChip('Exercise', 'exercise', _taskType, Colors.blue[700]!,
                () => setState(() => _taskType = 'exercise')),
            const SizedBox(width: 8),
            _TypeChip('Food', 'food', _taskType, Colors.green[700]!,
                () => setState(() => _taskType = 'food')),
          ]),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final label = _labelCtrl.text.trim();
            if (label.isEmpty) return;
            widget.onAdd(label, _taskType);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final Color color;
  final VoidCallback onTap;
  const _TypeChip(this.label, this.value, this.current, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    final selected = current == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey[300]!, width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? color : Colors.grey[600])),
      ),
    );
  }
}
