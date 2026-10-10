import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Timezone initialize
    tz.initializeTimeZones();

    // Bangladesh timezone
    tz.setLocalLocation(tz.getLocation('Asia/Dhaka'));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(settings: settings);

    // Android 13+ notification permission
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Exact alarm permission
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  // Test notification
  static Future<void> showTestNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'todo_channel',
          'To-Do Notifications',
          channelDescription: 'Notifications for To-Do tasks',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      id: 1,
      title: '🔔 To-Do Reminder',
      body: 'This is a test notification.',
      notificationDetails: details,
    );
  }

  // Scheduled notification
  static Future<void> scheduleTaskNotification({
    required int id,
    required String title,
    required DateTime scheduledDateTime,
  }) async {
    final scheduledTime = tz.TZDateTime(
      tz.local,
      scheduledDateTime.year,
      scheduledDateTime.month,
      scheduledDateTime.day,
      scheduledDateTime.hour,
      scheduledDateTime.minute,
    );

    print('Current time: ${tz.TZDateTime.now(tz.local)}');
    print('Scheduled time: $scheduledTime');

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'todo_schedule_channel',
          'Scheduled To-Do',
          channelDescription: 'Scheduled task reminders',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          ticker: 'To-Do Reminder',
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      id: id,
      title: '🔔 To-Do Reminder',
      body: title,
      notificationDetails: details,
      scheduledDate: scheduledTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task_$id',
    );

    print('✅ Notification scheduled successfully!');
  }
}
