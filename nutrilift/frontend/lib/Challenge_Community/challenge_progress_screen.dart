import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_api_service.dart';
import 'challenge_provider.dart';

const Color _kRed = Color(0xFFE53935);
const Color _kGreen = Color(0xFF4CAF50);
const Color _kGold = Color(0xFFFFC107);

class ChallengeProgressScreen extends StatefulWidget {
  final ChallengeModel challenge;
  const ChallengeProgressScreen({super.key, required this.challenge});

  @override
  State<ChallengeProgressScreen> createState() => _ChallengeProgressScreenState();
}

class _ChallengeProgressScreenState extends State<ChallengeProgressScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _innerTabController;

  List<ChallengeDailyLogModel> _logs = [];
  bool _logsLoading = true;
  String? _logsError;

  List<ChallengeParticipantModel> _leaderboard = [];
  bool _lbLoading = true;
  String? _lbError;

  @override
  void initState() {
    super.initState();
    _innerTabController = TabController(length: 2, vsync: this);
    _fetchLogs();
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    _innerTabController.dispose();
    super.dispose();
  }

  Future<void> _fetchLogs() async {
    setState(() { _logsLoading = true; _logsError = null; });
    try {
      final logs = await ChallengeApiService().fetchAllDailyLogs(widget.challenge.id);
      if (mounted) setState(() => _logs = logs);
    } catch (e) {
      if (mounted) setState(() => _logsError = e.toString());
    } finally {
      if (mounted) setState(() => _logsLoading = false);
    }
  }

  Future<void> _fetchLeaderboard() async {
    setState(() { _lbLoading = true; _lbError = null; });
    try {
      final lb = await ChallengeApiService().fetchLeaderboard(widget.challenge.id);
      if (mounted) setState(() => _leaderboard = lb);
    } catch (e) {
      if (mounted) setState(() => _lbError = e.toString());
    } finally {
      if (mounted) setState(() => _lbLoading = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_fetchLogs(), _fetchLeaderboard()]);
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'nutrition': return const Color(0xFF43A047);
      case 'workout': return const Color(0xFFFF7043);
      default: return const Color(0xFF7E57C2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, _) {
        final live = provider.challenges.firstWhere(
          (c) => c.id == widget.challenge.id,
          orElse: () => widget.challenge,
        );
        final tc = _typeColor(live.challengeType);
        final progress = live.goalValue > 0
            ? (live.participantProgress / live.goalValue).clamp(0.0, 1.0)
            : 0.0;
        final daysTotal = live.endDate.difference(live.startDate).inDays + 1;
        final daysLeft = live.endDate.difference(DateTime.now()).inDays;
        final daysDone = live.participantProgress.toInt();

        return NutriLiftScaffold(
          title: 'My Progress',
          showBackButton: true,
          showDrawer: false,
          body: RefreshIndicator(
            color: _kRed,
            onRefresh: _refresh,
            child: Column(
              children: [
                // ── Summary card ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(live.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                          const SizedBox(height: 4),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tc.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(live.challengeType.toUpperCase(),
                                  style: TextStyle(color: tc, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.schedule, size: 13, color: Colors.grey[500]),
                            const SizedBox(width: 3),
                            Text('${daysLeft < 0 ? 0 : daysLeft} days left',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                          ]),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(_kRed),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${live.participantProgress.toStringAsFixed(0)} / ${live.goalValue.toStringAsFixed(0)} ${live.unit}',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(color: _kRed, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(children: [
                            _StatChip(icon: Icons.check_circle_outline, label: 'Days Done', value: '$daysDone', color: _kGreen),
                            const SizedBox(width: 8),
                            _StatChip(icon: Icons.calendar_today, label: 'Total Days', value: '$daysTotal', color: _kRed),
                            const SizedBox(width: 8),
                            _StatChip(icon: Icons.hourglass_bottom, label: 'Days Left', value: '${daysLeft < 0 ? 0 : daysLeft}', color: Colors.orange),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Inner tab bar: Daily Log | Leaderboard ────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TabBar(
                      controller: _innerTabController,
                      indicator: BoxDecoration(
                        color: _kRed,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [BoxShadow(color: _kRed.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Daily Log History'),
                        Tab(text: 'Leaderboard'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Tab content ───────────────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _innerTabController,
                    children: [
                      _DailyLogTab(
                        logs: _logs,
                        loading: _logsLoading,
                        error: _logsError,
                        onRetry: _fetchLogs,
                      ),
                      _LeaderboardTab(
                        leaderboard: _leaderboard,
                        loading: _lbLoading,
                        error: _lbError,
                        onRetry: _fetchLeaderboard,
                        currentUserId: provider.currentUserId,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 10), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

// ─── Daily Log Tab ────────────────────────────────────────────────────────────
class _DailyLogTab extends StatelessWidget {
  final List<ChallengeDailyLogModel> logs;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  const _DailyLogTab({required this.logs, required this.loading, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _kRed));
    }
    if (error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
          ),
        ]),
      );
    }
    if (logs.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.history, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No logs yet.\nComplete your first day to see history!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500])),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: logs.length,
      itemBuilder: (context, index) => _DayLogTile(log: logs[index]),
    );
  }
}

// ─── Leaderboard Tab ──────────────────────────────────────────────────────────
class _LeaderboardTab extends StatelessWidget {
  final List<ChallengeParticipantModel> leaderboard;
  final bool loading;
  final String? error;
  final VoidCallback onRetry;
  final String? currentUserId;
  const _LeaderboardTab({
    required this.leaderboard,
    required this.loading,
    required this.error,
    required this.onRetry,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator(color: _kRed));
    }
    if (error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.grey),
          const SizedBox(height: 8),
          Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
          ),
        ]),
      );
    }
    if (leaderboard.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('No participants yet.', style: TextStyle(color: Colors.grey[500])),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final p = leaderboard[index];
        final isMe = p.userId == currentUserId;
        final rankColor = p.rank == 1
            ? _kGold
            : p.rank == 2
                ? Colors.grey[400]!
                : p.rank == 3
                    ? const Color(0xFFCD7F32)
                    : Colors.grey[300]!;
        final rankIcon = p.rank == 1
            ? Icons.emoji_events_rounded
            : p.rank == 2
                ? Icons.workspace_premium_rounded
                : p.rank == 3
                    ? Icons.military_tech_rounded
                    : null;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isMe ? _kRed.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMe ? _kRed.withOpacity(0.3) : Colors.grey[200]!,
              width: isMe ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: rankColor.withOpacity(0.2),
                  backgroundImage: p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
                  child: p.avatarUrl == null
                      ? Text(p.username.isNotEmpty ? p.username[0].toUpperCase() : '?',
                          style: TextStyle(color: rankColor, fontWeight: FontWeight.bold, fontSize: 16))
                      : null,
                ),
                if (rankIcon != null)
                  Positioned(
                    bottom: -4, right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(rankIcon, size: 14, color: rankColor),
                    ),
                  ),
              ],
            ),
            title: Row(children: [
              Text(p.username,
                  style: TextStyle(
                    fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                    fontSize: 14,
                    color: isMe ? _kRed : Colors.black87,
                  )),
              if (isMe) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
            subtitle: Text('${p.progress.toStringAsFixed(0)} pts',
                style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            trailing: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rankColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text('#${p.rank}',
                    style: TextStyle(
                      color: p.rank <= 3 ? rankColor : Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    )),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Day Log Tile ─────────────────────────────────────────────────────────────
class _DayLogTile extends StatelessWidget {
  final ChallengeDailyLogModel log;
  const _DayLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final completedTasks = log.taskItems.where((t) => t.completed).length;
    final totalTasks = log.taskItems.length;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: log.isComplete ? _kGreen.withOpacity(0.15) : Colors.grey[100],
          child: Icon(
            log.isComplete ? Icons.check : Icons.radio_button_unchecked,
            color: log.isComplete ? _kGreen : Colors.grey[400],
            size: 18,
          ),
        ),
        title: Text('Day ${log.dayNumber}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          log.isComplete
              ? (totalTasks > 0 ? '$completedTasks/$totalTasks tasks done' : 'Completed')
              : 'Not completed',
          style: TextStyle(fontSize: 12, color: log.isComplete ? _kGreen : Colors.grey[500]),
        ),
        trailing: log.isComplete
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _kGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Done', style: TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.bold)),
              )
            : null,
        children: [
          if (log.taskItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tasks:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  ...log.taskItems.map((task) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(children: [
                          Icon(
                            task.completed ? Icons.check_box : Icons.check_box_outline_blank,
                            size: 16,
                            color: task.completed ? _kGreen : Colors.grey[400],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(task.label,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: task.completed ? Colors.black87 : Colors.grey[600],
                                    decoration: task.completed ? TextDecoration.lineThrough : null)),
                          ),
                        ]),
                      )),
                ],
              ),
            ),
          if (log.mediaUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Media:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: log.mediaUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (_, i) {
                        final m = log.mediaUrls[i];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: m.isVideo
                              ? Container(
                                  width: 70, height: 70,
                                  color: Colors.black87,
                                  child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 28),
                                )
                              : Image.network(m.url, width: 70, height: 70, fit: BoxFit.cover),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          if (log.taskItems.isEmpty && log.mediaUrls.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text('No tasks or media for this day.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13)),
            ),
        ],
      ),
    );
  }
}