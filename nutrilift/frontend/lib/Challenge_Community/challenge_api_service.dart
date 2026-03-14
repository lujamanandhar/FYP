import 'package:dio/dio.dart';
import '../services/dio_client.dart';

// ==================== Models ====================

class ChallengeModel {
  final String id;
  final String name;
  final String description;
  final String challengeType; // 'nutrition' | 'workout' | 'mixed'
  final double goalValue;
  final String unit;
  final DateTime startDate;
  final DateTime endDate;
  final double participantProgress;
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
    required this.isJoined,
  });

  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    final progress = (json['participant_progress'] as num?)?.toDouble() ?? 0.0;
    return ChallengeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      challengeType: json['challenge_type'] as String,
      goalValue: (json['goal_value'] as num).toDouble(),
      unit: json['unit'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      participantProgress: progress,
      isJoined: progress > 0,
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
