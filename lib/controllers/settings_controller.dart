import 'package:flutter/material.dart';

import '../models/settings_state.dart';
import '../repositories/settings_repository.dart';
import '../services/session_service.dart';
import 'settings_preferences_controller.dart';
import 'settings_session_controller.dart';
import '../exceptions/rate_limit_exception.dart';

class SettingsController {
  final SettingsRepository settingsRepository;

  final SettingsPreferencesController settingsPreferencesController;
  final SettingsSessionController settingsSessionController;

  SettingsState _state = const SettingsState();

  SettingsState get state => _state;

  bool _refreshInProgress = false;

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

  // ============================================================
  // INITIALIZATION
  // ============================================================

  Future<void> initialize() async {
    _setState((state) => state.copyWith(isLoading: true, loadingError: null));

    try {
      final guest = await SessionService.isGuest();

      _setState((state) => state.copyWith(isGuest: guest), notify: false);

      // Load ONLY local/cache data first.
      //
      // This is what makes Settings open immediately without
      // waiting for the backend.
      await Future.wait([
        loadSettings(notify: false),
        loadProfileFromCache(notify: false),
        loadDashboardStatsFromCache(notify: false),
        loadLastSyncTime(notify: false),
      ]);

      // Cache/local initialization is complete.
      //
      // The UI can now render immediately.
      _setState(
        (state) => state.clearLoadingError().copyWith(isLoading: false),
      );

      // Refresh backend data after the UI has rendered.
      if (!_state.isGuest) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshInBackground();
        });
      }
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

  // ============================================================
  // BACKGROUND REFRESH
  // ============================================================

  Future<void> _refreshInBackground() async {
    if (_refreshInProgress) {
      return;
    }

    if (_state.isGuest) {
      return;
    }

    _refreshInProgress = true;

    try {
      await Future.wait([
        loadSettings(notify: false),
        loadProfile(notify: false),
        loadDashboardStats(notify: false),
        loadLastSyncTime(notify: false),
      ]);

      _setState(
        (state) => state.clearLoadingError().copyWith(isLoading: false),
      );

      debugPrint('Settings background refresh completed.');
    } on RateLimitException catch (e) {
      // Background refresh should not disturb the UI.
      debugPrint('Settings background refresh rate limited: ${e.message}');
    } catch (e) {
      // Cached settings remain visible.
      debugPrint('Settings background refresh failed: $e');
    } finally {
      _refreshInProgress = false;
    }
  }

  // ============================================================
  // RETRY
  // ============================================================

  Future<void> retryInitialization() async {
    await initialize();
  }

  // ============================================================
  // SESSION
  // ============================================================

  Future<void> loadSessionState() async {
    final guest = await SessionService.isGuest();

    _setState((state) => state.copyWith(isGuest: guest));
  }

  // ============================================================
  // PROFILE — CACHE FIRST
  // ============================================================

  Future<void> loadProfileFromCache({bool notify = true}) async {
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
      final profile = await settingsRepository.getCachedProfile();

      _setState(
        (state) => state.copyWith(
          userName: profile['name']?.toString() ?? '',
          userEmail: profile['email']?.toString() ?? '',
        ),
        notify: notify,
      );

      debugPrint('Loaded cached settings profile.');
    } catch (e) {
      debugPrint('No cached profile available: $e');
    }
  }

  // ============================================================
  // PROFILE — NETWORK
  // ============================================================

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
      final user = await settingsRepository.getProfile(forceRefresh: true);

      _setState(
        (state) => state.copyWith(
          userName: user['name']?.toString() ?? '',
          userEmail: user['email']?.toString() ?? '',
        ),
        notify: notify,
      );

      debugPrint('Settings profile refreshed.');
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  // ============================================================
  // PREFERENCES — LOCAL/CACHED
  // ============================================================

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

  // ============================================================
  // DASHBOARD STATISTICS — CACHE FIRST
  // ============================================================

  Future<void> loadDashboardStatsFromCache({bool notify = true}) async {
    if (_state.isGuest) {
      return;
    }

    try {
      final stats = await settingsRepository.getCachedDashboardStatistics();

      _setState(
        (state) => state.copyWith(
          totalGoals: int.tryParse(stats['totalGoals'].toString()) ?? 0,
          completedGoals: int.tryParse(stats['completedGoals'].toString()) ?? 0,
          totalExpenses: int.tryParse(stats['totalExpenses'].toString()) ?? 0,
          totalBudgets: int.tryParse(stats['totalBudgets'].toString()) ?? 0,
        ),
        notify: notify,
      );

      debugPrint('Loaded cached dashboard statistics.');
    } catch (e) {
      debugPrint('No cached dashboard statistics available: $e');
    }
  }

  // ============================================================
  // DASHBOARD STATISTICS — NETWORK
  // ============================================================

  Future<void> loadDashboardStats({bool notify = true}) async {
    try {
      final stats = await settingsRepository.getDashboardStatistics(
        forceRefresh: true,
      );

      _setState(
        (state) => state.copyWith(
          totalGoals: stats['totalGoals'] ?? 0,
          completedGoals: stats['completedGoals'] ?? 0,
          totalExpenses: stats['totalExpenses'] ?? 0,
          totalBudgets: stats['totalBudgets'] ?? 0,
        ),
        notify: notify,
      );

      debugPrint('Dashboard statistics refreshed.');
    } on RateLimitException catch (e) {
      debugPrint('Dashboard statistics rate limited: ${e.message}');

      rethrow;
    } catch (e) {
      debugPrint('Failed to load dashboard statistics: $e');
    }
  }

  // ============================================================
  // LAST SYNC
  // ============================================================

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

  // ============================================================
  // MANUAL REFRESH
  // ============================================================

  Future<void> refresh() async {
    if (_refreshInProgress) {
      return;
    }

    _refreshInProgress = true;

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
      _refreshInProgress = false;
      _notifyStateChanged();
    }
  }

  // ============================================================
  // NOTIFICATION PREFERENCES
  // ============================================================

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
      _notifyStateChanged();
      rethrow;
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await settingsSessionController.logout();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    onStateChanged = null;
  }
}
