import 'package:flutter/material.dart';
import '../models/challenge_models.dart';
import '../services/challenge_service.dart';
import 'challenge_complete_screen.dart';

class ActiveChallengeScreen extends StatefulWidget {
  const ActiveChallengeScreen({super.key});

  @override
  State<ActiveChallengeScreen> createState() => _ActiveChallengeScreenState();
}

class _ActiveChallengeScreenState extends State<ActiveChallengeScreen> {
  Challenge? activeChallenge;

  @override
  void initState() {
    super.initState();
    _loadActiveChallenge();
  }

  void _loadActiveChallenge() {
    setState(() {
      activeChallenge = ChallengeService.getActiveChallenge();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (activeChallenge == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Active Challenge'),
        ),
        body: const Center(
          child: Text(
            'No active challenge found',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final completedTasks = activeChallenge!.todaysTasks.where((t) => t.isCompleted).length;
    final totalTasks = activeChallenge!.todaysTasks.length;
    final allTasksCompleted = completedTasks == totalTasks && totalTasks > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Tasks'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Challenge Progress Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            activeChallenge!.title,
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
                        value: activeChallenge!.progressPercentage,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Day ${activeChallenge!.currentDay} of ${activeChallenge!.durationDays}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Today's Tasks Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Tasks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completedTasks/$totalTasks completed',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tasks List
            Expanded(
              child: activeChallenge!.todaysTasks.isEmpty
                  ? const Center(
                      child: Text(
                        'No tasks for today',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: activeChallenge!.todaysTasks.length,
                      itemBuilder: (context, index) {
                        final task = activeChallenge!.todaysTasks[index];
                        return _TaskTile(
                          task: task,
                          onToggle: () => _toggleTask(task.id),
                        );
                      },
                    ),
            ),

            if (allTasksCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _completeDay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Complete Day',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleTask(String taskId) {
    ChallengeService.completeTask(activeChallenge!.id, taskId);
    _loadActiveChallenge();

    // Check if challenge is completed
    final updatedChallenge = ChallengeService.getActiveChallenge();
    if (updatedChallenge == null) {
      // Challenge completed, navigate to completion screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ChallengeCompleteScreen(),
        ),
      );
    }
  }

  void _completeDay() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Great Job!'),
          content: const Text('You\'ve completed all tasks for today. Ready for tomorrow?'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to challenge overview
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }
}

class _TaskTile extends StatelessWidget {
  final DailyTask task;
  final VoidCallback onToggle;

  const _TaskTile({
    required this.task,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggle(),
          activeColor: Colors.red,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          task.description,
          style: TextStyle(
            color: task.isCompleted ? Colors.grey : Colors.grey[600],
          ),
        ),
        trailing: _TaskTypeIcon(type: task.type),
        onTap: onToggle,
      ),
    );
  }
}

class _TaskTypeIcon extends StatelessWidget {
  final TaskType type;

  const _TaskTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (type) {
      case TaskType.workout:
        icon = Icons.fitness_center;
        color = Colors.orange;
        break;
      case TaskType.nutrition:
        icon = Icons.restaurant;
        color = Colors.green;
        break;
      case TaskType.hydration:
        icon = Icons.water_drop;
        color = Colors.blue;
        break;
      case TaskType.general:
        icon = Icons.task_alt;
        color = Colors.purple;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}