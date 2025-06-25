// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/todo.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize notification service with proper permissions
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      print('🚀 Initializing notification service...');

      // Request permissions first
      await _requestAllPermissions();

      // Android settings
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      final initialized = await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        await _createNotificationChannels();
        await _requestExactAlarmPermission();
        _isInitialized = true;
        print('✅ NotificationService initialized successfully');
      } else {
        print('❌ Failed to initialize notification service');
      }
    } catch (e) {
      print('❌ Error initializing NotificationService: $e');
    }
  }

  /// Request all necessary permissions
  Future<void> _requestAllPermissions() async {
    try {
      // Request notification permission
      final notificationStatus = await Permission.notification.request();
      print('📱 Notification permission: $notificationStatus');

      // Request schedule exact alarm permission for Android 12+
      if (await Permission.scheduleExactAlarm.isDenied) {
        final scheduleStatus = await Permission.scheduleExactAlarm.request();
        print('⏰ Schedule exact alarm permission: $scheduleStatus');
      }

      // Request system alert window for better notification delivery
      if (await Permission.systemAlertWindow.isDenied) {
        final alertStatus = await Permission.systemAlertWindow.request();
        print('🪟 System alert window permission: $alertStatus');
      }
    } catch (e) {
      print('⚠️ Error requesting permissions: $e');
    }
  }

  /// Request exact alarm permission specifically
  Future<void> _requestExactAlarmPermission() async {
    try {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        final bool? exactAlarmPermission =
            await androidPlugin.requestExactAlarmsPermission();
        print('⏰ Exact alarm permission granted: $exactAlarmPermission');
      }
    } catch (e) {
      print('⚠️ Exact alarm permission error: $e');
    }
  }

  /// Create notification channels with maximum priority
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Create high-priority reminder channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'todo_reminders',
          'Todo Reminders',
          description: 'Critical reminders for your important tasks',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          showBadge: true,
          ledColor: Color(0xFFE91E63),
        ),
      );

      // Create celebration channel
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          'todo_celebrations',
          'Task Celebrations',
          description: 'Celebrations when you complete tasks',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          showBadge: false,
        ),
      );

      print('✅ High-priority notification channels created');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final payload = notificationResponse.payload;
    if (payload != null) {
      print('🔔 Notification tapped: $payload');
    }
  }

  /// Schedule reminder notifications with enhanced delivery
  Future<void> scheduleReminderNotification(Todo todo) async {
    if (!_isInitialized) await initialize();

    if (todo.dueDate == null) {
      print('⚠️ No due date set for todo: ${todo.title}');
      return;
    }

    try {
      final now = DateTime.now();
      final dueDate = todo.dueDate!;

      print('🕐 Current time: ${now.toString().substring(0, 19)}');
      print('📅 Due date: ${dueDate.toString().substring(0, 19)}');

      // Don't schedule if due date is in the past
      if (dueDate.isBefore(now)) {
        print('⚠️ Due date is in the past for: ${todo.title}');
        return;
      }

      // Get reminder times
      final reminderTimes = todo.getEffectiveReminderTimes();

      if (reminderTimes.isEmpty) {
        print('ℹ️ No reminders set for ${todo.title}');
        return;
      }

      print(
          '⏰ Reminder intervals: ${reminderTimes.map((d) => _formatDuration(d)).join(', ')}');

      // Enhanced notification details for maximum visibility
      const androidDetails = AndroidNotificationDetails(
        'todo_reminders',
        'Todo Reminders',
        channelDescription: 'Critical reminders for your important tasks',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        color: Color(0xFFE91E63),
        ledColor: Color(0xFFE91E63),
        ledOnMs: 1000,
        ledOffMs: 500,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showWhen: true,
        when: null,
        autoCancel: false,
        ongoing: false,
        silent: false,
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        channelShowBadge: true,
        onlyAlertOnce: false,
        showProgress: false,
        indeterminate: false,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        categoryIdentifier: 'todoReminder',
        threadIdentifier: 'todo_reminders',
      );

      const platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      int scheduledCount = 0;

      // Schedule notifications for each reminder time
      for (int i = 0; i < reminderTimes.length; i++) {
        final reminderTime = dueDate.subtract(reminderTimes[i]);
        final timeDesc = _formatDuration(reminderTimes[i]);

        print('📋 Checking reminder ${i + 1}: $timeDesc before due date');
        print(
            '🕐 Reminder time would be: ${reminderTime.toString().substring(0, 19)}');

        // Only schedule if reminder time is in the future (with 30 second buffer)
        final bufferTime = now.add(const Duration(seconds: 30));
        if (reminderTime.isAfter(bufferTime)) {
          final notificationId = _generateNotificationId(todo.id, i);
          final message = _getReminderMessage(todo, timeDesc);

          // Convert to timezone-aware DateTime
          final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);

          await _flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId,
            '⏰ Todo Reminder - ${todo.priority.toUpperCase()}',
            message,
            scheduledDate,
            platformDetails,
            payload: 'todo:${todo.id}',
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );

          scheduledCount++;
          print(
              '✅ Scheduled reminder for "${todo.title}" at ${reminderTime.toString().substring(0, 19)} ($timeDesc before due)');

          // Removed backup test notification as requested
        } else {
          final timeDiff = bufferTime.difference(reminderTime);
          print(
              '⚠️ Reminder time ${reminderTime.toString().substring(0, 19)} is ${_formatDuration(timeDiff)} in the past, skipping');
        }
      }

      // If no reminders could be scheduled, create a test reminder
      if (scheduledCount == 0) {
        await _scheduleEmergencyTestReminder(todo, now);
        scheduledCount = 1;
      }

      // Schedule overdue notification
      final overdueTime = dueDate.add(const Duration(hours: 1));
      if (overdueTime.isAfter(now)) {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          _generateNotificationId(todo.id, 999),
          '⚠️ OVERDUE: ${todo.title}',
          '${todo.title} is now overdue! Complete it as soon as possible.',
          tz.TZDateTime.from(overdueTime, tz.local),
          platformDetails,
          payload: 'todo:${todo.id}:overdue',
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );

        print(
            '⚠️ Scheduled overdue notification for "${todo.title}" at ${overdueTime.toString().substring(0, 19)}');
      }

      print('✅ Scheduled $scheduledCount reminders for ${todo.title}');

      // Removed test verification notification as requested
    } catch (e) {
      print('❌ Error scheduling reminder: $e');
    }
  }

  /// Schedule emergency test reminder when no regular reminders can be scheduled
  Future<void> _scheduleEmergencyTestReminder(Todo todo, DateTime now) async {
    try {
      final testTime = now.add(const Duration(seconds: 30));

      const androidDetails = AndroidNotificationDetails(
        'todo_reminders',
        'Todo Reminders',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFFFF9800),
        playSound: true,
        enableVibration: true,
        autoCancel: false,
      );

      const platformDetails = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        88886,
        '🚨 Emergency Test Reminder',
        'Your reminder times were in the past. Set due date further in future. Todo: "${todo.title}"',
        tz.TZDateTime.from(testTime, tz.local),
        platformDetails,
        payload: 'emergency_test',
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      print('🚨 Scheduled emergency test reminder for 30 seconds');
    } catch (e) {
      print('❌ Error scheduling emergency test: $e');
    }
  }

  /// Send immediate test verification
  Future<void> _sendTestVerification(
      String todoTitle, int scheduledCount) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'todo_reminders',
        'Todo Reminders',
        importance: Importance.max,
        priority: Priority.max,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        playSound: true,
        enableVibration: true,
        autoCancel: true,
      );

      const platformDetails = NotificationDetails(android: androidDetails);

      String message;
      if (scheduledCount > 0) {
        message =
            'SUCCESS: $scheduledCount reminder(s) scheduled for "$todoTitle". Watch for notifications!';
      } else {
        message =
            'ISSUE: No reminders scheduled for "$todoTitle". Check due date and reminder times.';
      }

      await _flutterLocalNotificationsPlugin.show(
        99999,
        '✅ Notification System Status',
        message,
        platformDetails,
        payload: 'verification',
      );

      print('📱 Sent verification notification');
    } catch (e) {
      print('❌ Error sending verification: $e');
    }
  }

  /// Get priority-based reminder message
  String _getReminderMessage(Todo todo, String timeDesc) {
    switch (todo.priority) {
      case 'high':
        return '🔥 URGENT: "${todo.title}" is due in $timeDesc! You\'re running out of time!';
      case 'medium':
        return '⚡ "${todo.title}" is due in $timeDesc! You\'re running out of time to complete this task.';
      case 'low':
        return '📝 "${todo.title}" is due in $timeDesc. Don\'t forget to complete it!';
      default:
        return '"${todo.title}" is due in $timeDesc! You\'re running out of time to complete this task.';
    }
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''}';
    }
  }

  /// Schedule completion celebration
  Future<void> scheduleCompletionNotification(Todo todo) async {
    if (!_isInitialized) await initialize();

    try {
      const androidDetails = AndroidNotificationDetails(
        'todo_celebrations',
        'Task Celebrations',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Color(0xFF4CAF50),
        playSound: true,
        enableVibration: true,
        timeoutAfter: 5000,
      );

      const platformDetails = NotificationDetails(android: androidDetails);

      await _flutterLocalNotificationsPlugin.show(
        _generateNotificationId(todo.id, 10000),
        '🎉 Task Completed!',
        'Awesome! You completed: ${todo.title}',
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
      final baseId = todoId.hashCode;
      for (int i = 0; i < 30; i++) {
        await _flutterLocalNotificationsPlugin.cancel(baseId + i);
      }
      await _flutterLocalNotificationsPlugin.cancel(baseId + 999);
      await _flutterLocalNotificationsPlugin.cancel(88887); // Test notification
      await _flutterLocalNotificationsPlugin.cancel(88886); // Emergency test

      print('✅ Cancelled notifications for todo: $todoId');
    } catch (e) {
      print('❌ Error cancelling notifications: $e');
    }
  }

  /// Cancel all notifications for a todo
  Future<void> cancelAllNotificationsForTodo(String todoId) async {
    await cancelReminderNotification(todoId);

    try {
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

  /// Schedule daily productivity summary
  Future<void> scheduleDailyProductivitySummary() async {
    print('📊 Daily productivity summary scheduled');
  }

  /// Generate unique notification ID
  int _generateNotificationId(String todoId, int index) {
    return todoId.hashCode.abs() + index;
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    if (!_isInitialized) return 0;

    try {
      final pending =
          await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      print('📊 Pending notifications: ${pending.length}');
      for (final notification in pending) {
        print(
            '📋 Pending: ID ${notification.id}, Title: ${notification.title}');
      }
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

  /// Send immediate test notification
  Future<void> showTestNotification() async {
    if (!_isInitialized) await initialize();

    try {
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

      const platformDetails = NotificationDetails(android: androidDetails);

      final currentTime = DateTime.now().toString().substring(11, 19);

      await _flutterLocalNotificationsPlugin.show(
        88888,
        '🔔 Immediate Test',
        'Notification system working! Time: $currentTime',
        platformDetails,
        payload: 'test_immediate',
      );

      print('✅ Sent immediate test notification');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  /// Check if service is properly initialized
  bool get isInitialized => _isInitialized;
}
