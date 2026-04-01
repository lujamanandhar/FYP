import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import '../services/dashboard_service.dart';
import '../services/dashboard_refresh_service.dart';
import '../services/tab_navigation_service.dart';
import '../services/streak_service.dart';
import '../widgets/nutrilift_header.dart';
import '../widgets/streak_overview_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Challenge_Community/challenge_api_service.dart';
import '../Challenge_Community/active_challenge_screen.dart';
import '../NutritionTracking/nutrition_tracking.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with ErrorHandlingMixin, WidgetsBindingObserver {
  bool showChart = false;
  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isLoadingStats = true;
  final AuthService _authService = AuthService();
  final DashboardService _dashboardService = DashboardService();
  final DashboardRefreshService _refreshService = DashboardRefreshService();
  final ChallengeApiService _challengeService = ChallengeApiService();
  final TabNavigationService _tabNavService = TabNavigationService();
  final StreakService _streakService = StreakService();

  DashboardStats? _dashboardStats;
  List<ChartData> _weeklyData = [];
  List<ChallengeModel> _activeChallenges = [];
  bool _isLoadingChallenges = true;
  List<QuickActionShortcut> _shortcuts = [];
  AllStreaks _allStreaks = const AllStreaks();

  // Active time tracking — counts seconds live, persists minutes to prefs
  int _activeTimeSeconds = 0;
  Timer? _activeTimer;
  
  // Track last refresh time to auto-refresh stale data
  DateTime? _lastRefreshTime;
  
  // Subscription to refresh events
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadActiveTime();
    _loadUserProfile();
    _loadDashboardStats();
    _loadActiveChallenges();
    _loadShortcuts();
    _loadAllStreaks();
    // Tick every second — update live display
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _activeTimeSeconds++);
    });
    
    // Listen for refresh events from other screens
    _refreshSubscription = _refreshService.refreshStream.listen((_) {
      print('🔔 Dashboard: Refresh event received!');
      if (mounted) {
        _loadDashboardStats();
        _loadActiveChallenges();
      }
    });
  }

  @override
  void dispose() {
    _activeTimer?.cancel();
    _refreshSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _saveActiveTime();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveActiveTime();
    } else if (state == AppLifecycleState.resumed) {
      _loadDashboardStats();
    }
  }

  Future<void> _loadActiveTime() async {
    // Always start from 0 — active time is per login session.
    // The key is cleared on logout so a fresh login always starts at 0.
    if (mounted) setState(() => _activeTimeSeconds = 0);
  }

  Future<void> _saveActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_time_session', _activeTimeSeconds);
  }

  Future<void> _loadDashboardStats() async {
    print('🔄 Dashboard: Loading stats...');
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _dashboardService.getDashboardStats();
      print('✅ Dashboard: Stats loaded - Workouts: ${stats.todayWorkouts}, Calories: ${stats.todayCaloriesBurned}, Intake: ${stats.todayCaloriesIntake}');
      setState(() {
        _dashboardStats = stats;
        _buildWeeklyChartData();
        _isLoadingStats = false;
        _lastRefreshTime = DateTime.now();
      });
    } catch (e) {
      print('❌ Dashboard: Error loading stats: $e');
      setState(() => _isLoadingStats = false);
    }
  }

  void _buildWeeklyChartData() {
    if (_dashboardStats == null) return;
    final now = DateTime.now();
    final weekData = <ChartData>[];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayLabel = DateFormat('EEE').format(date).substring(0, 3);
      double calories = 0;
      final dayData = _dashboardStats!.workoutByDate[dateStr];
      if (dayData != null) {
        calories = (dayData['calories'] ?? 0).toDouble();
      }
      weekData.add(ChartData(dayLabel, calories));
    }
    _weeklyData = weekData;
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    final profile = await executeWithErrorHandling(
      () => _authService.getProfile(),
      loadingMessage: 'Loading your profile...',
    );
    setState(() {
      _userProfile = profile;
      _isLoading = false;
    });
  }

  Future<void> _loadAllStreaks() async {
    final streaks = await _streakService.fetchAllStreaks();
    if (mounted) setState(() => _allStreaks = streaks);
  }

  Future<void> _loadActiveChallenges() async {
    setState(() => _isLoadingChallenges = true);
    try {
      final challenges = await _challengeService.fetchActiveChallenges();
      // Filter only joined challenges
      final joined = challenges.where((c) => c.isJoined).toList();
      setState(() {
        _activeChallenges = joined;
        _isLoadingChallenges = false;
      });
    } catch (e) {
      print('Error loading challenges: $e');
      setState(() => _isLoadingChallenges = false);
    }
  }

  Future<void> _loadShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final shortcuts = prefs.getStringList('quick_action_shortcuts') ?? [];
    setState(() {
      _shortcuts = shortcuts.map((s) {
        final parts = s.split('|');
        return QuickActionShortcut(
          label: parts[0],
          icon: _getIconFromString(parts[1]),
          route: parts[2],
        );
      }).toList();
    });
  }

  Future<void> _saveShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final shortcuts = _shortcuts.map((s) => '${s.label}|${_getStringFromIcon(s.icon)}|${s.route}').toList();
    await prefs.setStringList('quick_action_shortcuts', shortcuts);
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant;
      case 'fitness_center': return Icons.fitness_center;
      case 'water_drop': return Icons.water_drop;
      case 'camera_alt': return Icons.camera_alt;
      case 'emoji_events': return Icons.emoji_events;
      default: return Icons.add;
    }
  }

  String _getStringFromIcon(IconData icon) {
    if (icon == Icons.restaurant) return 'restaurant';
    if (icon == Icons.fitness_center) return 'fitness_center';
    if (icon == Icons.water_drop) return 'water_drop';
    if (icon == Icons.camera_alt) return 'camera_alt';
    if (icon == Icons.emoji_events) return 'emoji_events';
    return 'add';
  }

  Future<void> _refresh() async {
    await _saveActiveTime();
    await _loadDashboardStats();
    await _loadUserProfile();
    await _loadActiveChallenges();
    await _loadAllStreaks();
  }

  void nextView() => setState(() => showChart = true);
  void prevView() => setState(() => showChart = false);

  @override
  Widget build(BuildContext context) {
    // Auto-refresh if data is stale (older than 30 seconds)
    if (_lastRefreshTime != null && 
        DateTime.now().difference(_lastRefreshTime!) > const Duration(seconds: 30) &&
        !_isLoadingStats) {
      // Schedule refresh after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadDashboardStats();
        }
      });
    }
    
    final currentStreak = _dashboardStats?.currentStreak ?? 0;

    return NutriLiftScaffold(
      streakCount: currentStreak,
      onStreakTap: () => showStreakOverview(context, _allStreaks),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                )
              : _userProfile == null
                  ? _buildErrorWidget()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(),
                          const SizedBox(height: 16),

                          // Daily Summary / Chart toggle
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                showChart ? 'Overview' : 'Daily Summary',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D2D2D),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Stack(
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: showChart
                                        ? _buildChart()
                                        : _buildStatsGrid(),
                                  ),
                                  Positioned(
                                    left: -16,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.1),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon:
                                              const Icon(Icons.chevron_left),
                                          color: const Color(0xFF666666),
                                          onPressed: prevView,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -16,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.1),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon:
                                              const Icon(Icons.chevron_right),
                                          color: const Color(0xFF666666),
                                          onPressed: nextView,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Today's Plan
                          const Text(
                            "Today's Plan",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildPlanItem(
                            Icons.fitness_center,
                            'Cardio',
                            '07:00-08:00 AM',
                            'START',
                          ),
                          const SizedBox(height: 8),
                          _buildPlanItem(
                            Icons.restaurant,
                            'Lunch',
                            '01:00-02:00 PM',
                            'LOG',
                          ),
                          const SizedBox(height: 24),

                          // Quick Actions
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildQuickActionsSection(),
                          const SizedBox(height: 24),

                          // AI Assistant
                          Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFB71C1C),
                                  Color(0xFFC62828)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'AI Assistant',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Get Personalized Recommendations',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.chat_bubble,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Active Challenges
                          const Text(
                            'Active Challenges',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildActiveChallengesSection(),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final userName = _userProfile?.displayName ?? 'User';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $userName!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D2D2D),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Let's Crush Your Fitness Goals Today!",
          style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load profile',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please check your connection and try again',
            style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_isLoadingStats) {
      return Container(
        key: const ValueKey('stats'),
        height: 200,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final calBurned = _dashboardStats?.todayCaloriesBurned ?? 0;
    final calIntake = _dashboardStats?.todayCaloriesIntake ?? 0;
    final workouts = _dashboardStats?.todayWorkouts ?? 0;

    // Format active time: show seconds until 1 min, then Xm Ys, then Xh Ym
    final totalSecs = _activeTimeSeconds;
    final String activeLabel;
    if (totalSecs < 60) {
      activeLabel = '${totalSecs}s';
    } else {
      final h = totalSecs ~/ 3600;
      final m = (totalSecs % 3600) ~/ 60;
      final s = totalSecs % 60;
      if (h > 0) {
        activeLabel = '${h}h ${m}m';
      } else {
        activeLabel = '${m}m ${s}s';
      }
    }

    return GridView.count(
      key: const ValueKey('stats'),
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
            Icons.local_fire_department, '$calBurned kcal', 'Calories Burned'),
        _buildStatCard(
            Icons.restaurant, '$calIntake kcal', 'Calories Intake'),
        _buildStatCard(
            Icons.access_time, activeLabel, 'Active Time'),
        _buildStatCard(
            Icons.check_circle, '$workouts', 'Workouts Done'),
      ],
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_isLoadingStats || _weeklyData.isEmpty) {
      return Container(
        key: const ValueKey('chart'),
        height: 250,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final maxVal = _weeklyData.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      key: const ValueKey('chart'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      height: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Calories Burned',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal > 0 ? maxVal * 1.2 : 100,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} cal',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < _weeklyData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              _weeklyData[idx].day,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF666666)),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFF666666)),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.2),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _weeklyData.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: const Color(0xFFE53935),
                        width: 20,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanItem(
      IconData icon, String title, String time, String buttonText) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D2D2D))),
                const SizedBox(height: 2),
                Text(time,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF666666))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 0,
            ),
            child: Text(buttonText,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      children: [
        if (_shortcuts.isEmpty)
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  Icons.restaurant,
                  'QUICK LOG FOOD',
                  onTap: () {
                    _tabNavService.goToNutrition();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAction(
                  Icons.add_circle_outline,
                  'ADD SHORTCUTS',
                  onTap: _showAddShortcutDialog,
                ),
              ),
            ],
          )
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._shortcuts.map((shortcut) => SizedBox(
                    width: (MediaQuery.of(context).size.width - 44) / 2,
                    child: _buildQuickAction(
                      shortcut.icon,
                      shortcut.label,
                      onTap: () => _handleShortcutTap(shortcut.route),
                    ),
                  )),
              SizedBox(
                width: (MediaQuery.of(context).size.width - 44) / 2,
                child: _buildQuickAction(
                  Icons.add_circle_outline,
                  'ADD MORE',
                  onTap: _showAddShortcutDialog,
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _handleShortcutTap(String route) {
    switch (route) {
      case '/nutrition':
        // Switch to nutrition tab (index 2) in MainNavigation
        _tabNavService.goToNutrition();
        break;
      case '/workout':
        // Switch to workout tab (index 1) in MainNavigation
        _tabNavService.goToWorkout();
        break;
      case '/challenges':
        // Switch to community/challenges tab (index 3) in MainNavigation
        _tabNavService.goToCommunity();
        break;
      default:
        break;
    }
  }

  void _navigateToMainTab(int tabIndex) {
    // This method is no longer needed but kept for reference
    _tabNavService.switchToTab(tabIndex);
  }

  void _showAddShortcutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Quick Action Shortcut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restaurant, color: Colors.red),
              title: const Text('Quick Log Food'),
              onTap: () {
                _addShortcut('QUICK LOG FOOD', Icons.restaurant, '/nutrition');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center, color: Colors.red),
              title: const Text('Quick Log Exercise'),
              onTap: () {
                _addShortcut('QUICK LOG EXERCISE', Icons.fitness_center, '/workout');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.water_drop, color: Colors.red),
              title: const Text('Log Water'),
              onTap: () {
                _addShortcut('LOG WATER', Icons.water_drop, '/nutrition');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.red),
              title: const Text('Scan Meal'),
              onTap: () {
                _addShortcut('SCAN MEAL', Icons.camera_alt, '/nutrition');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events, color: Colors.red),
              title: const Text('View Challenges'),
              onTap: () {
                _addShortcut('CHALLENGES', Icons.emoji_events, '/challenges');
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _addShortcut(String label, IconData icon, String route) {
    setState(() {
      _shortcuts.add(QuickActionShortcut(label: label, icon: icon, route: route));
    });
    _saveShortcuts();
  }

  Widget _buildActiveChallengesSection() {
    if (_isLoadingChallenges) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_activeChallenges.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Active Challenges',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Join a challenge to get started!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF666666),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF999999),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _activeChallenges.take(3).map((challenge) {
        final daysTotal = challenge.endDate.difference(challenge.startDate).inDays;
        final daysPassed = DateTime.now().difference(challenge.startDate).inDays;
        final currentDay = daysPassed + 1;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActiveChallengeScreen(
                    challengeId: challenge.id,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2D2D2D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Day $currentDay of $daysTotal',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF999999),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ChartData {
  final String day;
  final double value;
  ChartData(this.day, this.value);
}

class QuickActionShortcut {
  final String label;
  final IconData icon;
  final String route;

  QuickActionShortcut({
    required this.label,
    required this.icon,
    required this.route,
  });
}
