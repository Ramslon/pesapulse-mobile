import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/screens/register_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';
import '../services/session_service.dart';

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

import '../repositories/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String userName = '';
  String userEmail = '';

  bool isLoading = false;

  bool dailyReminder = true;

  bool expenseAlerts = true;

  bool weeklySummary = false;

  int totalGoals = 0;
  int completedGoals = 0;
  int totalExpenses = 0;
  int totalBudgets = 0;

  DateTime? lastSyncTime;
  final DateFormat dateFormatter = DateFormat("dd MMM • hh:mm a");

  final SettingsRepository settingsRepository = SettingsRepository();

  bool isGuest = false;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    loadSessionState();

    loadSettings();
    loadProfile();
    loadDashboardStats();
    loadLastSyncTime();
  }

  Future<void> loadProfile() async {
    if (await SessionService.isGuest()) {
      if (!mounted) return;

      setState(() {
        userName = "Guest Account";
        userEmail = "Login to sync your data";
        isGuest = true;
        isLoading = false;
      });

      return;
    }

    try {
      final user = await settingsRepository.getProfile();

      if (!mounted) return;

      setState(() {
        userName = user["name"] ?? "";
        userEmail = user["email"] ?? "";
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      AuthMessageHelper.showOffline(context);
    }
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await settingsRepository.getPreferences();

      if (!mounted) return;

      setState(() {
        dailyReminder = prefs.dailyReminder;
        expenseAlerts = prefs.expenseAlerts;
        weeklySummary = prefs.weeklySummary;
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> loadDashboardStats() async {
    final stats = await settingsRepository.getDashboardStatistics();

    if (!mounted) return;

    setState(() {
      totalGoals = stats["totalGoals"]!;
      completedGoals = stats["completedGoals"]!;
      totalExpenses = stats["totalExpenses"]!;
      totalBudgets = stats["totalBudgets"]!;
    });
  }

  Future<void> loadLastSyncTime() async {
    lastSyncTime = await settingsRepository.getLastSync();

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> loadSessionState() async {
    isGuest = await SessionService.isGuest();
    isLoggedIn = await SessionService.isLoggedIn();

    if (mounted) {
      setState(() {});
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

  void showAboutPesaPulse() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("About PesaPulse"),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "PesaPulse is a personal finance management application designed to help users take control of their finances.",
              ),

              SizedBox(height: 15),

              Text("Features"),

              SizedBox(height: 8),

              Text("• Expense Tracking"),
              Text("• Budget Management"),
              Text("• Savings Goals"),
              Text("• Financial Analytics"),
              Text("• Smart Insights"),
              Text("• Secure Account Management"),

              SizedBox(height: 20),

              Text(
                "Version 2.1.0",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 10),

              Text("© 2026 PesaPulse"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> contactSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@pesapulse.app',
      queryParameters: {'subject': 'PesaPulse Support'},
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open email application')),
      );
    }
  }

  void shareApp() {
    Share.share('''
I'm using PesaPulse to manage my expenses, budgets and savings goals.

Download it here:

https://github.com/ramslon/PesaPulse
''');
  }

  void rateApp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rate PesaPulse"),
        content: const Text(
          "Thank you for using PesaPulse!\n\n"
          "The app will be available on Google Play soon, where you'll be able to leave a rating and review.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Privacy Policy"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your privacy matters to us.",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 15),

              Text(
                "PesaPulse securely stores your financial information to provide budgeting, expense tracking and savings features.",
              ),

              SizedBox(height: 15),

              Text("We do not:"),
              SizedBox(height: 8),

              Text("• Sell your personal data"),
              Text("• Share your financial records with third parties"),
              Text("• Access your passwords"),

              SizedBox(height: 15),

              Text("We may collect:"),

              SizedBox(height: 8),

              Text("• Your profile information"),
              Text("• Budget and expense data"),
              Text("• Goal progress"),
              Text("• App preferences"),

              SizedBox(height: 20),

              Text(
                "Last Updated: July 2026",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void showTermsOfService() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Terms of Service"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "By using PesaPulse you agree to:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 15),

              Text("• Use the application responsibly."),
              Text("• Keep your login credentials secure."),
              Text("• Maintain accurate financial records."),
              Text("• Comply with applicable laws."),

              SizedBox(height: 20),

              Text(
                "PesaPulse is intended as a financial management tool and should not be considered financial or investment advice.",
              ),

              SizedBox(height: 20),

              Text(
                "Version 2.1.0",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget _buildSectionTitle(String title, IconData icon) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return AppScaffold(
      showOfflineBanner: false,
      appBar: const AdaptiveAppBar(title: null),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadDashboardStats();
        },
        child: SingleChildScrollView(
          key: const PageStorageKey("settings"),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildSectionTitle('Account', Icons.person),

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
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },

                onSignIn: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
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

              _buildSectionTitle('Appearance', Icons.palette),

              SettingsAppearanceSection(),

              const SizedBox(height: 30),

              _buildSectionTitle('Security', Icons.lock),

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

              Align(
                alignment: Alignment.centerLeft,

                child: _buildSectionTitle('Notifications', Icons.notifications),
              ),

              const SizedBox(height: 10),

              SettingsNotificationsSection(
                dailyReminder: dailyReminder,
                expenseAlerts: expenseAlerts,
                weeklySummary: weeklySummary,

                onDailyReminderChanged: (value) {
                  setState(() {
                    dailyReminder = value;
                  });
                },

                onExpenseAlertsChanged: (value) {
                  setState(() {
                    expenseAlerts = value;
                  });
                },

                onWeeklySummaryChanged: (value) {
                  setState(() {
                    weeklySummary = value;
                  });
                },
              ),

              const SizedBox(height: 30),
              _buildSectionTitle("Sync & Offline", Icons.sync),

              SettingsSyncSection(
                isGuest: isGuest,
                lastSyncTime: lastSyncTime,
                formatLastSync: formatLastSync,
              ),

              const SizedBox(height: 30),

              _buildSectionTitle("About", Icons.info),

              SettingsAboutSection(
                onAbout: showAboutPesaPulse,
                onPrivacyPolicy: showPrivacyPolicy,
                onTermsOfService: showTermsOfService,
                version: 'v1.0.0',
              ),

              const SizedBox(height: 30),

              _buildSectionTitle('Support', Icons.support_agent),

              SettingsSupportSection(
                onContactSupport: contactSupport,
                onRateApp: rateApp,
                onShareApp: shareApp,
              ),

              const SizedBox(height: 30),

              _buildSectionTitle('Session', Icons.logout),

              SettingsSessionSection(
                isGuest: isGuest,

                onSignOut: () async {
                  final confirm = await showLogoutDialog();

                  if (confirm != true) return;

                  await SessionService.logout();

                  settingsRepository.clearCache();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );

                  ApiService.logoutUser().catchError((_) {});
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
                appName: 'PesaPulse',
                tagline: 'Personal Finance Manager',
                version: '1.0.0',
                year: 2026,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> showLogoutDialog() {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.red.shade100,
                child: const Icon(Icons.logout_rounded, color: Colors.red),
              ),

              const SizedBox(width: 12),

              const Text("Sign Out"),
            ],
          ),

          content: const Text(
            "Are you sure you want to sign out?\n\n"
            "You'll need to log in again to access your financial data.",
          ),

          actions: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context, false),

              icon: const Icon(Icons.close),

              label: const Text("Cancel"),
            ),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),

              onPressed: () => Navigator.pop(context, true),

              icon: const Icon(Icons.logout),

              label: const Text("Sign Out"),
            ),
          ],
        );
      },
    );
  }
}
