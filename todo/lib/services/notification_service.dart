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

  /// Request notification permissions - COMPATIBLE WITH VERSION 17.0.0
  Future<void> _requestPermissions() async {
    try {
      // Request basic notification permission using permission_handler
      await Permission.notification.request();

      // For Android 13+ (API level 33+), request notification permission
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      // For version 17.0.0, we don't call requestPermission on AndroidFlutterLocalNotificationsPlugin
      // as this method was removed. We rely on permission_handler instead.
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // Only request exact alarms permission if available
        try {
          // Check if the method exists before calling it
          final bool? exactAlarmsResult =
              await androidPlugin.requestExactAlarmsPermission();
          print('Exact alarms permission result: $exactAlarmsResult');
        } catch (e) {
          print('⚠️ Exact alarms permission not available in this version: $e');
        }
      }

      print('✅ Permissions requested successfully');
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
          playSound: true,
          enableVibration: true,
          showBadge: true,
        ),
      );

      // Celebration notifications channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'celebrations',
          'Task Celebrations',
          description: 'Celebrations for completed tasks',
          importance: Importance.defaultImportance,
          playSound: true,
          enableVibration: false,
          showBadge: false,
        ),
      );

      print('✅ Notification channels created');
    }
  }

  /// Handle notification taps
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 Notification tapped: ${response.payload}');

    if (response.payload != null) {
      final payload = response.payload!;

      if (payload.startsWith('todo:')) {
        final todoId = payload.substring(5);
        print('📝 Opening todo: $todoId');
        // Navigate to specific todo (implement navigation logic here)
      } else if (payload.contains(':celebration')) {
        final todoId = payload.split(':')[0];
        print('🎉 Celebration tapped for todo: $todoId');
      }
    }
  }

  /// Schedule reminder notification for a todo
  Future<void> scheduleReminderNotification(Todo todo) async {
    if (!_isInitialized) await initialize();
    if (todo.dueDate == null || todo.isCompleted) return;

    try {
      final now = DateTime.now();
      final dueDate = todo.dueDate!;

      // Don't schedule if due date is in the past
      if (dueDate.isBefore(now)) return;

      const androidDetails = AndroidNotificationDetails(
        'todo_reminders',
        'Todo Reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFE91E63),
        playSound: true,
        enableVibration: true,
        showWhen: true,
        when: null,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'todoReminder',
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule reminders at different intervals
      final intervals = [
        Duration(hours: 24), // 1 day before
        Duration(hours: 2), // 2 hours before
        Duration(minutes: 15), // 15 minutes before
      ];

      for (int i = 0; i < intervals.length; i++) {
        final reminderTime = dueDate.subtract(intervals[i]);

        if (reminderTime.isAfter(now)) {
          final notificationId = _generateNotificationId(todo.id, i);

          String timeDesc;
          if (intervals[i].inDays > 0) {
            timeDesc =
                '${intervals[i].inDays} day${intervals[i].inDays > 1 ? 's' : ''}';
          } else if (intervals[i].inHours > 0) {
            timeDesc =
                '${intervals[i].inHours} hour${intervals[i].inHours > 1 ? 's' : ''}';
          } else {
            timeDesc =
                '${intervals[i].inMinutes} minute${intervals[i].inMinutes > 1 ? 's' : ''}';
          }

          await _flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            '⏰ Todo Reminder',
            '${todo.title} is due in $timeDesc!',
            tz.TZDateTime.from(reminderTime, tz.local),
            platformDetails,
            payload: 'todo:${todo.id}',
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
        }
      }

      // Schedule overdue notification (1 hour after due date)
      final overdueTime = dueDate.add(const Duration(hours: 1));
      if (overdueTime.isAfter(now)) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          _generateNotificationId(todo.id, 999),
          '⚠️ Overdue Todo',
          '${todo.title} is now overdue!',
          tz.TZDateTime.from(overdueTime, tz.local),
          platformDetails,
          payload: 'todo:${todo.id}',
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }

      print('✅ Scheduled reminders for ${todo.title}');
    } catch (e) {
      print('❌ Error scheduling reminder: $e');
    }
  }

  /// Schedule completion celebration notification
  Future<void> scheduleCompletionNotification(Todo todo) async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'todo_celebrations',
        'Completion Celebrations',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        playSound: true,
        enableVibration: false,
        timeoutAfter: 8000,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
        categoryIdentifier: 'todoCelebration',
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        _generateNotificationId(todo.id, 10000),
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
