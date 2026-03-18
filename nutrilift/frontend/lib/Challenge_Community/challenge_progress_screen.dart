import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_api_service.dart';
import 'challenge_provider.dart';

const Color _kRed = Color(0xFFE53935);
const Color _kGreen = Color(0xFF4CAF50);

class ChallengeProgressScreen extends StatefulWidget {
  final ChallengeModel challenge;
  const ChallengeProgressScreen({super.key, required this.challenge});

  @override
  State<ChallengeProgressScreen> createState() =>
      _ChallengeProgressScreenState();
}

class _ChallengeProgressScreenState extends State<ChallengeProgressScreen> {
  List<ChallengeDailyLogModel> _logs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() { _loading = true; _error = null; });
    try {
      final logs = await ChallengeApiService().fetchAllDailyLogs(widget.challenge.id);
      if (mounted) setState(() => _logs = logs);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _typeColor(String t) {
    switch (t) {
      case 'nutrition': return Colors.green;
      case 'workout': return Colors.orange;
      default: return Colors.purple;
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
            onRefresh: _fetchLogs,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary card ──────────────────────────────────────
                  Card(
                    elevation: 4,
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
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 12,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(tc),
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
                                style: TextStyle(color: tc, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(children: [
                            _StatChip(icon: Icons.check_circle_outline, label: 'Days Done', value: '$daysDone', color: _kGreen),
                            const SizedBox(width: 10),
                            _StatChip(icon: Icons.calendar_today, label: 'Total Days', value: '$daysTotal', color: tc),
                            const SizedBox(width: 10),
                            _StatChip(icon: Icons.hourglass_bottom, label: 'Days Left', value: '${daysLeft < 0 ? 0 : daysLeft}', color: Colors.orange),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Daily Log History',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: _kRed)))
                  else if (_error != null)
                    Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.error_outline, size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _fetchLogs,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white),
                        ),
                      ]),
                    )
                  else if (_logs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.history, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('No logs yet.\nComplete your first day to see history!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500])),
                        ]),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) =>
                          _DayLogTile(log: _logs[index], typeColor: tc),
                    ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

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

class _DayLogTile extends StatelessWidget {
  final ChallengeDailyLogModel log;
  final Color typeColor;
  const _DayLogTile({required this.log, required this.typeColor});

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
                child: const Text('Done ✓',
                    style: TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.bold)),
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