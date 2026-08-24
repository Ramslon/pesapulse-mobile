import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../services/api_services.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();

    tz.setLocalLocation(tz.getLocation('Africa/Nairobi'));

    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  static const int budgetNotificationId = 2001;
  static const int preferenceNotificationId = 3001;

  static int goalNotificationId(int goalId) {
    return 1000 + goalId;
  }

  static int goalMilestoneNotificationId(int goalId) {
    return 100000 + goalId;
  }

  static Future<void> checkBudgetAlerts() async {
    try {
      final insights = await ApiService.getFinancialInsights();

      final status = insights['status'];
      final percentage =
          double.tryParse(insights['usage_percentage'].toString()) ?? 0;

      if (status == 'critical') {
        await showNotification(
          id: budgetNotificationId,
          title: 'Critical Budget Alert',
          body:
              'You have spent ${percentage.toStringAsFixed(1)}% of your budget.',
        );
      }

      if (status == 'warning') {
        await showNotification(
          id: budgetNotificationId,
          title: 'Budget Warning',
          body:
              'You have spent ${percentage.toStringAsFixed(1)}% of your budget.',
        );
      }

      if (status == 'overspent') {
        await showNotification(
          id: budgetNotificationId,
          title: 'Budget Exceeded',
          body:
              'You have spent ${percentage.toStringAsFixed(1)}% of your budget.',
        );
      }

      if (status == 'healthy') {
        await showNotification(
          id: budgetNotificationId,
          title: 'Budget Healthy',
          body:
              'You have spent ${percentage.toStringAsFixed(1)}% of your budget.',
        );
      }
    } catch (e) {
      debugPrint('Budget alert error: $e');
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'pesapulse_channel',
          'PesaPulse Notifications',
          channelDescription: 'Expense reminders and alerts',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFF2E7D32),
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }

  static Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledTZ,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'pesapulse_channel',
          'PesaPulse Notifications',
          channelDescription: 'Expense reminders and alerts',
          importance: Importance.max,
          priority: Priority.high,
          color: Color(0xFF2E7D32),
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<bool> shouldShowGoalDeadlineNotification(
    int goalId,
    int daysRemaining,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final key = 'goal_deadline_notification_${goalId}_$daysRemaining';

    final alreadyNotified = prefs.getBool(key) ?? false;

    if (alreadyNotified) {
      return false;
    }

    await prefs.setBool(key, true);

    return true;
  }

  static Future<bool> shouldShowGoalMilestoneNotification(
    int goalId,
    int percentage,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final key = 'goal_milestone_notification_${goalId}_$percentage';

    final alreadyNotified = prefs.getBool(key) ?? false;

    if (alreadyNotified) {
      return false;
    }

    await prefs.setBool(key, true);

    return true;
  }
}
