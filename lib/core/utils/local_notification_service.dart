// lib/core/utils/local_notification_service.dart
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:app_settings/app_settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // 1. Load timezone database
    tz_data.initializeTimeZones();

    // 2. Detect and set the device's actual local timezone
    final deviceTimeZone = DateTime.now().timeZoneName;
    dev.log('Device timezone name: $deviceTimeZone');
    try {
      final location = tz.getLocation(deviceTimeZone);
      tz.setLocalLocation(location);
      dev.log('Local timezone set to: $location');
    } catch (e) {
      dev.log(
          'Could not find location for "$deviceTimeZone", using Etc/GMT offset');
      final offset = DateTime.now().timeZoneOffset;
      final hours = offset.inHours;
      final sign = hours <= 0 ? '+' : '-';
      final absHours = hours.abs();
      final locationName = 'Etc/GMT$sign$absHours';
      try {
        final location = tz.getLocation(locationName);
        tz.setLocalLocation(location);
        dev.log('Local timezone fallback set to: $location');
      } catch (e2) {
        dev.log('Fallback also failed, using UTC');
        tz.setLocalLocation(tz.UTC);
      }
    }

    // 3. Initialize plugin
    const androidSettings = AndroidInitializationSettings('ic_notification');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings: settings);

    // 4. Create notification channels
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'reminders_channel',
        'Reminders',
        description: 'Notifications for your reminders',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'events_channel',
        'Events',
        description: 'Notifications for calendar events',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );

    // 5. Request notification permission (for Android 13+)
    await _requestNotificationPermission();

    // 6. Check and request exact alarm permission if needed
    final canScheduleExact = await canScheduleExactNotifications();
    dev.log('Can schedule exact notifications: $canScheduleExact');
    if (!canScheduleExact) {
      await requestExactAlarmPermission();
    }
  }

  /// Request notification permission from the user (required for Android 13+)
  static Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      final result = await Permission.notification.request();
      dev.log('Notification permission request result: $result');
    }
  }

  /// Request exact alarm permission (for Android 14+)
  static Future<void> requestExactAlarmPermission() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestExactAlarmsPermission();
      dev.log('Exact alarm permission request result: $granted');
    } catch (e) {
      dev.log('Error requesting exact alarm permission: $e');
    }
  }

  /// Check if the app can schedule exact notifications (Android 14+)
  static Future<bool> canScheduleExactNotifications() async {
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final canSchedule = await androidPlugin?.canScheduleExactNotifications();
      return canSchedule ?? false;
    } catch (e) {
      dev.log('Error checking exact alarm permission: $e');
      return false;
    }
  }

  static Future<bool> get hasPermission async =>
      (await Permission.notification.status).isGranted;

  /// Converts a local [DateTime] to a [TZDateTime] in the device's timezone.
  static tz.TZDateTime _toTZDateTime(DateTime dateTime) {
    return tz.TZDateTime.from(dateTime, tz.local);
  }

  static Future<void> scheduleReminder({
    required int id,
    required String description,
    required DateTime reminderTime,
  }) async {
    if (!(await hasPermission)) {
      dev.log('scheduleReminder: permission denied');
      return;
    }
    if (reminderTime.isBefore(DateTime.now())) {
      dev.log('scheduleReminder: time in past, skipping');
      return;
    }

    final notificationId = id + 200000;
    final scheduled = _toTZDateTime(reminderTime);
    dev.log('Scheduling reminder $id at $scheduled');

    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      dev.log('scheduleReminder: scheduled time is in the past after conversion');
      return;
    }

    try {
      await _plugin.zonedSchedule(
        id: notificationId,
        title: 'Reminder',
        body: description,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminders_channel',
            'Reminders',
            channelDescription: 'Notifications for your reminders',
            icon: 'ic_notification',
            color: Color(0xFFFF6B81),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      dev.log('Successfully scheduled reminder $id');
    } catch (e) {
      dev.log('Failed to schedule reminder $id: $e');
    }
  }

  static Future<void> scheduleEventReminder({
    required int id,
    required String title,
    required DateTime reminderTime,
  }) async {
    if (!(await hasPermission)) {
      dev.log('scheduleEventReminder: permission denied');
      return;
    }
    if (reminderTime.isBefore(DateTime.now())) {
      dev.log('scheduleEventReminder: time in past, skipping');
      return;
    }

    final notificationId = id + 300000;
    final scheduled = _toTZDateTime(reminderTime);
    dev.log('Scheduling event reminder $id at $scheduled');

    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) {
      dev.log('scheduleEventReminder: scheduled time is in the past after conversion');
      return;
    }

    try {
      await _plugin.zonedSchedule(
        id: notificationId,
        title: 'Event Reminder',
        body: title,
        scheduledDate: scheduled,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'events_channel',
            'Events',
            channelDescription: 'Notifications for calendar events',
            icon: 'ic_notification',
            color: Color(0xFFFF6B81),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      dev.log('Successfully scheduled event reminder $id');
    } catch (e) {
      dev.log('Failed to schedule event reminder $id: $e');
    }
  }

  static Future<void> cancelReminder(int id) async {
    await _plugin.cancel(id: id + 200000);
  }

  static Future<void> cancelEventReminder(int id) async {
    await _plugin.cancel(id: id + 300000);
  }

}