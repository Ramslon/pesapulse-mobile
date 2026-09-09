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

  static bool _toBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) {
      return value;
    }

    if (value is int) {
      return value != 0;
    }

    if (value is double) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();

      if (normalized == 'true' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'on') {
        return true;
      }

      if (normalized == 'false' ||
          normalized == '0' ||
          normalized == 'no' ||
          normalized == 'off') {
        return false;
      }
    }

    return defaultValue;
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      darkMode: _toBool(json['dark_mode'], defaultValue: false),
      notificationsEnabled: _toBool(
        json['notifications_enabled'],
        defaultValue: true,
      ),
      dailyReminder: _toBool(json['daily_reminder'], defaultValue: false),
      expenseAlerts: _toBool(json['expense_alerts'], defaultValue: false),
      weeklySummary: _toBool(json['weekly_summary'], defaultValue: false),
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
