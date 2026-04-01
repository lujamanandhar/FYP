import 'package:flutter/material.dart';
import '../services/streak_service.dart';

/// Reusable streak overview showing workout, nutrition, and challenge streaks.
/// Can be used as a bottom sheet, dialog, or inline widget.
class StreakOverviewWidget extends StatelessWidget {
  final AllStreaks streaks;

  const StreakOverviewWidget({Key? key, required this.streaks}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StreakCard(
          icon: '🔥💪',
          label: 'Workout Streak',
          current: streaks.workout.currentStreak,
          longest: streaks.workout.longestStreak,
          color: const Color(0xFFE53935),
          bgColor: const Color(0xFFFFEBEE),
        ),
        const SizedBox(height: 12),
        _StreakCard(
          icon: '🔥🍎',
          label: 'Nutrition Streak',
          current: streaks.nutrition.currentStreak,
          longest: streaks.nutrition.longestStreak,
          color: const Color(0xFF43A047),
          bgColor: const Color(0xFFE8F5E9),
        ),
        const SizedBox(height: 12),
        _StreakCard(
          icon: '🔥🏆',
          label: 'Challenge Streak',
          current: streaks.challenge.currentStreak,
          longest: streaks.challenge.longestStreak,
          color: const Color(0xFFFB8C00),
          bgColor: const Color(0xFFFFF3E0),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  final String icon;
  final String label;
  final int current;
  final int longest;
  final Color color;
  final Color bgColor;

  const _StreakCard({
    required this.icon,
    required this.label,
    required this.current,
    required this.longest,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color)),
                const SizedBox(height: 2),
                Text(
                  current > 0
                      ? '🔥 $current-day streak!'
                      : 'No active streak',
                  style: TextStyle(
                      fontSize: 12,
                      color: current > 0 ? color : Colors.grey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$current',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text('Best: $longest',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }
}

/// Shows the streak overview as a bottom sheet
void showStreakOverview(BuildContext context, AllStreaks streaks) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '🔥 My Streaks',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep it up! Log daily to maintain your streaks.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
          const SizedBox(height: 20),
          StreakOverviewWidget(streaks: streaks),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Compact streak badge for use in page headers
class StreakBadge extends StatelessWidget {
  final int count;
  final Color color;
  final String emoji;
  final VoidCallback? onTap;

  const StreakBadge({
    Key? key,
    required this.count,
    this.color = const Color(0xFFFF6F00),
    this.emoji = '🔥',
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: count > 0
              ? LinearGradient(colors: [color, color.withOpacity(0.7)])
              : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[400]!]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: count > 0 ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
