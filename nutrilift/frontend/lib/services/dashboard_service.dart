import 'package:intl/intl.dart';
import 'dio_client.dart';

class DashboardStats {
  final int todayCaloriesBurned;
  final int todayWorkouts;
  final int todayDurationMinutes;
  final int todayCaloriesIntake;
  final int activeTimeMinutes;
  final Map<String, dynamic> workoutByDate;
  final int currentStreak;
  final int longestStreak;

  DashboardStats({
    required this.todayCaloriesBurned,
    required this.todayWorkouts,
    required this.todayDurationMinutes,
    required this.todayCaloriesIntake,
    required this.activeTimeMinutes,
    required this.workoutByDate,
    required this.currentStreak,
    required this.longestStreak,
  });
}

class DashboardService {
  final _dioClient = DioClient();

  Future<DashboardStats> getDashboardStats({int activeTimeMinutes = 0}) async {
    final dio = _dioClient.dio;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    // Fetch full current year for monthly chart
    final yearStart = DateTime(now.year, 1, 1);

    // Fetch today's workout history to get today's calories burned and workout count
    final historyResponse = await dio.get('/workouts/logs/get_history/');
    final List<dynamic> allLogs = historyResponse.data as List? ?? [];
    
    print('📊 Dashboard: Fetched ${allLogs.length} workout logs');

    int todayCaloriesBurned = 0;
    int todayWorkouts = 0;
    int todayDuration = 0;

    for (final log in allLogs) {
      final logDateRaw = log['date'] ?? log['logged_at'];
      if (logDateRaw == null) continue;
      final logDate = DateTime.tryParse(logDateRaw.toString())?.toLocal();
      if (logDate == null) continue;
      final logDateStr = DateFormat('yyyy-MM-dd').format(logDate);
      
      if (logDateStr == todayStr) {
        todayWorkouts++;
        todayCaloriesBurned += double.parse(
          (log['calories_burned'] ?? '0').toString(),
        ).toInt();
        todayDuration += (log['duration'] ?? log['duration_minutes'] ?? 0) as int;
      }
    }

    // Fetch today's nutrition progress for calorie intake
    int todayCaloriesIntake = 0;
    try {
      final nutritionResponse = await dio.get(
        '/nutrition/nutrition-progress/',
        queryParameters: {'date_from': todayStr, 'date_to': todayStr},
      );
      final List<dynamic> progressResults;
      if (nutritionResponse.data is List) {
        progressResults = nutritionResponse.data as List;
      } else if (nutritionResponse.data is Map && nutritionResponse.data.containsKey('results')) {
        progressResults = nutritionResponse.data['results'] as List;
      } else {
        progressResults = [];
      }
      if (progressResults.isNotEmpty) {
        todayCaloriesIntake = double.parse(
          (progressResults.first['total_calories'] ?? '0').toString(),
        ).toInt();
      }
    } catch (_) {}

    // Fetch full-year workout stats for the chart (calories burned + workouts per date)
    Map<String, dynamic> workoutByDate = {};
    try {
      final statsResponse = await dio.get(
        '/workouts/logs/statistics/',
        queryParameters: {
          'start_date': yearStart.toIso8601String(),
          'end_date': now.toIso8601String(),
        },
      );
      workoutByDate = Map<String, dynamic>.from(
        statsResponse.data['workout_by_date'] ?? {},
      );
    } catch (_) {}

    // Merge full-year nutrition intake per date into workoutByDate
    try {
      final yearStartStr = DateFormat('yyyy-MM-dd').format(yearStart);
      final nutritionResponse = await dio.get(
        '/nutrition/nutrition-progress/',
        queryParameters: {'date_from': yearStartStr, 'date_to': todayStr, 'page_size': 400},
      );
      final List<dynamic> progressResults;
      if (nutritionResponse.data is List) {
        progressResults = nutritionResponse.data as List;
      } else if (nutritionResponse.data is Map && nutritionResponse.data.containsKey('results')) {
        progressResults = nutritionResponse.data['results'] as List;
      } else {
        progressResults = [];
      }
      for (final p in progressResults) {
        final dateStr = p['progress_date']?.toString() ?? '';
        if (dateStr.isEmpty) continue;
        workoutByDate.putIfAbsent(dateStr, () => <String, dynamic>{});
        workoutByDate[dateStr]['intake'] =
            double.tryParse((p['total_calories'] ?? '0').toString())?.toInt() ?? 0;
      }
    } catch (_) {}

    // Fetch streak
    int currentStreak = 0;
    int longestStreak = 0;
    try {
      final streakResponse = await dio.get('/challenges/streak/');
      currentStreak = streakResponse.data['current_streak'] ?? 0;
      longestStreak = streakResponse.data['longest_streak'] ?? 0;
    } catch (_) {}

    return DashboardStats(
      todayCaloriesBurned: todayCaloriesBurned,
      todayWorkouts: todayWorkouts,
      todayDurationMinutes: todayDuration,
      todayCaloriesIntake: todayCaloriesIntake,
      activeTimeMinutes: activeTimeMinutes,
      workoutByDate: workoutByDate,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
    );
  }

  Future<int> getCurrentStreak() async {
    final dio = _dioClient.dio;
    try {
      final streakResponse = await dio.get('/challenges/streak/');
      return streakResponse.data['current_streak'] ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
