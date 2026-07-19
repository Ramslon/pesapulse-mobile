import 'package:shared_preferences/shared_preferences.dart';
import 'api_services.dart';

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

  static Future<void> syncFromBackend() async {
    final prefs = await ApiService.getPreferences();

    await setDailyReminder(prefs['daily_reminder'] ?? false);

    await setExpenseAlerts(prefs['expense_alerts'] ?? false);

    await setWeeklySummary(prefs['weekly_summary'] ?? false);
  }

  static const String lastSyncKey = "last_sync";

  static Future<void> saveLastSync(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(lastSyncKey, time.toIso8601String());
  }

  static Future<DateTime?> getLastSync() async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString(lastSyncKey);

    if (value == null) return null;

    return DateTime.tryParse(value);
  }
}
