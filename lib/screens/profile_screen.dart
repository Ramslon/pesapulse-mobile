import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/guest_dialog_service.dart';
import '../repositories/settings_repository.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/auth_message_helper.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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

  void updateProfile() async {
    if (await GuestDialogService.isGuest()) {
      await GuestDialogService.show(context);
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await _settingsRepository.updateProfile(
        nameController.text.trim(),
        emailController.text.trim(),
      );

      await loadProfile();

      if (!mounted) return;

      //  Use helper for success message
      AuthMessageHelper.showSuccess(
        context,
        response["message"] ?? "Profile updated successfully.",
      );
    } catch (e) {
      if (!mounted) return;

      // Use helper for error/offline message
      AuthMessageHelper.showOffline(context);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> loadProfile() async {
    try {
      final profile = await _settingsRepository.getProfile();

      nameController.text = profile['name'] ?? '';
      emailController.text = profile['email'] ?? '';

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;

      // ✅ Use helper for offline/error message
      AuthMessageHelper.showOffline(context);
    }
  }

  Future<void> loadSettings() async {
    final repo = SettingsRepository();

    try {
      final prefs = await repo.getPreferences();

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
    try {
      final stats = await _settingsRepository.getDashboardStatistics(
        forceRefresh: true,
      );

      setState(() {
        totalGoals = stats["totalGoals"];
        completedGoals = stats["completedGoals"];
        totalExpenses = stats["totalExpenses"];
        totalBudgets = stats["totalBudgets"];
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 45,
                    child: Icon(Icons.person, size: 45),
                  ),

                  const SizedBox(height: 15),

                  Text(
                    nameController.text.isEmpty ? 'User' : nameController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    emailController.text,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            CustomTextField(controller: nameController, label: 'Name'),

            const SizedBox(height: 20),

            CustomTextField(controller: emailController, label: 'Email'),

            const SizedBox(height: 20),

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

            SizedBox(
              width: double.infinity,
              height: 50,

              child: CustomButton(
                text: 'Update Profile',
                icon: Icons.person,
                isLoading: isLoading,
                onPressed: updateProfile,
              ),
            ),

            const SizedBox(height: 30),

            Consumer<ThemeProvider>(
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
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerLeft,

              child: Text(
                'Notification Settings',

                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
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

                      final repo = SettingsRepository();

                      await repo.updatePreferencesOnline(
                        dailyReminder: value,
                        expenseAlerts: expenseAlerts,
                        weeklySummary: weeklySummary,
                      );

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
                      final repo = SettingsRepository();

                      await repo.updatePreferencesOnline(
                        dailyReminder: dailyReminder,
                        expenseAlerts: value,
                        weeklySummary: weeklySummary,
                      );

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

                      final repo = SettingsRepository();

                      await repo.updatePreferencesOnline(
                        dailyReminder: dailyReminder,
                        expenseAlerts: expenseAlerts,
                        weeklySummary: value,
                      );

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
