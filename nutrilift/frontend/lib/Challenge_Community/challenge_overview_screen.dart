import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_provider.dart';
import 'challenge_api_service.dart';
import 'challenge_details_screen.dart';
import 'community_feed_screen.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ChallengeHeaderTabs(selected: 0),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<ChallengeProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            provider.error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => provider.fetchChallenges(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final challenges = provider.challenges;

                  if (challenges.isEmpty) {
                    return const Center(
                      child: Text(
                        'No challenges available at the moment',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Challenges',
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: challenges.length,
                          itemBuilder: (context, index) {
                            final challenge = challenges[index];
                            return _ChallengeCard(
                              challenge: challenge,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChallengeDetailsScreen(
                                      challenge: challenge,
                                    ),
                                  ),
                                );
                              },
                              onJoin: () =>
                                  provider.joinChallenge(challenge.id),
                              onLeave: () =>
                                  provider.leaveChallenge(challenge.id),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Challenge Card ───────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  final VoidCallback onTap;
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const _ChallengeCard({
    required this.challenge,
    required this.onTap,
    required this.onJoin,
    required this.onLeave,
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
    return Card(
      elevation: 4,
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
              // Name + type badge
              Row(
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
                  Chip(
                    label: Text(
                      challenge.challengeType.toUpperCase(),
                      style: const TextStyle(fontSize: 11, color: Colors.white),
                    ),
                    backgroundColor: typeColor,
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Goal
              Text(
                'Goal: ${challenge.goalValue.toStringAsFixed(0)} ${challenge.unit}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 8),
              // Progress bar
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
              // Days remaining + JOIN/LEAVE button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '$_daysRemaining days remaining',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  challenge.isJoined
                      ? ElevatedButton(
                          onPressed: onLeave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE53935),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('LEAVE',
                              style: TextStyle(fontSize: 12)),
                        )
                      : ElevatedButton(
                          onPressed: onJoin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('JOIN',
                              style: TextStyle(fontSize: 12)),
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

// ─── Header Tabs ──────────────────────────────────────────────────────────────

class ChallengeHeaderTabs extends StatelessWidget {
  final int selected;
  const ChallengeHeaderTabs({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (selected != 0) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ChallengeOverviewScreen(),
                ),
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
            if (selected != 1) {
              Navigator.of(context).pop();
            }
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
    );
  }
}
