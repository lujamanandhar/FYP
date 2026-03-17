import 'package:flutter/foundation.dart';
import '../services/token_service.dart';
import 'challenge_api_service.dart';

/// Provider for challenge and gamification state.
class ChallengeProvider extends ChangeNotifier {
  final ChallengeApiService _service;

  List<ChallengeModel> challenges = [];
  bool isLoading = false;
  String? error;
  StreakModel? streak;
  List<BadgeModel> badges = [];
  String? _currentUserId;

  ChallengeProvider(ChallengeApiService service) : _service = service {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final token = await TokenService().getToken();
    if (token == null) return;
    final payload = TokenService().getTokenPayload(token);
    final uid = payload?['user_id'];
    _currentUserId = uid != null ? uid.toString() : null;
    notifyListeners();
  }

  String? get currentUserId => _currentUserId;

  /// Challenges the current user has joined.
  List<ChallengeModel> get myChallenges =>
      challenges.where((c) => c.isJoined).toList();

  /// Challenges created by the current user.
  List<ChallengeModel> get createdByMe =>
      challenges.where((c) => c.createdById == _currentUserId).toList();

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

  /// Delete a challenge created by the current user.
  Future<bool> deleteChallenge(String id) async {
    try {
      await _service.deleteChallenge(id);
      challenges.removeWhere((c) => c.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
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

  /// Create a new user challenge and prepend it to the list.
  Future<bool> createChallenge({
    required String name,
    required String description,
    required String challengeType,
    required double goalValue,
    required String unit,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final challenge = await _service.createChallenge(
        name: name,
        description: description,
        challengeType: challengeType,
        goalValue: goalValue,
        unit: unit,
        startDate: startDate,
        endDate: endDate,
      );
      challenges.add(challenge);
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
