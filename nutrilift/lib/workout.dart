import 'package:flutter/material.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workouts = [
      {'name': 'Push Ups', 'reps': '3 x 15'},
      {'name': 'Squats', 'reps': '3 x 20'},
      {'name': 'Plank', 'reps': '3 x 1 min'},
      {'name': 'Jumping Jacks', 'reps': '3 x 30'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
      ),
      body: ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text(workout['name']!),
              subtitle: Text(workout['reps']!),
            ),
          );
        },
      ),
    );
  }
}