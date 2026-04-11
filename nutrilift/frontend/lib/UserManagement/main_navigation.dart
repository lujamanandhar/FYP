import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../Hompage/home_page.dart';
import '../NutritionTracking/nutrition_tracking.dart';
import '../WorkoutTracking/workout_tracking.dart';
import '../Challenge_Community/challenge_community_wrapper.dart';
import '../Gym Finder/gym_comparison_screen.dart';
import '../services/tab_navigation_service.dart';
import '../services/notification_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  int _workoutTabRefreshKey = 0; // incremented to force workout page rebuild
  final TabNavigationService _tabNavService = TabNavigationService();
  // Track which tabs have been visited to enable lazy loading
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    _tabNavService.registerTabSwitcher(_switchToTab);
    // Start notification polling when user enters main navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider_pkg.Provider.of<NotificationService>(context, listen: false)
          .startPolling(intervalSeconds: 15);
    });
  }

  @override
  void dispose() {
    provider_pkg.Provider.of<NotificationService>(context, listen: false).stopPolling();
    super.dispose();
  }

  void _switchToTab(int index) {
    if (mounted) {
      setState(() {
        if (index == 1) {
          _workoutTabRefreshKey++;
        }
        _selectedIndex = index;
        _visitedTabs.add(index);
      });
    }
  }

  void _onItemTapped(int index) {
    print('📱 MainNavigation: Tab tapped - index: $index');
    _switchToTab(index);
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
          _visitedTabs.contains(1)
              ? WorkoutTracking(key: ValueKey('workout_$_workoutTabRefreshKey'))
              : const SizedBox.shrink(),
          _visitedTabs.contains(2) ? const NutritionTracking() : const SizedBox.shrink(),
          _visitedTabs.contains(3) ? const ChallengeCommunityWrapper() : const SizedBox.shrink(),
          _visitedTabs.contains(4) ? GymComparisonScreen() : const SizedBox.shrink(),
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
            label: 'Gym Compare',
          ),
        ],
      ),
    );
  }
}