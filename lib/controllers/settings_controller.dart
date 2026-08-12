import 'package:flutter/material.dart';
import '../models/settings_state.dart';
import '../repositories/settings_repository.dart';
import '../services/session_service.dart';
import 'settings_preferences_controller.dart';
import 'settings_session_controller.dart';

class SettingsController {
  final SettingsRepository settingsRepository;

  final SettingsPreferencesController settingsPreferencesController;
  final SettingsSessionController settingsSessionController;

  SettingsState _state = const SettingsState();

  SettingsState get state => _state;

  VoidCallback? onStateChanged;

  SettingsController({
    required this.settingsRepository,
    required this.settingsPreferencesController,
    required this.settingsSessionController,
  });

  void _setState(
    SettingsState Function(SettingsState state) update, {
    bool notify = true,
  }) {
    _state = update(_state);

    if (notify) {
      _notifyStateChanged();
    }
  }

  void _notifyStateChanged() {
    onStateChanged?.call();
  }

  Future<void> initialize() async {
    _setState((state) => state.copyWith(isLoading: true));

    try {
      final guest = await SessionService.isGuest();

      _setState((state) => state.copyWith(isGuest: guest), notify: false);

      await Future.wait([
        loadSettings(notify: false),
        loadProfile(notify: false),
        loadDashboardStats(notify: false),
        loadLastSyncTime(notify: false),
      ]);

      _setState(
        (state) => state.clearLoadingError().copyWith(isLoading: false),
      );
    } catch (e) {
      debugPrint('Failed to initialize settings: $e');

      _setState(
        (state) => state.copyWith(
          isLoading: false,
          loadingError: 'Unable to load some settings. Please try again.',
        ),
      );
    }
  }

  Future<void> retryInitialization() async {
    await initialize();
  }

  Future<void> loadSessionState() async {
    final guest = await SessionService.isGuest();

    _setState((state) => state.copyWith(isGuest: guest));
  }

  Future<void> loadProfile({bool notify = true}) async {
    if (_state.isGuest) {
      _setState(
        (state) => state.copyWith(
          userName: 'Guest Account',
          userEmail: 'Login to sync your data',
        ),
        notify: notify,
      );

      return;
    }

    try {
      final user = await settingsRepository.getProfile();

      _setState(
        (state) => state.copyWith(
          userName: user['name'] ?? '',
          userEmail: user['email'] ?? '',
        ),
        notify: notify,
      );
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  Future<void> loadSettings({bool notify = true}) async {
    try {
      final prefs = await settingsRepository.getPreferences();

      _setState(
        (state) => state.copyWith(
          dailyReminder: prefs.dailyReminder,
          expenseAlerts: prefs.expenseAlerts,
          weeklySummary: prefs.weeklySummary,
        ),
        notify: notify,
      );
    } catch (e) {
      debugPrint('Failed to load settings preferences: $e');
    }
  }

  Future<void> loadDashboardStats({bool notify = true}) async {
    try {
      final stats = await settingsRepository.getDashboardStatistics();

      _setState(
        (state) => state.copyWith(
          totalGoals: stats['totalGoals'] ?? 0,
          completedGoals: stats['completedGoals'] ?? 0,
          totalExpenses: stats['totalExpenses'] ?? 0,
          totalBudgets: stats['totalBudgets'] ?? 0,
        ),
        notify: notify,
      );
    } catch (e) {
      debugPrint('Failed to load dashboard statistics: $e');
    }
  }

  Future<void> loadLastSyncTime({bool notify = true}) async {
    try {
      final lastSync = await settingsRepository.getLastSync();

      _setState(
        (state) => state.copyWith(lastSyncTime: lastSync),
        notify: notify,
      );
    } catch (e) {
      debugPrint('Failed to load last sync time: $e');
    }
  }

  Future<void> refresh() async {
    try {
      await Future.wait([
        loadSettings(notify: false),
        loadProfile(notify: false),
        loadDashboardStats(notify: false),
        loadLastSyncTime(notify: false),
      ]);
    } catch (e) {
      debugPrint('Failed to refresh settings: $e');
      rethrow;
    } finally {
      _notifyStateChanged();
    }
  }

  Future<void> updateNotificationPreference({
    required String title,
    required bool value,
    required bool isOnline,
  }) async {
    final previousState = _state;

    _setState(
      (state) => state.copyWith(
        dailyReminder: title == 'Daily Reminder' ? value : state.dailyReminder,
        expenseAlerts: title == 'Expense Alerts' ? value : state.expenseAlerts,
        weeklySummary: title == 'Weekly Summary' ? value : state.weeklySummary,
      ),
    );

    try {
      await settingsPreferencesController.updateNotificationPreference(
        title: title,
        value: value,
        isOnline: isOnline,
        dailyReminder: _state.dailyReminder,
        expenseAlerts: _state.expenseAlerts,
        weeklySummary: _state.weeklySummary,
      );
    } catch (_) {
      _state = previousState;
      rethrow;
    }
  }

  Future<void> logout() async {
    await settingsSessionController.logout();
  }

  void dispose() {
    onStateChanged = null;
  }
}
