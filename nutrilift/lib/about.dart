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
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  radius: 28,
                  child: Icon(Icons.fitness_center, color: theme.colorScheme.primary, size: 32),
                ),
                const SizedBox(width: 16),
                Text(
                  'NutriLift',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Your personal nutrition and fitness companion.',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Track your meals, monitor your progress, and achieve your health goals with ease. NutriLift empowers you to live healthier every day with personalized insights and easy-to-use tools.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Card(
              color: theme.colorScheme.surfaceVariant,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Version 1.0.0',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
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