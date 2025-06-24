import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/todo.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
  }

  void _onNotificationTapped(NotificationResponse notificationResponse) {
    print('Notification tapped: ${notificationResponse.payload}');
  }

  Future<void> scheduleReminderNotification(Todo todo) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (todo.dueDate == null) return;

    final reminderTime = todo.dueDate!.subtract(const Duration(minutes: 20));

    if (reminderTime.isBefore(DateTime.now())) {
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'todo_reminders',
          'Todo Reminders',
          channelDescription: 'Reminders for upcoming todos',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFE91E63),
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      todo.id.hashCode,
      '⏰ Todo Reminder',
      '${todo.title} is due in 20 minutes!',
      tz.TZDateTime.from(reminderTime, tz.local),
      platformChannelSpecifics,
      payload: todo.id,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleCompletionNotification(Todo todo) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'todo_celebrations',
          'Todo Celebrations',
          channelDescription: 'Celebrations for completed todos',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFE91E63),
          playSound: true,
          enableVibration: true,
        );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      todo.id.hashCode + 1000,
      '🎉 Congratulations!',
      'You completed: ${todo.title}',
      platformChannelSpecifics,
      payload: todo.id,
    );
  }

  Future<void> cancelReminderNotification(String todoId) async {
    if (!_isInitialized) return;
    await _flutterLocalNotificationsPlugin.cancel(todoId.hashCode);
  }

  Future<void> cancelAllNotificationsForTodo(String todoId) async {
    if (!_isInitialized) return;
    await _flutterLocalNotificationsPlugin.cancel(todoId.hashCode);
    await _flutterLocalNotificationsPlugin.cancel(todoId.hashCode + 1000);
  }

  Future<void> updateReminderNotification(Todo todo) async {
    await cancelReminderNotification(todo.id);
    if (!todo.isCompleted && todo.dueDate != null) {
      await scheduleReminderNotification(todo);
    }
  }

  Future<void> scheduleDailyProductivitySummary() async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'daily_summary',
          'Daily Productivity Summary',
          channelDescription: 'Daily summary of your productivity',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFE91E63),
        );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    final now = DateTime.now();
    final scheduledTime = DateTime(now.year, now.month, now.day, 20, 0);
    final nextScheduledTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      9999,
      '📊 Daily Productivity',
      'Check your productivity summary for today!',
      tz.TZDateTime.from(nextScheduledTime, tz.local),
      platformChannelSpecifics,
      payload: 'daily_summary',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) return [];
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}
