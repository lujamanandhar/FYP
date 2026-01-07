import 'package:flutter/material.dart';
import 'level_screen.dart';
import '../widgets/onboarding_header.dart';
import '../services/onboarding_service.dart';

class AgeGroupScreen extends StatefulWidget {
  const AgeGroupScreen({super.key});

  @override
  State<AgeGroupScreen> createState() => _AgeGroupScreenState();
}

class _AgeGroupScreenState extends State<AgeGroupScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  String? _selectedAge;

  @override
  void initState() {
    super.initState();
   
    _selectedAge = _onboardingService.data.ageGroup;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingHeader(currentStep: 2, totalSteps: 5),
            Expanded(
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
                  _buildAgeButton('Adult', Icons.person),
                  const SizedBox(height: 15),
                  _buildAgeButton('Mid-Age Adult', Icons.person_outline),
                  const SizedBox(height: 15),
                  _buildAgeButton('Older Adult', Icons.person_outline_sharp),
                ],
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: _selectedAge != null ? () {
                  // Validate current step before proceeding
                  final error = _onboardingService.validateCurrentStep(2);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_onboardingService.getStepErrorMessage(2) ?? error),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LevelScreen()),
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

  Widget _buildAgeButton(String label, IconData icon) {
    final isSelected = _selectedAge == label;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _selectedAge = label;
          });
          _onboardingService.updateAgeGroup(label);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.red : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          alignment: Alignment.centerLeft,
        ),
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}