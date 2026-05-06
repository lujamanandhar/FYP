import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider_pkg;
import '../Hompage/home_page.dart';
import '../NutritionTracking/nutrition_tracking.dart';
import '../WorkoutTracking/workout_tracking.dart';
import '../Challenge_Community/challenge_community_wrapper.dart';
import '../Gym Finder/gym_comparison_screen.dart';
import '../services/tab_navigation_service.dart';
import '../services/notification_service.dart';

const _kRed = Color(0xFFE53935);

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  int _workoutTabRefreshKey = 0;
  final TabNavigationService _tabNavService = TabNavigationService();
  final Set<int> _visitedTabs = {0};

  late final List<AnimationController> _iconControllers;

  static const _items = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.fitness_center_outlined, activeIcon: Icons.fitness_center, label: 'Workout'),
    _NavItem(icon: Icons.restaurant_outlined, activeIcon: Icons.restaurant, label: 'Nutrition'),
    _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Community'),
    _NavItem(icon: Icons.location_on_outlined, activeIcon: Icons.location_on, label: 'Gyms'),
  ];

  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(
      _items.length,
      (_) => AnimationController(vsync: this, duration: const Duration(milliseconds: 300)),
    );
    _iconControllers[0].forward();
    _tabNavService.registerTabSwitcher(_switchToTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider_pkg.Provider.of<NotificationService>(context, listen: false)
          .startPolling(intervalSeconds: 15);
    });
  }

  @override
  void dispose() {
    for (final c in _iconControllers) c.dispose();
    provider_pkg.Provider.of<NotificationService>(context, listen: false).stopPolling();
    super.dispose();
  }

  void _switchToTab(int index) {
    if (!mounted) return;
    _iconControllers[_selectedIndex].reverse();
    _iconControllers[index].forward();
    setState(() {
      if (index == 1) _workoutTabRefreshKey++;
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
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
      bottomNavigationBar: _AnimatedBottomNav(
        selectedIndex: _selectedIndex,
        items: _items,
        iconControllers: _iconControllers,
        onTap: _switchToTab,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _AnimatedBottomNav extends StatelessWidget {
  final int selectedIndex;
  final List<_NavItem> items;
  final List<AnimationController> iconControllers;
  final void Function(int) onTap;

  const _AnimatedBottomNav({
    required this.selectedIndex,
    required this.items,
    required this.iconControllers,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final selected = selectedIndex == i;
              final item = items[i];
              return GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? _kRed.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                          CurvedAnimation(parent: iconControllers[i], curve: Curves.elasticOut),
                        ),
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          color: selected ? _kRed : const Color(0xFFBBBBBB),
                          size: 22,
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: selected
                            ? Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(item.label,
                                    style: const TextStyle(
                                      color: _kRed,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    )),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
