import '../models/user_preferences.dart';
import '../services/api_services.dart';
import '../services/settings_service.dart';

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

  // ==========================
  // DASHBOARD
  // ==========================

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
