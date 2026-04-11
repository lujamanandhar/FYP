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
  final bool isPaid;
  final double price;
  final String currency;
  final String prizeDescription;
  final bool hasPaid;
  final int? maxParticipants;
  final int participantCount;
  final int? spotsLeft;

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
    this.isPaid = false,
    this.price = 0,
    this.currency = 'NPR',
    this.prizeDescription = '',
    this.hasPaid = true,
    this.maxParticipants,
    this.participantCount = 0,
    this.spotsLeft,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    return ChallengeModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      challengeType: json['challenge_type'] as String? ?? '',
      goalValue: (json['goal_value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      participantProgress: (json['participant_progress'] as num?)?.toDouble() ?? 0.0,
      isOfficial: json['is_official'] as bool? ?? false,
      createdByUsername: json['created_by_username'] as String? ?? 'NutriLift',
      createdById: json['created_by_id'] as String?,
      isJoined: json['is_joined'] as bool? ?? false,
      isPaid: json['is_paid'] as bool? ?? false,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      currency: json['currency'] as String? ?? 'NPR',
      prizeDescription: json['prize_description'] as String? ?? '',
      hasPaid: json['has_paid'] as bool? ?? true,
      maxParticipants: json['max_participants'] as int?,
      participantCount: json['participant_count'] as int? ?? 0,
      spotsLeft: json['spots_left'] as int?,
    );
  }
}

class ChallengeParticipantModel {
  final int rank;
  final String userId;
  final String username;
  final String? avatarUrl;
  final double progress;
  final int currentStreak;
  final String? email;
  final String? participantId;

  ChallengeParticipantModel({
    required this.rank,
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.progress,
    this.currentStreak = 0,
    this.email,
    this.participantId,
  });

  factory ChallengeParticipantModel.fromJson(Map<String, dynamic> json) {
    return ChallengeParticipantModel(
      rank: json['rank'] as int? ?? 0,
      userId: json['user_id'] as String? ?? '',
      username: (json['username'] ?? json['name'] ?? '') as String,
      avatarUrl: json['avatar_url'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      currentStreak: json['current_streak'] as int? ?? 0,
      email: json['email'] as String?,
      participantId: json['participant_id'] as String?,
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
      badgeId: json['badge_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      iconUrl: json['icon_url'] as String? ?? '',
      pointsReward: json['points_reward'] as int? ?? 0,
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
  final String type; // 'manual', 'exercise', 'food'
  bool completed;

  // Exercise task fields
  final String? exerciseName;
  final int? targetReps;

  // Food task fields
  final String? foodName;
  final double? targetGrams;

  // Verification result (from verify endpoint)
  bool? verified;
  double? actualValue;
  double? targetValue;
  String? verificationMessage;

  DailyTaskItem({
    required this.label,
    this.type = 'manual',
    required this.completed,
    this.exerciseName,
    this.targetReps,
    this.foodName,
    this.targetGrams,
    this.verified,
    this.actualValue,
    this.targetValue,
    this.verificationMessage,
  });

  bool get isManual => type == 'manual';
  bool get isStructured => type == 'exercise' || type == 'food';

  factory DailyTaskItem.fromJson(Map<String, dynamic> json) {
    return DailyTaskItem(
      label: json['label'] as String? ?? '',
      type: json['type'] as String? ?? 'manual',
      completed: json['completed'] as bool? ?? false,
      exerciseName: json['exercise_name'] as String?,
      targetReps: json['target_reps'] as int?,
      foodName: json['food_name'] as String?,
      targetGrams: (json['target_grams'] as num?)?.toDouble(),
      verified: json['verified'] as bool?,
      actualValue: (json['actual_value'] as num?)?.toDouble(),
      targetValue: (json['target_value'] as num?)?.toDouble(),
      verificationMessage: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'label': label, 'type': type, 'completed': completed};
    if (exerciseName != null) m['exercise_name'] = exerciseName;
    if (targetReps != null) m['target_reps'] = targetReps;
    if (foodName != null) m['food_name'] = foodName;
    if (targetGrams != null) m['target_grams'] = targetGrams;
    return m;
  }
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

  bool get allTasksComplete {
    if (taskItems.isEmpty) return true;
    return taskItems.every((t) {
      if (t.isStructured) return t.verified == true;
      return t.completed;
    });
  }
}

class ChallengeCompletionModel {
  final String id;
  final String certificateNumber;
  final String challengeId;
  final String challengeName;
  final String challengeType;
  final int daysTaken;
  final int? rank;
  final int totalParticipants;
  final DateTime completedAt;
  final String prizeDescription;
  final bool isOfficial;

  ChallengeCompletionModel({
    required this.id,
    required this.certificateNumber,
    required this.challengeId,
    required this.challengeName,
    required this.challengeType,
    required this.daysTaken,
    this.rank,
    required this.totalParticipants,
    required this.completedAt,
    required this.prizeDescription,
    required this.isOfficial,
  });

  factory ChallengeCompletionModel.fromJson(Map<String, dynamic> json) {
    return ChallengeCompletionModel(
      id: json['id'] as String,
      certificateNumber: json['certificate_number'] as String,
      challengeId: json['challenge_id'] as String,
      challengeName: json['challenge_name'] as String,
      challengeType: json['challenge_type'] as String,
      daysTaken: json['days_taken'] as int? ?? 0,
      rank: json['rank'] as int?,
      totalParticipants: json['total_participants'] as int? ?? 0,
      completedAt: DateTime.parse(json['completed_at'] as String),
      prizeDescription: json['prize_description'] as String? ?? '',
      isOfficial: json['is_official'] as bool? ?? false,
    );
  }
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

  /// Verify today's tasks against actual workout/nutrition logs.
  Future<Map<String, dynamic>> verifyTodayLog(String challengeId) async {
    try {
      final response = await _dio.get('/challenges/$challengeId/daily-log/verify/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to verify daily log');
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

  /// Initiate eSewa payment for a paid challenge.
  Future<Map<String, dynamic>> initiateEsewaPayment(String challengeId) async {
    try {
      final response = await _dio.post('/challenges/$challengeId/pay/initiate/');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to initiate payment');
    }
  }

  /// Fetch all challenge completion certificates for the current user.
  Future<List<ChallengeCompletionModel>> fetchCompletions() async {
    try {
      final response = await _dio.get('/challenges/completions/');
      final List<dynamic> data = response.data is List
          ? response.data as List
          : (response.data['results'] as List? ?? []);
      return data
          .map((e) => ChallengeCompletionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e, 'Failed to fetch completions');
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
