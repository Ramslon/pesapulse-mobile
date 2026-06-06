import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  // DAILY REMINDER
  static Future<void> setDailyReminder(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('dailyReminder', value);
  }

  static Future<bool> getDailyReminder() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool('dailyReminder') ?? true;
  }

  // EXPENSE ALERTS
  static Future<void> setExpenseAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('expenseAlerts', value);
  }

  static Future<bool> getExpenseAlerts() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool('expenseAlerts') ?? true;
  }

  // WEEKLY SUMMARY
  static Future<void> setWeeklySummary(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('weeklySummary', value);
  }

  static Future<bool> getWeeklySummary() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool('weeklySummary') ?? false;
  }
}
