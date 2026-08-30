import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class ReminderService {
  ReminderService(this._preferences);

  static const _enabledKey = 'daily_reminder_enabled';
  static const _notificationId = 6101;
  final SharedPreferences _preferences;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get isEnabled => _preferences.getBool(_enabledKey) ?? false;

  Future<bool> enableAfterExplicitPrompt() async {
    try {
      await _initialize();
      final granted = await _requestPermission();
      if (!granted) return false;
      await _preferences.setBool(_enabledKey, true);
      await _scheduleDailyReminder();
      return true;
    } catch (error, stackTrace) {
      debugPrint('Unable to enable reminders: $error\n$stackTrace');
      return false;
    }
  }

  Future<void> disable() async {
    await _preferences.setBool(_enabledKey, false);
    if (_initialized) await _notifications.cancel(id: _notificationId);
  }

  Future<void> rescheduleIfEnabled() async {
    if (!isEnabled) return;
    try {
      await _initialize();
      await _scheduleDailyReminder();
    } catch (error, stackTrace) {
      debugPrint('Unable to reschedule reminder: $error\n$stackTrace');
    }
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  Future<void> _scheduleDailyReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    await _notifications.zonedSchedule(
      id: _notificationId,
      title: 'Your Zendoku garden is waiting 🌸',
      body: 'Today’s challenge and daily reward are ready.',
      scheduledDate: next,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'zendoku_daily_reminders',
          'Daily reminders',
          channelDescription: 'Optional reminders for daily Zendoku rewards',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/challenges',
    );
  }
}
