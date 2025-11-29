import 'package:flutter/material.dart';
import 'success_screen.dart';
import 'widgets/onboarding_header.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  double _selectedWeight = 70; // in kg

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const OnboardingHeader(currentStep: 5, totalSteps: 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/nutrilift_logo.png', height: 60),
              const SizedBox(height: 30),
              const Text(
                'What is your weight?',
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
                      '${_selectedWeight.toInt()} kg',
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    Slider(
                      value: _selectedWeight,
                      min: 30,
                      max: 200,
                      divisions: 170,
                      activeColor: Colors.red,
                      inactiveColor: Colors.grey[300],
                      onChanged: (double value) {
                        setState(() {
                          _selectedWeight = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('30 kg', style: TextStyle(color: Colors.grey)),
                        Text('200 kg', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SuccessScreen()),
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