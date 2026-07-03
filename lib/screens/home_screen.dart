import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'expense_list_content.dart';

import '../services/settings_service.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

import 'settings_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List screens = [
    const DashboardScreen(),

    const ExpenseListContent(),

    const BudgetScreen(),

    const AnalyticsScreen(),

    const GoalsScreen(),

    const SettingsScreen(),
  ];

  final List<String> titles = [
    'Dashboard',
    'Expenses',
    'Budget',
    'Analytics',
    'Goals',
    'Settings',
  ];

  final List<IconData> icons = [
    Icons.dashboard,

    Icons.receipt_long,

    Icons.account_balance_wallet,

    Icons.bar_chart,

    Icons.flag,

    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();

    _syncPreferences();
  }

  Future<void> _syncPreferences() async {
    try {
      await SettingsService.syncFromBackend();
    } catch (e) {
      debugPrint("Settings sync failed: $e");
    }

    try {
      await Provider.of<ThemeProvider>(
        context,
        listen: false,
      ).syncWithBackend();
    } catch (e) {
      debugPrint("Theme sync failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,

        title: Row(
          mainAxisSize: MainAxisSize.min,

          children: [
            Icon(icons[currentIndex]),

            const SizedBox(width: 10),

            Text(titles[currentIndex]),
          ],
        ),

        actions: const [],
      ),

      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        type: BottomNavigationBarType.fixed,

        selectedItemColor: Colors.green,

        unselectedItemColor: Colors.grey,

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),

            label: 'Dashboard',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),

            label: 'Expenses',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),

            label: 'Budget',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),

            label: 'Analytics',
          ),

          BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Goals'),

          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
