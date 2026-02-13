import 'package:flutter/material.dart';
// import 'success_screen.dart';
import '../widgets/onboarding_header.dart';
import '../services/onboarding_service.dart';
import 'main_navigation.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  double _selectedWeight = 70; // in kilograms
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if any
    _selectedWeight = _onboardingService.data.weight ?? 70;
    
    // Listen to onboarding service changes
    _onboardingService.addListener(_onOnboardingServiceChanged);
  }

  @override
  void dispose() {
    _onboardingService.removeListener(_onOnboardingServiceChanged);
    super.dispose();
  }

  void _onOnboardingServiceChanged() {
    if (mounted) {
      setState(() {
        _isSubmitting = _onboardingService.isLoading;
      });
      
      // Show error if submission failed
      if (_onboardingService.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_onboardingService.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _submitProfile,
            ),
          ),
        );
      }
    }
  }

  Future<void> _submitProfile() async {
    // Validate current step first
    final error = _onboardingService.validateCurrentStep(5);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_onboardingService.getStepErrorMessage(5) ?? error),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await _onboardingService.submitProfile();
    if (success && mounted) {
      // Navigate to main navigation on success
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
        (route) => false,
      );
    }
  }

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
                        _onboardingService.updateWeight(value);
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
                onPressed: _isSubmitting ? null : _submitProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Complete Profile'),
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