import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/connectivity_provider.dart';
import '../../services/notification_service.dart';
import '../../services/sync_events.dart';
import '../../utils/responsive_helper.dart';
import '../../repositories/settings_repository.dart';

class SettingsNotificationsSection extends StatelessWidget {
  final bool dailyReminder;
  final bool expenseAlerts;
  final bool weeklySummary;

  final ValueChanged<bool> onDailyReminderChanged;
  final ValueChanged<bool> onExpenseAlertsChanged;
  final ValueChanged<bool> onWeeklySummaryChanged;

  const SettingsNotificationsSection({
    super.key,
    required this.dailyReminder,
    required this.expenseAlerts,
    required this.weeklySummary,
    required this.onDailyReminderChanged,
    required this.onExpenseAlertsChanged,
    required this.onWeeklySummaryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    final cardRadius = isCompact ? 16.0 : 18.0;

    final horizontalPadding = isCompact
        ? 12.0
        : isLandscape
        ? 16.0
        : 18.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(color: colorScheme.outline.withOpacity(.10)),
      ),
      child: Column(
        children: [
          _NotificationSwitchTile(
            icon: Icons.alarm_outlined,
            iconColor: Colors.green,
            title: 'Daily Reminder',
            subtitle: 'Receive a reminder every day.',
            value: dailyReminder,
            compact: isCompact,
            horizontalPadding: horizontalPadding,
            onChanged: (value) async {
              try {
                await _updatePreferences(
                  context,
                  dailyReminder: value,
                  expenseAlerts: expenseAlerts,
                  weeklySummary: weeklySummary,
                );

                onDailyReminderChanged(value);

                await NotificationService.showNotification(
                  id: NotificationService.preferenceNotificationId,
                  title: 'Daily Reminder',
                  body: value
                      ? 'Daily reminders enabled'
                      : 'Daily reminders disabled',
                );
              } catch (e) {
                debugPrint('Daily reminder update failed: $e');

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Couldn’t update Daily Reminder. Please try again.',
                    ),
                  ),
                );
              }
            },
          ),

          const Divider(height: 1),

          _NotificationSwitchTile(
            icon: Icons.notifications_active_outlined,
            iconColor: Colors.orange,
            title: 'Expense Alerts',
            subtitle: 'Notify me when spending exceeds your budget.',
            value: expenseAlerts,
            compact: isCompact,
            horizontalPadding: horizontalPadding,
            onChanged: (value) async {
              try {
                await _updatePreferences(
                  context,
                  dailyReminder: dailyReminder,
                  expenseAlerts: value,
                  weeklySummary: weeklySummary,
                );

                onExpenseAlertsChanged(value);

                await NotificationService.showNotification(
                  id: NotificationService.preferenceNotificationId,
                  title: 'Expense Alerts',
                  body: value
                      ? 'Expense alerts enabled'
                      : 'Expense alerts disabled',
                );
              } catch (e) {
                debugPrint('Expense alerts update failed: $e');

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Couldn’t update Expense Alerts. Please try again.',
                    ),
                  ),
                );
              }
            },
          ),

          const Divider(height: 1),

          _NotificationSwitchTile(
            icon: Icons.summarize_outlined,
            iconColor: Colors.blue,
            title: 'Weekly Summary',
            subtitle: 'Receive weekly financial reports.',
            value: weeklySummary,
            compact: isCompact,
            horizontalPadding: horizontalPadding,
            onChanged: (value) async {
              try {
                await _updatePreferences(
                  context,
                  dailyReminder: dailyReminder,
                  expenseAlerts: expenseAlerts,
                  weeklySummary: value,
                );

                onWeeklySummaryChanged(value);

                await NotificationService.showNotification(
                  id: NotificationService.preferenceNotificationId,
                  title: 'Weekly Summary',
                  body: value
                      ? 'Weekly summaries enabled'
                      : 'Weekly summaries disabled',
                );
              } catch (e) {
                debugPrint('Weekly summary update failed: $e');

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Couldn’t update Weekly Summary. Please try again.',
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _updatePreferences(
    BuildContext context, {
    required bool dailyReminder,
    required bool expenseAlerts,
    required bool weeklySummary,
  }) async {
    final connectivity = context.read<ConnectivityProvider>();
    final SettingsRepository settingsRepository = SettingsRepository();

    if (connectivity.isOnline) {
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
}

class _NotificationSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool compact;
  final double horizontalPadding;
  final ValueChanged<bool> onChanged;

  const _NotificationSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.compact,
    required this.horizontalPadding,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: compact ? 2 : 4,
      ),

      secondary: Container(
        width: compact ? 38 : 42,
        height: compact ? 38 : 42,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(.10),
          borderRadius: BorderRadius.circular(compact ? 11 : 13),
        ),
        child: Icon(icon, color: iconColor, size: compact ? 20 : 21),
      ),

      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontSize: compact ? 14 : null,
          fontWeight: FontWeight.w700,
        ),
      ),

      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: compact ? 11 : null,
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.3,
        ),
      ),

      value: value,
      activeColor: theme.colorScheme.primary,
      onChanged: onChanged,
    );
  }
}
