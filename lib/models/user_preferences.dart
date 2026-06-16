class UserPreferences {
  final bool darkMode;
  final bool notificationsEnabled;
  final bool dailyReminder;
  final bool expenseAlerts;
  final bool weeklySummary;

  UserPreferences({
    required this.darkMode,
    required this.notificationsEnabled,
    required this.dailyReminder,
    required this.expenseAlerts,
    required this.weeklySummary,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      darkMode: json['dark_mode'] ?? false,
      notificationsEnabled: json['notifications_enabled'] ?? true,
      dailyReminder: json['daily_reminder'] ?? false,
      expenseAlerts: json['expense_alerts'] ?? false,
      weeklySummary: json['weekly_summary'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dark_mode': darkMode,
      'notifications_enabled': notificationsEnabled,
      'daily_reminder': dailyReminder,
      'expense_alerts': expenseAlerts,
      'weekly_summary': weeklySummary,
    };
  }
}
