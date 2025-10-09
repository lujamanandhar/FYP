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
      {'name': 'Lunges', 'reps': '3 x 12 each leg'},
      {'name': 'Burpees', 'reps': '3 x 10'},
      {'name': 'Mountain Climbers', 'reps': '3 x 20'},
      {'name': 'Sit Ups', 'reps': '3 x 15'},
      {'name': 'High Knees', 'reps': '3 x 30 sec'},
      {'name': 'Tricep Dips', 'reps': '3 x 12'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.purpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final workout = workouts[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: Colors.white.withOpacity(0.9),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                leading: CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Icon(Icons.fitness_center, color: Colors.white),
                ),
                title: Text(
                  workout['name']!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.deepPurple,
                  ),
                ),
                subtitle: Text(
                  'Reps: ${workout['reps']}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                trailing: Icon(Icons.arrow_forward_ios, color: Colors.deepPurpleAccent),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected: ${workout['name']}'),
                      duration: const Duration(seconds: 1),
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