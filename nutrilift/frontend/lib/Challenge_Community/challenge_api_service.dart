import 'package:dio/dio.dart';
import '../services/dio_client.dart';

// ==================== Models ====================

class ChallengeModel {
  final String id;
  final String name;
  final String description;
  final String challengeType;
  final double goalValue;
  final String unit;
  final DateTime startDate;
  final DateTime endDate;
  double participantProgress;
  final bool isOfficial;
  final String createdByUsername;
  final String? createdById;
  bool isJoined;

  ChallengeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.challengeType,
    required this.goalValue,
    required this.unit,
    required this.startDate,
    required this.endDate,
    required this.participantProgress,
    required this.isOfficial,
    required this.createdByUsername,
    this.createdById,
    required this.isJoined,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      challengeType: json['challenge_type'] as String,
      goalValue: (json['goal_value'] as num).toDouble(),
      unit: json['unit'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      participantProgress: (json['participant_progress'] as num?)?.toDouble() ?? 0.0,
      isOfficial: json['is_official'] as bool? ?? false,
      createdByUsername: json['created_by_username'] as String? ?? 'NutriLift',
      createdById: json['created_by_id'] as String?,
      isJoined: json['is_joined'] as bool? ?? false,
    );
  }
}

class ChallengeParticipantModel {
  final int rank;
  final String userId;
  final String username;
  final String? avatarUrl;
  final double progress;

  ChallengeParticipantModel({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.progress,
  });

  factory ChallengeParticipantModel.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipantModel(
      rank: json['rank'] as int,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      progress: (json['progress'] as num).toDouble(),
    );
  }
}

class BadgeModel {
  final String badgeId;
  final String name;
  final String description;
  final String iconUrl;
  final int pointsReward;
  final DateTime earnedAt;

  BadgeModel({
    required this.badgeId,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.pointsReward,
    required this.earnedAt,
  });

  factory BadgeModel.fromJson(Map<String, dynamic> json) {
    return BadgeModel(
      badgeId: json['badge_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['icon_url'] as String,
      pointsReward: json['points_reward'] as int,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }
}

class StreakModel {
  final int currentStreak;
  final int longestStreak;
  final String? lastActiveDate;

  StreakModel({
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveDate,
  });

  factory StreakModel.fromJson(Map<String, dynamic> json) {
    return StreakModel(
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      lastActiveDate: json['last_active_date'] as String?,
    );
  }
}

// ── Daily Log Models ──────────────────────────────────────────────────────

class DailyTaskItem {
  final String label;
  bool completed;

  DailyTaskItem({required this.label, required this.completed});

  factory DailyTaskItem.fromJson(Map<String, dynamic> json) {
    return DailyTaskItem(
      label: json['label'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'label': label, 'completed': completed};
}

class DailyMediaItem {
  final String url;
  final bool isVideo;

  DailyMediaItem({required this.url, required this.isVideo});

  factory DailyMediaItem.fromJson(Map<String, dynamic> json) {
    return DailyMediaItem(
      url: json['url'] as String,
      isVideo: json['is_video'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'url': url, 'is_video': isVideo};
}

class ChallengeDailyLogModel {
  final String id;
  final int dayNumber;
  List<DailyTaskItem> taskItems;
  List<DailyMediaItem> mediaUrls;
  final bool isComplete;
  final String? completedAt;

  ChallengeDailyLogModel({
    required this.id,
    required this.dayNumber,
    required this.taskItems,
    required this.mediaUrls,
    required this.isComplete,
    this.completedAt,
  });

  factory ChallengeDailyLogModel.fromJson(Map<String, dynamic> json) {
    return ChallengeDailyLogModel(
      id: json['id'] as String,
      dayNumber: json['day_number'] as int,
      taskItems: (json['task_items'] as List<dynamic>? ?? [])
          .map((e) => DailyTaskItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaUrls: (json['media_urls'] as List<dynamic>? ?? [])
          .map((e) => DailyMediaItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      isComplete: json['is_complete'] as bool? ?? false,
      completedAt: json['completed_at'] as String?,
    );
  }

  bool get allTasksComplete =>
      taskItems.isEmpty || taskItems.every((t) => t.completed);
}

// ==================== Service ====================

/// API service for challenge and gamification endpoints.
///
/// Validates: Requirements 3.1–3.5, 4.1–4.2
class ChallengeApiService {
  final DioClient _dioClient;
  late final Dio _dio;

  ChallengeApiService([DioClient? dioClient])
      : _dioClient = dioClient ?? DioClient() {
    _dio = _dioClient.dio;
  }

  /// Fetch all active challenges for the current user.
  ///
  /// Validates: Requirement 3.1
  Future<List<ChallengeModel>> fetchActiveChallenges() async {
    try {
      final response = await _dio.get('/challenges/active/');
      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['results'] as List? ?? []);
      return data
          .map((e) => ChallengeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch active challenges');
    }
  }

  /// Create a new user challenge.
  Future<ChallengeModel> createChallenge({
    required String name,
    required String description,
    required String challengeType,
    required double goalValue,
    required String unit,
    required DateTime startDate,
    required DateTime endDate,
    List<Map<String, String>> defaultTasks = const [],
  }) async {
    try {
      final response = await _dio.post('/challenges/create/', data: {
        'name': name,
        'description': description,
        'challenge_type': challengeType,
        'goal_value': goalValue,
        'unit': unit,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        if (defaultTasks.isNotEmpty) 'default_tasks': defaultTasks,
      });
      return ChallengeModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to create challenge');
    }
  }

  /// Join a challenge by ID.
  ///
  /// Validates: Requirement 3.2
  Future<void> joinChallenge(String id) async {
    try {
      await _dio.post('/challenges/$id/join/');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to join challenge');
    }
  }

  /// Leave a challenge by ID.
  ///
  /// Validates: Requirement 3.5
  Future<void> leaveChallenge(String id) async {
    try {
      await _dio.delete('/challenges/$id/leave/');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to leave challenge');
    }
  }

  /// Delete a challenge by ID (owner only).
  Future<void> deleteChallenge(String id) async {
    try {
      await _dio.delete('/challenges/$id/');
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to delete challenge');
    }
  }

  /// Fetch the leaderboard for a challenge (top 10 participants).
  ///
  /// Validates: Requirement 3.4
  Future<List<ChallengeParticipantModel>> fetchLeaderboard(String id) async {
    try {
      final response = await _dio.get('/challenges/$id/leaderboard/');
      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['results'] as List? ?? []);
      return data
          .map((e) =>
              ChallengeParticipantModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch leaderboard');
    }
  }

  /// Fetch badges earned by the current user.
  ///
  /// Validates: Requirement 4.1
  Future<List<BadgeModel>> fetchBadges() async {
    try {
      final response = await _dio.get('/challenges/badges/');
      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['results'] as List? ?? []);
      return data
          .map((e) => BadgeModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch badges');
    }
  }

  /// Fetch the current user's streak.
  ///
  /// Validates: Requirement 4.2
  Future<StreakModel> fetchStreak() async {
    try {
      final response = await _dio.get('/challenges/streak/');
      return StreakModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch streak');
    }
  }

  // ── Daily Log API methods ───────────────────────────────────────────────

  /// Fetch (or create) today's daily log for a challenge.
  /// Requirements: 23.1
  Future<ChallengeDailyLogModel> fetchTodayLog(String challengeId) async {
    try {
      final response = await _dio.get('/challenges/$challengeId/daily-log/');
      return ChallengeDailyLogModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch today\'s log');
    }
  }

  /// Update task_items and/or media_urls for today's log.
  /// Requirements: 23.3, 23.6
  Future<ChallengeDailyLogModel> updateDailyLog(
    String challengeId, {
    List<DailyTaskItem>? taskItems,
    List<DailyMediaItem>? mediaUrls,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (taskItems != null) data['task_items'] = taskItems.map((t) => t.toJson()).toList();
      if (mediaUrls != null) data['media_urls'] = mediaUrls.map((m) => m.toJson()).toList();
      final response = await _dio.patch('/challenges/$challengeId/daily-log/', data: data);
      return ChallengeDailyLogModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to update daily log');
    }
  }

  /// Mark today's log complete, optionally sharing to community.
  /// Returns map with 'log' and optional 'shared_post'.
  /// Requirements: 24.1–24.7
  Future<Map<String, dynamic>> completeDailyLog(
    String challengeId, {
    bool shareToCommunity = false,
  }) async {
    try {
      final response = await _dio.post(
        '/challenges/$challengeId/daily-log/complete/',
        data: {'share_to_community': shareToCommunity},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to complete daily log');
    }
  }

  /// Fetch all daily logs for a challenge (ordered by day_number asc).
  /// Requirements: 23.9, 23.10
  Future<List<ChallengeDailyLogModel>> fetchAllDailyLogs(String challengeId) async {
    try {
      final response = await _dio.get('/challenges/$challengeId/daily-logs/');
      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['results'] as List? ?? []);
      return data
          .map((e) => ChallengeDailyLogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch daily logs');
    }
  }

  Exception _handleError(DioException e, String defaultMessage) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    String message = defaultMessage;
    if (data is Map<String, dynamic>) {
      message = (data['detail'] ?? data['message'] ?? data['error'] ?? defaultMessage)
          .toString();
    }
    return Exception('$message (HTTP $status)');
  }
}
