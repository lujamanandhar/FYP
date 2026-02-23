import 'package:flutter/material.dart';
import '../widgets/nutrilift_header.dart';
import '../screens/workout_history_screen.dart';
import '../screens/new_workout_screen.dart';
import '../screens/exercise_library_screen.dart';
import '../screens/personal_records_screen.dart';

class WorkoutTracking extends StatelessWidget {
  const WorkoutTracking({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const WorkoutHome();
  }
}

class WorkoutHome extends StatefulWidget {
  const WorkoutHome({Key? key}) : super(key: key);

  @override
  State<WorkoutHome> createState() => _WorkoutHomeState();
}

class _WorkoutHomeState extends State<WorkoutHome> {
  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      body: _buildWorkoutScreen(),
    );
  }

  Widget _buildWorkoutScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Workout Tracking',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE53935),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Track your workouts, view history, and monitor your progress',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),
          
          // Quick Actions Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildQuickActionCard(
                context,
                icon: Icons.add_circle_outline,
                title: 'New Workout',
                subtitle: 'Log a new workout',
                color: const Color(0xFFE53935),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewWorkoutScreen()),
                ),
              ),
              _buildQuickActionCard(
                context,
                icon: Icons.history,
                title: 'History',
                subtitle: 'View past workouts',
                color: const Color(0xFFD32F2F),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkoutHistoryScreen()),
                ),
              ),
              _buildQuickActionCard(
                context,
                icon: Icons.library_books,
                title: 'Exercise Library',
                subtitle: 'Browse exercises',
                color: const Color(0xFFC62828),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ExerciseLibraryScreen()),
                ),
              ),
              _buildQuickActionCard(
                context,
                icon: Icons.emoji_events,
                title: 'Personal Records',
                subtitle: 'View your PRs',
                color: const Color(0xFFB71C1C),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PersonalRecordsScreen()),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Legacy Workout Templates Section
          const Text(
            'Workout Templates',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildLegacyWorkoutTemplates(),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyWorkoutTemplates() {
    final List<Map<String, dynamic>> templates = [
      {
        'name': 'Full Body',
        'exercises': '12 Exercises',
        'time': '45 min',
        'icon': Icons.fitness_center,
      },
      {
        'name': 'Upper Body',
        'exercises': '8 Exercises',
        'time': '30 min',
        'icon': Icons.sports_martial_arts,
      },
      {
        'name': 'Cardio',
        'exercises': '10 Exercises',
        'time': '35 min',
        'icon': Icons.directions_run,
      },
    ];

    return Column(
      children: templates.map((template) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  template['icon'],
                  size: 32,
                  color: const Color(0xFFE53935),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${template['exercises']} • ${template['time']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
