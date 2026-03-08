import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../widgets/nutrilift_header.dart';
import '../widgets/pr_card.dart';
import '../providers/personal_records_provider.dart';
import '../models/personal_record.dart';

/// Personal Records Screen
/// 
/// Displays all personal records achieved by the user in a grid layout.
/// Features:
/// - Pull-to-refresh functionality
/// - Grid layout of PR cards
/// - Progress indicators for improvements
/// - Share functionality for PRs
/// - Navigation to workout history filtered by exercise
/// 
/// Validates: Requirements 4.1
class PersonalRecordsScreen extends ConsumerWidget {
  const PersonalRecordsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personalRecordsState = ref.watch(personalRecordsProvider);

    return NutriLiftScaffold(
      title: 'Personal Records',
      showBackButton: true,
      body: RefreshIndicator(
        onRefresh: () => _handleRefresh(ref),
        color: const Color(0xFFE53935),
        child: personalRecordsState.when(
          data: (records) => _buildRecordsGrid(context, ref, records),
          loading: () => _buildLoadingState(),
          error: (error, stack) => _buildErrorState(context, ref, error),
        ),
      ),
    );
  }

  /// Build personal records grid
  Widget _buildRecordsGrid(BuildContext context, WidgetRef ref, List<PersonalRecord> records) {
    if (records.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) {
        return PRCard(
          personalRecord: records[index],
          onTap: () => _navigateToWorkoutHistory(context, records[index]),
          onShare: () => _sharePersonalRecord(context, records[index]),
        );
      },
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
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
                'No Personal Records Yet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start logging workouts to track your personal bests',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context, WidgetRef ref, Object error) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
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
                'Failed to Load Records',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _handleRefresh(ref),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle pull-to-refresh
  Future<void> _handleRefresh(WidgetRef ref) async {
    await ref.read(personalRecordsProvider.notifier).refresh();
  }

  /// Navigate to workout history filtered by exercise
  /// 
  /// Navigates to the workout history screen and filters workouts
  /// to show only those containing the selected exercise.
  /// 
  /// Validates: Requirements 4.4
  void _navigateToWorkoutHistory(BuildContext context, PersonalRecord record) {
    // Navigate to workout history screen
    // The workout history screen will need to support exercise filtering
    Navigator.of(context).pushNamed(
      '/workout-history',
      arguments: {
        'exerciseId': record.exerciseId,
        'exerciseName': record.exerciseName,
      },
    );
  }

  /// Share personal record
  /// 
  /// Generates a shareable message with PR details and opens
  /// the system share dialog.
  /// 
  /// Validates: Requirements 4.5
  void _sharePersonalRecord(BuildContext context, PersonalRecord record) {
    final message = _generateShareMessage(record);
    
    Share.share(
      message,
      subject: 'Personal Record Achievement - ${record.exerciseName}',
    );
  }

  /// Generate share message for a personal record
  /// 
  /// Creates a formatted message containing:
  /// - Exercise name
  /// - Max weight, reps, and volume
  /// - Date achieved
  /// - Improvement percentage (if available)
  /// 
  /// Validates: Requirements 4.5
  String _generateShareMessage(PersonalRecord record) {
    final dateStr = DateFormat('MMMM dd, yyyy').format(record.achievedDate);
    final buffer = StringBuffer();
    
    buffer.writeln('🏆 New Personal Record! 🏆');
    buffer.writeln();
    buffer.writeln('Exercise: ${record.exerciseName}');
    buffer.writeln('Max Weight: ${record.maxWeight.toStringAsFixed(1)} kg');
    buffer.writeln('Max Reps: ${record.maxReps}');
    buffer.writeln('Max Volume: ${record.maxVolume.toStringAsFixed(0)} kg');
    buffer.writeln('Achieved: $dateStr');
    
    if (record.improvementPercentage != null && record.improvementPercentage! > 0) {
      buffer.writeln();
      buffer.writeln('Improvement: +${record.improvementPercentage!.toStringAsFixed(1)}%');
    }
    
    buffer.writeln();
    buffer.writeln('Tracked with NutriLift 💪');
    
    return buffer.toString();
  }
}
