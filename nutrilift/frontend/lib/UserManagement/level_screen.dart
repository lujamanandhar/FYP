import 'package:flutter/material.dart';
import 'height_screen.dart';
import '../widgets/onboarding_header.dart';
import '../services/onboarding_service.dart';

class LevelScreen extends StatefulWidget {
  const LevelScreen({super.key});

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  String? _selectedLevel;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if any
    _selectedLevel = _onboardingService.data.fitnessLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingHeader(currentStep: 3, totalSteps: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/nutrilift_logo.png', height: 60),
              const SizedBox(height: 30),
              const Text(
                'What is your fitness level?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Column(
                children: [
                  _buildLevelButton('Beginner'),
                  const SizedBox(height: 15),
                  _buildLevelButton('Intermediate'),
                  const SizedBox(height: 15),
                  _buildLevelButton('Advance'),
                ],
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _selectedLevel != null ? () {
                  // Validate current step before proceeding
                  final error = _onboardingService.validateCurrentStep(3);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_onboardingService.getStepErrorMessage(3) ?? error),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HeightScreen()),
                  );
                } : null,
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

  Widget _buildLevelButton(String label) {
    final isSelected = _selectedLevel == label;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedLevel = label;
          });
          _onboardingService.updateFitnessLevel(label);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.red : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 20),
        ),
        child: Text(label),
      ),
    );
  }
}