import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/nutrilift_header.dart';
import '../services/dashboard_service.dart';
import 'challenge_provider.dart';
import 'challenge_overview_screen.dart';
import 'community_provider.dart';
import 'community_feed_screen.dart';

const Color _kRed = Color(0xFFE53935);

class ChallengeCommunityWrapper extends StatefulWidget {
  const ChallengeCommunityWrapper({Key? key}) : super(key: key);

  @override
  State<ChallengeCommunityWrapper> createState() =>
      _ChallengeCommunityWrapperState();
}

class _ChallengeCommunityWrapperState extends State<ChallengeCommunityWrapper> {
  int _selectedTab = 1;
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadStreak();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().fetchFeed();
    });
  }

  Future<void> _loadStreak() async {
    try {
      final dashboardService = DashboardService();
      final streak = await dashboardService.getCurrentStreak();
      if (mounted) {
        setState(() {
          _currentStreak = streak;
        });
      }
    } catch (e) {
      // Silently handle error
    }
  }

  void _switchTab(int index) {
    setState(() => _selectedTab = index);
    if (index == 0) {
      context.read<ChallengeProvider>().fetchChallenges();
    } else {
      context.read<CommunityProvider>().fetchFeed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      streakCount: _currentStreak,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _TabHeader(selectedTab: _selectedTab, onTabSelected: _switchTab),
          ),
          Expanded(
            child: _selectedTab == 0
                ? const ChallengeOverviewBody()
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
  const _TabHeader({required this.selectedTab, required this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        _tab(context, 'Challenges', 0, color),
        const SizedBox(width: 16),
        _tab(context, 'Community', 1, color),
      ],
    );
  }

  Widget _tab(BuildContext context, String label, int index, Color color) {
    final selected = selectedTab == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: selected ? color : Colors.grey[500])),
      ),
    );
  }
}

class _CommunityTabContent extends StatelessWidget {
  const _CommunityTabContent();
  @override
  Widget build(BuildContext context) => const CommunityFeedScreen();
}
