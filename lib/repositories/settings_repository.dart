import 'dart:convert';
import '../models/user_preferences.dart';
import '../services/api_services.dart';
import '../services/settings_service.dart';
import '../database/database_helper.dart';

class SettingsRepository {
  // PROFILE

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final profile = await ApiService.getProfile();

      await SettingsService.saveProfile(
        name: profile["name"] ?? "",
        email: profile["email"] ?? "",
      );

      return profile;
    } catch (_) {
      return await SettingsService.getProfile();
    }
  }

  Future<Map<String, dynamic>> updateProfile(String name, String email) async {
    final response = await ApiService.updateProfile(name, email);

    if (response["user"] != null) {
      await SettingsService.saveProfile(
        name: response["user"]["name"],
        email: response["user"]["email"],
      );
    }

    return response;
  }

  // USER PREFERENCES

  Future<UserPreferences> getPreferences() async {
    return await ApiService.getUserPreferences();
  }

  Future<void> updatePreferences(Map<String, dynamic> data) async {
    await ApiService.updatePreferences(data);
  }

  Future<void> updatePreferencesOffline({
    required bool dailyReminder,
    required bool expenseAlerts,
    required bool weeklySummary,
  }) async {
    await SettingsService.setDailyReminder(dailyReminder);

    await SettingsService.setExpenseAlerts(expenseAlerts);

    await SettingsService.setWeeklySummary(weeklySummary);

    final db = await DatabaseHelper.instance.database;

    await db.insert("sync_queue", {
      "table_name": "preferences",
      "operation": "update",
      "record_id": 0,
      "payload": jsonEncode({
        "daily_reminder": dailyReminder,
        "expense_alerts": expenseAlerts,
        "weekly_summary": weeklySummary,
      }),
      "created_at": DateTime.now().toIso8601String(),
    });
  }

  Future<void> updatePreferencesOnline({
    required bool dailyReminder,
    required bool expenseAlerts,
    required bool weeklySummary,
  }) async {
    await ApiService.updatePreferences({
      "daily_reminder": dailyReminder,

      "expense_alerts": expenseAlerts,

      "weekly_summary": weeklySummary,
    });

    await SettingsService.setDailyReminder(dailyReminder);

    await SettingsService.setExpenseAlerts(expenseAlerts);

    await SettingsService.setWeeklySummary(weeklySummary);
  }

  // DASHBOARD

  Future getDashboardStatistics() async {
    try {
      final goalsAnalytics = await ApiService.getGoalAnalytics();

      final expenses = await ApiService.getExpenses();

      final budgetSummary = await ApiService.getBudgetSummary();

      final stats = {
        "totalGoals": goalsAnalytics["total_goals"] ?? 0,
        "completedGoals": goalsAnalytics["completed_goals"] ?? 0,
        "totalExpenses": (expenses["data"] as List).length,
        "totalBudgets": budgetSummary["budget"] != null ? 1 : 0,
      };

      await SettingsService.saveDashboardStats(
        totalGoals: stats["totalGoals"]!,
        completedGoals: stats["completedGoals"]!,
        totalExpenses: stats["totalExpenses"]!,
        totalBudgets: stats["totalBudgets"]!,
      );

      return stats;
    } catch (_) {
      return await SettingsService.getDashboardStats();
    }
  }

  Future<Map<String, dynamic>> getGoalAnalytics() async {
    return await ApiService.getGoalAnalytics();
  }

  Future<Map<String, dynamic>> getExpenses() async {
    return await ApiService.getExpenses();
  }

  Future<Map<String, dynamic>> getBudgetSummary() async {
    return await ApiService.getBudgetSummary();
  }

  // ==========================
  // LOCAL SETTINGS
  // ==========================

  Future<bool> getDailyReminder() => SettingsService.getDailyReminder();

  Future<bool> getExpenseAlerts() => SettingsService.getExpenseAlerts();

  Future<bool> getWeeklySummary() => SettingsService.getWeeklySummary();

  Future<void> setDailyReminder(bool value) =>
      SettingsService.setDailyReminder(value);

  Future<void> setExpenseAlerts(bool value) =>
      SettingsService.setExpenseAlerts(value);

  Future<void> setWeeklySummary(bool value) =>
      SettingsService.setWeeklySummary(value);

  Future<DateTime?> getLastSync() => SettingsService.getLastSync();

  Future<void> saveLastSync(DateTime date) =>
      SettingsService.saveLastSync(date);
}
