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
              title: Text(workout['name']!),
              subtitle: Text('Reps: ${workout['reps']}'),
              leading: const Icon(Icons.fitness_center),
            ),
          );
        },
      ),
    );
  }
}

class WorkingPage extends StatelessWidget {
  const WorkingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workingSteps = [
      {'step': 'Warm Up', 'desc': '5 min light cardio'},
      {'step': 'Stretch', 'desc': 'Full body stretching'},
      {'step': 'Workout', 'desc': 'Follow the workout routine'},
      {'step': 'Cool Down', 'desc': '5 min slow walk'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Working'),
      ),
      body: ListView.builder(
        itemCount: workingSteps.length,
        itemBuilder: (context, index) {
          final step = workingSteps[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(step['step']!),
              subtitle: Text(step['desc']!),
              leading: const Icon(Icons.directions_run),
            ),
          );
        },
      ),
    );
  }
}