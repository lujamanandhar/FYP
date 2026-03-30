import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/personal_record.dart';

/// Personal Record Card Widget
/// 
/// Displays a personal record in a card format with:
/// - Exercise name
/// - Max weight, reps, and volume
/// - Date achieved
/// - Progress indicator if improvement data exists
/// - Share button
/// 
/// Validates: Requirements 4.2, 4.3, 4.5
class PRCard extends StatelessWidget {
  final PersonalRecord personalRecord;
  final VoidCallback? onTap;
  final VoidCallback? onShare;

  const PRCard({
    Key? key,
    required this.personalRecord,
    this.onTap,
    this.onShare,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with trophy icon and share button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Color(0xFFE53935),
                    size: 24,
                  ),
                  if (onShare != null)
                    IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: onShare,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.grey[600],
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Exercise name
              Text(
                personalRecord.exerciseName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Max weight
              _buildStatRow(
                icon: Icons.fitness_center,
                label: 'Max Weight',
                value: '${personalRecord.maxWeight.toStringAsFixed(1)} kg',
              ),
              const SizedBox(height: 8),

              // Max reps
              _buildStatRow(
                icon: Icons.repeat,
                label: 'Max Reps',
                value: '${personalRecord.maxReps}',
              ),
              const SizedBox(height: 8),

              // Max volume
              _buildStatRow(
                icon: Icons.trending_up,
                label: 'Max Volume',
                value: '${personalRecord.maxVolume.toStringAsFixed(0)} kg',
              ),
              const SizedBox(height: 12),

              // Date achieved
              Text(
                'Achieved: ${_formatDate(personalRecord.achievedDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),

              // Progress indicator if improvement exists
              if (personalRecord.improvementPercentage != null &&
                  personalRecord.improvementPercentage! > 0) ...[
                const SizedBox(height: 12),
                _buildProgressIndicator(personalRecord.improvementPercentage!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build a stat row with icon, label, and value
  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build progress indicator showing improvement percentage
  ///
  /// Validates: Requirements 4.3
  Widget _buildProgressIndicator(double improvementPercentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Improvement',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '+${improvementPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE53935),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (improvementPercentage / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  /// Format date for display
  /// Converts UTC time to local time before formatting
  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return DateFormat('MMM dd, yyyy').format(localDate);
  }
}
