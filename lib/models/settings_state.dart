class SettingsState {
  final String userName;
  final String userEmail;

  final bool dailyReminder;
  final bool expenseAlerts;
  final bool weeklySummary;

  final int totalGoals;
  final int completedGoals;
  final int totalExpenses;
  final int totalBudgets;

  final DateTime? lastSyncTime;

  final bool isGuest;
  final bool isLoading;

  final String? loadingError;

  const SettingsState({
    this.userName = '',
    this.userEmail = '',
    this.dailyReminder = true,
    this.expenseAlerts = true,
    this.weeklySummary = false,
    this.totalGoals = 0,
    this.completedGoals = 0,
    this.totalExpenses = 0,
    this.totalBudgets = 0,
    this.lastSyncTime,
    this.isGuest = false,
    this.isLoading = true,
    this.loadingError,
  });

  SettingsState copyWith({
    String? userName,
    String? userEmail,
    bool? dailyReminder,
    bool? expenseAlerts,
    bool? weeklySummary,
    int? totalGoals,
    int? completedGoals,
    int? totalExpenses,
    int? totalBudgets,
    DateTime? lastSyncTime,
    bool? isGuest,
    bool? isLoading,
    String? loadingError,
  }) {
    return SettingsState(
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      expenseAlerts: expenseAlerts ?? this.expenseAlerts,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      totalGoals: totalGoals ?? this.totalGoals,
      completedGoals: completedGoals ?? this.completedGoals,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      totalBudgets: totalBudgets ?? this.totalBudgets,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isGuest: isGuest ?? this.isGuest,
      isLoading: isLoading ?? this.isLoading,
      loadingError: loadingError ?? this.loadingError,
    );
  }

  SettingsState clearLoadingError() {
    return SettingsState(
      userName: userName,
      userEmail: userEmail,
      dailyReminder: dailyReminder,
      expenseAlerts: expenseAlerts,
      weeklySummary: weeklySummary,
      totalGoals: totalGoals,
      completedGoals: completedGoals,
      totalExpenses: totalExpenses,
      totalBudgets: totalBudgets,
      lastSyncTime: lastSyncTime,
      isGuest: isGuest,
      isLoading: isLoading,
      loadingError: null,
    );
  }
}
