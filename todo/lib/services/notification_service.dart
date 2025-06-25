import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../models/todo.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service with proper permissions and channels
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      print('🚀 Initializing notification service...');

      // Initialize timezone
      tz.initializeTimeZones();

      // Request permissions
      await _requestPermissions();

      // Configure notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestSoundPermission: true,
        requestBadgePermission: true,
        requestAlertPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        await _createNotificationChannels();
        _isInitialized = true;
        print('✅ Notification service initialized successfully');

        // Send test notification to verify it works
        await _sendWelcomeNotification();
        return true;
      }

      print('❌ Failed to initialize notifications');
      return false;
    } catch (e) {
      print('❌ Error initializing notifications: $e');
      return false;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      // Request basic notification permission
      await Permission.notification.request();

      // Request Android-specific permissions
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.requestPermission();
        await androidPlugin.requestExactAlarmsPermission();
      }
    } catch (e) {
      print('⚠️ Permission request error: $e');
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Todo reminders channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'todo_reminders',
          'Todo Reminders',
          description: 'Reminders for your pending todos',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Urgent reminders channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'urgent_reminders',
          'Urgent Todo Reminders',
          description: 'Urgent reminders for overdue todos',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
          enableLights: true,
          ledColor: Color(0xFFFF0000),
        ),
      );

      // Completion celebrations
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'celebrations',
          'Task Celebrations',
          description: 'Celebrations for completed todos',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      print('📢 Notification channels created');
    }
  }

  /// Handle notification taps
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');
    // You can add navigation logic here if needed
  }

  /// Schedule smart reminders for a todo
  Future<bool> scheduleReminderNotification(Todo todo) async {
    if (!_isInitialized || todo.dueDate == null || todo.isCompleted) {
      return false;
    }

    try {
      print('📅 Scheduling reminders for: ${todo.title}');

      // Cancel any existing notifications for this todo
      await cancelReminderNotification(todo.id);

      final now = DateTime.now();
      final dueDate = todo.dueDate!;
      final timeDifference = dueDate.difference(now);

      // If already overdue, send overdue notification
      if (timeDifference.isNegative) {
        await _sendOverdueNotification(todo);
        return true;
      }

      // Calculate smart reminder times
      final reminderTimes = _calculateReminderTimes(dueDate, timeDifference);
      int scheduledCount = 0;

      // Schedule each reminder
      for (int i = 0; i < reminderTimes.length; i++) {
        final reminderTime = reminderTimes[i];

        if (reminderTime.isAfter(now)) {
          final success =
              await _scheduleIndividualReminder(todo, reminderTime, i);
          if (success) scheduledCount++;
        }
      }

      print('✅ Scheduled $scheduledCount reminders for ${todo.title}');
      return scheduledCount > 0;
    } catch (e) {
      print('❌ Error scheduling reminders: $e');
      return false;
    }
  }

  /// Calculate optimal reminder times based on due date
  List<DateTime> _calculateReminderTimes(
      DateTime dueDate, Duration timeDifference) {
    final reminderTimes = <DateTime>[];

    // Smart scheduling based on time remaining
    if (timeDifference.inDays >= 7) {
      // Long term: 7 days, 3 days, 1 day, 4 hours, 1 hour, due
      reminderTimes.addAll([
        dueDate.subtract(const Duration(days: 7)),
        dueDate.subtract(const Duration(days: 3)),
        dueDate.subtract(const Duration(days: 1)),
        dueDate.subtract(const Duration(hours: 4)),
        dueDate.subtract(const Duration(hours: 1)),
        dueDate, // Due now
      ]);
    } else if (timeDifference.inDays >= 3) {
      // Medium term: 3 days, 1 day, 4 hours, 1 hour, due
      reminderTimes.addAll([
        dueDate.subtract(const Duration(days: 3)),
        dueDate.subtract(const Duration(days: 1)),
        dueDate.subtract(const Duration(hours: 4)),
        dueDate.subtract(const Duration(hours: 1)),
        dueDate,
      ]);
    } else if (timeDifference.inDays >= 1) {
      // Daily: 1 day, 4 hours, 1 hour, 15 min, due
      reminderTimes.addAll([
        dueDate.subtract(const Duration(days: 1)),
        dueDate.subtract(const Duration(hours: 4)),
        dueDate.subtract(const Duration(hours: 1)),
        dueDate.subtract(const Duration(minutes: 15)),
        dueDate,
      ]);
    } else if (timeDifference.inHours >= 4) {
      // Half day: 4 hours, 1 hour, 15 min, due
      reminderTimes.addAll([
        dueDate.subtract(const Duration(hours: 4)),
        dueDate.subtract(const Duration(hours: 1)),
        dueDate.subtract(const Duration(minutes: 15)),
        dueDate,
      ]);
    } else if (timeDifference.inHours >= 1) {
      // Hourly: 1 hour, 15 min, 5 min, due
      reminderTimes.addAll([
        dueDate.subtract(const Duration(hours: 1)),
        dueDate.subtract(const Duration(minutes: 15)),
        dueDate.subtract(const Duration(minutes: 5)),
        dueDate,
      ]);
    } else if (timeDifference.inMinutes >= 15) {
      // Short: 15 min, 5 min, due
      reminderTimes.addAll([
        dueDate.subtract(const Duration(minutes: 15)),
        dueDate.subtract(const Duration(minutes: 5)),
        dueDate,
      ]);
    } else if (timeDifference.inMinutes >= 5) {
      // Very short: 5 min, 2 min, due
      reminderTimes.addAll([
        dueDate.subtract(const Duration(minutes: 5)),
        dueDate.subtract(const Duration(minutes: 2)),
        dueDate,
      ]);
    } else if (timeDifference.inMinutes >= 2) {
      // Ultra short: 2 min, due
      reminderTimes.addAll([
        dueDate.subtract(const Duration(minutes: 2)),
        dueDate,
      ]);
    } else {
      // Immediate: due now
      reminderTimes.add(dueDate);
    }

    return reminderTimes;
  }

  /// Schedule individual reminder notification
  Future<bool> _scheduleIndividualReminder(
      Todo todo, DateTime reminderTime, int index) async {
    try {
      final dueDate = todo.dueDate!;
      final isDueNow = reminderTime.isAtSameMomentAs(dueDate);
      final minutesUntilDue = dueDate.difference(reminderTime).inMinutes;

      // Create notification content
      final content =
          _createNotificationContent(todo, minutesUntilDue, isDueNow);

      // Determine urgency
      final isUrgent = isDueNow || minutesUntilDue <= 5;
      final channelId = isUrgent ? 'urgent_reminders' : 'todo_reminders';

      // Create notification details
      final androidDetails = AndroidNotificationDetails(
        channelId,
        isUrgent ? 'Urgent Todo Reminders' : 'Todo Reminders',
        channelDescription: isUrgent
            ? 'Urgent reminders for due todos'
            : 'Reminders for upcoming todos',
        importance: isUrgent ? Importance.max : Importance.high,
        priority: isUrgent ? Priority.max : Priority.high,
        icon: '@mipmap/ic_launcher',
        color: const Color(0xFFE91E63),
        playSound: true,
        enableVibration: true,
        enableLights: isUrgent,
        ongoing: isDueNow,
        autoCancel: !isDueNow,
        category: AndroidNotificationCategory.reminder,
        styleInformation: BigTextStyleInformation(
          content['body']!,
          contentTitle: content['title'],
        ),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.active,
      );

      final platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Generate unique ID
      final notificationId = _generateNotificationId(todo.id, index);

      // Schedule notification
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        notificationId,
        content['title']!,
        content['body']!,
        tz.TZDateTime.from(reminderTime, tz.local),
        platformDetails,
        payload: '${todo.id}:$index',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Scheduled notification $notificationId at $reminderTime');
      return true;
    } catch (e) {
      print('❌ Error scheduling individual reminder: $e');
      return false;
    }
  }

  /// Create notification content based on timing
  Map<String, String> _createNotificationContent(
      Todo todo, int minutesUntilDue, bool isDueNow) {
    String title;
    String body;

    if (isDueNow) {
      title = '🚨 Task Due Now!';
      body = '${todo.title} is due right now!';
    } else if (minutesUntilDue <= 2) {
      title =
          '🔥 URGENT: Due in $minutesUntilDue minute${minutesUntilDue != 1 ? 's' : ''}!';
      body = '${todo.title} - Almost due!';
    } else if (minutesUntilDue <= 15) {
      title = '⚠️ Due in $minutesUntilDue minutes';
      body = '${todo.title} - Don\'t forget!';
    } else if (minutesUntilDue <= 60) {
      title = '⏰ Due in 1 hour';
      body = '${todo.title} - Get ready!';
    } else if (minutesUntilDue <= 1440) {
      // 24 hours
      final hours = (minutesUntilDue / 60).round();
      title = '📅 Due in $hours hour${hours != 1 ? 's' : ''}';
      body = '${todo.title} - Plan ahead!';
    } else {
      final days = (minutesUntilDue / 1440).round();
      title = '📅 Due in $days day${days != 1 ? 's' : ''}';
      body = '${todo.title} - Keep it in mind!';
    }

    // Add priority indicator
    if (todo.priority == 'high') {
      title = '🔴 $title';
    } else if (todo.priority == 'medium') {
      title = '🟡 $title';
    }

    // Add description if short
    if (todo.description.isNotEmpty && todo.description.length <= 30) {
      body += '\n📝 ${todo.description}';
    }

    return {'title': title, 'body': body};
  }

  /// Send overdue notification
  Future<void> _sendOverdueNotification(Todo todo) async {
    try {
      final minutesOverdue = DateTime.now().difference(todo.dueDate!).inMinutes;

      const androidDetails = AndroidNotificationDetails(
        'urgent_reminders',
        'Urgent Todo Reminders',
        channelDescription: 'Urgent overdue reminders',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFFF0000),
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ongoing: true,
        category: AndroidNotificationCategory.reminder,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.critical,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        _generateNotificationId(todo.id, 999),
        '🚨 OVERDUE TASK!',
        '${todo.title} was due $minutesOverdue minute${minutesOverdue != 1 ? 's' : ''} ago!',
        platformDetails,
        payload: '${todo.id}:overdue',
      );

      print('📢 Sent overdue notification for ${todo.title}');
    } catch (e) {
      print('❌ Error sending overdue notification: $e');
    }
  }

  /// Schedule completion celebration
  Future<void> scheduleCompletionNotification(Todo todo) async {
    if (!_isInitialized) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        'celebrations',
        'Task Celebrations',
        channelDescription: 'Celebrations for completed tasks',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        todo.id.hashCode + 10000,
        '🎉 Task Completed!',
        'Great job! You completed: ${todo.title}',
        platformDetails,
        payload: '${todo.id}:celebration',
      );

      print('🎉 Sent completion celebration for ${todo.title}');
    } catch (e) {
      print('❌ Error sending completion notification: $e');
    }
  }

  /// Cancel all reminders for a todo
  Future<void> cancelReminderNotification(String todoId) async {
    if (!_isInitialized) return;

    try {
      // Cancel using multiple possible IDs
      final baseId = todoId.hashCode;
      for (int i = 0; i < 15; i++) {
        await _flutterLocalNotificationsPlugin.cancel(baseId + i);
      }
      // Cancel overdue notification
      await _flutterLocalNotificationsPlugin.cancel(baseId + 999);

      print('✅ Cancelled notifications for todo: $todoId');
    } catch (e) {
      print('❌ Error cancelling notifications: $e');
    }
  }

  /// Cancel all notifications for a todo (including celebrations)
  Future<void> cancelAllNotificationsForTodo(String todoId) async {
    await cancelReminderNotification(todoId);

    try {
      // Cancel celebration notification
      await _flutterLocalNotificationsPlugin.cancel(todoId.hashCode + 10000);
    } catch (e) {
      print('❌ Error cancelling celebration notification: $e');
    }
  }

  /// Update reminders when todo is modified
  Future<void> updateReminderNotification(Todo todo) async {
    await cancelReminderNotification(todo.id);

    if (!todo.isCompleted && todo.dueDate != null) {
      await scheduleReminderNotification(todo);
    }
  }

  /// Send welcome notification
  Future<void> _sendWelcomeNotification() async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'todo_reminders',
        'Todo Reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFE91E63),
        timeoutAfter: 5000,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        99999,
        '✅ Re-Todo Ready!',
        'Notifications are working perfectly!',
        platformDetails,
        payload: 'welcome',
      );
    } catch (e) {
      print('❌ Error sending welcome notification: $e');
    }
  }

  /// Send test notification
  Future<void> showTestNotification() async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'todo_reminders',
        'Todo Reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFE91E63),
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final currentTime = DateTime.now().toString().substring(11, 19);

      await _flutterLocalNotificationsPlugin.show(
        88888,
        '🔔 Test Notification',
        'Notification system working! Time: $currentTime',
        platformDetails,
        payload: 'test',
      );

      print('✅ Test notification sent');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  /// Schedule test reminder (for testing purposes)
  Future<void> scheduleTestReminder(int seconds) async {
    if (!_isInitialized) await initialize();

    try {
      final scheduledTime = DateTime.now().add(Duration(seconds: seconds));

      const androidDetails = AndroidNotificationDetails(
        'todo_reminders',
        'Todo Reminders',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFE91E63),
        playSound: true,
        enableVibration: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        77777,
        '⏰ Test Reminder',
        'This reminder was scheduled $seconds seconds ago!',
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformDetails,
        payload: 'test_scheduled',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('✅ Test reminder scheduled for $seconds seconds');
    } catch (e) {
      print('❌ Error scheduling test reminder: $e');
    }
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    if (!_isInitialized) return 0;

    try {
      final pending =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
      return 0;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) return;

    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      print('🗑️ All notifications cancelled');
    } catch (e) {
      print('❌ Error cancelling all notifications: $e');
    }
  }

  /// Generate unique notification ID
  int _generateNotificationId(String todoId, int index) {
    return todoId.hashCode + index;
  }

  /// Daily productivity summary (optional)
  Future<void> scheduleDailyProductivitySummary() async {
    // Implementation can be added if needed
  }

  /// Check if service is properly initialized
  bool get isInitialized => _isInitialized;
}
