import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/notification_service.dart';
import '../services/guest_dialog_service.dart';
import '../repositories/settings_repository.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/auth_message_helper.dart';
import '../providers/theme_provider.dart';
import '../../utils/responsive_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final SettingsRepository _settingsRepository = SettingsRepository();

  bool isLoading = false;

  bool dailyReminder = true;
  bool expenseAlerts = true;
  bool weeklySummary = false;

  int totalGoals = 0;
  int completedGoals = 0;
  int totalExpenses = 0;
  int totalBudgets = 0;

  @override
  void initState() {
    super.initState();

    loadSettings();
    loadProfile();
    loadDashboardStats();
  }

  // ─────────────────────────────────────────────
  // Profile
  // ─────────────────────────────────────────────

  Future<void> updateProfile() async {
    if (await GuestDialogService.isGuest()) {
      await GuestDialogService.show(context);
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await _settingsRepository.updateProfile(
        nameController.text.trim(),
        emailController.text.trim(),
      );

      await loadProfile();

      if (!mounted) return;

      AuthMessageHelper.showSuccess(
        context,
        response['message'] ?? 'Profile updated successfully.',
      );
    } catch (e) {
      if (!mounted) return;

      AuthMessageHelper.showOffline(context);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> loadProfile() async {
    try {
      final profile = await _settingsRepository.getProfile();

      if (!mounted) return;

      setState(() {
        nameController.text = profile['name'] ?? '';
        emailController.text = profile['email'] ?? '';
      });
    } catch (e) {
      if (!mounted) return;

      AuthMessageHelper.showOffline(context);
    }
  }

  // ─────────────────────────────────────────────
  // Settings
  // ─────────────────────────────────────────────

  Future<void> loadSettings() async {
    try {
      final prefs = await _settingsRepository.getPreferences();

      if (!mounted) return;

      setState(() {
        dailyReminder = prefs.dailyReminder;
        expenseAlerts = prefs.expenseAlerts;
        weeklySummary = prefs.weeklySummary;
      });
    } catch (e) {
      debugPrint('Settings Error: $e');
    }
  }

  Future<void> _updateNotificationPreferences({
    bool? dailyReminderValue,
    bool? expenseAlertsValue,
    bool? weeklySummaryValue,
    required String notificationTitle,
    required String enabledMessage,
    required String disabledMessage,
  }) async {
    final newDailyReminder = dailyReminderValue ?? dailyReminder;
    final newExpenseAlerts = expenseAlertsValue ?? expenseAlerts;
    final newWeeklySummary = weeklySummaryValue ?? weeklySummary;

    try {
      await _settingsRepository.updatePreferencesOnline(
        dailyReminder: newDailyReminder,
        expenseAlerts: newExpenseAlerts,
        weeklySummary: newWeeklySummary,
      );

      await NotificationService.showNotification(
        title: notificationTitle,
        body:
            (dailyReminderValue ??
                expenseAlertsValue ??
                weeklySummaryValue ??
                false)
            ? enabledMessage
            : disabledMessage,
      );
    } catch (e) {
      debugPrint('Preference update error: $e');

      if (!mounted) return;

      AuthMessageHelper.showOffline(context);
    }
  }

  // ─────────────────────────────────────────────
  // Dashboard statistics
  // ─────────────────────────────────────────────

  Future<void> loadDashboardStats() async {
    try {
      final stats = await _settingsRepository.getDashboardStatistics(
        forceRefresh: true,
      );

      if (!mounted) return;

      setState(() {
        totalGoals = stats['totalGoals'] ?? 0;
        completedGoals = stats['completedGoals'] ?? 0;
        totalExpenses = stats['totalExpenses'] ?? 0;
        totalBudgets = stats['totalBudgets'] ?? 0;
      });
    } catch (e) {
      debugPrint('Stats Error: $e');
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final spacing = ResponsiveHelper.spacing(context);

    final contentMaxWidth = ResponsiveHelper.contentMaxWidth(context);

    final statColumns = ResponsiveHelper.gridColumns(
      context,
      mobilePortrait: 2,
      mobileLandscape: 4,
      tabletPortrait: 4,
      tabletLandscape: 4,
      desktop: 4,
    );

    final profileRadius = desktop
        ? 26.0
        : tablet
        ? 24.0
        : compact
        ? 18.0
        : 22.0;

    final profileAvatarSize = desktop
        ? 52.0
        : tablet
        ? 48.0
        : compact
        ? 38.0
        : 45.0;

    final profileIconSize = desktop
        ? 27.0
        : tablet
        ? 25.0
        : compact
        ? 20.0
        : 23.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: landscape ? 12 : 20,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─────────────────────────────────
                // Profile header
                // ─────────────────────────────────
                _buildProfileHeader(
                  context,
                  radius: profileRadius,
                  avatarSize: profileAvatarSize,
                  iconSize: profileIconSize,
                  compact: compact,
                  landscape: landscape,
                  desktop: desktop,
                ),

                SizedBox(height: sectionSpacing),

                // ─────────────────────────────────
                // Profile information
                // ─────────────────────────────────
                _buildSectionHeader(
                  context,
                  icon: Icons.person_outline_rounded,
                  title: 'Profile Information',
                  subtitle: 'Keep your personal details up to date.',
                ),

                SizedBox(height: spacing),

                _buildProfileFields(
                  context,
                  compact: compact,
                  tablet: tablet,
                  desktop: desktop,
                  spacing: spacing,
                ),

                SizedBox(height: sectionSpacing),

                // ─────────────────────────────────
                // Statistics
                // ─────────────────────────────────
                _buildSectionHeader(
                  context,
                  icon: Icons.insights_outlined,
                  title: 'Your Overview',
                  subtitle: 'A quick look at your PesaPulse activity.',
                ),

                SizedBox(height: spacing),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: statColumns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  childAspectRatio: _statAspectRatio(
                    context,
                    columns: statColumns,
                  ),
                  children: [
                    _buildProfileStat(
                      context,
                      value: totalGoals.toString(),
                      title: 'Goals',
                      icon: Icons.flag_rounded,
                      color: Colors.indigo,
                    ),
                    _buildProfileStat(
                      context,
                      value: completedGoals.toString(),
                      title: 'Completed',
                      icon: Icons.emoji_events_rounded,
                      color: Colors.green,
                    ),
                    _buildProfileStat(
                      context,
                      value: totalBudgets.toString(),
                      title: 'Budgets',
                      icon: Icons.account_balance_wallet_rounded,
                      color: Colors.orange,
                    ),
                    _buildProfileStat(
                      context,
                      value: totalExpenses.toString(),
                      title: 'Expenses',
                      icon: Icons.receipt_long_rounded,
                      color: Colors.teal,
                    ),
                  ],
                ),

                SizedBox(height: sectionSpacing),

                // ─────────────────────────────────
                // Update profile
                // ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: desktop
                      ? 56
                      : compact
                      ? 46
                      : 50,
                  child: CustomButton(
                    text: 'Update Profile',
                    icon: Icons.save_outlined,
                    isLoading: isLoading,
                    onPressed: updateProfile,
                  ),
                ),

                SizedBox(height: sectionSpacing),

                // ─────────────────────────────────
                // Appearance
                // ─────────────────────────────────
                _buildSectionHeader(
                  context,
                  icon: Icons.palette_outlined,
                  title: 'Appearance',
                  subtitle: 'Customize how PesaPulse looks.',
                ),

                SizedBox(height: spacing),

                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return _buildSettingTile(
                      context,
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Mode',
                      subtitle: themeProvider.isDarkMode
                          ? 'Dark theme is enabled'
                          : 'Use the light theme',
                      value: themeProvider.isDarkMode,
                      onChanged: themeProvider.toggleTheme,
                    );
                  },
                ),

                SizedBox(height: sectionSpacing),

                // ─────────────────────────────────
                // Notification settings
                // ─────────────────────────────────
                _buildSectionHeader(
                  context,
                  icon: Icons.notifications_none_rounded,
                  title: 'Notification Settings',
                  subtitle: 'Control reminders and financial alerts.',
                ),

                SizedBox(height: spacing),

                Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(compact ? 16 : 20),
                    side: BorderSide(
                      color: colorScheme.outline.withOpacity(.10),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildSettingTile(
                        context,
                        icon: Icons.notifications_active_outlined,
                        title: 'Daily Reminder',
                        subtitle:
                            'Get a daily reminder to review your expenses.',
                        value: dailyReminder,
                        onChanged: (value) async {
                          setState(() {
                            dailyReminder = value;
                          });

                          await _updateNotificationPreferences(
                            dailyReminderValue: value,
                            notificationTitle: 'Daily Reminder',
                            enabledMessage: 'Daily reminders enabled',
                            disabledMessage: 'Daily reminders disabled',
                          );
                        },
                      ),

                      _buildDivider(context),

                      _buildSettingTile(
                        context,
                        icon: Icons.warning_amber_rounded,
                        title: 'Expense Alerts',
                        subtitle:
                            'Receive alerts when your spending needs attention.',
                        value: expenseAlerts,
                        onChanged: (value) async {
                          setState(() {
                            expenseAlerts = value;
                          });

                          await _updateNotificationPreferences(
                            expenseAlertsValue: value,
                            notificationTitle: 'Expense Alerts',
                            enabledMessage: 'Expense alerts enabled',
                            disabledMessage: 'Expense alerts disabled',
                          );
                        },
                      ),

                      _buildDivider(context),

                      _buildSettingTile(
                        context,
                        icon: Icons.bar_chart_rounded,
                        title: 'Weekly Summary',
                        subtitle:
                            'Receive a summary of your weekly financial activity.',
                        value: weeklySummary,
                        onChanged: (value) async {
                          setState(() {
                            weeklySummary = value;
                          });

                          await _updateNotificationPreferences(
                            weeklySummaryValue: value,
                            notificationTitle: 'Weekly Summary',
                            enabledMessage: 'Weekly summaries enabled',
                            disabledMessage: 'Weekly summaries disabled',
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: sectionSpacing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Profile header
  // ─────────────────────────────────────────────

  Widget _buildProfileHeader(
    BuildContext context, {
    required double radius,
    required double avatarSize,
    required double iconSize,
    required bool compact,
    required bool landscape,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final verticalPadding = landscape
        ? 16.0
        : desktop
        ? 28.0
        : compact
        ? 18.0
        : 24.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? 30 : 20,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(.30)),
            ),
            child: Icon(
              Icons.person_rounded,
              size: iconSize,
              color: Colors.white,
            ),
          ),

          SizedBox(width: compact ? 12 : 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameController.text.trim().isEmpty
                      ? 'User'
                      : nameController.text.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: desktop
                        ? 24
                        : compact
                        ? 18
                        : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  emailController.text.trim().isEmpty
                      ? 'Welcome to PesaPulse'
                      : emailController.text.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.78),
                    fontSize: compact ? 11 : 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Profile fields
  // ─────────────────────────────────────────────

  Widget _buildProfileFields(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
    required double spacing,
  }) {
    final fields = [
      CustomTextField(controller: nameController, label: 'Name'),
      CustomTextField(controller: emailController, label: 'Email'),
    ];

    if (tablet || desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: fields[0]),
          SizedBox(width: spacing),
          Expanded(child: fields[1]),
        ],
      );
    }

    return Column(
      children: [
        fields[0],
        SizedBox(height: spacing),
        fields[1],
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Section header
  // ─────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: compact ? 38 : 42,
          height: compact ? 38 : 42,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: compact ? 19 : 21,
          ),
        ),

        SizedBox(width: compact ? 10 : 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 16 : 18,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(.60),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Statistics
  // ─────────────────────────────────────────────

  Widget _buildProfileStat(
    BuildContext context, {
    required String value,
    required String title,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        side: BorderSide(color: colorScheme.outline.withOpacity(.10)),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          desktop
              ? 20
              : compact
              ? 12
              : 16,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: compact ? 34 : 42,
              height: compact ? 34 : 42,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: compact ? 18 : 21, color: color),
            ),

            SizedBox(height: compact ? 7 : 10),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: desktop
                      ? 25
                      : compact
                      ? 18
                      : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 3),

            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                color: colorScheme.onSurface.withOpacity(.60),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Setting tile
  // ─────────────────────────────────────────────

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    return SwitchListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 2 : 4,
      ),
      dense: compact,
      secondary: Container(
        width: compact ? 38 : 42,
        height: compact ? 38 : 42,
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(.09),
          borderRadius: BorderRadius.circular(compact ? 11 : 13),
        ),
        child: Icon(icon, color: colorScheme.primary, size: compact ? 19 : 21),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: compact ? 13 : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodySmall?.color?.withOpacity(.60),
          height: 1.3,
          fontSize: compact ? 11 : null,
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outline.withOpacity(.08),
    );
  }

  // ─────────────────────────────────────────────
  // Responsive statistics aspect ratio
  // ─────────────────────────────────────────────

  double _statAspectRatio(BuildContext context, {required int columns}) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    if (desktop) {
      return 1.9;
    }

    if (tablet) {
      return landscape ? 1.8 : 1.45;
    }

    if (landscape) {
      return 2.0;
    }

    if (compact) {
      return columns == 2 ? 1.35 : 1.5;
    }

    return 1.45;
  }
}
