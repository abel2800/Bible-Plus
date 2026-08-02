import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const dailyReminderId = 1001;
  static const streakReminderId = 1002;
  static const dailyPrayerReminderId = 1003;
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _timezoneReady = false;

  Future<void> initialize() async {
    await _ensureLocalTimezone();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings: initSettings);
  }

  Future<void> _ensureLocalTimezone() async {
    if (_timezoneReady || kIsWeb) return;
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (error) {
      debugPrint('Timezone lookup failed ($error); using UTC offset fallback.');
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;
      final etc = hours == 0
          ? 'Etc/UTC'
          : 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
      try {
        tz.setLocalLocation(tz.getLocation(etc));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
    _timezoneReady = true;
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted ?? iosGranted ?? false;
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    await _ensureLocalTimezone();
    await _notifications.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleDailyDevotional({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) {
    return scheduleDaily(
      id: dailyReminderId,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      channelId: 'daily_devotional',
      channelName: 'Daily Devotional',
      channelDescription: 'Daily verse and prayer notifications',
    );
  }

  Future<void> scheduleStreakReminder({
    required String title,
    required String body,
    int hour = 19,
    int minute = 0,
  }) {
    return scheduleDaily(
      id: streakReminderId,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      channelId: 'streak_reminder',
      channelName: 'Reading Streak',
      channelDescription: 'Reminders to keep your daily Scripture streak',
    );
  }

  Future<void> scheduleDailyPrayerReminder({
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) {
    return scheduleDaily(
      id: dailyPrayerReminderId,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      channelId: 'daily_prayer',
      channelName: 'Daily Prayer',
      channelDescription: 'A fresh prayer for each day',
    );
  }

  Future<void> cancelDailyReminder() async {
    await _notifications.cancel(id: dailyReminderId);
  }

  Future<void> cancelStreakReminder() async {
    await _notifications.cancel(id: streakReminderId);
  }

  Future<void> cancelDailyPrayerReminder() async {
    await _notifications.cancel(id: dailyPrayerReminderId);
  }

  Future<void> cancelAllEngagementReminders() async {
    await cancelDailyReminder();
    await cancelStreakReminder();
    await cancelDailyPrayerReminder();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }
}
