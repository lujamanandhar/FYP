import 'package:flutter/material.dart';
import '../widgets/nutrilift_header.dart';
import '../screens/workout_history_screen.dart';
import '../screens/new_workout_screen.dart';
import '../screens/exercise_library_screen.dart';
import '../screens/personal_records_screen.dart';

/// Workout Tracking Main Screen
/// 
/// Provides navigation to all workout-related screens:
/// - Workout History: View all logged workouts
/// - New Workout: Log a new workout session
/// - Exercise Library: Browse available exercises
/// - Personal Records: View personal bests
/// 
/// Validates: Requirements 7.10, 13.2, 13.3
class WorkoutTracking extends StatelessWidget {
  const WorkoutTracking({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const WorkoutTrackingHome();
  }
}

class WorkoutTrackingHome extends StatelessWidget {
  const WorkoutTrackingHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NutriLiftScaffold(
      title: 'Workout Tracking',
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome section
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              
              // Quick actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 16),
              
              // Navigation cards
              _buildNavigationCard(
                context,
                title: 'Workout History',
                subtitle: 'View your logged workouts',
                icon: Icons.history,
                color: const Color(0xFFE53935),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WorkoutHistoryScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              _buildNavigationCard(
                context,
                title: 'Log New Workout',
                subtitle: 'Record your training session',
                icon: Icons.add_circle,
                color: const Color(0xFFE53935),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NewWorkoutScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              _buildNavigationCard(
                context,
                title: 'Exercise Library',
                subtitle: 'Browse available exercises',
                icon: Icons.fitness_center,
                color: const Color(0xFFE53935),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExerciseLibraryScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              _buildNavigationCard(
                context,
                title: 'Personal Records',
                subtitle: 'View your personal bests',
                icon: Icons.emoji_events,
                color: const Color(0xFFE53935),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonalRecordsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.fitness_center,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Track Your Progress',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Log workouts, track PRs, and achieve your fitness goals',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
