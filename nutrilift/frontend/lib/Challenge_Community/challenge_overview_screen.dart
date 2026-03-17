import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_provider.dart';
import 'challenge_api_service.dart';
import 'challenge_details_screen.dart';
import 'community_feed_screen.dart';

const Color _kRed = Color(0xFFE53935);

class ChallengeOverviewScreen extends StatefulWidget {
  const ChallengeOverviewScreen({super.key});

  @override
  State<ChallengeOverviewScreen> createState() => _ChallengeOverviewScreenState();
}

class _ChallengeOverviewScreenState extends State<ChallengeOverviewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().fetchChallenges();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CreateChallengeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      showBackButton: true,
      body: Column(
        children: [
          const ChallengeHeaderTabs(selected: 0),
          const SizedBox(height: 8),
          const Expanded(child: ChallengeOverviewBody()),
        ],
      ),
    );
  }
}

/// The challenge tabs content (All/Mine) without any scaffold wrapping.
/// Used both inside [ChallengeOverviewScreen] and [ChallengeCommunityWrapper].
class ChallengeOverviewBody extends StatefulWidget {
  const ChallengeOverviewBody({super.key});

  @override
  State<ChallengeOverviewBody> createState() => _ChallengeOverviewBodyState();
}

class _ChallengeOverviewBodyState extends State<ChallengeOverviewBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().fetchChallenges();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _CreateChallengeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // All / Mine tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: _kRed,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'All Challenges'),
              Tab(text: 'My Challenges'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Consumer<ChallengeProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.challenges.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: _kRed));
              }
              if (provider.error != null && provider.challenges.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(provider.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => provider.fetchChallenges(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kRed,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Stack(
                children: [
                  TabBarView(
                    controller: _tabController,
                    children: [
                      _ChallengeList(
                        challenges: provider.challenges,
                        provider: provider,
                        emptyMessage: 'No challenges available',
                      ),
                      _ChallengeList(
                        challenges: provider.myChallenges,
                        provider: provider,
                        emptyMessage: 'You haven\'t joined any challenges yet',
                        showDeleteForOwned: true,
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.extended(
                      onPressed: _showCreateSheet,
                      backgroundColor: _kRed,
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Challenge',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Challenge List ───────────────────────────────────────────────────────────

class _ChallengeList extends StatelessWidget {
  final List<ChallengeModel> challenges;
  final ChallengeProvider provider;
  final String emptyMessage;
  final bool showDeleteForOwned;

  const _ChallengeList({
    required this.challenges,
    required this.provider,
    required this.emptyMessage,
    this.showDeleteForOwned = false,
  });

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(emptyMessage, style: TextStyle(color: Colors.grey[500])),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final challenge = challenges[index];
        final isOwner = provider.currentUserId != null &&
            challenge.createdById == provider.currentUserId;
        return _ChallengeCard(
          challenge: challenge,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ChallengeDetailsScreen(challenge: challenge)),
          ),
          onJoin: () => provider.joinChallenge(challenge.id),
          onLeave: () => provider.leaveChallenge(challenge.id),
          onDelete: (showDeleteForOwned && isOwner)
              ? () => _confirmDelete(context, provider, challenge)
              : null,
        );
      },
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, ChallengeProvider provider, ChallengeModel c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Challenge'),
        content: Text('Delete "${c.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: _kRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final ok = await provider.deleteChallenge(c.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Challenge deleted' : (provider.error ?? 'Failed')),
        ));
      }
    }
  }
}

// ─── Challenge Card ───────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback? onDelete;

  const _ChallengeCard({
    required this.challenge,
    required this.onTap,
    required this.onJoin,
    required this.onLeave,
    this.onDelete,
  });

  int get _daysRemaining {
    final diff = challenge.endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  double get _progressValue {
    if (challenge.goalValue <= 0) return 0;
    return (challenge.participantProgress / challenge.goalValue).clamp(0.0, 1.0);
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'nutrition': return Colors.green;
      case 'workout': return Colors.orange;
      default: return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(challenge.challengeType);
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(challenge.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Chip(
                    label: Text(challenge.challengeType.toUpperCase(),
                        style: const TextStyle(fontSize: 11, color: Colors.white)),
                    backgroundColor: typeColor,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  if (onDelete != null) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, size: 18, color: Colors.grey[400]),
                      onSelected: (v) { if (v == 'delete') onDelete!(); },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ]),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (challenge.isOfficial) ...[
                    const Icon(Icons.verified, size: 14, color: _kRed),
                    const SizedBox(width: 4),
                    const Text('NutriLift',
                        style: TextStyle(fontSize: 12, color: _kRed, fontWeight: FontWeight.w600)),
                  ] else ...[
                    const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('by @${challenge.createdByUsername}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Text('Goal: ${challenge.goalValue.toStringAsFixed(0)} ${challenge.unit}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _progressValue,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${challenge.participantProgress.toStringAsFixed(0)} / ${challenge.goalValue.toStringAsFixed(0)} ${challenge.unit}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('$_daysRemaining days remaining',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ]),
                  challenge.isJoined
                      ? ElevatedButton(
                          onPressed: onLeave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kRed,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('LEAVE', style: TextStyle(fontSize: 12)),
                        )
                      : ElevatedButton(
                          onPressed: onJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('JOIN', style: TextStyle(fontSize: 12)),
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

// ─── Create Challenge Sheet ───────────────────────────────────────────────────

class _CreateChallengeSheet extends StatefulWidget {
  const _CreateChallengeSheet();
  @override
  State<_CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<_CreateChallengeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  String _type = 'workout';
  String _unit = 'reps';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _kRed),
        ),
        child: child!,
      ),
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
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date must be after start date')));
      return;
    }
    setState(() => _loading = true);
    final provider = context.read<ChallengeProvider>();
    final ok = await provider.createChallenge(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      challengeType: _type,
      goalValue: double.tryParse(_goalCtrl.text.trim()) ?? 0,
      unit: _unit,
      startDate: _startDate,
      endDate: _endDate,
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge created!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to create challenge')));
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kRed),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create a Challenge',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: _dec('Challenge Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: _dec('Description'),
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _type,
                      decoration: _dec('Type'),
                      items: const [
                        DropdownMenuItem(value: 'workout', child: Text('Workout')),
                        DropdownMenuItem(value: 'nutrition', child: Text('Nutrition')),
                        DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
                      ],
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: _dec('Unit'),
                      items: const [
                        DropdownMenuItem(value: 'reps', child: Text('Reps')),
                        DropdownMenuItem(value: 'kcal', child: Text('kcal')),
                        DropdownMenuItem(value: 'days', child: Text('Days')),
                      ],
                      onChanged: (v) => setState(() => _unit = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _goalCtrl,
                decoration: _dec('Goal Value'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v.trim()) == null) return 'Enter a number';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(true),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                          'Start: ${_startDate.day}/${_startDate.month}/${_startDate.year}',
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kRed),
                        foregroundColor: _kRed,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDate(false),
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                          'End: ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                          style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _kRed),
                        foregroundColor: _kRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Challenge',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Header Tabs ──────────────────────────────────────────────────────────────

class ChallengeHeaderTabs extends StatelessWidget {
  final int selected;
  const ChallengeHeaderTabs({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (selected != 0) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ChallengeOverviewScreen()),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected == 0 ? color.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Challenges',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected == 0 ? color : Colors.grey[500],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              if (selected != 1) Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: selected == 1 ? color.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Community',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected == 1 ? color : Colors.grey[500],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
