import 'package:flutter/foundation.dart';

class SyncEvents {
  SyncEvents._();

  static final SyncEvents instance = SyncEvents._();

  // Goals
  final ValueNotifier<int> goalsRefresh = ValueNotifier<int>(0);

  final ValueNotifier<int> archivedRefresh = ValueNotifier<int>(0);

  // Expenses
  final ValueNotifier<int> expensesRefresh = ValueNotifier<int>(0);

  // Dashboard
  final ValueNotifier<int> dashboardRefresh = ValueNotifier<int>(0);

  // Analytics
  final ValueNotifier<int> analyticsRefresh = ValueNotifier<int>(0);

  // Settings
  final ValueNotifier<int> settingsRefresh = ValueNotifier<int>(0);

  void notifyGoalsUpdated() {
    goalsRefresh.value++;
  }

  void notifyArchivedUpdated() {
    archivedRefresh.value++;
  }

  void notifyExpensesUpdated() {
    expensesRefresh.value++;
  }

  void notifyDashboardUpdated() {
    dashboardRefresh.value++;
  }

  void notifyAnalyticsUpdated() {
    analyticsRefresh.value++;
  }

  void notifySettingsUpdated() {
    settingsRefresh.value++;
  }

  /// Call this after a financial record changes locally
  /// or after synchronization updates local SQLite.
  void notifyFinancialDataUpdated() {
    expensesRefresh.value++;
    dashboardRefresh.value++;
    analyticsRefresh.value++;
    settingsRefresh.value++;
  }

  void notifyGoalDataUpdated() {
    goalsRefresh.value++;
    dashboardRefresh.value++;
    analyticsRefresh.value++;
    settingsRefresh.value++;
  }
}
