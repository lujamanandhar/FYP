import 'package:flutter/material.dart';

class OnboardingHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onBackPressed;

  const OnboardingHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress Breadcrumb - Centered
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final isCompleted = index < currentStep;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 30,
                height: 6,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.red : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          // Back Button - Left aligned
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.red),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
