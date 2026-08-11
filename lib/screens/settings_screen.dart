import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/screens/register_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/session_service.dart';

import '../core/constants/app_constants.dart';
import '../controllers/settings_preferences_controller.dart';
import '../controllers/settings_support_controller.dart';
import '../controllers/settings_session_controller.dart';
import '../providers/connectivity_provider.dart';

import '../screens/login_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/delete_account_screen.dart';

import '../widgets/auth_message_helper.dart';
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
import '../widgets/settings/dialogs/about_pesapulse_dialog.dart';
import '../widgets/settings/dialogs/privacy_policy_dialog.dart';
import '../widgets/settings/dialogs/terms_of_service_dialog.dart';
import '../widgets/settings/dialogs/logout_confirmation_dialog.dart';

import '../repositories/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = '';
  String userEmail = '';

  bool dailyReminder = true;

  bool expenseAlerts = true;

  bool weeklySummary = false;

  int totalGoals = 0;
  int completedGoals = 0;
  int totalExpenses = 0;
  int totalBudgets = 0;

  DateTime? lastSyncTime;

  final SettingsRepository settingsRepository = SettingsRepository();
  late final SettingsSessionController settingsSessionController;
  final SettingsSupportController supportController =
      SettingsSupportController();
  late final SettingsPreferencesController settingsPreferencesController;

  bool isGuest = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    settingsPreferencesController = SettingsPreferencesController(
      settingsRepository: settingsRepository,
    );

    settingsSessionController = SettingsSessionController(
      settingsRepository: settingsRepository,
    );

    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    await loadSessionState();

    if (!mounted) return;

    await Future.wait([
      loadSettings(),
      loadProfile(),
      loadDashboardStats(),
      loadLastSyncTime(),
    ]);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadProfile() async {
    if (isGuest) {
      userName = 'Guest Account';
      userEmail = 'Login to sync your data';
      return;
    }

    try {
      final user = await settingsRepository.getProfile();

      userName = user['name'] ?? '';
      userEmail = user['email'] ?? '';
    } catch (e) {
      if (!mounted) return;

      AuthMessageHelper.showOffline(context);

      debugPrint('Failed to load profile: $e');
    }
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await settingsRepository.getPreferences();

      dailyReminder = prefs.dailyReminder;
      expenseAlerts = prefs.expenseAlerts;
      weeklySummary = prefs.weeklySummary;
    } catch (e) {
      debugPrint('Failed to load settings preferences: $e');
    }
  }

  Future<void> loadDashboardStats() async {
    final stats = await settingsRepository.getDashboardStatistics();

    totalGoals = stats["totalGoals"] ?? 0;
    completedGoals = stats["completedGoals"] ?? 0;
    totalExpenses = stats["totalExpenses"] ?? 0;
    totalBudgets = stats["totalBudgets"] ?? 0;
  }

  Future<void> loadLastSyncTime() async {
    lastSyncTime = await settingsRepository.getLastSync();
  }

  Future<void> loadSessionState() async {
    isGuest = await SessionService.isGuest();
  }

  Future<void> _updateNotificationPreferences({
    required String title,
    required bool value,
  }) async {
    final previousDailyReminder = dailyReminder;
    final previousExpenseAlerts = expenseAlerts;
    final previousWeeklySummary = weeklySummary;

    setState(() {
      switch (title) {
        case 'Daily Reminder':
          dailyReminder = value;
          break;

        case 'Expense Alerts':
          expenseAlerts = value;
          break;

        case 'Weekly Summary':
          weeklySummary = value;
          break;
      }
    });

    final connectivity = context.read<ConnectivityProvider>();

    try {
      await settingsPreferencesController.updateNotificationPreference(
        title: title,
        value: value,
        isOnline: connectivity.isOnline,
        dailyReminder: dailyReminder,
        expenseAlerts: expenseAlerts,
        weeklySummary: weeklySummary,
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        dailyReminder = previousDailyReminder;
        expenseAlerts = previousExpenseAlerts;
        weeklySummary = previousWeeklySummary;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update $title. Please try again.')),
      );

      debugPrint('Failed to update notification preference "$title": $e');
    }
  }

  Future<void> _refreshSettings() async {
    await Future.wait([
      loadSettings(),
      loadProfile(),
      loadDashboardStats(),
      loadLastSyncTime(),
    ]);

    if (!mounted) return;

    setState(() {});
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
  Widget build(BuildContext context) {
    return AppScaffold(
      showOfflineBanner: false,
      appBar: const AdaptiveAppBar(title: null),
      body: RefreshIndicator(
        onRefresh: _refreshSettings,
        child: SingleChildScrollView(
          key: const PageStorageKey('settings'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: CircularProgressIndicator(),
                  ),
                )
              : Column(
                  children: [
                    SettingsSectionHeader(title: 'Account', icon: Icons.person),

                    SettingsAccountCard(
                      isGuest: isGuest,
                      userName: userName,
                      userEmail: userEmail,

                      onEditProfile: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );

                        if (updated == true) {
                          loadProfile();
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

                    const SizedBox(height: 30),

                    SettingsStatisticsSection(
                      totalGoals: totalGoals,
                      completedGoals: completedGoals,
                      totalBudgets: totalBudgets,
                      totalExpenses: totalExpenses,
                    ),

                    const SizedBox(height: 30),

                    SettingsSectionHeader(
                      title: 'Appearance',
                      icon: Icons.palette,
                    ),

                    SettingsAppearanceSection(),

                    const SizedBox(height: 30),

                    SettingsSectionHeader(title: 'Security', icon: Icons.lock),

                    SettingsSecuritySection(
                      isGuest: isGuest,
                      onChangePassword: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePasswordScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 20),

                    SettingsSectionHeader(
                      title: 'Notifications',
                      icon: Icons.notifications,
                    ),

                    const SizedBox(height: 10),

                    SettingsNotificationsSection(
                      dailyReminder: dailyReminder,
                      expenseAlerts: expenseAlerts,
                      weeklySummary: weeklySummary,

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

                    const SizedBox(height: 30),
                    SettingsSectionHeader(
                      title: 'Sync & Offline',
                      icon: Icons.sync,
                    ),

                    SettingsSyncSection(
                      isGuest: isGuest,
                      lastSyncTime: lastSyncTime,
                      formatLastSync: formatLastSync,
                    ),

                    const SizedBox(height: 30),

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

                    const SizedBox(height: 30),

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
                    const SizedBox(height: 30),

                    SettingsSectionHeader(title: 'Session', icon: Icons.logout),

                    SettingsSessionSection(
                      isGuest: isGuest,

                      onSignOut: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => const LogoutConfirmationDialog(),
                        );

                        if (confirm != true) return;

                        await settingsSessionController.logout();

                        if (!mounted) return;

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
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

                    const SizedBox(height: 25),

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
    );
  }
}
