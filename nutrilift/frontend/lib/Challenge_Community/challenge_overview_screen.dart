import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_provider.dart';
import 'challenge_api_service.dart';
import 'challenge_details_screen.dart';
import 'active_challenge_screen.dart';
import 'community_feed_screen.dart';
import 'challenge_progress_screen.dart';

const Color _kRed = Color(0xFFE53935);
const Color _kGold = Color(0xFFFFC107);
const Color _kGreen = Color(0xFF4CAF50);

// ─── Standalone screen ────────────────────────────────────────────────────────
class ChallengeOverviewScreen extends StatefulWidget {
  const ChallengeOverviewScreen({super.key});
  @override
  State<ChallengeOverviewScreen> createState() => _ChallengeOverviewScreenState();
}
class _ChallengeOverviewScreenState extends State<ChallengeOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().fetchChallenges();
    });
  }
  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      showBackButton: true,
      body: Column(children: [
        const Expanded(child: ChallengeOverviewBody()),
      ]),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────
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
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChallengeProvider>();
      if (provider.challenges.isEmpty) provider.fetchChallenges();
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
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _CreateChallengeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Column(children: [
        // ── Tab bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                  color: _kRed,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: _kRed.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              dividerColor: Colors.transparent,
              isScrollable: false,
              tabAlignment: TabAlignment.fill,
              tabs: [
                const Tab(text: 'All'),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.star_rounded, size: 14, color: _kGold),
                  SizedBox(width: 4),
                  Text('Official'),
                ])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.check_circle_rounded, size: 13),
                  SizedBox(width: 4),
                  Text('Joined'),
                ])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.person_rounded, size: 13),
                  SizedBox(width: 4),
                  Text('Mine'),
                ])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // ── Content ──
        Expanded(
          child: Consumer<ChallengeProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && provider.challenges.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: _kRed));
              }
              if (provider.error != null && provider.challenges.isEmpty) {
                return _ErrorState(
                  message: provider.error!,
                  onRetry: provider.fetchChallenges,
                );
              }
              final official = provider.challenges.where((c) => c.isOfficial).toList();
              final joined = provider.myChallenges;
              final createdByMe = provider.createdByMe;
              return RefreshIndicator(
                color: _kRed,
                onRefresh: () => provider.fetchChallenges(),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ChallengeList(challenges: provider.challenges, provider: provider, emptyMessage: 'No challenges available'),
                    _ChallengeList(challenges: official, provider: provider, emptyMessage: 'No official challenges yet'),
                    _ActiveChallengeList(challenges: joined, provider: provider),
                    _ChallengeList(challenges: createdByMe, provider: provider, emptyMessage: 'You haven\'t created any challenges yet'),
                  ],
                ),
              );
            },
          ),
        ),
      ]),

      // ── FAB ──
      Positioned(
        bottom: 20, right: 16,
        child: FloatingActionButton.extended(
          onPressed: _showCreateSheet,
          backgroundColor: _kRed,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add),
          label: const Text('Create', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    ]);
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
        ),
      ]),
    );
  }
}

// ─── Challenge List (All + Official tabs) ─────────────────────────────────────
class _ChallengeList extends StatelessWidget {
  final List<ChallengeModel> challenges;
  final ChallengeProvider provider;
  final String emptyMessage;

  const _ChallengeList({
    required this.challenges,
    required this.provider,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(emptyMessage, style: TextStyle(color: Colors.grey[500], fontSize: 15)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final c = challenges[index];
        final isOwner = provider.currentUserId != null && c.createdById == provider.currentUserId;
        return _ChallengeCard(
          challenge: c,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChallengeDetailsScreen(challenge: c))),
          onJoin: () async {
            await provider.joinChallenge(c.id);
            if (context.mounted) {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => ActiveChallengeScreen(challengeId: c.id)));
            }
          },
          onLeave: () => _confirmLeave(context, provider, c),
          onDelete: isOwner ? () => _confirmDelete(context, provider, c) : null,
        );
      },
    );
  }

  Future<void> _confirmLeave(BuildContext context, ChallengeProvider provider, ChallengeModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Challenge?'),
        content: const Text('All your progress will be reset and cannot be recovered.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600]))),
          TextButton(onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: _kRed),
              child: const Text('Leave')),
        ],
      ),
    );
    if (ok == true && context.mounted) await provider.leaveChallenge(c.id);
  }

  Future<void> _confirmDelete(BuildContext context, ChallengeProvider provider, ChallengeModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Challenge'),
        content: Text('Delete "${c.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: _kRed),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final deleted = await provider.deleteChallenge(c.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(deleted ? 'Challenge deleted' : (provider.error ?? 'Failed'))));
      }
    }
  }
}

// ─── Enhanced Challenge Card ──────────────────────────────────────────────────
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

  Color _typeColor(String t) {
    switch (t) {
      case 'nutrition': return const Color(0xFF43A047);
      case 'workout': return const Color(0xFFFF7043);
      default: return const Color(0xFF7E57C2);
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'nutrition': return Icons.restaurant_rounded;
      case 'workout': return Icons.fitness_center_rounded;
      default: return Icons.track_changes_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = _typeColor(challenge.challengeType);
    final official = challenge.isOfficial;
    final progress = challenge.goalValue > 0
        ? (challenge.participantProgress / challenge.goalValue).clamp(0.0, 1.0)
        : 0.0;
    final daysLeft = challenge.endDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: official ? _kGold.withOpacity(0.18) : Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Coloured header strip ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: official
                      ? [const Color(0xFFFFC107), const Color(0xFFFFB300)]
                      : [tc.withOpacity(0.85), tc],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon(challenge.challengeType), color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(challenge.name,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(children: [
                      if (official) ...[
                        const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        const Text('Official', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ] else ...[
                        const Icon(Icons.person_outline, size: 12, color: Colors.white70),
                        const SizedBox(width: 3),
                        Text('@${challenge.createdByUsername}',
                            style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ]),
                  ]),
                ),
                if (onDelete != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 20),
                    onSelected: (v) { if (v == 'delete') onDelete!(); },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'delete',
                          child: Row(children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ])),
                    ],
                  ),
              ]),
            ),

            // ── Body ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Stats row
                Row(children: [
                  _MiniStat(icon: Icons.flag_rounded, label: '${challenge.goalValue.toStringAsFixed(0)} ${challenge.unit}', color: tc),
                  const SizedBox(width: 12),
                  _MiniStat(
                    icon: Icons.schedule_rounded,
                    label: '${daysLeft < 0 ? 0 : daysLeft}d left',
                    color: daysLeft <= 3 ? Colors.red : Colors.grey[600]!,
                  ),
                  const Spacer(),
                  if (challenge.isJoined)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _kGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kGreen.withOpacity(0.3)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle_rounded, size: 13, color: _kGreen),
                        SizedBox(width: 4),
                        Text('Joined', style: TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                ]),
                const SizedBox(height: 12),

                // Progress bar
                Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: Colors.grey[100],
                          valueColor: AlwaysStoppedAnimation<Color>(_kRed),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${challenge.participantProgress.toStringAsFixed(0)} / ${challenge.goalValue.toStringAsFixed(0)}',
                            style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        Text('${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(color: _kRed, fontWeight: FontWeight.bold, fontSize: 11)),
                      ]),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),

                // Action button
                if (!challenge.isJoined)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.emoji_events_rounded, size: 16),
                      label: const Text('Join Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                    ),
                  )
                else
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.today_rounded, size: 15),
                        label: const Text('View', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kRed,
                          side: BorderSide(color: _kRed.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: onLeave,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kRed,
                        side: BorderSide(color: _kRed.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Leave', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _MiniStat({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    ]);
  }
}


// ─── Active Challenge List (My Challenges tab) ────────────────────────────────
class _ActiveChallengeList extends StatelessWidget {
  final List<ChallengeModel> challenges;
  final ChallengeProvider provider;

  const _ActiveChallengeList({required this.challenges, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (challenges.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kRed.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_outlined, size: 56, color: _kRed),
          ),
          const SizedBox(height: 16),
          const Text("No joined challenges", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          Text('Browse the All tab and join one!', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final c = challenges[index];
        return _ActiveChallengeCard(
          challenge: c,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ActiveChallengeScreen(challengeId: c.id))),
          onProgress: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChallengeProgressScreen(challenge: c))),
          onLeave: () => _confirmLeave(context, c),
        );
      },
    );
  }

  Future<void> _confirmLeave(BuildContext context, ChallengeModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Leave Challenge?'),
        content: const Text('All your progress will be reset and cannot be recovered.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[600]))),
          TextButton(onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: _kRed),
              child: const Text('Leave')),
        ],
      ),
    );
    if (ok == true && context.mounted) await provider.leaveChallenge(c.id);
  }
}

// ─── Enhanced Active Challenge Card ──────────────────────────────────────────
class _ActiveChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback onTap;
  final VoidCallback onLeave;
  final VoidCallback onProgress;

  const _ActiveChallengeCard({
    required this.challenge,
    required this.onTap,
    required this.onLeave,
    required this.onProgress,
  });

  Color _typeColor(String t) {
    switch (t) {
      case 'nutrition': return const Color(0xFF43A047);
      case 'workout': return const Color(0xFFFF7043);
      default: return const Color(0xFF7E57C2);
    }
  }

  IconData _typeIcon(String t) {
    switch (t) {
      case 'nutrition': return Icons.restaurant_rounded;
      case 'workout': return Icons.fitness_center_rounded;
      default: return Icons.track_changes_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = _typeColor(challenge.challengeType);
    final progress = challenge.goalValue > 0
        ? (challenge.participantProgress / challenge.goalValue).clamp(0.0, 1.0)
        : 0.0;
    final daysLeft = challenge.endDate.difference(DateTime.now()).inDays;
    final pct = (progress * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: tc.withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Gradient header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [tc, tc.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_typeIcon(challenge.challengeType), color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(challenge.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(children: [
                    const Icon(Icons.play_circle_filled_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    const Text('Active', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 10),
                    Icon(Icons.schedule_rounded, size: 12, color: Colors.white70),
                    const SizedBox(width: 3),
                    Text('${daysLeft < 0 ? 0 : daysLeft} days left',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ]),
                ]),
              ),
              // Big % circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$pct%',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ]),
          ),

          // ── Progress bar ──
          Container(
            height: 6,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[100],
              valueColor: AlwaysStoppedAnimation<Color>(_kRed),
              minHeight: 6,
            ),
          ),

          // ── Body ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Progress text
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${challenge.participantProgress.toStringAsFixed(0)} / ${challenge.goalValue.toStringAsFixed(0)} ${challenge.unit}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _kRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(challenge.challengeType.toUpperCase(),
                      style: TextStyle(color: _kRed, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 14),

              // Action buttons
              Row(children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: onTap,
                    icon: const Icon(Icons.today_rounded, size: 16),
                    label: const Text("Today's Log", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: onProgress,
                    icon: const Icon(Icons.bar_chart_rounded, size: 15, color: _kRed),
                    label: const Text('Progress', style: TextStyle(fontSize: 11, color: _kRed, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kRed,
                      side: BorderSide(color: _kRed.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onLeave,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kRed,
                    side: BorderSide(color: _kRed.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Icon(Icons.exit_to_app_rounded, size: 18),
                ),
              ]),
            ]),
          ),
        ]),
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
  final List<TextEditingController> _taskControllers = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _goalCtrl.dispose();
    for (final c in _taskControllers) c.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _kRed)),
          child: child!),
    );
    if (picked != null) setState(() => isStart ? _startDate = picked : _endDate = picked);
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
      defaultTasks: _taskControllers
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .map((s) => {'label': s})
          .toList(),
    );
    setState(() => _loading = false);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Challenge created!'), backgroundColor: _kGreen));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Failed to create challenge')));
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Column(children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: _kRed.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.emoji_events_rounded, color: _kRed, size: 20),
              ),
              const SizedBox(width: 10),
              const Text('Create Challenge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ),
          const SizedBox(height: 4),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildField('Challenge Name', _nameCtrl, hint: 'e.g. 30-Day Workout Streak'),
                  const SizedBox(height: 14),
                  _buildField('Description', _descCtrl, hint: 'What is this challenge about?', maxLines: 3),
                  const SizedBox(height: 14),

                  // Type selector
                  const Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(children: ['workout', 'nutrition', 'mixed'].map((t) {
                    final selected = _type == t;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected ? _kRed : Colors.grey[100],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? _kRed : Colors.grey[300]!),
                          ),
                          child: Text(t[0].toUpperCase() + t.substring(1),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: selected ? Colors.white : Colors.grey[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12)),
                        ),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 14),

                  Row(children: [
                    Expanded(child: _buildField('Goal Value', _goalCtrl, hint: '30', keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Unit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _unit,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: _kRed)),
                          ),
                          items: ['reps', 'days', 'km', 'minutes', 'calories', 'kg']
                              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                              .toList(),
                          onChanged: (v) => setState(() => _unit = v!),
                        ),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  // Dates
                  Row(children: [
                    Expanded(child: _DateTile(label: 'Start', date: _startDate, onTap: () => _pickDate(true))),
                    const SizedBox(width: 12),
                    Expanded(child: _DateTile(label: 'End', date: _endDate, onTap: () => _pickDate(false))),
                  ]),
                  const SizedBox(height: 16),

                  // Tasks
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Daily Tasks (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    TextButton.icon(
                      onPressed: () => setState(() => _taskControllers.add(TextEditingController())),
                      icon: const Icon(Icons.add, size: 16, color: _kRed),
                      label: const Text('Add', style: TextStyle(color: _kRed, fontSize: 12)),
                    ),
                  ]),
                  ..._taskControllers.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(children: [
                          Expanded(
                            child: TextFormField(
                              controller: e.value,
                              decoration: InputDecoration(
                                hintText: 'Task ${e.key + 1}',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: _kRed)),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                            onPressed: () => setState(() {
                              e.value.dispose();
                              _taskControllers.removeAt(e.key);
                            }),
                          ),
                        ]),
                      )),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Create Challenge',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {String? hint, int maxLines = 1, TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kRed)),
        ),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    ]);
  }
}

class _DateTile extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 15, color: _kRed),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            Text(fmt, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ]),
      ),
    );
  }
}
