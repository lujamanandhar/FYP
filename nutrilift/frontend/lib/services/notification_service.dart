import 'dart:async';
import 'package:flutter/material.dart';
import 'dio_client.dart';

class AppNotification {
  final String id;
  final String type; // social, challenge, streak, system
  final String title;
  final String message;
  final bool isRead;
  final String actionUrl;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.actionUrl,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'system',
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool? ?? false,
      actionUrl: json['action_url'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        isRead: isRead ?? this.isRead,
        actionUrl: actionUrl,
        createdAt: createdAt,
      );

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  IconData get icon {
    switch (type) {
      case 'social': return Icons.people_outline;
      case 'challenge': return Icons.emoji_events_outlined;
      case 'streak': return Icons.local_fire_department;
      default: return Icons.notifications_outlined;
    }
  }

  Color get color {
    switch (type) {
      case 'social': return const Color(0xFF1976D2);
      case 'challenge': return const Color(0xFFFB8C00);
      case 'streak': return const Color(0xFFE53935);
      default: return const Color(0xFF757575);
    }
  }
}

/// Singleton notification service with polling support.
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _dio = DioClient();
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  Timer? _pollTimer;
  bool _isPolling = false;

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  /// Start polling every [intervalSeconds] seconds.
  void startPolling({int intervalSeconds = 15}) {
    _pollTimer?.cancel();
    _fetchNotifications(); // immediate first fetch
    _pollTimer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      _fetchNotifications();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _fetchNotifications() async {
    if (_isPolling) return;
    _isPolling = true;
    try {
      final response = await _dio.dio.get('/notifications/');
      final data = response.data as Map<String, dynamic>;
      final list = (data['notifications'] as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList();
      final newUnread = data['unread_count'] as int? ?? 0;

      if (_unreadCount != newUnread || list.length != _notifications.length) {
        _notifications = list;
        _unreadCount = newUnread;
        notifyListeners();
      }
    } catch (_) {
      // Silently fail — don't disrupt the UI
    } finally {
      _isPolling = false;
    }
  }

  Future<void> refresh() => _fetchNotifications();

  Future<void> markRead(String id) async {
    try {
      await _dio.dio.patch('/notifications/$id/read/');
      _notifications = _notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _dio.dio.patch('/notifications/read-all/');
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}
