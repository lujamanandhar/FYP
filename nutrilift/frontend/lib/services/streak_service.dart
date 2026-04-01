import 'dio_client.dart';

class StreakData {
  final int currentStreak;
  final int longestStreak;

  const StreakData({this.currentStreak = 0, this.longestStreak = 0});

  factory StreakData.fromJson(Map<String, dynamic> json) => StreakData(
        currentStreak: json['current_streak'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
      );
}

class AllStreaks {
  final StreakData workout;
  final StreakData nutrition;
  final StreakData challenge;

  const AllStreaks({
    this.workout = const StreakData(),
    this.nutrition = const StreakData(),
    this.challenge = const StreakData(),
  });

  int get total => workout.currentStreak + nutrition.currentStreak + challenge.currentStreak;
}

class StreakService {
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  final _dioClient = DioClient();

  Future<AllStreaks> fetchAllStreaks() async {
    try {
      final response = await _dioClient.dio.get('/challenges/streaks/all/');
      final data = response.data as Map<String, dynamic>;
      return AllStreaks(
        workout: StreakData.fromJson(data['workout'] as Map<String, dynamic>? ?? {}),
        nutrition: StreakData.fromJson(data['nutrition'] as Map<String, dynamic>? ?? {}),
        challenge: StreakData.fromJson(data['challenge'] as Map<String, dynamic>? ?? {}),
      );
    } catch (_) {
      return const AllStreaks();
    }
  }

  Future<StreakData> fetchWorkoutStreak() async {
    try {
      final all = await fetchAllStreaks();
      return all.workout;
    } catch (_) {
      return const StreakData();
    }
  }

  Future<StreakData> fetchNutritionStreak() async {
    try {
      final all = await fetchAllStreaks();
      return all.nutrition;
    } catch (_) {
      return const StreakData();
    }
  }

  Future<StreakData> fetchChallengeStreak() async {
    try {
      final all = await fetchAllStreaks();
      return all.challenge;
    } catch (_) {
      return const StreakData();
    }
  }
}
