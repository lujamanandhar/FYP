import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_provider.dart';
import 'challenge_api_service.dart';

const Color _kRed = Color(0xFFE53935);

/// Screen showing the user's streak and earned badges.
class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<ChallengeProvider>();
      p.fetchStreak();
      p.fetchBadges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Achievements',
      showBackButton: true,
      showDrawer: false,
      body: Consumer<ChallengeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.streak == null) {
            return const Center(child: CircularProgressIndicator(color: _kRed));
          }
          if (provider.error != null && provider.streak == null) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(provider.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    provider.fetchStreak();
                    provider.fetchBadges();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kRed, foregroundColor: Colors.white),
                  child: const Text('Retry'),
                ),
              ]),
            );
          }
          return RefreshIndicator(
            color: _kRed,
            onRefresh: () async {
              await provider.fetchStreak();
              await provider.fetchBadges();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.streak != null)
                  _StreakCard(streak: provider.streak!),
                const SizedBox(height: 24),
                const Text('Badges',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                provider.badges.isEmpty
                    ? const _EmptyBadgesPlaceholder()
                    : _BadgesGrid(badges: provider.badges),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final StreakModel streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 40),
              const SizedBox(width: 8),
              Text(
                '${streak.currentStreak}',
                style: const TextStyle(
                    fontSize: 56, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ]),
            const Text('Day Streak',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              const SizedBox(width: 6),
              Text(
                'Longest streak: ${streak.longestStreak} days',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _BadgesGrid extends StatelessWidget {
  final List<BadgeModel> badges;
  const _BadgesGrid({required this.badges});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) => _BadgeTile(badge: badges[index]),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeModel badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: Colors.amber[100],
          backgroundImage:
              badge.iconUrl.isNotEmpty ? NetworkImage(badge.iconUrl) : null,
          child: badge.iconUrl.isEmpty
              ? const Icon(Icons.military_tech, size: 32, color: Colors.amber)
              : null,
        ),
        const SizedBox(height: 6),
        Text(badge.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text('+${badge.pointsReward} pts',
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _EmptyBadgesPlaceholder extends StatelessWidget {
  const _EmptyBadgesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(children: [
          Icon(Icons.military_tech_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('Complete challenges to earn badges',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
