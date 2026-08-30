import 'dart:convert';
import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:pesapulse_mobile/services/session_service.dart';
import 'package:sqflite/sqflite.dart';

import '../models/user_preferences.dart';
import '../services/api_services.dart';
import '../services/settings_service.dart';
import '../database/database_helper.dart';
import '../exceptions/rate_limit_exception.dart';

class SettingsRepository extends BaseRepository {
  Map<String, dynamic>? _profileCache;

  UserPreferences? _preferencesCache;

  Map<String, dynamic>? _dashboardCache;

  // PROFILE
  Future<Map<String, dynamic>> getProfile({bool forceRefresh = false}) async {
    // Guest users should never see another user's cached profile
    if (await SessionService.isGuest()) {
      final guestProfile = {"name": "Guest Account", "email": ""};

      _profileCache = guestProfile;

      return guestProfile;
    }

    if (!forceRefresh && _profileCache != null) {
      return _profileCache!;
    }

    try {
      final profile = await ApiService.getProfile();

      await _saveSetting("profile_name", profile["name"] ?? "");
      await _saveSetting("profile_email", profile["email"] ?? "");

      _profileCache = profile;

      return profile;
    } on RateLimitException {
      rethrow;
    } catch (_) {
      final name = await _getSetting("profile_name") ?? "";
      final email = await _getSetting("profile_email") ?? "";

      final local = {"name": name, "email": email};

      _profileCache = local;

      return local;
    }
  }

  Future<Map<String, dynamic>> updateProfile(String name, String email) async {
    final response = await ApiService.updateProfile(name, email);

    if (response["user"] != null) {
      final user = response["user"];

      await _saveSetting("profile_name", user["name"] ?? "");

      await _saveSetting("profile_email", user["email"] ?? "");

      _profileCache = {"name": user["name"], "email": user["email"]};
    }

    return response;
  }

  Future<void> deleteAccount(String password) async {
    await ApiService.deleteAccount(password);

    // clear local database
    final ownerId = await SessionService.currentOwnerId();

    await DatabaseHelper.instance.clearUserData(ownerId);

    // clear local settings

    await SettingsService.clearUserSettings();

    // logout

    await SessionService.logout();
  }
  // USER PREFERENCES

  Future<UserPreferences> getPreferences() async {
    if (_preferencesCache != null) {
      return _preferencesCache!;
    }

    if (await SessionService.isGuest()) {
      _preferencesCache = UserPreferences(
        dailyReminder: false,
        expenseAlerts: false,
        weeklySummary: false,
        darkMode: false,
        notificationsEnabled: true,
      );

      return _preferencesCache!;
    }

    final dailyReminder = (await _getSetting("daily_reminder")) == "true";
    final expenseAlerts = (await _getSetting("expense_alerts")) == "true";
    final weeklySummary = (await _getSetting("weekly_summary")) == "true";

    _preferencesCache = UserPreferences(
      darkMode: false,
      notificationsEnabled: true,
      dailyReminder: dailyReminder,
      expenseAlerts: expenseAlerts,
      weeklySummary: weeklySummary,
    );

    return _preferencesCache!;
  }

  Future<void> updatePreferences(Map<String, dynamic> data) async {
    if (await SessionService.isGuest()) return;

    await ApiService.updatePreferences(data);
  }

  Future<void> updatePreferencesOffline({
    required bool dailyReminder,
    required bool expenseAlerts,
    required bool weeklySummary,
  }) async {
    final ownerId = await this.ownerId;

    await _saveSetting("daily_reminder", dailyReminder.toString());

    await _saveSetting("expense_alerts", expenseAlerts.toString());

    await _saveSetting("weekly_summary", weeklySummary.toString());

    _preferencesCache = UserPreferences(
      darkMode: false,
      notificationsEnabled: true,
      dailyReminder: dailyReminder,
      expenseAlerts: expenseAlerts,
      weeklySummary: weeklySummary,
    );

    final database = await db.database;

    await database.insert("sync_queue", {
      "owner_id": ownerId,
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

  Future<void> _savePreferencesLocally({
    required bool dailyReminder,
    required bool expenseAlerts,
    required bool weeklySummary,
  }) async {
    await _saveSetting("daily_reminder", dailyReminder.toString());
    await _saveSetting("expense_alerts", expenseAlerts.toString());
    await _saveSetting("weekly_summary", weeklySummary.toString());

    _preferencesCache = UserPreferences(
      darkMode: false,
      notificationsEnabled: true,
      dailyReminder: dailyReminder,
      expenseAlerts: expenseAlerts,
      weeklySummary: weeklySummary,
    );
  }

  Future<void> updatePreferencesOnline({
    required bool dailyReminder,
    required bool expenseAlerts,
    required bool weeklySummary,
  }) async {
    // Guest users only save locally
    if (await SessionService.isGuest()) {
      await _savePreferencesLocally(
        dailyReminder: dailyReminder,
        expenseAlerts: expenseAlerts,
        weeklySummary: weeklySummary,
      );
      return;
    }

    // Logged-in users sync to backend

    await ApiService.updatePreferences({
      "daily_reminder": dailyReminder,
      "expense_alerts": expenseAlerts,
      "weekly_summary": weeklySummary,
    });

    await _savePreferencesLocally(
      dailyReminder: dailyReminder,
      expenseAlerts: expenseAlerts,
      weeklySummary: weeklySummary,
    );
  }

  // DASHBOARD

  Future<Map<String, dynamic>> getDashboardStatistics({
    bool forceRefresh = false,
  }) async {
    final ownerId = await this.ownerId;

    if (ownerId == "guest") {
      return {
        "totalGoals": 0,
        "completedGoals": 0,
        "totalExpenses": 0,
        "totalBudgets": 0,
      };
    }

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
        "totalBudgets": budgetSummary["budget_count"] ?? 0,
      };

      await _saveSetting("dashboard_stats_$ownerId", jsonEncode(stats));

      _dashboardCache = stats;

      return stats;
    } on RateLimitException {
      // Do NOT hide rate-limit errors.
      rethrow;
    } catch (_) {
      final cached = await _getSetting("dashboard_stats_$ownerId");

      if (cached != null) {
        _dashboardCache = jsonDecode(cached) as Map<String, dynamic>;
        return _dashboardCache!;
      }

      return {
        "totalGoals": 0,
        "completedGoals": 0,
        "totalExpenses": 0,
        "totalBudgets": 0,
      };
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

  Future<bool> getDailyReminder() async =>
      (await _getSetting("daily_reminder")) == "true";

  Future<bool> getExpenseAlerts() async =>
      (await _getSetting("expense_alerts")) == "true";

  Future<bool> getWeeklySummary() async =>
      (await _getSetting("weekly_summary")) == "true";

  Future<void> setDailyReminder(bool value) async =>
      _saveSetting("daily_reminder", value.toString());

  Future<void> setExpenseAlerts(bool value) async =>
      _saveSetting("expense_alerts", value.toString());

  Future<void> setWeeklySummary(bool value) async =>
      _saveSetting("weekly_summary", value.toString());

  Future<DateTime?> getLastSync() async {
    final value = await _getSetting("last_sync");

    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  Future<void> saveLastSync(DateTime date) async {
    await _saveSetting("last_sync", date.toIso8601String());
  }

  Future<void> _saveSetting(String key, String value) async {
    final database = await db.database;

    await database.insert("settings", {
      "key": key,
      "value": value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> _getSetting(String key) async {
    final database = await db.database;

    final result = await database.query(
      "settings",
      where: "key=?",
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first["value"] as String?;
  }

  Future<void> syncPreferencesFromBackend() async {
    if (await SessionService.isGuest()) {
      return;
    }
    final preferences = await ApiService.getPreferences();

    await SettingsService.setDailyReminder(
      preferences["daily_reminder"] ?? false,
    );

    await SettingsService.setExpenseAlerts(
      preferences["expense_alerts"] ?? false,
    );

    await SettingsService.setWeeklySummary(
      preferences["weekly_summary"] ?? false,
    );

    _preferencesCache = UserPreferences(
      darkMode: false,
      notificationsEnabled: true,
      dailyReminder: preferences["daily_reminder"] ?? false,
      expenseAlerts: preferences["expense_alerts"] ?? false,
      weeklySummary: preferences["weekly_summary"] ?? false,
    );
  }

  void clearCache() {
    _profileCache = null;
    _preferencesCache = null;
    _dashboardCache = null;
  }
}
