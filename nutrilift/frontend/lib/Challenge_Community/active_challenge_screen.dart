import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_provider.dart';
import 'challenge_api_service.dart';

class ActiveChallengeScreen extends StatefulWidget {
  /// Optionally pass a specific challenge ID to display.
  /// If null, the first joined challenge from the provider is shown.
  final String? challengeId;

  const ActiveChallengeScreen({super.key, this.challengeId});

  @override
  State<ActiveChallengeScreen> createState() => _ActiveChallengeScreenState();
}

class _ActiveChallengeScreenState extends State<ActiveChallengeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChallengeProvider>();
      if (provider.challenges.isEmpty) {
        provider.fetchChallenges();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return NutriLiftScaffold(
            title: 'Active Challenge',
            showBackButton: true,
            showDrawer: false,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // Find the active challenge: by ID if provided, otherwise first joined
        ChallengeModel? activeChallenge;
        if (widget.challengeId != null) {
          try {
            activeChallenge = provider.challenges
                .firstWhere((c) => c.id == widget.challengeId);
          } catch (_) {
            activeChallenge = null;
          }
        } else {
          try {
            activeChallenge =
                provider.challenges.firstWhere((c) => c.isJoined);
          } catch (_) {
            activeChallenge = null;
          }
        }

        if (activeChallenge == null) {
          return NutriLiftScaffold(
            title: 'Active Challenge',
            showBackButton: true,
            showDrawer: false,
            body: const Center(
              child: Text(
                'No active challenge found',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        }

        return _ActiveChallengeBody(challenge: activeChallenge);
      },
    );
  }
}

class _ActiveChallengeBody extends StatelessWidget {
  final ChallengeModel challenge;

  const _ActiveChallengeBody({required this.challenge});

  int get _daysRemaining {
    final diff = challenge.endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  double get _progressValue {
    if (challenge.goalValue <= 0) return 0;
    return (challenge.participantProgress / challenge.goalValue)
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
    final typeColor = _typeColor(challenge.challengeType);

    return NutriLiftScaffold(
      title: 'Active Challenge',
      showBackButton: true,
      showDrawer: false,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Challenge progress card ──────────────────────────────────
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            challenge.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progressValue,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${challenge.participantProgress.toStringAsFixed(0)} / ${challenge.goalValue.toStringAsFixed(0)} ${challenge.unit}',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                        Text(
                          '$_daysRemaining days remaining',
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Participant stats ────────────────────────────────────────
            Text(
              'Challenge Info',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _StatRow(
                      icon: Icons.category,
                      label: 'Type',
                      value: challenge.challengeType.toUpperCase(),
                    ),
                    const Divider(),
                    _StatRow(
                      icon: Icons.flag,
                      label: 'Goal',
                      value:
                          '${challenge.goalValue.toStringAsFixed(0)} ${challenge.unit}',
                    ),
                    const Divider(),
                    _StatRow(
                      icon: Icons.trending_up,
                      label: 'Progress',
                      value:
                          '${(_progressValue * 100).toStringAsFixed(1)}%',
                    ),
                    const Divider(),
                    _StatRow(
                      icon: Icons.schedule,
                      label: 'Days Left',
                      value: '$_daysRemaining',
                    ),
                    const Divider(),
                    _StatRow(
                      icon: Icons.event,
                      label: 'Ends',
                      value: _formatDate(challenge.endDate),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── LEAVE button ─────────────────────────────────────────────
            Consumer<ChallengeProvider>(
              builder: (context, provider, _) {
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
                      'LEAVE CHALLENGE',
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

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
