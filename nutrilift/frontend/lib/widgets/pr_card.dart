import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/personal_record.dart';

/// Personal Record Card Widget
/// 
/// Displays a personal record in a card format.
/// Shows exercise name, max weight, max reps, max volume, date, and improvement.
/// 
/// Validates: Requirements 4.2, 4.3
class PRCard extends StatelessWidget {
  final PersonalRecord pr;
  final VoidCallback? onTap;
  final VoidCallback? onShare;

  const PRCard({
    Key? key,
    required this.pr,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.amber,
                    size: 24,
                  ),
                  if (onShare != null)
                    IconButton(
                      icon: const Icon(Icons.share, size: 18),
                      onPressed: onShare,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: Colors.grey[600],
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                pr.exerciseName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              _buildStatRow(
                icon: Icons.fitness_center,
                label: 'Max Weight',
                value: '${pr.maxWeight.toStringAsFixed(1)} kg',
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                icon: Icons.repeat,
                label: 'Max Reps',
                value: '${pr.maxReps}',
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                icon: Icons.trending_up,
                label: 'Max Volume',
                value: '${pr.maxVolume.toStringAsFixed(0)} kg',
              ),
              const SizedBox(height: 12),
              Text(
                DateFormat('MMM dd, yyyy').format(pr.achievedDate),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (pr.improvementPercentage != null && pr.improvementPercentage! > 0) ...[
                const SizedBox(height: 8),
                _buildImprovementIndicator(pr.improvementPercentage!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
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

  Widget _buildImprovementIndicator(double percentage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.arrow_upward,
              size: 12,
              color: Colors.green[700],
            ),
            const SizedBox(width: 4),
            Text(
              '+${percentage.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
