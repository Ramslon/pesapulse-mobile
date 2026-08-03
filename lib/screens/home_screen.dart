import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'expense_list_content.dart';

import '../repositories/settings_repository.dart';
import '../repositories/financial_insights_repository.dart';

import '../providers/theme_provider.dart';
import 'package:provider/provider.dart';

import 'settings_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';
import '../widgets/auth_message_helper.dart';
import 'package:flutter/services.dart';
import '../services/session_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final isGuest = false;

  final FinancialInsightsRepository _financialInsightsRepository =
      FinancialInsightsRepository();

  final GlobalKey<ExpenseListContentState> expenseKey = GlobalKey();
  final GlobalKey<BudgetScreenState> budgetKey = GlobalKey();

  late List<Widget> screens;

  @override
  void initState() {
    super.initState();

    screens = [
      const DashboardScreen(),
      ExpenseListContent(key: expenseKey),
      BudgetScreen(key: budgetKey),
      const AnalyticsScreen(),
      const GoalsScreen(),
      const SettingsScreen(),
    ];
    /*
    WidgetsBinding.instance.addPostFrameCallback((_) {
      //  Only show message if user is guest
      if (SessionService.isGuest) {
        AuthMessageHelper.showSuccess(context, "You’re now in Guest Mode");
      }
    });   */

    _syncPreferences();
    loadBudgetStatus();
  }

  final List<String> titles = const [
    'Dashboard',
    'Expenses',
    'Budget',
    'Analytics',
    'Goals',
    'Settings',
  ];

  final List<IconData> icons = const [
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

  Widget buildNavIcon({
    required IconData icon,
    Color? badgeColor,
    bool selected = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? Colors.green.withOpacity(.12)
                : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: selected ? Colors.green : Colors.grey,
            size: selected ? 26 : 24,
          ),
        ),

        if (badgeColor != null)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _syncPreferences() async {
    if (await SessionService.isGuest()) {
      return;
    }

    try {
      await SettingsRepository().syncPreferencesFromBackend();
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
    try {
      final insights = await _financialInsightsRepository.getInsights();

      if (!mounted) return;

      setState(() {
        budgetStatus = insights["budget_status"] ?? "healthy";
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        budgetStatus = "healthy";
      });
    }
  }

  List<NavigationDestination> get _navigationDestinations => [
    // Dashboard
    NavigationDestination(
      icon: Tooltip(
        message: "Dashboard",
        child: buildNavIcon(icon: Icons.dashboard_outlined),
      ),
      selectedIcon: Tooltip(
        message: "Dashboard",
        child: buildNavIcon(icon: Icons.dashboard, selected: true),
      ),
      label: "Dashboard",
    ),

    // Expenses
    NavigationDestination(
      icon: Tooltip(
        message: "Expenses",
        child: buildNavIcon(icon: Icons.receipt_long_outlined),
      ),
      selectedIcon: Tooltip(
        message: "Expenses",
        child: buildNavIcon(icon: Icons.receipt_long, selected: true),
      ),
      label: "Expenses",
    ),

    // Budget
    NavigationDestination(
      icon: Tooltip(
        message: "Budget",
        child: buildNavIcon(
          icon: Icons.account_balance_wallet_outlined,
          badgeColor: getBudgetBadgeColor(),
        ),
      ),
      selectedIcon: Tooltip(
        message: "Budget",
        child: buildNavIcon(
          icon: Icons.account_balance_wallet,
          badgeColor: getBudgetBadgeColor(),
          selected: true,
        ),
      ),
      label: "Budget",
    ),
    NavigationDestination(
      icon: Tooltip(
        message: "Analytics",

        child: buildNavIcon(icon: Icons.bar_chart_outlined),
      ),

      selectedIcon: Tooltip(
        message: "Analytics",
        child: buildNavIcon(icon: Icons.bar_chart, selected: true),
      ),
      label: "Analytics",
    ),

    NavigationDestination(
      icon: Tooltip(
        message: "Goals",
        child: buildNavIcon(icon: Icons.flag_outlined),
      ),
      selectedIcon: Tooltip(
        message: "Goals",
        child: buildNavIcon(icon: Icons.flag, selected: true),
      ),
      label: "Goals",
    ),

    NavigationDestination(
      icon: Tooltip(
        message: "Settings",
        child: buildNavIcon(icon: Icons.settings_outlined),
      ),
      selectedIcon: Tooltip(
        message: "Settings",
        child: buildNavIcon(icon: Icons.settings, selected: true),
      ),
      label: "Settings",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Row(
            key: ValueKey(currentIndex),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icons[currentIndex]),
              const SizedBox(width: 10),
              Text(
                titles[currentIndex],
                style: TextStyle(
                  fontSize: isLandscape ? 18 : 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        actions: const [],
      ),

      body: IndexedStack(index: currentIndex, children: screens),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isLandscape ? 6 : 8,
            0,
            isLandscape ? 6 : 8,
            isLandscape ? 6 : 10,
          ),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(28),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: NavigationBar(
                animationDuration: const Duration(milliseconds: 300),
                selectedIndex: currentIndex,

                onDestinationSelected: (index) async {
                  if (index == currentIndex) return;
                  HapticFeedback.lightImpact();

                  setState(() {
                    currentIndex = index;
                  });

                  if (index == 1) {
                    expenseKey.currentState?.refreshExpenses();
                  }
                  if (index == 2) {
                    budgetKey.currentState?.refreshBudget();
                  }
                },

                height: isLandscape ? 60 : 72,

                labelBehavior: isLandscape
                    ? NavigationDestinationLabelBehavior.alwaysHide
                    : NavigationDestinationLabelBehavior.onlyShowSelected,
                destinations: _navigationDestinations,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
