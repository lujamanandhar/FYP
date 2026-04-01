import 'package:flutter/material.dart';

/// Reusable bottom navigation bar for the app
/// Use this on screens that need navigation footer
class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const AppBottomNavigation({
    Key? key,
    this.currentIndex = -1, // -1 means no item is selected (for detail screens)
    this.onTap,
  }) : super(key: key);

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    // Default navigation behavior - pop to main navigation
    Navigator.of(context).popUntil((route) => route.isFirst);
    
    // If we need to navigate to a specific tab, we can use a global key or event
    // For now, just pop to main screen
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex >= 0 ? currentIndex : 0,
      onTap: (index) => _handleTap(context, index),
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
    );
  }
}
