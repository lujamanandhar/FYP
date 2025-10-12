import 'package:flutter/material.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final List<Map<String, dynamic>> workouts = [
    {
      'name': 'Push Ups',
      'reps': '3 x 15',
      'desc': 'Great for chest, shoulders, and triceps.',
      'icon': Icons.push_pin,
      'completed': false,
    },
    {
      'name': 'Squats',
      'reps': '3 x 20',
      'desc': 'Strengthens legs and glutes.',
      'icon': Icons.directions_run,
      'completed': false,
    },
    {
      'name': 'Plank',
      'reps': '3 x 1 min',
      'desc': 'Core stability exercise.',
      'icon': Icons.crop_square,
      'completed': false,
    },
    {
      'name': 'Jumping Jacks',
      'reps': '3 x 30',
      'desc': 'Full body cardio move.',
      'icon': Icons.star,
      'completed': false,
    },
  ];

  void toggleCompleted(int index) {
    setState(() {
      workouts[index]['completed'] = !(workouts[index]['completed'] as bool);
    });
  }

  void showDetails(int index) {
    final workout = workouts[index];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(workout['icon'] as IconData, color: Colors.green[700]),
            const SizedBox(width: 10),
            Text(workout['name'] as String),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(workout['desc'] as String),
            const SizedBox(height: 12),
            Text('Reps: ${workout['reps']}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: workout['completed'] as bool,
                  onChanged: (_) {
                    Navigator.pop(context);
                    toggleCompleted(index);
                  },
                ),
                const Text('Mark as completed'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int completedCount = workouts.where((w) => w['completed'] as bool).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        backgroundColor: Colors.green[700],
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                '$completedCount/${workouts.length} Done',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.green[50],
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workout = workouts[index];
            return Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              margin: const EdgeInsets.symmetric(vertical: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => showDetails(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: workout['completed'] as bool
                            ? Colors.green[400]
                            : Colors.green[200],
                        child: Icon(
                          workout['icon'] as IconData,
                          color: workout['completed'] as bool
                              ? Colors.white
                              : Colors.green[900],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout['name'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                decoration: workout['completed'] as bool
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: workout['completed'] as bool
                                    ? Colors.green[700]
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              workout['reps'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              workout['desc'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Checkbox(
                        value: workout['completed'] as bool,
                        onChanged: (_) => toggleCompleted(index),
                        activeColor: Colors.green[700],
                      ),
                      Icon(Icons.arrow_forward_ios, size: 20, color: Colors.green[700]),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}