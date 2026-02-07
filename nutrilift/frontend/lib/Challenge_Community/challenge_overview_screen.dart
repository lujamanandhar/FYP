import 'package:flutter/material.dart';
import '../models/challenge_models.dart';
import '../services/challenge_service.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_details_screen.dart';
import 'active_challenge_screen.dart';
import 'community_feed_screen.dart';

class ChallengeOverviewScreen extends StatefulWidget {
  const ChallengeOverviewScreen({super.key});

  @override
  State<ChallengeOverviewScreen> createState() => _ChallengeOverviewScreenState();
}

class _ChallengeOverviewScreenState extends State<ChallengeOverviewScreen> {
  @override
  Widget build(BuildContext context) {
    final activeChallenge = ChallengeService.getActiveChallenge();
    final availableChallenges = ChallengeService.getAvailableChallenges();

    return NutriLiftScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ChallengeHeaderTabs(selected: 0),
            const SizedBox(height: 16),
            
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
              // Navigate to Challenges tab
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
              // Go back to Community tab (pop the challenge screen)
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

class _ChallengeOverviewCard extends StatelessWidget {
  const _ChallengeOverviewCard();

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '30 Days Fitness Challenge',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'February 1 - February 30, 2025',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              'Transform your lifestyle with our comprehensive 30-day challenge. Focus on nutrition, exercise, and mindful habits.',
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Basic Rules',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            const _BulletRow(text: 'Log meals daily'),
            const _BulletRow(text: 'Complete daily challenges'),
            const _BulletRow(text: 'Share progress weekly'),
          ],
        ),
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  final String text;
  const _BulletRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, size: 6),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    );
  }
}
