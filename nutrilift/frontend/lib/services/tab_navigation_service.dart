import 'package:flutter/material.dart';

/// Service to handle tab navigation in MainNavigation
/// This allows any screen to switch tabs in the main navigation
class TabNavigationService {
  static final TabNavigationService _instance = TabNavigationService._internal();
  factory TabNavigationService() => _instance;
  TabNavigationService._internal();

  // Callback to switch tabs - will be set by MainNavigation
  Function(int)? _onTabSwitch;

  /// Register the tab switch callback from MainNavigation
  void registerTabSwitcher(Function(int) callback) {
    _onTabSwitch = callback;
  }

  /// Switch to a specific tab
  /// Tab indices: 0=Home, 1=Workout, 2=Nutrition, 3=Community, 4=Gym Finder
  void switchToTab(int tabIndex) {
    if (_onTabSwitch != null) {
      _onTabSwitch!(tabIndex);
    }
  }

  /// Navigate to Home tab
  void goToHome() => switchToTab(0);

  /// Navigate to Workout tab
  void goToWorkout() => switchToTab(1);

  /// Navigate to Nutrition tab
  void goToNutrition() => switchToTab(2);

  /// Navigate to Community tab
  void goToCommunity() => switchToTab(3);

  /// Navigate to Gym Finder tab
  void goToGymFinder() => switchToTab(4);
}
