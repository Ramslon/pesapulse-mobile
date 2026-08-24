import '../repositories/settings_repository.dart';
import '../services/notification_service.dart';
import '../services/sync_events.dart';

class SettingsPreferencesController {
  final SettingsRepository settingsRepository;

  SettingsPreferencesController({required this.settingsRepository});

  static const int preferenceNotificationId = 3001;

  Future<void> updatePreferences({
    required bool dailyReminder,
    required bool expenseAlerts,
    required bool weeklySummary,
    required bool isOnline,
  }) async {
    if (isOnline) {
      await settingsRepository.updatePreferencesOnline(
        dailyReminder: dailyReminder,
        expenseAlerts: expenseAlerts,
        weeklySummary: weeklySummary,
      );
    } else {
      await settingsRepository.updatePreferencesOffline(
        dailyReminder: dailyReminder,
        expenseAlerts: expenseAlerts,
        weeklySummary: weeklySummary,
      );
    }

    SyncEvents.instance.notifySettingsUpdated();
  }

  Future<void> notifyPreferenceChanged({
    required String title,
    required bool enabled,
  }) async {
    await NotificationService.showNotification(
      id: preferenceNotificationId,
      title: title,
      body: enabled ? '$title enabled' : '$title disabled',
    );
  }

  Future<void> updateNotificationPreference({
    required String title,
    required bool value,
    required bool isOnline,
    required bool dailyReminder,
    required bool expenseAlerts,
    required bool weeklySummary,
  }) async {
    await updatePreferences(
      dailyReminder: dailyReminder,
      expenseAlerts: expenseAlerts,
      weeklySummary: weeklySummary,
      isOnline: isOnline,
    );

    await notifyPreferenceChanged(title: title, enabled: value);
  }
}
