import 'package:flutter/material.dart';
import '../widgets/nutrilift_header.dart';
import 'challenge_overview_screen.dart';
import 'challenge_complete_screen.dart';

class ChallengeProgressScreen extends StatelessWidget {
  const ChallengeProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return NutriLiftScaffold(
      title: 'NUTRILIFT',
      showBackButton: true,
      showDrawer: false,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const ChallengeHeaderTabs(selected: 0),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '30 Days Fitness Challenge',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
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
                        value: 29 / 30,
                        minHeight: 10,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '29 Days Completed  •  1 Day Remaining',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Today\'s Task',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 12),
            const _TaskTile(
              title: 'Morning Workout',
              status: 'Completed',
              isCompleted: true,
            ),
            const _TaskTile(
              title: 'Protein Intake',
              status: 'Pending',
              isCompleted: false,
            ),
            const _TaskTile(
              title: 'Water Intake',
              status: 'Pending',
              isCompleted: false,
            ),
            const _TaskTile(
              title: 'Evening Walk',
              status: 'Pending',
              isCompleted: false,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChallengeCompleteScreen(),
                    ),
                  );
                },
                child: const Text('Complete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final String title;
  final String status;
  final bool isCompleted;

  const _TaskTile({
    required this.title,
    required this.status,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (_) {},
        ),
        title: Text(title),
        trailing: Text(
          status,
          style: TextStyle(
            color: isCompleted ? color : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
