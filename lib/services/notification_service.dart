import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io';
import '../models/todos.dart';
import '../database/db_helper.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
      },
    );
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.requestNotificationsPermission();
      await androidImplementation?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleTodoNotification(Todo todo) async {
    if (!todo.isReminder || todo.reminderTime == null) return;

    // Parse reminder time HH:mm
    final List<String> timeParts = todo.reminderTime!.split(':');
    final int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);

    final int id = todo.notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'dailyku_reminders',
      'Dailyku Reminders',
      channelDescription: 'Notifications for Dailyku tasks',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    if (todo.repeatType == 'weekly' && todo.repeatValue != null) {
      // Weekly repeating (1-7, 1=Monday in ISO, but flutter_local_notifications uses 1=Monday too)
      await _scheduleWeekly(id, todo.title, hour, minute, todo.repeatValue!, platformChannelSpecifics);
    } else if (todo.date != null) {
      // One-time
      final DateTime date = DateTime.parse(todo.date!);
      final scheduledDate = DateTime(date.year, date.month, date.day, hour, minute);
      
      if (scheduledDate.isAfter(DateTime.now())) {
        await flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          'Pengingat Tugas',
          todo.title,
          tz.TZDateTime.from(scheduledDate, tz.local),
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    } else if (todo.repeatType == 'daily') {
      // Daily (not explicitly requested but good for production)
       await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        'Pengingat Tugas',
        todo.title,
        _nextInstanceOfTime(hour, minute),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> _scheduleWeekly(int id, String title, int hour, int minute, int dayOfWeek, NotificationDetails details) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Pengingat Tugas',
      title,
      _nextInstanceOfDayAndTime(dayOfWeek, hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDayAndTime(int dayOfWeek, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelNotification(int? id) async {
    if (id != null) {
      await flutterLocalNotificationsPlugin.cancel(id);
    }
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> refreshNotifications() async {
    // Get all todos from DB and re-schedule them
    final List<Todo> todos = await DBHelper.instance.getTodos();
    for (var todo in todos) {
      if (todo.isReminder && !todo.isDone) {
        await scheduleTodoNotification(todo);
      }
    }
  }
}
