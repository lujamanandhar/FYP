import 'package:flutter/material.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({Key? key}) : super(key: key);

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
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workout = workouts[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[200],
                  child: Icon(workout['icon'] as IconData, color: Colors.green[900]),
                ),
                title: Text(
                  workout['name']!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout['reps']!, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(workout['desc']!, style: const TextStyle(fontSize: 13, color: Colors.black54)),
                  ],
                ),
                trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.green[700]),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(workout['name']!),
                      content: Text(workout['desc']!),
                      actions: [
                        TextButton(
                          child: const Text('Close'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}