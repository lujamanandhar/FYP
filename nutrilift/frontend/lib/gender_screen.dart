import 'package:flutter/material.dart';
import 'age_group_screen.dart';
import 'widgets/onboarding_header.dart';

class GenderScreen extends StatefulWidget {
  const GenderScreen({super.key});

  @override
  State<GenderScreen> createState() => _GenderScreenState();
}

class _GenderScreenState extends State<GenderScreen> {
  String? _selectedGender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingHeader(currentStep: 1, totalSteps: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/nutrilift_logo.png', height: 60),
              const SizedBox(height: 30),
              const Text(
                'What is your gender?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedGender = 'Male';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedGender == 'Male' ? Colors.red : Colors.grey[200],
                        foregroundColor: _selectedGender == 'Male' ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: const Text('Male'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedGender = 'Female';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedGender == 'Female' ? Colors.red : Colors.grey[200],
                        foregroundColor: _selectedGender == 'Female' ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: const Text('Female'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AgeGroupScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Next'),
              ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}