import 'package:flutter/material.dart';
import '../models/challenge_models.dart';
import '../services/challenge_service.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_details_screen.dart';
import 'active_challenge_screen.dart';
import 'comments_screen.dart';
import 'community_feed_screen.dart' show CommunityPost;

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

// Challenge Tab Content
class _ChallengeTabContent extends StatefulWidget {
  const _ChallengeTabContent();

  @override
  State<_ChallengeTabContent> createState() => _ChallengeTabContentState();
}

class _ChallengeTabContentState extends State<_ChallengeTabContent> {
  @override
  Widget build(BuildContext context) {
    final activeChallenge = ChallengeService.getActiveChallenge();
    final availableChallenges = ChallengeService.getAvailableChallenges();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Challenge Section
          if (activeChallenge != null) ...[
            Text(
              'Active Challenge',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _ActiveChallengeCard(challenge: activeChallenge),
            const SizedBox(height: 24),
          ],

          // Available Challenges Section
          Text(
            activeChallenge != null ? 'Other Challenges' : 'Available Challenges',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          Expanded(
            child: availableChallenges.isEmpty
                ? const Center(
                    child: Text(
                      'No challenges available at the moment',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: availableChallenges.length,
                    itemBuilder: (context, index) {
                      final challenge = availableChallenges[index];
                      return _ChallengeCard(
                        challenge: challenge,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChallengeDetailsScreen(challenge: challenge),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const _ActiveChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ActiveChallengeScreen(),
            ),
          );
        },
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
                      challenge.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Active',
                      style: TextStyle(
                        color: Colors.red,
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
                  value: challenge.progressPercentage,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Day ${challenge.currentDay} of ${challenge.durationDays}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to view today\'s tasks',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.challenge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
              Text(
                challenge.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                challenge.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.durationDays} days',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Tap to view details',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
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

// Community Tab Content
class _CommunityTabContent extends StatelessWidget {
  const _CommunityTabContent();

  @override
  Widget build(BuildContext context) {
    final posts = [
      CommunityPost(
        username: 'c_bum',
        role: 'Coach',
        time: '34 min ago',
        content:
            'Just completed my intense arm workout. Time to destroy leg tomorrow. #ArmDay #Gym',
      ),
      CommunityPost(
        username: 'luja_manandhar',
        role: 'User',
        time: '1 hr ago',
        content: '4 times in a row!!!',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _PostCard(post: post);
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text(post.username),
            subtitle: Text(post.role),
            trailing: Text(
              post.time,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Container(
            height: 200,
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.image, size: 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(post.content),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CommentsScreen(post: post),
                      ),
                    );
                  },
                ),
                const Spacer(),
                Text(
                  'View all comments',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
