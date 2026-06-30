import 'package:flutter/material.dart';

import '../services/api_services.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../screens/login_screen.dart';
import '../screens/edit_profile_screen.dart';
import '../screens/change_password_screen.dart';

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

  @override
  void initState() {
    super.initState();

    loadSettings();
    loadProfile();
    loadDashboardStats();
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

    return SingleChildScrollView(
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
                      radius: 45,
                      backgroundColor: Colors.green.shade100,
                      child: Icon(
                        Icons.person,
                        size: 45,
                        color: Colors.green.shade700,
                      ),
                    ),

                    const SizedBox(height: 15),

                    Text(
                      userName.isEmpty ? 'User' : userName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(userEmail, style: const TextStyle(color: Colors.grey)),

                    const Divider(height: 35),

                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit),
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
                  child: _buildProfileStat('$totalGoals', 'Goals', Icons.flag),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildProfileStat(
                    '$completedGoals',
                    'Completed',
                    Icons.emoji_events,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildProfileStat(
                    '$totalBudgets',
                    'Budgets',
                    Icons.account_balance_wallet,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _buildProfileStat(
                    '$totalExpenses',
                    'Expenses',
                    Icons.receipt_long,
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
                    title: const Text('Dark Mode'),
                    secondary: const Icon(Icons.dark_mode),
                    value: themeProvider.isDarkMode,

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
                leading: const Icon(Icons.key),
                title: const Text("Change Password"),
                trailing: const Icon(Icons.arrow_forward_ios),
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
                    title: const Text('Daily Reminder'),

                    secondary: const Icon(Icons.notifications_active),

                    value: dailyReminder,

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

                  SwitchListTile(
                    title: const Text('Expense Alerts'),

                    secondary: const Icon(Icons.warning),

                    value: expenseAlerts,

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

                  SwitchListTile(
                    title: const Text('Weekly Summary'),

                    secondary: const Icon(Icons.bar_chart),

                    value: weeklySummary,

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

            _buildSectionTitle("About", Icons.info),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text("About PesaPulse"),
                    subtitle: const Text(
                      "Version, credits and application information",
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: showAboutPesaPulse,
                  ),

                  const Divider(height: 1),

                  const ListTile(
                    leading: Icon(Icons.verified_outlined),
                    title: Text("Version"),
                    trailing: Text(
                      "v2.1.0",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            _buildSectionTitle('Session', Icons.logout),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),

                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  await ApiService.logoutUser();

                  if (!mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ),
            const Divider(height: 40),
            const SizedBox(height: 35),

            Center(
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  const Text(
                    "Made with ❤️ in Kenya",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "PesaPulse",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text("Version 2.1.0"),

                  const SizedBox(height: 4),

                  Text("© 2026", style: TextStyle(color: Colors.grey.shade600)),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileStat(String value, String title, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            Icon(icon, size: 30),

            const SizedBox(height: 10),

            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(title),
          ],
        ),
      ),
    );
  }
}
