import 'package:flutter/foundation.dart';
import 'challenge_api_service.dart';

/// Provider for challenge and gamification state.
///
/// Validates: Requirements 17.1, 17.3
class ChallengeProvider extends ChangeNotifier {
  final ChallengeApiService _service;

  List<ChallengeModel> challenges = [];
  bool isLoading = false;
  String? error;
  StreakModel? streak;
  List<BadgeModel> badges = [];

  ChallengeProvider(ChallengeApiService service) : _service = service;

  /// Fetch all active challenges from the API.
  ///
  /// Sets [isLoading] during the request and [error] on failure.
  Future<void> fetchChallenges() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      challenges = await _service.fetchActiveChallenges();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Join a challenge by [id].
  ///
  /// Updates the matching challenge in-place (sets isJoined=true) without
  /// a full list refresh — Requirement 17.3.
  Future<void> joinChallenge(String id) async {
    try {
      await _service.joinChallenge(id);
      final index = challenges.indexWhere((c) => c.id == id);
      if (index != -1) {
        challenges[index].isJoined = true;
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Leave a challenge by [id].
  ///
  /// Updates the matching challenge in-place (sets isJoined=false) without
  /// a full list refresh.
  Future<void> leaveChallenge(String id) async {
    try {
      await _service.leaveChallenge(id);
      final index = challenges.indexWhere((c) => c.id == id);
      if (index != -1) {
        challenges[index].isJoined = false;
        notifyListeners();
      }
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch the current user's streak.
  Future<void> fetchStreak() async {
    try {
      streak = await _service.fetchStreak();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }

  /// Fetch badges earned by the current user.
  Future<void> fetchBadges() async {
    try {
      badges = await _service.fetchBadges();
      notifyListeners();
    } catch (e) {
      error = e.toString();
      notifyListeners();
    }
  }
}
