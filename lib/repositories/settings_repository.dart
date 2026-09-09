import 'dart:convert';
import 'package:pesapulse_mobile/repositories/base_repository.dart';
import 'package:pesapulse_mobile/services/session_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

import '../models/user_preferences.dart';
import '../services/api_services.dart';
import '../services/settings_service.dart';
import '../services/startup_refresh_coordinator.dart';
import '../database/database_helper.dart';
import '../exceptions/rate_limit_exception.dart';

class SettingsRepository extends BaseRepository {
  Map<String, dynamic>? _profileCache;

  UserPreferences? _preferencesCache;

  Map<String, dynamic>? _dashboardCache;

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value == 1;
    }

    if (value is double) {
      return value == 1;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }

    return false;
  }

  // PROFILE
  Future<Map<String, dynamic>> getProfile({bool forceRefresh = false}) async {
    // Guest users should never see another user's cached profile.
    if (await SessionService.isGuest()) {
      final guestProfile = {"name": "Guest Account", "email": ""};

      _profileCache = guestProfile;

      return guestProfile;
    }

    // Use in-memory cache when a forced network refresh is not required.
    if (!forceRefresh && _profileCache != null) {
      return _profileCache!;
    }

    try {
      final profile = await StartupRefreshCoordinator.instance.run(
        'profile',
        () async {
          debugPrint('SettingsRepository: requesting profile from API...');

          return await ApiService.getProfile();
        },
      );

      await _saveSetting("profile_name", profile["name"] ?? "");

      await _saveSetting("profile_email", profile["email"] ?? "");

      _profileCache = profile;

      return profile;
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('SettingsRepository: profile API failed, using cache: $e');

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

    // ------------------------------------------------------------
    // Use cached dashboard statistics when a refresh is not needed.
    // Always reconcile goals and expenses with the current local DB.
    // ------------------------------------------------------------
    if (!forceRefresh && _dashboardCache != null) {
      final goalStats = await _getLocalGoalStatistics();
      final localExpenseCount = await _getLocalExpenseCount();

      final stats = {
        ..._dashboardCache!,
        "totalGoals": goalStats["totalGoals"],
        "completedGoals": goalStats["completedGoals"],
        "totalExpenses": localExpenseCount,
      };

      _dashboardCache = stats;

      return stats;
    }

    try {
      // ----------------------------------------------------------
      // Budget still comes from the backend because budget data
      // is not being calculated from the expenses table here.
      // ----------------------------------------------------------
      final budgetSummary = await ApiService.getBudgetSummary();

      // ----------------------------------------------------------
      // Goals and expenses use the local SQLite database as the
      // current source of truth.
      // ----------------------------------------------------------
      final goalStats = await _getLocalGoalStatistics();

      final localExpenseCount = await _getLocalExpenseCount();

      final stats = {
        "totalGoals": goalStats["totalGoals"],
        "completedGoals": goalStats["completedGoals"],
        "totalExpenses": localExpenseCount,
        "totalBudgets": budgetSummary["budget_count"] ?? 0,
      };

      await _saveSetting("dashboard_stats_$ownerId", jsonEncode(stats));

      _dashboardCache = stats;

      return stats;
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('Settings dashboard statistics refresh failed: $e');

      // ----------------------------------------------------------
      // Fall back to stored statistics.
      // Always reconcile goals and expenses with local SQLite.
      // ----------------------------------------------------------
      final cached = await _getSetting("dashboard_stats_$ownerId");

      final goalStats = await _getLocalGoalStatistics();

      final localExpenseCount = await _getLocalExpenseCount();

      if (cached != null && cached.isNotEmpty) {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;

        decoded["totalGoals"] = goalStats["totalGoals"];

        decoded["completedGoals"] = goalStats["completedGoals"];

        decoded["totalExpenses"] = localExpenseCount;

        _dashboardCache = decoded;

        return decoded;
      }

      return {
        "totalGoals": goalStats["totalGoals"],
        "completedGoals": goalStats["completedGoals"],
        "totalExpenses": localExpenseCount,
        "totalBudgets": 0,
      };
    }
  }

  Future<Map<String, dynamic>> getCachedProfile() async {
    if (_profileCache != null) {
      return _profileCache!;
    }

    final name = await _getSetting("profile_name");
    final email = await _getSetting("profile_email");

    if (name == null && email == null) {
      throw Exception("No cached profile");
    }

    final profile = {"name": name ?? "", "email": email ?? ""};

    _profileCache = profile;

    return profile;
  }

  Future<Map<String, dynamic>> getCachedDashboardStatistics() async {
    final ownerId = await this.ownerId;

    Map<String, dynamic> stats;

    if (_dashboardCache != null) {
      stats = Map<String, dynamic>.from(_dashboardCache!);
    } else {
      final cached = await _getSetting("dashboard_stats_$ownerId");

      if (cached == null || cached.isEmpty) {
        throw Exception("No cached dashboard statistics");
      }

      final decoded = jsonDecode(cached);

      if (decoded is! Map<String, dynamic>) {
        throw Exception("Invalid cached dashboard statistics");
      }

      stats = Map<String, dynamic>.from(decoded);
    }

    // ------------------------------------------------------------
    // Always reconcile goals with local SQLite.
    // ------------------------------------------------------------
    final goalStats = await _getLocalGoalStatistics();

    stats["totalGoals"] = goalStats["totalGoals"];

    stats["completedGoals"] = goalStats["completedGoals"];

    // ------------------------------------------------------------
    // Always reconcile expenses with local SQLite.
    // ------------------------------------------------------------
    final localExpenseCount = await _getLocalExpenseCount();

    stats["totalExpenses"] = localExpenseCount;

    _dashboardCache = stats;

    return stats;
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

    final preferences = await StartupRefreshCoordinator.instance.run(
      'preferences',
      () async {
        return await ApiService.getPreferences();
      },
    );

    final dailyReminder = _toBool(preferences["daily_reminder"]);

    final expenseAlerts = _toBool(preferences["expense_alerts"]);

    final weeklySummary = _toBool(preferences["weekly_summary"]);

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

  Future<Map<String, int>> _getLocalGoalStatistics() async {
    final database = await db.database;
    final ownerId = await this.ownerId;

    final totalResult = await database.rawQuery(
      """
    SELECT COUNT(*)
    FROM goals
    WHERE owner_id = ?
      AND is_archived = 0
      AND is_deleted = 0
    """,
      [ownerId],
    );

    final completedResult = await database.rawQuery(
      """
    SELECT COUNT(*)
    FROM goals
    WHERE owner_id = ?
      AND is_archived = 0
      AND is_deleted = 0
      AND completed_at IS NOT NULL
    """,
      [ownerId],
    );

    return {
      "totalGoals": Sqflite.firstIntValue(totalResult) ?? 0,
      "completedGoals": Sqflite.firstIntValue(completedResult) ?? 0,
    };
  }

  Future<int> _getLocalExpenseCount() async {
    final database = await db.database;
    final ownerId = await this.ownerId;

    final result = await database.rawQuery(
      """
    SELECT COUNT(*)
    FROM expenses
    WHERE owner_id = ?
    """,
      [ownerId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  void clearCache() {
    _profileCache = null;
    _preferencesCache = null;
    _dashboardCache = null;
  }
}
