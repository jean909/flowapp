import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

/// Schedules local notifications that fire even when the app is in background or closed.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  NotificationService._();

  static const String _channelId = 'flow_reminders';
  static const String _channelName = 'Flow reminders';
  static const int _workoutIdStart = 1000;
  static const int _workoutIdEnd = 1999;
  static const int _gamificationIdStart = 2000;
  static const int _gamificationIdEnd = 2029;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Call once at app startup (e.g. from main() after WidgetsBinding).
  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('NotificationService: timezone init failed, using local: $e');
      try {
        tz.setLocalLocation(tz.local);
      } catch (_) {}
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: android);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Workout and reminder notifications',
          importance: Importance.defaultImportance,
        ));

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Payload could be used to open a specific screen (e.g. planned workouts).
    debugPrint('NotificationService: tapped ${response.payload}');
  }

  /// Request notification permission (Android 13+). Call after user is logged in.
  Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    final granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Cancel all scheduled workout reminders (e.g. before rescheduling).
  Future<void> cancelWorkoutReminders() async {
    for (int id = _workoutIdStart; id <= _workoutIdEnd; id++) {
      await _plugin.cancel(id);
    }
  }

  /// Cancel gamification reminders (streak, water).
  Future<void> cancelGamificationReminders() async {
    for (int id = _gamificationIdStart; id <= _gamificationIdEnd; id++) {
      await _plugin.cancel(id);
    }
  }

  Future<void> _scheduleOne({
    required int id,
    required DateTime scheduledAt,
    required String title,
    required String body,
    required bool useExact,
  }) async {
    if (scheduledAt.isBefore(DateTime.now())) return;

    final tz.TZDateTime tzDate = tz.TZDateTime.from(scheduledAt, tz.local);
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Workout and reminder notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      details,
      androidScheduleMode: useExact ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Schedule a single notification at [scheduledAt] with [title] and [body].
  /// [id] must be in range [_workoutIdStart, _workoutIdEnd].
  Future<void> scheduleAt({
    required int id,
    required DateTime scheduledAt,
    required String title,
    required String body,
    required bool useExact,
  }) async {
    if (id < _workoutIdStart || id > _workoutIdEnd) return;
    await _scheduleOne(id: id, scheduledAt: scheduledAt, title: title, body: body, useExact: useExact);
  }

  /// Reschedule workout reminders from list of planned workouts.
  /// Each item: { 'scheduled_date': 'YYYY-MM-DD', 'scheduled_time': 'HH:mm' or null }.
  /// [title] and [bodyBuilder](date, time) are used for each notification (pass l10n strings from UI).
  Future<void> scheduleWorkoutReminders(
    List<Map<String, dynamic>> planned, {
    required String title,
    required String Function(String dateStr, String? timeStr) bodyBuilder,
  }) async {
    if (!_initialized) return;
    await cancelWorkoutReminders();

    final now = DateTime.now();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final useExact = await android?.canScheduleExactNotifications() ?? false;

    int id = _workoutIdStart;
    for (final workout in planned) {
      if (id > _workoutIdEnd) break;
      final dateStr = workout['scheduled_date'] as String?;
      if (dateStr == null) continue;
      final parts = dateStr.split('-');
      if (parts.length != 3) continue;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      if (year == null || month == null || day == null) continue;

      String? timeStr = workout['scheduled_time'] as String?;
      int hour = 9;
      int minute = 0;
      if (timeStr != null && timeStr.isNotEmpty) {
        final timeParts = timeStr.split(':');
        if (timeParts.isNotEmpty) hour = int.tryParse(timeParts[0]) ?? 9;
        if (timeParts.length > 1) minute = int.tryParse(timeParts[1]) ?? 0;
      }

      final scheduledAt = DateTime(year, month, day, hour, minute);
      if (scheduledAt.isBefore(now)) continue;

      final body = bodyBuilder(dateStr, timeStr?.isNotEmpty == true ? timeStr : null);
      await scheduleAt(id: id, scheduledAt: scheduledAt, title: title, body: body, useExact: useExact);
      id++;
    }
  }

  /// Gamification: streak reminder (evening if nothing logged today) + water reminders.
  /// Reuses same channel. Call from dashboard when data is loaded.
  Future<void> scheduleGamificationReminders({
    required int streakCount,
    required bool hasLoggedToday,
    required int waterMl,
    required int waterTargetMl,
    required String streakReminderTitle,
    required String streakReminderBody,
    required String waterReminderTitle,
    required String waterReminderBody,
  }) async {
    if (!_initialized) return;
    await cancelGamificationReminders();

    final now = DateTime.now();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final useExact = await android?.canScheduleExactNotifications() ?? false;

    // Streak: one reminder today at 20:00 if streak > 0 and nothing logged yet
    if (streakCount > 0 && !hasLoggedToday) {
      var evening = DateTime(now.year, now.month, now.day, 20, 0);
      if (evening.isAfter(now)) {
        await _scheduleOne(
          id: _gamificationIdStart,
          scheduledAt: evening,
          title: streakReminderTitle,
          body: streakReminderBody,
          useExact: useExact,
        );
      }
    }

    // Water: up to 2 reminders (in 2h and 4h) if below target and still daytime
    if (waterTargetMl > 0 && waterMl < waterTargetMl && now.hour < 19) {
      for (var i = 0; i < 2; i++) {
        final at = now.add(Duration(hours: 2 + (i * 2)));
        if (at.hour >= 21) break;
        await _scheduleOne(
          id: _gamificationIdStart + 1 + i,
          scheduledAt: at,
          title: waterReminderTitle,
          body: waterReminderBody,
          useExact: useExact,
        );
      }
    }
  }
}
