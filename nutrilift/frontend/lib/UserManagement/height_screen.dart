import 'package:flutter/material.dart';
import 'weight_screen.dart';
import '../widgets/onboarding_header.dart';
import '../services/onboarding_service.dart';

class HeightScreen extends StatefulWidget {
  const HeightScreen({super.key});

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  double _selectedHeight = 170; // in cm

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if any
    _selectedHeight = _onboardingService.data.height ?? 170;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingHeader(currentStep: 4, totalSteps: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/nutrilift_logo.png', height: 60),
              const SizedBox(height: 30),
              const Text(
                'What is your height?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_selectedHeight.toInt()} cm',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    Slider(
                      value: _selectedHeight,
                      min: 120,
                      max: 220,
                      divisions: 100,
                      activeColor: Colors.red,
                      inactiveColor: Colors.grey[300],
                      onChanged: (double value) {
                        setState(() {
                          _selectedHeight = value;
                        });
                        _onboardingService.updateHeight(value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('120 cm', style: TextStyle(color: Colors.grey)),
                        Text('220 cm', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  // Validate current step before proceeding
                  final error = _onboardingService.validateCurrentStep(4);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_onboardingService.getStepErrorMessage(4) ?? error),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WeightScreen()),
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