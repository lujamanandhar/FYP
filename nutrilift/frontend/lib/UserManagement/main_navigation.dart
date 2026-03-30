import 'package:flutter/material.dart';
import '../Hompage/home_page.dart';
import '../NutritionTracking/nutrition_tracking.dart';
import '../WorkoutTracking/workout_tracking.dart';
import '../Challenge_Community/challenge_community_wrapper.dart';
import '../Gym Finder/gym_comparison_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  int _workoutTabRefreshKey = 0; // incremented to force workout page rebuild

  void _onItemTapped(int index) {
    print('📱 MainNavigation: Tab tapped - index: $index');
    setState(() {
      // If tapping the workout tab (index 1), force a rebuild to refresh stats
      if (index == 1) {
        _workoutTabRefreshKey++;
      }
      _selectedIndex = index;
    });
    print('📱 MainNavigation: Selected index updated to: $_selectedIndex');
  }

  @override
  Widget build(BuildContext context) {
    print('📱 MainNavigation: build() called, selectedIndex: $_selectedIndex');
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const HomePage(),
          WorkoutTracking(key: ValueKey('workout_$_workoutTabRefreshKey')),
          const NutritionTracking(),
          const ChallengeCommunityWrapper(),
          GymComparisonScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFE53935),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Workout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Nutrition',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Gym Finder',
          ),
        ],
      ),
    );
  }
}