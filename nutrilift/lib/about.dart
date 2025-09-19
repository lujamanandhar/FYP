import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('About NutriLift'),
        centerTitle: true,
        backgroundColor: theme.primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.fitness_center, color: theme.primaryColor, size: 36),
                const SizedBox(width: 10),
                Text(
                  'NutriLift',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Your personal nutrition and fitness companion.',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              'Track your meals, monitor your progress, and achieve your health goals with ease. NutriLift empowers you to live healthier every day.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey[600], size: 18),
                const SizedBox(width: 6),
                Text(
                  'Version 1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: Text(
                '© 2024 NutriLift Team',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}