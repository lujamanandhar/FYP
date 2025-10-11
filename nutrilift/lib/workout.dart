import 'package:flutter/material.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final workouts = [
      {
        'name': 'Push Ups',
        'reps': '3 x 15',
        'desc': 'Great for chest, shoulders, and triceps.',
        'icon': Icons.push_pin,
      },
      {
        'name': 'Squats',
        'reps': '3 x 20',
        'desc': 'Strengthens legs and glutes.',
        'icon': Icons.directions_run,
      },
      {
        'name': 'Plank',
        'reps': '3 x 1 min',
        'desc': 'Core stability exercise.',
        'icon': Icons.crop_square,
      },
      {
        'name': 'Jumping Jacks',
        'reps': '3 x 30',
        'desc': 'Full body cardio move.',
        'icon': Icons.star,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        backgroundColor: Colors.green[700],
        elevation: 0,
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
                onTap: () {
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
                      content: Text(workout['desc'] as String),
                      actions: [
                        TextButton(
                          child: const Text('Close'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.green[200],
                        child: Icon(workout['icon'] as IconData, color: Colors.green[900], size: 28),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              workout['name'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
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