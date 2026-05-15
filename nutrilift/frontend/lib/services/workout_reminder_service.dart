import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// A single workout reminder — fires weekly on selected days at a set time.
class WorkoutReminder {
  final String id;
  final String label; // e.g. "Morning Workout"
  final TimeOfDay time;
  final List<int> days; // 1=Mon … 7=Sun (ISO weekday)
  final bool enabled;

  WorkoutReminder({
    required this.id,
    required this.label,
    required this.time,
    required this.days,
    required this.enabled,
  });

  WorkoutReminder copyWith({String? label, TimeOfDay? time, List<int>? days, bool? enabled}) =>
      WorkoutReminder(
        id: id,
        label: label ?? this.label,
        time: time ?? this.time,
        days: days ?? this.days,
        enabled: enabled ?? this.enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'hour': time.hour,
        'minute': time.minute,
        'days': days,
        'enabled': enabled,
      };

  factory WorkoutReminder.fromJson(Map<String, dynamic> j) => WorkoutReminder(
        id: j['id'] as String,
        label: j['label'] as String,
        time: TimeOfDay(hour: j['hour'] as int, minute: j['minute'] as int),
        days: List<int>.from(j['days'] as List),
        enabled: j['enabled'] as bool? ?? true,
      );

  String get timeString {
    final h = time.hour;
    final m = time.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '$hour12:$m $period';
  }

  String get daysString {
    if (days.isEmpty) return 'No days selected';
    if (days.length == 7) return 'Every day';
    const names = {1: 'Mon', 2: 'Tue', 3: 'Wed', 4: 'Thu', 5: 'Fri', 6: 'Sat', 7: 'Sun'};
    final sorted = List<int>.from(days)..sort();
    return sorted.map((d) => names[d]!).join(', ');
  }
}

/// Manages workout reminders using flutter_local_notifications weekly scheduling.
class WorkoutReminderService {
  static final WorkoutReminderService _instance = WorkoutReminderService._internal();
  factory WorkoutReminderService() => _instance;
  WorkoutReminderService._internal();

  static const _prefsKey = 'workout_reminders';
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));
    _initialized = true;
  }

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<List<WorkoutReminder>> loadReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => WorkoutReminder.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveReminders(List<WorkoutReminder> reminders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(reminders.map((r) => r.toJson()).toList()));
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────────

  Future<void> addReminder(WorkoutReminder reminder) async {
    final list = await loadReminders();
    list.add(reminder);
    await _saveReminders(list);
    if (reminder.enabled) await _scheduleReminder(reminder);
  }

  Future<void> updateReminder(WorkoutReminder reminder) async {
    final list = await loadReminders();
    final idx = list.indexWhere((r) => r.id == reminder.id);
    if (idx == -1) return;
    await _cancelReminder(list[idx]);
    list[idx] = reminder;
    await _saveReminders(list);
    if (reminder.enabled) await _scheduleReminder(reminder);
  }

  Future<void> deleteReminder(String id) async {
    final list = await loadReminders();
    final reminder = list.firstWhere((r) => r.id == id, orElse: () => throw Exception('Not found'));
    await _cancelReminder(reminder);
    list.removeWhere((r) => r.id == id);
    await _saveReminders(list);
  }

  Future<void> toggleReminder(String id, bool enabled) async {
    final list = await loadReminders();
    final idx = list.indexWhere((r) => r.id == id);
    if (idx == -1) return;
    final updated = list[idx].copyWith(enabled: enabled);
    list[idx] = updated;
    await _saveReminders(list);
    if (enabled) {
      await _scheduleReminder(updated);
    } else {
      await _cancelReminder(updated);
    }
  }

  // ── Scheduling ───────────────────────────────────────────────────────────────

  /// Schedule weekly notifications for each selected day.
  Future<void> _scheduleReminder(WorkoutReminder reminder) async {
    await initialize();
    for (final day in reminder.days) {
      final notifId = _notifId(reminder.id, day);
      final androidDetails = AndroidNotificationDetails(
        'workout_reminders',
        'Workout Reminders',
        channelDescription: 'Scheduled workout reminder notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const iosDetails = DarwinNotificationDetails();
      final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

      final scheduledDate = _nextWeekday(day, reminder.time);

      await _plugin.zonedSchedule(
        notifId,
        '💪 ${reminder.label}',
        'Time for your workout! Stay consistent and keep going.',
        scheduledDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> _cancelReminder(WorkoutReminder reminder) async {
    await initialize();
    for (final day in reminder.days) {
      await _plugin.cancel(_notifId(reminder.id, day));
    }
  }

  /// Reschedule all enabled reminders (call after app restart).
  Future<void> rescheduleAll() async {
    await initialize();
    final reminders = await loadReminders();
    for (final r in reminders) {
      if (r.enabled) await _scheduleReminder(r);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Unique notification ID per reminder+day combination.
  int _notifId(String reminderId, int day) =>
      (reminderId.hashCode.abs() % 10000) * 10 + day;

  /// Next occurrence of [weekday] (1=Mon…7=Sun) at [time].
  tz.TZDateTime _nextWeekday(int weekday, TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    // Advance until we hit the right weekday AND the time is in the future
    // Add at least 1 minute buffer to avoid scheduling in the past
    final cutoff = now.add(const Duration(minutes: 1));
    while (scheduled.weekday != weekday || scheduled.isBefore(cutoff)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
