import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import 'api_services.dart';
import '../services/session_service.dart';

class SettingsService {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  static Future<void> setValue(String key, String value) async {
    final database = await _db.database;

    await database.insert("settings", {
      "key": key,
      "value": value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<String?> getValue(String key) async {
    final database = await _db.database;

    final rows = await database.query(
      "settings",
      where: "key=?",
      whereArgs: [key],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return rows.first["value"] as String?;
  }

  // DAILY REMINDER
  static Future<void> setDailyReminder(bool value) async {
    await setValue("dailyReminder", value.toString());
  }

  static Future<bool> getDailyReminder() async {
    final value = await getValue("dailyReminder");

    return value == null ? true : value == "true";
  }

  // EXPENSE ALERTS
  static Future<void> setExpenseAlerts(bool value) async {
    await setValue("expenseAlerts", value.toString());
  }

  static Future<bool> getExpenseAlerts() async {
    final value = await getValue("expenseAlerts");

    return value == null ? true : value == "true";
  }

  // WEEKLY SUMMARY
  static Future<void> setWeeklySummary(bool value) async {
    await setValue("weeklySummary", value.toString());
  }

  static Future<bool> getWeeklySummary() async {
    final value = await getValue("weeklySummary");

    return value == null ? false : value == "true";
  }

  static Future<void> syncFromBackend() async {
    if (await SessionService.isGuest()) {
      return;
    }

    final preferences = await ApiService.getPreferences();

    await setDailyReminder(preferences["daily_reminder"] ?? false);

    await setExpenseAlerts(preferences["expense_alerts"] ?? false);

    await setWeeklySummary(preferences["weekly_summary"] ?? false);
  }

  static Future<void> saveLastSync(DateTime time) async {
    await setValue("last_sync", time.toIso8601String());
  }

  static Future<DateTime?> getLastSync() async {
    final value = await getValue("last_sync");

    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value);
  }
  //  PROFILE

  static Future<void> saveProfile({
    required String name,
    required String email,
  }) async {
    await setValue("profile_name", name);
    await setValue("profile_email", email);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    return {
      "name": await getValue("profile_name") ?? "",
      "email": await getValue("profile_email") ?? "",
    };
  }

  //  DASHBOARD

  static Future<void> clearUserSettings() async {
    final db = await DatabaseHelper.instance.database;

    final ownerId = await SessionService.currentOwnerId();

    await db.delete(
      "settings",
      where: "key IN (?,?,?,?,?,?,?)",
      whereArgs: [
        "profile_name",
        "profile_email",
        "dashboard_stats_$ownerId",
        "dailyReminder",
        "expenseAlerts",
        "weeklySummary",
        "last_sync",
      ],
    );
  }
}
