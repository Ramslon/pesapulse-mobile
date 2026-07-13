import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'expense_list_content.dart';

import '../services/settings_service.dart';
import '../services/api_services.dart';
import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

import 'settings_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> screens = [
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

  String budgetStatus = "healthy";

  Color? getBudgetBadgeColor() {
    switch (budgetStatus) {
      case "warning":
        return Colors.orange;

      case "overspent":
        return Colors.deepOrange;

      case "critical":
        return Colors.red;

      default:
        return Colors.green;
    }
  }

  Widget buildNavIcon({required IconData icon, Color? badgeColor}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),

        if (badgeColor != null)
          Positioned(
            right: -3,
            top: -3,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();

    _syncPreferences();
    loadBudgetStatus();
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

  Future<void> loadBudgetStatus() async {
    final insights = await ApiService.getFinancialInsights();

    if (!mounted) return;

    setState(() {
      budgetStatus = insights['budget_status'] ?? 'healthy';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,

        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Row(
            key: ValueKey(currentIndex),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icons[currentIndex]),
              const SizedBox(width: 10),
              Text(titles[currentIndex]),
            ],
          ),
        ),

        actions: const [],
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey(currentIndex),
          child: IndexedStack(index: currentIndex, children: screens),
        ),
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),

        child: Material(
          elevation: 12,
          borderRadius: BorderRadius.circular(24),

          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),

            child: NavigationBar(
              animationDuration: const Duration(milliseconds: 300),
              selectedIndex: currentIndex,

              onDestinationSelected: (index) async {
                if (index == currentIndex) return;
                HapticFeedback.lightImpact();

                if (index == 2 || currentIndex == 2) {
                  await loadBudgetStatus();
                }

                setState(() {
                  currentIndex = index;
                });
              },

              height: 72,

              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,

              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.dashboard_outlined),
                  selectedIcon: const Icon(Icons.dashboard),
                  label: "Dashboard",
                ),

                NavigationDestination(
                  icon: const Icon(Icons.receipt_long_outlined),
                  selectedIcon: const Icon(Icons.receipt_long),
                  label: "Expenses",
                ),

                NavigationDestination(
                  icon: buildNavIcon(
                    icon: Icons.account_balance_wallet_outlined,
                    badgeColor: getBudgetBadgeColor(),
                  ),
                  selectedIcon: buildNavIcon(
                    icon: Icons.account_balance_wallet,
                    badgeColor: getBudgetBadgeColor(),
                  ),
                  label: "Budget",
                ),

                NavigationDestination(
                  icon: const Icon(Icons.bar_chart_outlined),
                  selectedIcon: const Icon(Icons.bar_chart),
                  label: "Analytics",
                ),

                NavigationDestination(
                  icon: const Icon(Icons.flag_outlined),
                  selectedIcon: const Icon(Icons.flag),
                  label: "Goals",
                ),

                NavigationDestination(
                  icon: const Icon(Icons.settings_outlined),
                  selectedIcon: const Icon(Icons.settings),
                  label: "Settings",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
