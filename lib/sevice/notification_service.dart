import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:todo_app/sevice/task_database.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String offActionId = 'OFF_ACTION';

  // ==============================
  // INITIALIZE
  // ==============================

  static Future<void> init() async {
    tz.initializeTimeZones();

    tz.setLocalLocation(
      tz.getLocation('Asia/Dhaka'),
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  // ==============================
  // NOTIFICATION DETAILS
  // ==============================

  static AndroidNotificationDetails _androidDetails() {
    return const AndroidNotificationDetails(
      'todo_schedule_channel',
      'Scheduled To-Do',
      channelDescription: 'Scheduled task reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'To-Do Reminder',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'OFF_ACTION',
          'OFF',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );
  }

  static NotificationDetails get _notificationDetails {
    return NotificationDetails(
      android: _androidDetails(),
    );
  }

  // ==============================
  // OFF BUTTON
  // ==============================

  static Future<void> _onNotificationResponse(
    NotificationResponse response,
  ) async {
    debugPrint('🔔 Notification response received');
    debugPrint('Action ID: ${response.actionId}');
    debugPrint('Payload: ${response.payload}');

    if (response.actionId == offActionId) {
      final payload = response.payload;

      if (payload != null && payload.startsWith('task_')) {
        final idString = payload.replaceFirst('task_', '');

        final notificationId = int.tryParse(idString);

        if (notificationId != null) {
          // সব ৩টা reminder বন্ধ করবে
          await stopReminder(notificationId);

          // সব task বের করবে
          final tasks = TaskDatabase.getTasks();

          // যে task-এর notification সেটা খুঁজবে
          for (final task in tasks) {
            final taskNotificationId =
                int.parse(task.id) % 2147483647;

            if (taskNotificationId == notificationId) {
              // Task Done করে দিচ্ছি
              task.isCompleted = true;

              await TaskDatabase.updateTask(task);

              debugPrint(
                '✅ Task marked as DONE: ${task.title}',
              );

              break;
            }
          }
        }
      }

      debugPrint('🛑 OFF button pressed');
    }
  }

  // ==============================
  // TEST NOTIFICATION
  // ==============================

  static Future<void> showTestNotification() async {
    await _notifications.show(
      id: 1,
      title: '🔔 To-Do Reminder',
      body: 'This is a test notification.',
      notificationDetails: _notificationDetails,
      payload: 'task_1',
    );

    debugPrint('✅ Test notification shown');
  }

  // ==============================
  // SCHEDULE 3 NOTIFICATIONS
  // ==============================

  static Future<void> scheduleTaskNotification({
    required int id,
    required String title,
    required DateTime scheduledDateTime,
  }) async {
    final firstTime = tz.TZDateTime(
      tz.local,
      scheduledDateTime.year,
      scheduledDateTime.month,
      scheduledDateTime.day,
      scheduledDateTime.hour,
      scheduledDateTime.minute,
    );

    final now = tz.TZDateTime.now(tz.local);

    debugPrint('Current time: $now');
    debugPrint('First notification: $firstTime');

    if (firstTime.isBefore(now)) {
      debugPrint('⚠️ Scheduled time has already passed.');
      return;
    }

    // ৩টা আলাদা notification ID
    final id1 = id;
    final id2 = id + 1;
    final id3 = id + 2;

    // ==============================
    // 1st notification
    // Scheduled time
    // ==============================

    await _notifications.zonedSchedule(
      id: id1,
      title: '🔔 To-Do Reminder',
      body: title,
      notificationDetails: _notificationDetails,
      scheduledDate: firstTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task_$id',
    );

    // ==============================
    // 2nd notification
    // 1 minute later
    // ==============================

    final secondTime = firstTime.add(
      const Duration(minutes: 1),
    );

    await _notifications.zonedSchedule(
      id: id2,
      title: '🔔 To-Do Reminder',
      body: title,
      notificationDetails: _notificationDetails,
      scheduledDate: secondTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task_$id',
    );

    // ==============================
    // 3rd notification
    // 2 minutes later
    // ==============================

    final thirdTime = firstTime.add(
      const Duration(minutes: 2),
    );

    await _notifications.zonedSchedule(
      id: id3,
      title: '🔔 To-Do Reminder',
      body: title,
      notificationDetails: _notificationDetails,
      scheduledDate: thirdTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'task_$id',
    );

    debugPrint('✅ 3 notifications scheduled!');
    debugPrint('1st: $firstTime');
    debugPrint('2nd: $secondTime');
    debugPrint('3rd: $thirdTime');
  }

  // ==============================
  // STOP REMINDER
  // ==============================

  static Future<void> stopReminder(int id) async {
    await _notifications.cancel(
      id: id,
    );

    await _notifications.cancel(
      id: id + 1,
    );

    await _notifications.cancel(
      id: id + 2,
    );

    debugPrint('🛑 All 3 reminders stopped! ID: $id');
  }

  // ==============================
  // CANCEL TASK NOTIFICATIONS
  // ==============================

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(
      id: id,
    );

    await _notifications.cancel(
      id: id + 1,
    );

    await _notifications.cancel(
      id: id + 2,
    );

    debugPrint(
      '❌ All task notifications cancelled! ID: $id',
    );
  }

  // ==============================
  // CANCEL ALL
  // ==============================

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();

    debugPrint('❌ All notifications cancelled!');
  }
}