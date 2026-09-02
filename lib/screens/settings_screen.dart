import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/screens/auth_choice_screen.dart';
import 'package:pesapulse_mobile/screens/register_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_constants.dart';
import '../controllers/settings_preferences_controller.dart';
import '../controllers/settings_support_controller.dart';
import '../controllers/settings_session_controller.dart';
import '../controllers/settings_controller.dart';
import '../providers/connectivity_provider.dart';

import '../screens/login_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/delete_account_screen.dart';

import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../widgets/settings/settings_account_card.dart';
import '../widgets/settings/settings_statitistics_section.dart';
import '../widgets/settings/settings_appearance_section.dart';
import '../widgets/settings/settings_security_section.dart';
import '../widgets/settings/settings_notifications_section.dart';
import '../widgets/settings/settings_sync_sections.dart';
import '../widgets/settings/settings_about_section.dart';
import '../widgets/settings/settings_support_section.dart';
import '../widgets/settings/settings_session_section.dart';
import '../widgets/settings/settings_footer.dart';
import '../widgets/settings/settings_section_header.dart';
import '../widgets/settings/settings_loading_skeleton.dart';
import '../widgets/settings/dialogs/about_pesapulse_dialog.dart';
import '../widgets/settings/dialogs/privacy_policy_dialog.dart';
import '../widgets/settings/dialogs/terms_of_service_dialog.dart';
import '../widgets/settings/dialogs/logout_confirmation_dialog.dart';
import '../widgets/app/app_error_helper.dart';

import '../repositories/settings_repository.dart';
import '../models/settings_state.dart';
import '../utils/responsive_helper.dart';
import '../utils/settings_error_message.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController settingsController;

  final SettingsRepository settingsRepository = SettingsRepository();

  final SettingsSupportController supportController =
      SettingsSupportController();

  SettingsState get _settingsState => settingsController.state;

  @override
  void initState() {
    super.initState();

    settingsController = SettingsController(
      settingsRepository: settingsRepository,
      settingsPreferencesController: SettingsPreferencesController(
        settingsRepository: settingsRepository,
      ),
      settingsSessionController: SettingsSessionController(
        settingsRepository: settingsRepository,
      ),
    );

    settingsController.onStateChanged = _handleSettingsStateChanged;

    settingsController.initialize();
  }

  void _handleSettingsStateChanged() {
    if (!mounted) return;

    setState(() {});
  }

  Future<void> _updateNotificationPreferences({
    required String title,
    required bool value,
  }) async {
    final connectivity = context.read<ConnectivityProvider>();

    try {
      await settingsController.updateNotificationPreference(
        title: title,
        value: value,
        isOnline: connectivity.isOnline,
      );
    } catch (e) {
      if (!mounted) return;

      AppErrorHelper.show(context, message: SettingsErrorMessage.getMessage(e));

      debugPrint('Failed to update notification preference "$title": $e');
    }
  }

  Future<void> _refreshSettings() async {
    try {
      await settingsController.refresh();
    } catch (e) {
      if (!mounted) return;

      AppErrorHelper.show(context, message: SettingsErrorMessage.getMessage(e));
    }
  }

  String formatLastSync(DateTime? date) {
    if (date == null) return "Never";

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final syncDay = DateTime(date.year, date.month, date.day);

    if (syncDay == today) {
      return "Today • ${DateFormat("hh:mm a").format(date)}";
    }

    if (syncDay == yesterday) {
      return "Yesterday • ${DateFormat("hh:mm a").format(date)}";
    }

    return DateFormat("dd MMM • hh:mm a").format(date);
  }

  @override
  void dispose() {
    settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final spacing = ResponsiveHelper.spacing(context);

    final horizontalPadding = compact
        ? 14.0
        : landscape
        ? 24.0
        : 20.0;

    final sectionSpacing = compact ? 24.0 : 30.0;
    return AppScaffold(
      showOfflineBanner: false,
      appBar: const AdaptiveAppBar(title: null),
      body: RefreshIndicator(
        onRefresh: _refreshSettings,
        child: SingleChildScrollView(
          key: const PageStorageKey('settings'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: spacing,
          ),
          child: _settingsState.isLoading
              ? const SettingsLoadingSkeleton()
              : _settingsState.loadingError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _settingsState.loadingError!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await settingsController.retryInitialization();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      children: [
                        SettingsSectionHeader(
                          title: 'Account',
                          icon: Icons.person,
                        ),

                        SettingsAccountCard(
                          isGuest: _settingsState.isGuest,
                          userName: _settingsState.userName,
                          userEmail: _settingsState.userEmail,

                          onEditProfile: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );

                            if (updated == true) {
                              await settingsController.loadProfile();
                            }
                          },

                          onCreateAccount: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },

                          onSignIn: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: sectionSpacing),

                        SettingsStatisticsSection(
                          totalGoals: _settingsState.totalGoals,
                          completedGoals: _settingsState.completedGoals,
                          totalBudgets: _settingsState.totalBudgets,
                          totalExpenses: _settingsState.totalExpenses,
                        ),

                        SizedBox(height: sectionSpacing),

                        SettingsSectionHeader(
                          title: 'Appearance',
                          icon: Icons.palette,
                        ),

                        SettingsAppearanceSection(),

                        SizedBox(height: sectionSpacing),

                        SettingsSectionHeader(
                          title: 'Security',
                          icon: Icons.lock,
                        ),

                        SettingsSecuritySection(
                          isGuest: _settingsState.isGuest,
                          onChangePassword: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ChangePasswordScreen(),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: sectionSpacing),

                        SettingsSectionHeader(
                          title: 'Notifications',
                          icon: Icons.notifications,
                        ),

                        const SizedBox(height: 10),

                        SettingsNotificationsSection(
                          dailyReminder: _settingsState.dailyReminder,
                          expenseAlerts: _settingsState.expenseAlerts,
                          weeklySummary: _settingsState.weeklySummary,

                          onDailyReminderChanged: (value) {
                            _updateNotificationPreferences(
                              title: 'Daily Reminder',
                              value: value,
                            );
                          },

                          onExpenseAlertsChanged: (value) {
                            _updateNotificationPreferences(
                              title: 'Expense Alerts',
                              value: value,
                            );
                          },

                          onWeeklySummaryChanged: (value) {
                            _updateNotificationPreferences(
                              title: 'Weekly Summary',
                              value: value,
                            );
                          },
                        ),

                        SizedBox(height: sectionSpacing),
                        SettingsSectionHeader(
                          title: 'Sync & Offline',
                          icon: Icons.sync,
                        ),

                        SettingsSyncSection(
                          isGuest: _settingsState.isGuest,
                          lastSyncTime: _settingsState.lastSyncTime,
                          formatLastSync: formatLastSync,
                        ),

                        SizedBox(height: sectionSpacing),

                        SettingsSectionHeader(title: 'About', icon: Icons.info),

                        SettingsAboutSection(
                          onAbout: () {
                            showDialog(
                              context: context,
                              builder: (_) => const AboutPesaPulseDialog(),
                            );
                          },
                          onPrivacyPolicy: () {
                            showDialog(
                              context: context,
                              builder: (_) => const PrivacyPolicyDialog(),
                            );
                          },
                          onTermsOfService: () {
                            showDialog(
                              context: context,
                              builder: (_) => const TermsOfServiceDialog(),
                            );
                          },
                          version: AppConstants.appVersionLabel,
                        ),

                        SizedBox(height: sectionSpacing),

                        SettingsSectionHeader(
                          title: 'Support',
                          icon: Icons.support_agent,
                        ),

                        SettingsSupportSection(
                          onContactSupport: () {
                            supportController.contactSupport(context);
                          },
                          onRateApp: () {
                            supportController.showRateAppDialog(context);
                          },
                          onShareApp: () {
                            supportController.shareApp();
                          },
                        ),
                        SizedBox(height: sectionSpacing),

                        SettingsSectionHeader(
                          title: 'Session',
                          icon: Icons.logout,
                        ),

                        SettingsSessionSection(
                          isGuest: _settingsState.isGuest,

                          onSignOut: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (_) => const LogoutConfirmationDialog(),
                            );

                            if (confirm != true) return;

                            try {
                              await settingsController.logout();
                            } catch (e) {
                              debugPrint('Logout error: $e');
                            }

                            if (!mounted) return;

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AuthChoiceScreen(),
                              ),
                              (route) => false,
                            );
                          },

                          onDeleteAccount: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DeleteAccountScreen(),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: spacing),

                        SettingsFooter(
                          appName: AppConstants.appName,
                          tagline: 'Personal Finance Manager',
                          version: AppConstants.appVersion,
                          year: AppConstants.appYear,
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
