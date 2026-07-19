import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../services/api_services.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/login_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/change_password_screen.dart';
import '../providers/connectivity_provider.dart';
import '../services/sync_service.dart';

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

  @override
  void initState() {
    super.initState();

    loadSettings();
    loadProfile();
    loadDashboardStats();
    loadLastSyncTime();
  }

  Future<void> loadProfile() async {
    try {
      final user = await ApiService.getProfile();

      setState(() {
        userName = user['name'] ?? '';
        userEmail = user['email'] ?? '';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await ApiService.getUserPreferences();

      if (!mounted) return;

      setState(() {
        dailyReminder = prefs.dailyReminder;
        expenseAlerts = prefs.expenseAlerts;
        weeklySummary = prefs.weeklySummary;
      });
    } catch (e) {
      // fallback to local storage

      dailyReminder = await SettingsService.getDailyReminder();
      expenseAlerts = await SettingsService.getExpenseAlerts();
      weeklySummary = await SettingsService.getWeeklySummary();

      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> loadDashboardStats() async {
    try {
      final goalsAnalytics = await ApiService.getGoalAnalytics();

      final expenses = await ApiService.getExpenses();

      final budgetSummary = await ApiService.getBudgetSummary();

      setState(() {
        totalGoals = goalsAnalytics['total_goals'] ?? 0;

        completedGoals = goalsAnalytics['completed_goals'] ?? 0;

        totalExpenses = (expenses['data'] as List).length;

        totalBudgets = budgetSummary['budget'] != null ? 1 : 0;
      });
    } catch (e) {
      debugPrint('Stats Error: $e');
    }
  }

  Future<void> loadLastSyncTime() async {
    lastSyncTime = await SettingsService.getLastSync();

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

    return RefreshIndicator(
      onRefresh: () async {
        await loadDashboardStats();
      },

      child: SingleChildScrollView(
        key: const PageStorageKey("settings"),
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              _buildSectionTitle('Account', Icons.person),

              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green.shade100,
                        child: const Icon(
                          Icons.account_circle,
                          size: 60,
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(height: 15),

                      Text(
                        "Welcome back!",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      Text(
                        userName.isEmpty ? 'User' : userName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        userEmail,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Divider(),

                      const SizedBox(height: 18),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.green.shade100,
                          child: const Icon(Icons.edit, color: Colors.green),
                        ),
                        title: const Text("Edit Profile"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () async {
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
                      ),
                    ],
                  ),
                ),
              ),

              _buildSectionTitle('Statistics', Icons.bar_chart),

              Row(
                children: [
                  Expanded(
                    child: _buildProfileStat(
                      '$totalGoals',
                      'Goals Created',
                      Icons.flag,
                      Colors.green,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildProfileStat(
                      '$completedGoals',
                      'Completed Goals',
                      Icons.emoji_events,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildProfileStat(
                      '$totalBudgets',
                      'Budgets Created',
                      Icons.account_balance_wallet,
                      Colors.blue,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildProfileStat(
                      '$totalExpenses',
                      'Expenses Recorded',
                      Icons.receipt_long,
                      Colors.red,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              _buildSectionTitle('Appearance', Icons.palette),
              Card(
                child: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return SwitchListTile(
                      secondary: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.indigo.shade100,
                        child: const Icon(
                          Icons.dark_mode_outlined,
                          color: Colors.indigo,
                        ),
                      ),

                      title: const Text(
                        "Dark Mode",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: const Text(
                        "Switch between light and dark appearance.",
                      ),

                      value: themeProvider.isDarkMode,

                      activeColor: Colors.green,

                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),
              _buildSectionTitle('Security', Icons.lock),

              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(Icons.lock_outline, color: Colors.orange),
                  ),

                  title: const Text(
                    "Change Password",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  subtitle: const Text(
                    "Update your account password securely.",
                  ),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ChangePasswordScreen(),
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: const Icon(Icons.verified_user, color: Colors.green),
                ),

                title: const Text(
                  "Security Status",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),

                subtitle: Text("Your account is protected."),
              ),
              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,

                child: _buildSectionTitle('Notifications', Icons.notifications),
              ),

              const SizedBox(height: 10),

              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.green.shade100,
                        child: const Icon(Icons.alarm, color: Colors.green),
                      ),

                      title: const Text(
                        "Daily Reminder",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: const Text("Receive a reminder every day."),

                      value: dailyReminder,

                      activeColor: Colors.green,

                      onChanged: (value) async {
                        setState(() {
                          dailyReminder = value;
                        });

                        await SettingsService.setDailyReminder(value);

                        await ApiService.updatePreferences({
                          'daily_reminder': value,
                          'expense_alerts': expenseAlerts,
                          'weekly_summary': weeklySummary,
                        });

                        NotificationService.showNotification(
                          title: 'Daily Reminder',

                          body: value
                              ? 'Daily reminders enabled'
                              : 'Daily reminders disabled',
                        );
                      },
                    ),

                    const Divider(height: 1),

                    SwitchListTile(
                      secondary: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.orange.shade100,
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.orange,
                        ),
                      ),

                      title: const Text(
                        "Expense Alerts",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: const Text(
                        "Notify me when spending exceeds my budget.",
                      ),

                      value: expenseAlerts,

                      activeColor: Colors.green,

                      onChanged: (value) async {
                        setState(() {
                          expenseAlerts = value;
                        });
                        await SettingsService.setExpenseAlerts(value);

                        await ApiService.updatePreferences({
                          'daily_reminder': dailyReminder,
                          'expense_alerts': value,
                          'weekly_summary': weeklySummary,
                        });

                        NotificationService.showNotification(
                          title: 'Expense Alerts',

                          body: value
                              ? 'Expense alerts enabled'
                              : 'Expense alerts disabled',
                        );
                      },
                    ),

                    const Divider(height: 1),

                    SwitchListTile(
                      secondary: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(
                          Icons.summarize_outlined,
                          color: Colors.blue,
                        ),
                      ),
                      title: const Text(
                        "Weekly Summary",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: const Text("Receive weekly financial reports."),

                      value: weeklySummary,

                      activeColor: Colors.green,

                      onChanged: (value) async {
                        setState(() {
                          weeklySummary = value;
                        });
                        await SettingsService.setWeeklySummary(value);

                        await ApiService.updatePreferences({
                          'daily_reminder': dailyReminder,
                          'expense_alerts': expenseAlerts,
                          'weekly_summary': value,
                        });

                        NotificationService.showNotification(
                          title: 'Weekly Summary',

                          body: value
                              ? 'Weekly summaries enabled'
                              : 'Weekly summaries disabled',
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              _buildSectionTitle("Sync & Offline", Icons.sync),

              Consumer<ConnectivityProvider>(
                builder: (context, network, child) {
                  return Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: network.isOnline
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                            child: Icon(
                              network.isOnline
                                  ? Icons.cloud_done
                                  : Icons.cloud_off,
                              color: network.isOnline
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),

                          title: Text(
                            network.isOnline ? "Online" : "Offline",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),

                          subtitle: Text(
                            network.isOnline
                                ? "Your data is syncing normally."
                                : "Changes will sync automatically when you're online.",
                          ),
                        ),

                        const Divider(height: 1),

                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: const Icon(Icons.sync, color: Colors.blue),
                          ),

                          title: const Text(
                            "Pending Changes",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),

                          subtitle: Text(
                            "${network.pendingChanges} item(s) waiting to sync",
                          ),
                        ),

                        const Divider(height: 1),

                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade100,
                            child: const Icon(
                              Icons.schedule,
                              color: Colors.purple,
                            ),
                          ),

                          title: const Text(
                            "Last Sync",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),

                          subtitle: Text(formatLastSync(lastSyncTime)),
                        ),

                        const Divider(height: 1),

                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: network.isSyncing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.sync),
                              label: Text(
                                network.isSyncing ? "Syncing..." : "Sync Now",
                              ),
                              onPressed: network.isOnline
                                  ? () async {
                                      network.setSyncing(true);

                                      try {
                                        await SyncService.instance
                                            .syncPendingOperations();

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Sync completed successfully",
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text("Sync failed: $e"),
                                          ),
                                        );
                                      } finally {
                                        network.setSyncing(false);
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),

              _buildSectionTitle("About", Icons.info),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                        ),
                      ),

                      title: const Text(
                        "About PesaPulse",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: const Text(
                        "Version, credits and application information.",
                      ),

                      trailing: const Icon(Icons.chevron_right),

                      onTap: showAboutPesaPulse,
                    ),

                    const Divider(height: 1),

                    ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.purple.shade100,
                        child: const Icon(
                          Icons.privacy_tip_outlined,
                          color: Colors.purple,
                        ),
                      ),

                      title: const Text(
                        "Privacy Policy",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: const Text("Learn how your data is protected."),

                      trailing: const Icon(Icons.chevron_right),

                      onTap: showPrivacyPolicy,
                    ),

                    const Divider(height: 1),

                    ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.teal.shade100,
                        child: const Icon(
                          Icons.description_outlined,
                          color: Colors.teal,
                        ),
                      ),

                      title: const Text(
                        "Terms of Service",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: const Text(
                        "Review the terms of using PesaPulse.",
                      ),

                      trailing: const Icon(Icons.chevron_right),

                      onTap: showTermsOfService,
                    ),

                    const Divider(height: 1),

                    const ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(
                          Icons.verified_outlined,
                          color: Colors.green,
                        ),
                      ),

                      title: Text(
                        "Application Version",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: Text("Current installed version"),

                      trailing: Text(
                        "v2.1.0",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              _buildSectionTitle('Support', Icons.support_agent),

              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(
                          Icons.support_agent,
                          color: Colors.blue,
                        ),
                      ),

                      title: const Text(
                        "Contact Support",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: const Text(
                        "Need help? Reach out to our support team.",
                      ),

                      trailing: const Icon(Icons.chevron_right),

                      onTap: contactSupport,
                    ),

                    const Divider(height: 1),

                    ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.amber.shade100,
                        child: const Icon(
                          Icons.star_rate_rounded,
                          color: Colors.amber,
                        ),
                      ),

                      title: const Text(
                        "Rate PesaPulse",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: const Text("Share your experience with us."),

                      trailing: const Icon(Icons.chevron_right),

                      onTap: rateApp,
                    ),

                    const Divider(height: 1),

                    ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.green.shade100,
                        child: const Icon(
                          Icons.share_rounded,
                          color: Colors.green,
                        ),
                      ),

                      title: const Text(
                        "Share App",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),

                      subtitle: const Text(
                        "Invite your friends to use PesaPulse.",
                      ),

                      trailing: const Icon(Icons.chevron_right),

                      onTap: shareApp,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              _buildSectionTitle('Session', Icons.logout),

              Card(
                elevation: 2,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.red.shade100,
                            child: const Icon(
                              Icons.logout_rounded,
                              color: Colors.red,
                            ),
                          ),

                          const SizedBox(width: 14),

                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Sign Out",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),

                                SizedBox(height: 4),

                                Text(
                                  "Securely sign out from your account.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),

                          icon: const Icon(Icons.logout_rounded),

                          label: const Text(
                            "Sign Out",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          onPressed: () async {
                            final confirm = await showLogoutDialog();

                            if (confirm != true) return;

                            await ApiService.logoutUser();

                            if (!mounted) return;

                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),
              Column(
                children: [
                  const SizedBox(height: 30),

                  Divider(color: Colors.grey.shade300),

                  const SizedBox(height: 25),

                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.green.shade100,
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.green,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    "PesaPulse",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Personal Finance Manager",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Version 2.1.0",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Designed & Developed\nwith ❤️ in Kenya",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "© 2026 PesaPulse\nAll rights reserved.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStat(
    String value,
    String title,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: iconColor.withOpacity(0.12),
              child: Icon(icon, color: iconColor, size: 24),
            ),

            const SizedBox(height: 14),

            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),

            Text(title, textAlign: TextAlign.center),
          ],
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
