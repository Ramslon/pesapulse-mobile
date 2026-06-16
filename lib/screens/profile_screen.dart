import 'package:flutter/material.dart';

import '../services/api_services.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
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

  bool isLoading = false;

  bool dailyReminder = true;

  bool expenseAlerts = true;

  bool weeklySummary = false;

  @override
  void initState() {
    super.initState();

    loadSettings();
    loadProfile();
  }

  void updateProfile() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await ApiService.updateProfile(
        nameController.text.trim(),
        emailController.text.trim(),
      );

      await loadProfile();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response['message'])));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
      final profile = await ApiService.getProfile();

      nameController.text = profile['name'] ?? '';

      emailController.text = profile['email'] ?? '';

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Profile load error: $e');
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
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),

            const SizedBox(height: 30),

            CustomTextField(controller: nameController, label: 'Name'),

            const SizedBox(height: 20),

            CustomTextField(controller: emailController, label: 'Email'),

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
          ],
        ),
      ),
    );
  }
}
