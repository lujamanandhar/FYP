import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
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
  late final PageController _summaryPageController = PageController();
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
  List<ChartData> _monthlyData = [];
  List<ChallengeModel> _activeChallenges = [];

  // Chart state
  int _selectedMetric = 0; // 0=CalBurned, 1=CalIntake, 2=ActiveTime, 3=Workouts
  bool _isMonthlyView = false;
  bool _isLoadingChallenges = true;
  List<QuickActionShortcut> _shortcuts = [];
  bool _isEditingShortcuts = false;
  AllStreaks _allStreaks = const AllStreaks();

  // Active time tracking â€” counts seconds live, persists minutes to prefs
  int _activeTimeSeconds = 0;
  Timer? _activeTimer;
  
  // Track last refresh time to auto-refresh stale data
  DateTime? _lastRefreshTime;

  // Today's Plan
  List<PlanTask> _planTasks = [];
  final Set<int> _completingTaskIds = {}; // tasks showing done animation
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
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
    _initNotifications();
    _loadPlanTasks();
    // Tick every second â€” update live display
    _activeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _activeTimeSeconds++);
    });
    
    // Listen for refresh events from other screens
    _refreshSubscription = _refreshService.refreshStream.listen((_) {
      print('ðŸ”” Dashboard: Refresh event received!');
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
    _summaryPageController.dispose();
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
    // Always start from 0 â€” active time is per login session.
    // The key is cleared on logout so a fresh login always starts at 0.
    if (mounted) setState(() => _activeTimeSeconds = 0);
  }

  Future<void> _saveActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_time_session', _activeTimeSeconds);
  }

  Future<void> _loadDashboardStats() async {
    print('ðŸ”„ Dashboard: Loading stats...');
    setState(() => _isLoadingStats = true);
    try {
      final stats = await _dashboardService.getDashboardStats();
      print('âœ… Dashboard: Stats loaded - Workouts: ${stats.todayWorkouts}, Calories: ${stats.todayCaloriesBurned}, Intake: ${stats.todayCaloriesIntake}');
      setState(() {
        _dashboardStats = stats;
        _buildWeeklyChartData();
        _isLoadingStats = false;
        _lastRefreshTime = DateTime.now();
      });
    } catch (e) {
      print('âŒ Dashboard: Error loading stats: $e');
      setState(() => _isLoadingStats = false);
    }
  }

  void _buildWeeklyChartData() {
    if (_dashboardStats == null) return;
    final now = DateTime.now();

    // Weekly â€” current week Sunâ†’Sat (7 fixed days)
    final weekData = <List<ChartData>>[[], [], [], []];
    // Find Sunday of current week
    final todayWeekday = now.weekday % 7; // Mon=1..Sun=0 â†’ Sun=0
    final sunday = now.subtract(Duration(days: todayWeekday));
    for (int i = 0; i < 7; i++) {
      final date = sunday.add(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final dayLabel = DateFormat('EEE').format(date).substring(0, 3);
      final dayData = _dashboardStats!.workoutByDate[dateStr];
      weekData[0].add(ChartData(dayLabel, (dayData?['calories'] ?? 0).toDouble()));
      weekData[1].add(ChartData(dayLabel, (dayData?['intake'] ?? 0).toDouble()));
      weekData[2].add(ChartData(dayLabel, (dayData?['duration'] ?? dayData?['active_minutes'] ?? 0).toDouble()));
      weekData[3].add(ChartData(dayLabel, (dayData?['workouts'] ?? dayData?['count'] ?? 0).toDouble()));
    }
    _weeklyData = weekData[_selectedMetric];

    // Monthly â€” Janâ†’Dec of current year (12 fixed months)
    final monthData = <List<ChartData>>[[], [], [], []];
    for (int m = 1; m <= 12; m++) {
      final monthDate = DateTime(now.year, m, 1);
      final monthLabel = DateFormat('MMM').format(monthDate);
      double c0 = 0, c1 = 0, c2 = 0, c3 = 0;
      final daysInMonth = DateUtils.getDaysInMonth(now.year, m);
      for (int d = 1; d <= daysInMonth; d++) {
        final date = DateTime(now.year, m, d);
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final dayData = _dashboardStats!.workoutByDate[dateStr];
        c0 += (dayData?['calories'] ?? 0).toDouble();
        c1 += (dayData?['intake'] ?? 0).toDouble();
        c2 += (dayData?['duration'] ?? dayData?['active_minutes'] ?? 0).toDouble();
        c3 += (dayData?['workouts'] ?? dayData?['count'] ?? 0).toDouble();
      }
      monthData[0].add(ChartData(monthLabel, c0));
      monthData[1].add(ChartData(monthLabel, c1));
      monthData[2].add(ChartData(monthLabel, c2));
      monthData[3].add(ChartData(monthLabel, c3));
    }
    _monthlyData = monthData[_selectedMetric];
  }

  List<ChartData> get _currentChartData => _isMonthlyView ? _monthlyData : _weeklyData;

  void _onMetricChanged(int idx) {
    setState(() {
      _selectedMetric = idx;
      _buildWeeklyChartData();
    });
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

  // â”€â”€ Today's Plan â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _initNotifications() async {
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _notificationsPlugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
  }

  Future<void> _loadPlanTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('plan_tasks_today') ?? [];
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final savedDate = prefs.getString('plan_tasks_date') ?? '';
    if (savedDate != today) {
      // New day â€” clear tasks
      await prefs.setStringList('plan_tasks_today', []);
      await prefs.setString('plan_tasks_date', today);
      if (mounted) setState(() => _planTasks = []);
      return;
    }
    final tasks = raw.map((s) => PlanTask.fromString(s)).toList();
    if (mounted) setState(() => _planTasks = tasks);
  }

  Future<void> _savePlanTasks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'plan_tasks_today', _planTasks.map((t) => t.toString()).toList());
    await prefs.setString(
        'plan_tasks_date', DateFormat('yyyy-MM-dd').format(DateTime.now()));
  }

  Future<void> _scheduleNotification(PlanTask task) async {
    // Respect the user's notification preference
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool('notifications_enabled') ?? true)) return;

    final now = DateTime.now();
    final scheduled = DateTime(
        now.year, now.month, now.day, task.startHour, task.startMinute);
    if (scheduled.isBefore(now)) return; // already passed
    await _notificationsPlugin.zonedSchedule(
      task.id,
      'Time for ${task.title}!',
      'Your scheduled task is starting now.',
      tz.TZDateTime.from(scheduled, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'plan_channel', 'Today\'s Plan',
          channelDescription: 'Reminders for your daily plan',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    TaskType selectedType = TaskType.workout;
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay(
        hour: (TimeOfDay.now().hour + 1) % 24, minute: TimeOfDay.now().minute);

    String Function(TaskType) notesHint = (TaskType t) {
      switch (t) {
        case TaskType.workout:
          return 'e.g. Push-ups 3x12, Squats 3x15, Plank 1min';
        case TaskType.meal:
          return 'e.g. Oatmeal with banana, Green tea, 2 eggs';
        case TaskType.water:
          return 'e.g. 500ml water, 2 glasses';
        case TaskType.challenge:
          return 'e.g. Day 5 - 20 burpees, 10 pull-ups';
        case TaskType.custom:
          return 'Add details...';
      }
    };

    String Function(TaskType) notesLabel = (TaskType t) {
      switch (t) {
        case TaskType.workout: return 'Exercises';
        case TaskType.meal:    return 'What to eat';
        case TaskType.water:   return 'Amount';
        case TaskType.challenge: return 'Details';
        case TaskType.custom:  return 'Notes';
      }
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Task',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Task name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Type',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TaskType.values.map((t) {
                  final sel = t == selectedType;
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: sel,
                    selectedColor: Colors.red,
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : Colors.black87,
                        fontSize: 12),
                    onSelected: (_) => setModal(() => selectedType = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              // Context-aware notes field
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: notesLabel(selectedType),
                  hintText: notesHint(selectedType),
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _timePicker(
                      ctx,
                      label: 'Start',
                      time: startTime,
                      onPicked: (t) => setModal(() => startTime = t),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timePicker(
                      ctx,
                      label: 'End',
                      time: endTime,
                      onPicked: (t) => setModal(() => endTime = t),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final task = PlanTask(
                      id: DateTime.now().millisecondsSinceEpoch % 100000,
                      title: titleCtrl.text.trim(),
                      type: selectedType,
                      startHour: startTime.hour,
                      startMinute: startTime.minute,
                      endHour: endTime.hour,
                      endMinute: endTime.minute,
                      notes: notesCtrl.text.trim(),
                    );
                    setState(() => _planTasks.add(task));
                    _savePlanTasks();
                    _scheduleNotification(task);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Add Task',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  void _showEditTaskDialog(int index, PlanTask existing) {
    final titleCtrl = TextEditingController(text: existing.title);
    final notesCtrl = TextEditingController(text: existing.notes);
    TaskType selectedType = existing.type;
    TimeOfDay startTime =
        TimeOfDay(hour: existing.startHour, minute: existing.startMinute);
    TimeOfDay endTime =
        TimeOfDay(hour: existing.endHour, minute: existing.endMinute);

    String Function(TaskType) notesLabel = (TaskType t) {
      switch (t) {
        case TaskType.workout:   return 'Exercises';
        case TaskType.meal:      return 'What to eat';
        case TaskType.water:     return 'Amount';
        case TaskType.challenge: return 'Details';
        case TaskType.custom:    return 'Notes';
      }
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Task',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Task name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Type',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: TaskType.values.map((t) {
                  final sel = t == selectedType;
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: sel,
                    selectedColor: Colors.red,
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : Colors.black87,
                        fontSize: 12),
                    onSelected: (_) => setModal(() => selectedType = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: notesLabel(selectedType),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _timePicker(ctx,
                        label: 'Start',
                        time: startTime,
                        onPicked: (t) => setModal(() => startTime = t)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timePicker(ctx,
                        label: 'End',
                        time: endTime,
                        onPicked: (t) => setModal(() => endTime = t)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final updated = PlanTask(
                      id: existing.id,
                      title: titleCtrl.text.trim(),
                      type: selectedType,
                      startHour: startTime.hour,
                      startMinute: startTime.minute,
                      endHour: endTime.hour,
                      endMinute: endTime.minute,
                      notes: notesCtrl.text.trim(),
                    );
                    _cancelNotification(existing.id);
                    setState(() => _planTasks[index] = updated);
                    _savePlanTasks();
                    _scheduleNotification(updated);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save Changes',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _timePicker(BuildContext ctx,
      {required String label,
      required TimeOfDay time,
      required ValueChanged<TimeOfDay> onPicked}) {
    return GestureDetector(
      onTap: () async {
        final picked =
            await showTimePicker(context: ctx, initialTime: time);
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, size: 16, color: Colors.grey),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.grey)),
                Text(time.format(context),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleTaskStart(PlanTask task, int index) {
    // Mark as started so "Mark Done" button appears on return
    setState(() {
      _planTasks[index] = task.copyWith(isStarted: true);
    });
    _savePlanTasks();
    switch (task.type) {
      case TaskType.workout:
        _tabNavService.goToWorkout();
        break;
      case TaskType.meal:
      case TaskType.water:
        _tabNavService.goToNutrition();
        break;
      case TaskType.challenge:
        _tabNavService.goToCommunity();
        break;
      case TaskType.custom:
        break;
    }
  }

  void _markTaskDone(int index) {
    final task = _planTasks[index];
    // Show green "Done" state briefly, then remove
    setState(() {
      _completingTaskIds.add(task.id);
      _planTasks[index] = task.copyWith(isDone: true);
    });
    _savePlanTasks();
    // After the green flash, remove from list â€” AnimatedList handles the slide
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _completingTaskIds.remove(task.id);
        _planTasks.removeWhere((t) => t.id == task.id);
      });
      _savePlanTasks();
    });
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

  void nextView() {
    _summaryPageController.animateToPage(1,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => showChart = true);
  }

  void prevView() {
    _summaryPageController.animateToPage(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() => showChart = false);
  }

  @override
  Widget build(BuildContext context) {
    // Auto-refresh if data is stale (older than 30 seconds)
    if (_lastRefreshTime != null && 
        DateTime.now().difference(_lastRefreshTime!) > const Duration(minutes: 5) &&
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

                          // Daily Summary / Chart swipeable pages
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
                              // Use a fixed height that fits both pages fully
                              SizedBox(
                                height: 330,
                                child: PageView(
                                  controller: _summaryPageController,
                                  onPageChanged: (i) =>
                                      setState(() => showChart = i == 1),
                                  children: [
                                    // Page 1: stats grid — wrap in SingleChildScrollView
                                    // so it doesn't overflow if content is taller
                                    SingleChildScrollView(
                                      physics: const NeverScrollableScrollPhysics(),
                                      child: _buildStatsGrid(),
                                    ),
                                    // Page 2: chart — let it use full height
                                    SingleChildScrollView(
                                      physics: const NeverScrollableScrollPhysics(),
                                      child: _buildChart(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Page indicator dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(2, (i) {
                                  final active = (showChart ? 1 : 0) == i;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    width: active ? 18 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: active
                                          ? const Color(0xFFE53935)
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Today's Plan
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Today's Plan",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D2D2D),
                                ),
                              ),
                              GestureDetector(
                                onTap: _showAddTaskDialog,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add,
                                          color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text('Add Task',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_planTasks.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey[200]!,
                                    style: BorderStyle.solid),
                              ),
                              child: Column(children: [
                                Icon(Icons.event_note_outlined,
                                    color: Colors.grey[400], size: 32),
                                const SizedBox(height: 8),
                                Text('No tasks planned yet',
                                    style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 13)),
                                const SizedBox(height: 4),
                                Text('Tap "Add Task" to plan your day',
                                    style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 11)),
                              ]),
                            )
                          else
                            ..._planTasks.asMap().entries.map((entry) {
                              final i = entry.key;
                              final task = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildPlanItem(task, i),
                              );
                            }),
                          const SizedBox(height: 24),

                          // Quick Actions
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Quick Actions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2D2D2D),
                                ),
                              ),
                              if (_shortcuts.isNotEmpty)
                                _isEditingShortcuts
                                    ? TextButton(
                                        onPressed: () => setState(() => _isEditingShortcuts = false),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                      )
                                    : PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert, color: Colors.grey[500], size: 20),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                            value: 'edit',
                                            child: Row(children: [
                                              Icon(Icons.edit_outlined, size: 18, color: Colors.black87),
                                              SizedBox(width: 10),
                                              Text('Edit'),
                                            ]),
                                          ),
                                        ],
                                        onSelected: (v) {
                                          if (v == 'edit') setState(() => _isEditingShortcuts = true);
                                        },
                                      ),
                            ],
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
    if (_isLoadingStats) {
      return Container(
        key: const ValueKey('chart'),
        height: 320,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    const metrics = [
      _MetricMeta('Cal Burned', Icons.local_fire_department, Color(0xFFE53935), 'kcal'),
      _MetricMeta('Cal Intake', Icons.restaurant, Color(0xFFFF9800), 'kcal'),
      _MetricMeta('Active Time', Icons.access_time, Color(0xFF43A047), 'min'),
      _MetricMeta('Workouts', Icons.fitness_center, Color(0xFF1E88E5), ''),
    ];

    final meta = metrics[_selectedMetric];
    final data = _currentChartData;
    final maxVal = data.isEmpty ? 10.0 : data.map((e) => e.value).fold(0.0, (a, b) => a > b ? a : b);

    return Container(
      key: const ValueKey('chart'),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, spreadRadius: 1),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Single centered dropdown as the chart title
          Center(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedMetric,
                icon: Icon(Icons.keyboard_arrow_down_rounded, color: meta.color, size: 20),
                borderRadius: BorderRadius.circular(12),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: meta.color),
                selectedItemBuilder: (context) => List.generate(metrics.length, (i) {
                  final m = metrics[i];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(m.icon, size: 18, color: m.color),
                      const SizedBox(width: 8),
                      Text(m.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: m.color)),
                    ],
                  );
                }),
                items: List.generate(metrics.length, (i) {
                  final m = metrics[i];
                  return DropdownMenuItem(
                    value: i,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(m.icon, size: 15, color: m.color),
                        const SizedBox(width: 8),
                        Text(m.label, style: const TextStyle(fontSize: 14, color: Color(0xFF2D2D2D))),
                      ],
                    ),
                  );
                }),
                onChanged: (i) { if (i != null) _onMetricChanged(i); },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Weekly / Monthly toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TimeToggleButton(
                label: 'Weekly',
                selected: !_isMonthlyView,
                onTap: () => setState(() { _isMonthlyView = false; _buildWeeklyChartData(); }),
              ),
              const SizedBox(width: 6),
              _TimeToggleButton(
                label: 'Monthly',
                selected: _isMonthlyView,
                onTap: () => setState(() { _isMonthlyView = true; _buildWeeklyChartData(); }),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bar chart
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: SizedBox(
              key: ValueKey('$_selectedMetric-$_isMonthlyView'),
              height: 175,
              child: data.isEmpty
                  ? Center(child: Text('No data', style: TextStyle(color: Colors.grey[400])))
                  : _buildBarChart(data, meta, maxVal),
            ),
          ),

          // Timeframe label below x-axis
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isMonthlyView ? 'Monthly' : 'Weekly',
                style: TextStyle(fontSize: 11, color: Colors.grey[400], letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChart _buildBarChart(List<ChartData> data, _MetricMeta meta, double maxVal) {
    final barWidth = _isMonthlyView ? 10.0 : 18.0;
    final leftReserved = _isMonthlyView ? 28.0 : 36.0;
    final labelFontSize = _isMonthlyView ? 9.0 : 10.0;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal > 0 ? maxVal * 1.25 : 10,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final suffix = meta.unit.isNotEmpty ? ' ${meta.unit}' : '';
              return BarTooltipItem(
                '${rod.toY.toInt()}$suffix',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx >= 0 && idx < data.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(data[idx].day,
                        style: TextStyle(fontSize: labelFontSize, color: const Color(0xFF888888))),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: leftReserved,
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: labelFontSize, color: const Color(0xFF888888)),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.grey.withOpacity(0.15), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: entry.value.value,
                color: meta.color,
                width: barWidth,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal > 0 ? maxVal * 1.25 : 10,
                  color: meta.color.withOpacity(0.07),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanItem(PlanTask task, int index) {
    final now = DateTime.now();
    final startDt = DateTime(now.year, now.month, now.day, task.startHour, task.startMinute);
    final endDt   = DateTime(now.year, now.month, now.day, task.endHour,   task.endMinute);
    final isActive    = now.isAfter(startDt) && now.isBefore(endDt);
    final isPast      = now.isAfter(endDt);
    final isCompleting = _completingTaskIds.contains(task.id);
    final timeStr = '${_fmt(task.startHour)}:${_fmt(task.startMinute)} - ${_fmt(task.endHour)}:${_fmt(task.endMinute)}';

    // While completing: show green card briefly, then it disappears via setState
    if (isCompleting) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key('task_${task.id}_${task.isDone}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) {
        _cancelNotification(task.id);
        setState(() => _planTasks.removeAt(index));
        _savePlanTasks();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: task.isDone ? const Color(0xFFF0FFF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: task.isDone
              ? Border.all(color: Colors.green.withOpacity(0.4), width: 1.5)
              : isActive
                  ? Border.all(color: Colors.red.withOpacity(0.4), width: 1.5)
                  : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, spreadRadius: 1)],
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: task.isDone ? Colors.green[50] : isPast ? Colors.grey[100] : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                task.isDone ? Icons.check_circle : task.type.icon,
                color: task.isDone ? Colors.green : isPast ? Colors.grey[400] : Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: task.isDone ? Colors.green[700] : isPast ? Colors.grey[400] : const Color(0xFF2D2D2D),
                            decoration: task.isDone || isPast ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                      if (isActive && !task.isDone) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                          child: const Text('NOW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                      if (task.isDone) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                          child: const Text('Done', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    task.type.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: task.isDone ? Colors.green[400] : isPast ? Colors.grey[300] : Colors.red[300],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 12, color: isPast || task.isDone ? Colors.grey[400] : const Color(0xFF666666)),
                  ),
                  if (task.notes.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.notes,
                      style: TextStyle(fontSize: 11, color: isPast || task.isDone ? Colors.grey[300] : Colors.grey[500], fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (task.isDone)
              const Icon(Icons.check_circle, color: Colors.green, size: 24)
            else if (task.isStarted)
              ElevatedButton(
                onPressed: () => _markTaskDone(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: const Text('Done', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              )
            else if (!isPast)
              ElevatedButton(
                onPressed: () => _handleTaskStart(task, index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? Colors.red : const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Text(task.type.actionLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              )
            else
              const Icon(Icons.check_circle_outline, color: Colors.grey, size: 22),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey[400], size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18, color: Colors.black87), SizedBox(width: 10), Text('Edit')])),
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red), SizedBox(width: 10), Text('Delete', style: TextStyle(color: Colors.red))])),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditTaskDialog(index, task);
                } else {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      title: const Text('Delete Task'),
                      content: Text('Remove "${task.title}" from today\'s plan?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _cancelNotification(task.id);
                            setState(() => _planTasks.removeAt(index));
                            _savePlanTasks();
                          },
                          child: const Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) => n.toString().padLeft(2, '0');

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
                  onTap: () => _tabNavService.goToNutrition(),
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
              ..._shortcuts.asMap().entries.map((entry) {
                final i = entry.key;
                final shortcut = entry.value;
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 44) / 2,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _buildQuickAction(
                        shortcut.icon,
                        shortcut.label,
                        onTap: _isEditingShortcuts ? null : () => _handleShortcutTap(shortcut.route),
                      ),
                      // Remove button â€” only visible in edit mode
                      if (_isEditingShortcuts)
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _shortcuts.removeAt(i);
                                if (_shortcuts.isEmpty) _isEditingShortcuts = false;
                              });
                              _saveShortcuts();
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 13),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
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

class _MetricMeta {
  final String label;
  final IconData icon;
  final Color color;
  final String unit;
  const _MetricMeta(this.label, this.icon, this.color, this.unit);
}

class _TimeToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TimeToggleButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFB71C1C) : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ Today's Plan models â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

enum TaskType {
  workout,
  meal,
  water,
  challenge,
  custom;

  String get label {
    switch (this) {
      case TaskType.workout: return 'Workout';
      case TaskType.meal:    return 'Meal';
      case TaskType.water:   return 'Water';
      case TaskType.challenge: return 'Challenge';
      case TaskType.custom:  return 'Custom';
    }
  }

  String get actionLabel {
    switch (this) {
      case TaskType.workout:   return 'START';
      case TaskType.meal:      return 'LOG';
      case TaskType.water:     return 'LOG';
      case TaskType.challenge: return 'VIEW';
      case TaskType.custom:    return 'OPEN';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskType.workout:   return Icons.fitness_center;
      case TaskType.meal:      return Icons.restaurant;
      case TaskType.water:     return Icons.water_drop;
      case TaskType.challenge: return Icons.emoji_events;
      case TaskType.custom:    return Icons.task_alt;
    }
  }
}

class PlanTask {
  final int id;
  final String title;
  final TaskType type;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final String notes;
  final bool isStarted; // user tapped START at least once
  final bool isDone;    // user marked as completed

  PlanTask({
    required this.id,
    required this.title,
    required this.type,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.notes = '',
    this.isStarted = false,
    this.isDone = false,
  });

  PlanTask copyWith({
    bool? isStarted,
    bool? isDone,
    String? title,
    TaskType? type,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    String? notes,
  }) => PlanTask(
    id: id,
    title: title ?? this.title,
    type: type ?? this.type,
    startHour: startHour ?? this.startHour,
    startMinute: startMinute ?? this.startMinute,
    endHour: endHour ?? this.endHour,
    endMinute: endMinute ?? this.endMinute,
    notes: notes ?? this.notes,
    isStarted: isStarted ?? this.isStarted,
    isDone: isDone ?? this.isDone,
  );

  @override
  String toString() {
    final safeNotes = notes.replaceAll('Â§Â§', '');
    // format: id|title|typeIdx|sh|sm|eh|em|isStarted|isDoneÂ§Â§notes
    return '$id|$title|${type.index}|$startHour|$startMinute|$endHour|$endMinute|${isStarted ? 1 : 0}|${isDone ? 1 : 0}Â§Â§$safeNotes';
  }

  factory PlanTask.fromString(String s) {
    final parts = s.split('Â§Â§');
    final p = parts[0].split('|');
    return PlanTask(
      id: int.parse(p[0]),
      title: p[1],
      type: TaskType.values[int.parse(p[2])],
      startHour: int.parse(p[3]),
      startMinute: int.parse(p[4]),
      endHour: int.parse(p[5]),
      endMinute: int.parse(p[6]),
      isStarted: p.length > 7 ? p[7] == '1' : false,
      isDone: p.length > 8 ? p[8] == '1' : false,
      notes: parts.length > 1 ? parts[1] : '',
    );
  }
}

