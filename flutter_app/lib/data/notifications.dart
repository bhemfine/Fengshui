import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'local_store.dart';

/// Opt-in daily reminder. Inexact (no exact-alarm permission). The text is
/// generic and carries no name, birth data or address.
class DailyNotifications {
  DailyNotifications._();
  static final _plugin = FlutterLocalNotificationsPlugin();
  static var _ready = false;
  static const _id = 1001;
  static const onKey = 'notify.daily.on.v1';
  static const hourKey = 'notify.daily.hour.v1';
  static const minuteKey = 'notify.daily.minute.v1';
  static const defaultHour = 7;
  static const defaultMinute = 0;

  static Future<void> _ensure() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Singapore'));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(const InitializationSettings(android: android));
    _ready = true;
  }

  static Future<({bool on, int hour, int minute})> loadPrefs() async {
    final s = LocalStore.instance;
    return (
      on: await s.loadBool(onKey) ?? false,
      hour: await s.loadInt(hourKey) ?? defaultHour,
      minute: await s.loadInt(minuteKey) ?? defaultMinute,
    );
  }

  static Future<bool> requestPermission() async {
    await _ensure();
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;
    return await android.requestNotificationsPermission() ?? false;
  }

  static Future<void> enable({required int hour, required int minute}) async {
    await _ensure();
    final s = LocalStore.instance;
    await s.saveBool(onKey, true);
    await s.saveInt(hourKey, hour);
    await s.saveInt(minuteKey, minute);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_card',
        'Daily card',
        channelDescription: 'A once-a-day reminder to open today’s reading.',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
    final next = _next(hour, minute);
    await _plugin.zonedSchedule(
      _id,
      'Inkstone',
      'Today’s card is ready. Open the app for your reading.',
      next,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel() async {
    try {
      await _ensure();
      await _plugin.cancel(_id);
    } catch (e) {
      debugPrint('DailyNotifications.cancel: $e');
    }
    await LocalStore.instance.saveBool(onKey, false);
  }

  static tz.TZDateTime _next(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
