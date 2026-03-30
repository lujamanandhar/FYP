import 'dart:async';

/// Service to notify the home page when dashboard data needs to be refreshed.
/// 
/// This allows other screens (nutrition, workout) to trigger a refresh
/// of the home page dashboard when they make changes.
class DashboardRefreshService {
  // Singleton pattern
  static final DashboardRefreshService _instance = DashboardRefreshService._internal();
  factory DashboardRefreshService() => _instance;
  DashboardRefreshService._internal();

  // Stream controller for refresh events
  final _refreshController = StreamController<void>.broadcast();

  /// Stream that emits when dashboard should refresh
  Stream<void> get refreshStream => _refreshController.stream;

  /// Trigger a dashboard refresh
  void notifyRefresh() {
    if (!_refreshController.isClosed) {
      _refreshController.add(null);
    }
  }

  /// Dispose the service (call on app shutdown)
  void dispose() {
    _refreshController.close();
  }
}
