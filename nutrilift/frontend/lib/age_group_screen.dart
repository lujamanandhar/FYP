import 'package:flutter/material.dart';
import 'level_screen.dart';

class AgeGroupScreen extends StatelessWidget {
  const AgeGroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/nutrilift_logo.png', height: 60),
              const SizedBox(height: 30),
              const Text(
                'What is your age group?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Column(
                children: [
                  _buildAgeButton(context, 'Adult', Icons.person),
                  const SizedBox(height: 15),
                  _buildAgeButton(context, 'Mid-Age Adult', Icons.person_outline),
                  const SizedBox(height: 15),
                  _buildAgeButton(context, 'Older Adult', Icons.person_outline_sharp),
                ],
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LevelScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Next'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeButton(BuildContext context, String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        alignment: Alignment.centerLeft,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }
}