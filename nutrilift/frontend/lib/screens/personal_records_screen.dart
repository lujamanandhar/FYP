import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../widgets/nutrilift_header.dart';
import '../widgets/pr_card.dart';
import '../providers/personal_records_provider.dart';

/// Personal Records Screen
/// 
/// Displays all personal records achieved by the user.
/// Features:
/// - Grid layout of PR cards
/// - Progress indicators for improvements
/// - Share functionality
/// - Navigation to filtered workout history
/// 
/// Validates: Requirements 4.1
class PersonalRecordsScreen extends ConsumerWidget {
  const PersonalRecordsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prState = ref.watch(personalRecordsProvider);

    return NutriLiftScaffold(
      title: 'Personal Records',
      showBackButton: true,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(personalRecordsProvider.notifier).loadPersonalRecords();
        },
        color: const Color(0xFFE53935),
        child: prState.when(
          data: (prs) => _buildPRGrid(context, prs),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(context, ref, error),
        ),
      ),
    );
  }

  Widget _buildPRGrid(BuildContext context, List prs) {
    if (prs.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: prs.length,
      itemBuilder: (context, index) {
        return PRCard(
          pr: prs[index],
          onTap: () => _handlePRTap(context, prs[index]),
          onShare: () => _handleShare(context, prs[index]),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No personal records yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start logging workouts to track your PRs',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load personal records',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(personalRecordsProvider.notifier).loadPersonalRecords();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _handlePRTap(BuildContext context, dynamic pr) {
    // TODO: Navigate to workout history filtered by exercise
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing workouts for ${pr.exerciseName}'),
        backgroundColor: const Color(0xFFE53935),
      ),
    );
  }

  void _handleShare(BuildContext context, dynamic pr) {
    final message = _generateShareMessage(pr);
    
    // TODO: Implement actual sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share: $message'),
        backgroundColor: const Color(0xFFE53935),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _generateShareMessage(dynamic pr) {
    final date = DateFormat('MMM dd, yyyy').format(pr.achievedDate);
    return '🏆 New PR! ${pr.exerciseName}: ${pr.maxWeight}kg x ${pr.maxReps} reps (${pr.maxVolume}kg total volume) on $date #NutriLift';
  }
}
