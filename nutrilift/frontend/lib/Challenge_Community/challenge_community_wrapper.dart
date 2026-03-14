import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_provider.dart';
import 'challenge_api_service.dart';
import 'challenge_details_screen.dart';
import 'community_provider.dart';
import 'community_feed_screen.dart';

/// Wrapper screen that contains both Challenge and Community tabs
/// This ensures the bottom navigation bar is always visible
class ChallengeCommunityWrapper extends StatefulWidget {
  const ChallengeCommunityWrapper({Key? key}) : super(key: key);

  @override
  State<ChallengeCommunityWrapper> createState() => _ChallengeCommunityWrapperState();
}

class _ChallengeCommunityWrapperState extends State<ChallengeCommunityWrapper> {
  int _selectedTab = 1; // Default to Community tab

  void _switchTab(int index) {
    setState(() {
      _selectedTab = index;
    });
    if (index == 0) {
      context.read<ChallengeProvider>().fetchChallenges();
    } else if (index == 1) {
      context.read<CommunityProvider>().fetchFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      body: Column(
        children: [
          // Tab Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _TabHeader(
              selectedTab: _selectedTab,
              onTabSelected: _switchTab,
            ),
          ),
          // Tab Content
          Expanded(
            child: _selectedTab == 0
                ? const _ChallengeTabContent()
                : const _CommunityTabContent(),
          ),
        ],
      ),
    );
  }
}

class _TabHeader extends StatelessWidget {
  final int selectedTab;
  final Function(int) onTabSelected;

  const _TabHeader({
    required this.selectedTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        GestureDetector(
          onTap: () => onTabSelected(0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selectedTab == 0 ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Challenges',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selectedTab == 0 ? color : Colors.grey[500],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => onTabSelected(1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selectedTab == 1 ? color.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Community',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selectedTab == 1 ? color : Colors.grey[500],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Challenge Tab Content ────────────────────────────────────────────────────

class _ChallengeTabContent extends StatefulWidget {
  const _ChallengeTabContent();

  @override
  State<_ChallengeTabContent> createState() => _ChallengeTabContentState();
}

class _ChallengeTabContentState extends State<_ChallengeTabContent> {
  @override
  void initState() {
    super.initState();
    // Fetch challenges on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChallengeProvider>().fetchChallenges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChallengeProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
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

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available Challenges',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                      onJoin: () => provider.joinChallenge(challenge.id),
                      onLeave: () => provider.leaveChallenge(challenge.id),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
    final now = DateTime.now();
    final diff = challenge.endDate.difference(now).inDays;
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
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

// ─── Community Tab Content ────────────────────────────────────────────────────

/// Delegates to [CommunityFeedScreen] which is wired to [CommunityProvider].
class _CommunityTabContent extends StatelessWidget {
  const _CommunityTabContent();

  @override
  Widget build(BuildContext context) {
    return const CommunityFeedScreen();
  }
}
