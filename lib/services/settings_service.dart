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

  //  PROFILE

  static Future<void> saveProfile({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("profile_name", name);
    await prefs.setString("profile_email", email);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "name": prefs.getString("profile_name") ?? "",
      "email": prefs.getString("profile_email") ?? "",
    };
  }

  //  DASHBOARD

  static Future<void> saveDashboardStats({
    required int totalGoals,
    required int completedGoals,
    required int totalExpenses,
    required int totalBudgets,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt("dashboard_total_goals", totalGoals);
    await prefs.setInt("dashboard_completed_goals", completedGoals);
    await prefs.setInt("dashboard_total_expenses", totalExpenses);
    await prefs.setInt("dashboard_total_budgets", totalBudgets);
  }

  static Future<Map<String, int>> getDashboardStats() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      "totalGoals": prefs.getInt("dashboard_total_goals") ?? 0,
      "completedGoals": prefs.getInt("dashboard_completed_goals") ?? 0,
      "totalExpenses": prefs.getInt("dashboard_total_expenses") ?? 0,
      "totalBudgets": prefs.getInt("dashboard_total_budgets") ?? 0,
    };
  }
}
