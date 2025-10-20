import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize notifications
  static Future<void> initialize() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(tz.local.name));

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _notificationsPlugin.initialize(initSettings);
  }

  /// Helper to schedule a daily notification
  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'daily_channel',
      'Daily Reminders',
      channelDescription: 'Fixed reminders for GrowDay app',
      importance: Importance.max,
      priority: Priority.high,
    );

    final details = NotificationDetails(android: androidDetails);

    final now = tz.TZDateTime.now(tz.local);
    var schedule = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If the scheduled time already passed today, schedule for tomorrow
    if (schedule.isBefore(now)) {
      schedule = schedule.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      schedule,
      details,
      androidAllowWhileIdle: true, // ✅ compatible with your version
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  /// 🔔 Debug version — fires 1 & 2 minutes after launch
  static Future<void> scheduleDebugTestReminders() async {
    await _notificationsPlugin.cancelAll(); // clear old schedules

    final now = DateTime.now();

    await _scheduleDaily(
      id: 2001,
      title: 'Test Morning 🌞',
      body: 'This is a test notification (1 minute after launch)',
      hour: now.hour,
      minute: (now.minute + 1) % 60,
    );

    await _scheduleDaily(
      id: 2002,
      title: 'Test Evening ✨',
      body: 'Second test notification (2 minutes after launch)',
      hour: now.hour,
      minute: (now.minute + 2) % 60,
    );
  }

  /// 🕗 Real version — 8 AM and 10 PM every day
  static Future<void> scheduleFixedDailyReminders() async {
    await _notificationsPlugin.cancelAll();

    await _scheduleDaily(
      id: 1001,
      title: 'Good Morning 🌞',
      body: 'Start your day strong! Review your habits now.',
      hour: 8,
      minute: 0,
    );

    await _scheduleDaily(
      id: 1002,
      title: 'Evening Check ✨',
      body: 'Reflect and mark your habits before you sleep.',
      hour: 22,
      minute: 0,
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async => _notificationsPlugin.cancelAll();

  static Future<void> showTestNotification() async {
    await _notificationsPlugin.show(
      9999, // any unique ID
      'Test Notification 🎯',
      'This is a direct test notification!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Used for manual test triggers',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> scheduleDailyReminder() async {}
}
