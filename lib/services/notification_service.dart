import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  static Future<void> checkBudgetAlerts() async {
    try {
      final insights = await ApiService.getFinancialInsights();

      final status = insights['status'];

      if (status == 'warning') {
        await showNotification(
          title: 'Budget Warning',
          body: 'You have used more than 80% of your budget.',
        );
      }

      if (status == 'overspent') {
        await showNotification(
          title: 'Budget Exceeded',
          body: 'You have exceeded your budget. Review your expenses.',
        );
      }
    } catch (e) {
      print('Budget alert error: $e');
    }
  }

  static Future<void> showNotification({
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
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id: 0,
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

  static Future<void> debugPendingNotifications() async {
    final pending = await flutterLocalNotificationsPlugin
        .pendingNotificationRequests();

    print('Pending notifications: ${pending.length}');

    for (final item in pending) {
      print('${item.id} - ${item.title}');
    }
  }

  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final scheduledTZ = tz.TZDateTime.from(scheduledDate, tz.local);

    print('Now: ${DateTime.now()}');
    print('Scheduled Local: ${scheduledDate.toLocal()}');
    print('Scheduled: $scheduledTZ');

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
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
