import 'dart:convert';
import '../models/user_preferences.dart';
import '../services/api_services.dart';
import '../services/settings_service.dart';
import '../database/database_helper.dart';

class SettingsRepository {
  Map<String, dynamic>? _profileCache;

  UserPreferences? _preferencesCache;

  Map<String, dynamic>? _dashboardCache;
  // PROFILE

  Future<Map<String, dynamic>> getProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && _profileCache != null) {
      return _profileCache!;
    }

    try {
      final profile = await ApiService.getProfile();

      await SettingsService.saveProfile(
        name: profile["name"] ?? "",
        email: profile["email"] ?? "",
      );

      _profileCache = profile;

      return profile;
    } catch (_) {
      final local = await SettingsService.getProfile();

      _profileCache = local;

      return local;
    }
  }

  Future<Map<String, dynamic>> updateProfile(String name, String email) async {
    final response = await ApiService.updateProfile(name, email);

    if (response["user"] != null) {
      final user = response["user"];

      await SettingsService.saveProfile(
        name: user["name"],
        email: user["email"],
      );

      _profileCache = {"name": user["name"], "email": user["email"]};
    }

    return response;
  }

  // USER PREFERENCES

  Future<UserPreferences> getPreferences() async {
    if (_preferencesCache != null) {
      return _preferencesCache!;
    }

    final prefs = UserPreferences(
      darkMode: false, // until Dark Mode is added
      notificationsEnabled: true, // until Notification toggle is added
      dailyReminder: await SettingsService.getDailyReminder(),
      expenseAlerts: await SettingsService.getExpenseAlerts(),
      weeklySummary: await SettingsService.getWeeklySummary(),
    );

    _preferencesCache = prefs;

    return prefs;
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

    _preferencesCache = UserPreferences(
      darkMode: false,
      notificationsEnabled: true,
      dailyReminder: dailyReminder,
      expenseAlerts: expenseAlerts,
      weeklySummary: weeklySummary,
    );

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

    _preferencesCache = UserPreferences(
      darkMode: false,
      notificationsEnabled: true,
      dailyReminder: dailyReminder,
      expenseAlerts: expenseAlerts,
      weeklySummary: weeklySummary,
    );
  }

  // DASHBOARD

  Future<Map<String, dynamic>> getDashboardStatistics({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _dashboardCache != null) {
      return _dashboardCache!;
    }

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

      _dashboardCache = stats;

      return stats;
    } catch (_) {
      final stats = await SettingsService.getDashboardStats();

      _dashboardCache = stats;

      return stats;
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

  void clearCache() {
    _profileCache = null;
    _preferencesCache = null;
    _dashboardCache = null;
  }
}
