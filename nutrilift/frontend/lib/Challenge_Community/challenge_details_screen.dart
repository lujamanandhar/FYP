import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_provider.dart';
import 'challenge_api_service.dart';

class ChallengeDetailsScreen extends StatefulWidget {
  final ChallengeModel challenge;

  const ChallengeDetailsScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailsScreen> createState() => _ChallengeDetailsScreenState();
}

class _ChallengeDetailsScreenState extends State<ChallengeDetailsScreen> {
  List<ChallengeParticipantModel> _leaderboard = [];
  bool _leaderboardLoading = false;
  String? _leaderboardError;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() {
      _leaderboardLoading = true;
      _leaderboardError = null;
    });
    try {
      final service = ChallengeApiService();
      final data = await service.fetchLeaderboard(widget.challenge.id);
      if (mounted) {
        setState(() {
          _leaderboard = data;
          _leaderboardLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _leaderboardError = e.toString();
          _leaderboardLoading = false;
        });
      }
    }
  }

  int get _daysRemaining {
    final diff = widget.challenge.endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  double get _progressPercent {
    if (widget.challenge.goalValue <= 0) return 0;
    return (widget.challenge.participantProgress / widget.challenge.goalValue)
        .clamp(0.0, 1.0);
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'nutrition':
        return Colors.green;
      case 'workout':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final typeColor = _typeColor(challenge.challengeType);

    return NutriLiftScaffold(
      title: 'Challenge Details',
      showBackButton: true,
      showDrawer: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ──────────────────────────────────────────────
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            challenge.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Chip(
                          label: Text(
                            challenge.challengeType.toUpperCase(),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.white),
                          ),
                          backgroundColor: typeColor,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.description,
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    // Dates
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label:
                          'Start: ${_formatDate(challenge.startDate)}',
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.event,
                      label: 'End: ${_formatDate(challenge.endDate)}',
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.schedule,
                      label: '$_daysRemaining days remaining',
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.flag,
                      label:
                          'Goal: ${challenge.goalValue.toStringAsFixed(0)} ${challenge.unit}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Circular progress ────────────────────────────────────────
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Progress',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: _progressPercent,
                              strokeWidth: 10,
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(typeColor),
                            ),
                            Center(
                              child: Text(
                                '${(_progressPercent * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '${challenge.participantProgress.toStringAsFixed(0)} / ${challenge.goalValue.toStringAsFixed(0)} ${challenge.unit}',
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Leaderboard ──────────────────────────────────────────────
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Leaderboard',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_leaderboardLoading)
                      const Center(
                          child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ))
                    else if (_leaderboardError != null)
                      Column(
                        children: [
                          Text(
                            _leaderboardError!,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          TextButton.icon(
                            onPressed: _fetchLeaderboard,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      )
                    else if (_leaderboard.isEmpty)
                      const Text(
                        'No participants yet.',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _leaderboard.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = _leaderboard[index];
                          return _LeaderboardTile(entry: entry);
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── LEAVE button (if joined) ─────────────────────────────────
            Consumer<ChallengeProvider>(
              builder: (context, provider, _) {
                // Reflect the latest joined state from provider if available
                final current = provider.challenges.firstWhere(
                  (c) => c.id == challenge.id,
                  orElse: () => challenge,
                );
                if (!current.isJoined) return const SizedBox.shrink();
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await provider.leaveChallenge(challenge.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Left challenge successfully')),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'LEAVE',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(color: Colors.grey[700], fontSize: 13)),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final ChallengeParticipantModel entry;

  const _LeaderboardTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    Color rankColor;
    switch (entry.rank) {
      case 1:
        rankColor = const Color(0xFFFFD700); // gold
        break;
      case 2:
        rankColor = const Color(0xFFC0C0C0); // silver
        break;
      case 3:
        rankColor = const Color(0xFFCD7F32); // bronze
        break;
      default:
        rankColor = Colors.grey;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: rankColor.withOpacity(0.2),
        child: Text(
          '#${entry.rank}',
          style: TextStyle(
              color: rankColor,
              fontWeight: FontWeight.bold,
              fontSize: 13),
        ),
      ),
      title: Text(entry.username,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: Text(
        '${entry.progress.toStringAsFixed(0)}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
