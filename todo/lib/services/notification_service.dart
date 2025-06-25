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

  // FIXED: Enhanced reminder notification with multiple time intervals and better scheduling
  Future<void> scheduleReminderNotification(Todo todo) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (todo.dueDate == null || todo.isCompleted) return;

    final now = DateTime.now();
    final dueDate = todo.dueDate!;

    // Cancel any existing notifications for this todo first
    await cancelReminderNotification(todo.id);

    // Calculate different reminder intervals based on how far the due date is
    final timeDifference = dueDate.difference(now);
    final reminderTimes = <DateTime>[];

    // Add multiple reminder times based on the time until due date
    if (timeDifference.inDays >= 7) {
      // For tasks due in a week or more, remind 7 days, 3 days, 1 day, and 1 hour before
      reminderTimes.addAll([
        dueDate.subtract(const Duration(days: 7)),
        dueDate.subtract(const Duration(days: 3)),
        dueDate.subtract(const Duration(days: 1)),
        dueDate.subtract(const Duration(hours: 1)),
      ]);
    } else if (timeDifference.inDays >= 3) {
      // For tasks due in 3-7 days, remind 3 days, 1 day, and 1 hour before
      reminderTimes.addAll([
        dueDate.subtract(const Duration(days: 3)),
        dueDate.subtract(const Duration(days: 1)),
        dueDate.subtract(const Duration(hours: 1)),
      ]);
    } else if (timeDifference.inDays >= 1) {
      // For tasks due in 1-3 days, remind 1 day, 4 hours, and 1 hour before
      reminderTimes.addAll([
        dueDate.subtract(const Duration(days: 1)),
        dueDate.subtract(const Duration(hours: 4)),
        dueDate.subtract(const Duration(hours: 1)),
      ]);
    } else if (timeDifference.inHours >= 4) {
      // For tasks due in 4-24 hours, remind 4 hours, 1 hour, and 30 minutes before
      reminderTimes.addAll([
        dueDate.subtract(const Duration(hours: 4)),
        dueDate.subtract(const Duration(hours: 1)),
        dueDate.subtract(const Duration(minutes: 30)),
      ]);
    } else if (timeDifference.inHours >= 1) {
      // For tasks due in 1-4 hours, remind 1 hour and 30 minutes before
      reminderTimes.addAll([
        dueDate.subtract(const Duration(hours: 1)),
        dueDate.subtract(const Duration(minutes: 30)),
      ]);
    } else if (timeDifference.inMinutes >= 30) {
      // For tasks due in 30-60 minutes, remind 30 minutes and 10 minutes before
      reminderTimes.addAll([
        dueDate.subtract(const Duration(minutes: 30)),
        dueDate.subtract(const Duration(minutes: 10)),
      ]);
    } else if (timeDifference.inMinutes >= 10) {
      // For tasks due in 10-30 minutes, remind 10 minutes before
      reminderTimes.add(dueDate.subtract(const Duration(minutes: 10)));
    }

    // Schedule notifications for each reminder time
    for (int i = 0; i < reminderTimes.length; i++) {
      final reminderTime = reminderTimes[i];

      // Only schedule if reminder time is in the future
      if (reminderTime.isAfter(now)) {
        await _scheduleIndividualReminder(
          todo,
          reminderTime,
          i, // Use index to create unique notification IDs
        );
      }
    }

    // Also schedule a notification for when the task is actually due
    if (dueDate.isAfter(now)) {
      await _scheduleIndividualReminder(
        todo,
        dueDate,
        999, // Special index for due date notification
        isDueNow: true,
      );
    }
  }

  // Helper method to schedule individual reminder notifications
  Future<void> _scheduleIndividualReminder(
    Todo todo,
    DateTime reminderTime,
    int reminderIndex, {
    bool isDueNow = false,
  }) async {
    final now = DateTime.now();
    final dueDate = todo.dueDate!;
    final timeDifference = dueDate.difference(reminderTime);

    // Create notification message based on time difference
    String title;
    String body;

    if (isDueNow) {
      title = '🚨 Task Due Now!';
      body = '${todo.title} is due now!';
    } else if (timeDifference.inDays > 0) {
      title = '📅 Upcoming Task';
      body =
          '${todo.title} is due in ${timeDifference.inDays} day${timeDifference.inDays > 1 ? 's' : ''}';
    } else if (timeDifference.inHours > 0) {
      title = '⏰ Task Reminder';
      body =
          '${todo.title} is due in ${timeDifference.inHours} hour${timeDifference.inHours > 1 ? 's' : ''}';
    } else {
      title = '⏰ Task Reminder';
      body =
          '${todo.title} is due in ${timeDifference.inMinutes} minute${timeDifference.inMinutes > 1 ? 's' : ''}';
    }

    // Set notification importance based on urgency
    Importance importance;
    Priority priority;

    if (isDueNow || timeDifference.inMinutes <= 10) {
      importance = Importance.max;
      priority = Priority.max;
    } else if (timeDifference.inHours <= 1) {
      importance = Importance.high;
      priority = Priority.high;
    } else {
      importance = Importance.defaultImportance;
      priority = Priority.defaultPriority;
    }

    // FIXED: Create AndroidNotificationDetails properly
    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'todo_reminders',
      'Todo Reminders',
      channelDescription: 'Reminders for upcoming todos',
      importance: importance,
      priority: priority,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFE91E63),
      playSound: true,
      enableVibration:
          timeDifference.inHours <= 1, // Vibrate for urgent reminders
      category: AndroidNotificationCategory.reminder,
      ticker: title,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    // Create unique notification ID
    final notificationId = todo.id.hashCode + reminderIndex;

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(reminderTime, tz.local),
        platformChannelSpecifics,
        payload: '${todo.id}:$reminderIndex',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print(
          'Scheduled reminder for ${todo.title} at $reminderTime (ID: $notificationId)');
    } catch (e) {
      print('Error scheduling reminder: $e');
    }
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

  // FIXED: Enhanced cancellation to remove all reminder notifications for a todo
  Future<void> cancelReminderNotification(String todoId) async {
    if (!_isInitialized) return;

    try {
      // Cancel all possible reminder notifications for this todo
      // We use multiple indices to cover all possible reminders
      final baseId = todoId.hashCode;

      // Cancel reminder notifications (indices 0-10 should cover most cases)
      for (int i = 0; i < 10; i++) {
        await _flutterLocalNotificationsPlugin.cancel(baseId + i);
      }

      // Cancel the due date notification (index 999)
      await _flutterLocalNotificationsPlugin.cancel(baseId + 999);

      print('Cancelled all reminder notifications for todo: $todoId');
    } catch (e) {
      print('Error cancelling reminder notifications: $e');
    }
  }

  Future<void> cancelAllNotificationsForTodo(String todoId) async {
    if (!_isInitialized) return;

    try {
      await cancelReminderNotification(todoId);
      await _flutterLocalNotificationsPlugin
          .cancel(todoId.hashCode + 1000); // completion notification

      print('Cancelled all notifications for todo: $todoId');
    } catch (e) {
      print('Error cancelling notifications for todo: $e');
    }
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

  // FIXED: Enhanced test notification with better timing options
  Future<void> showTestNotification({Duration? delay}) async {
    if (!_isInitialized) {
      await initialize();
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Test notification channel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFE91E63),
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

    if (delay != null) {
      // Schedule a test notification with delay
      final scheduledTime = DateTime.now().add(delay);
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        98888,
        '🔔 Scheduled Test Notification',
        'This notification was scheduled ${delay.inSeconds} seconds ago!',
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        payload: 'test_scheduled',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } else {
      // Show immediate test notification
      await _flutterLocalNotificationsPlugin.show(
        99999,
        '🔔 Test Notification',
        'Your notification system is working perfectly!',
        platformChannelSpecifics,
        payload: 'test_immediate',
      );
    }
  }

  // FIXED: New method to reschedule all notifications for existing todos
  Future<void> rescheduleAllNotifications(List<Todo> todos) async {
    print('Rescheduling notifications for ${todos.length} todos...');

    for (final todo in todos) {
      if (!todo.isCompleted && todo.dueDate != null) {
        await scheduleReminderNotification(todo);
      }
    }

    print('Notification rescheduling completed.');
  }

  // Get notification statistics
  Future<Map<String, dynamic>> getNotificationStats() async {
    final pendingNotifications = await getPendingNotifications();

    final reminderCount = pendingNotifications
        .where((n) => n.id.toString().contains('todo_reminders'))
        .length;

    final celebrationCount = pendingNotifications
        .where((n) => n.id.toString().contains('todo_celebrations'))
        .length;

    return {
      'total': pendingNotifications.length,
      'reminders': reminderCount,
      'celebrations': celebrationCount,
      'dailySummary': pendingNotifications.any((n) => n.id == 9999) ? 1 : 0,
    };
  }
}
