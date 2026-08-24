import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'dashboard_screen.dart';
import 'expense_list_content.dart';
import 'settings_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'goals_screen.dart';

import '../repositories/settings_repository.dart';
import '../repositories/financial_insights_repository.dart';

import '../providers/theme_provider.dart';
import '../providers/connectivity_provider.dart';
import '../services/session_service.dart';

import '../../utils/responsive_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final FinancialInsightsRepository _financialInsightsRepository =
      FinancialInsightsRepository();

  final GlobalKey<ExpenseListContentState> expenseKey =
      GlobalKey<ExpenseListContentState>();

  final GlobalKey<BudgetScreenState> budgetKey = GlobalKey<BudgetScreenState>();

  late final List<Widget> screens;

  String budgetStatus = 'healthy';

  final List<String> titles = const [
    'Dashboard',
    'Expenses',
    'Budget',
    'Analytics',
    'Goals',
    'Settings',
  ];

  final List<IconData> icons = const [
    Icons.dashboard_rounded,
    Icons.receipt_long_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.bar_chart_rounded,
    Icons.flag_rounded,
    Icons.settings_rounded,
  ];

  /// Each section gets its own identity color.
  final List<Color> navigationColors = const [
    Colors.indigo,
    Colors.green,
    Colors.blue,
    Colors.teal,
    Colors.amber,
    Colors.deepPurple,
  ];

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

    _syncPreferences();
    loadBudgetStatus();
  }

  Color get currentNavigationColor {
    return navigationColors[currentIndex];
  }

  Color getBudgetBadgeColor() {
    switch (budgetStatus) {
      case 'warning':
        return Colors.orange;

      case 'overspent':
        return Colors.deepOrange;

      case 'critical':
        return Colors.red;

      default:
        return Colors.green;
    }
  }

  // ─────────────────────────────────────────────
  // Navigation icon
  // ─────────────────────────────────────────────

  Widget buildNavIcon({
    required BuildContext context,
    required IconData icon,
    required Color color,
    bool selected = false,
    Color? badgeColor,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final containerSize = desktop
        ? 44.0
        : landscape
        ? 34.0
        : compact
        ? 36.0
        : 40.0;

    final iconSize = desktop
        ? 25.0
        : landscape
        ? 20.0
        : compact
        ? 21.0
        : 23.0;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: containerSize,
          height: containerSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? color.withOpacity(.13) : Colors.transparent,
          ),
          child: Icon(
            icon,
            color: selected ? color : color.withOpacity(.58),
            size: selected ? iconSize + 1 : iconSize,
          ),
        ),

        if (badgeColor != null)
          Positioned(
            right: 1,
            top: 1,
            child: Container(
              width: compact ? 8 : 9,
              height: compact ? 8 : 9,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Navigation destinations
  // ─────────────────────────────────────────────

  List<NavigationDestination> _navigationDestinations(BuildContext context) {
    final budgetColor = navigationColors[2];

    return [
      NavigationDestination(
        icon: Tooltip(
          message: 'Dashboard',
          child: buildNavIcon(
            context: context,
            icon: Icons.dashboard_outlined,
            color: navigationColors[0],
          ),
        ),
        selectedIcon: Tooltip(
          message: 'Dashboard',
          child: buildNavIcon(
            context: context,
            icon: Icons.dashboard_rounded,
            color: navigationColors[0],
            selected: true,
          ),
        ),
        label: 'Dashboard',
      ),

      NavigationDestination(
        icon: Tooltip(
          message: 'Expenses',
          child: buildNavIcon(
            context: context,
            icon: Icons.receipt_long_outlined,
            color: navigationColors[1],
          ),
        ),
        selectedIcon: Tooltip(
          message: 'Expenses',
          child: buildNavIcon(
            context: context,
            icon: Icons.receipt_long_rounded,
            color: navigationColors[1],
            selected: true,
          ),
        ),
        label: 'Expenses',
      ),

      NavigationDestination(
        icon: Tooltip(
          message: 'Budget',
          child: buildNavIcon(
            context: context,
            icon: Icons.account_balance_wallet_outlined,
            color: budgetColor,
            badgeColor: getBudgetBadgeColor(),
          ),
        ),
        selectedIcon: Tooltip(
          message: 'Budget',
          child: buildNavIcon(
            context: context,
            icon: Icons.account_balance_wallet_rounded,
            color: budgetColor,
            badgeColor: getBudgetBadgeColor(),
            selected: true,
          ),
        ),
        label: 'Budget',
      ),

      NavigationDestination(
        icon: Tooltip(
          message: 'Analytics',
          child: buildNavIcon(
            context: context,
            icon: Icons.bar_chart_outlined,
            color: navigationColors[3],
          ),
        ),
        selectedIcon: Tooltip(
          message: 'Analytics',
          child: buildNavIcon(
            context: context,
            icon: Icons.bar_chart_rounded,
            color: navigationColors[3],
            selected: true,
          ),
        ),
        label: 'Analytics',
      ),

      NavigationDestination(
        icon: Tooltip(
          message: 'Goals',
          child: buildNavIcon(
            context: context,
            icon: Icons.flag_outlined,
            color: navigationColors[4],
          ),
        ),
        selectedIcon: Tooltip(
          message: 'Goals',
          child: buildNavIcon(
            context: context,
            icon: Icons.flag_rounded,
            color: navigationColors[4],
            selected: true,
          ),
        ),
        label: 'Goals',
      ),

      NavigationDestination(
        icon: Tooltip(
          message: 'Settings',
          child: buildNavIcon(
            context: context,
            icon: Icons.settings_outlined,
            color: navigationColors[5],
          ),
        ),
        selectedIcon: Tooltip(
          message: 'Settings',
          child: buildNavIcon(
            context: context,
            icon: Icons.settings_rounded,
            color: navigationColors[5],
            selected: true,
          ),
        ),
        label: 'Settings',
      ),
    ];
  }

  // ─────────────────────────────────────────────
  // Preferences
  // ─────────────────────────────────────────────

  Future<void> _syncPreferences() async {
    if (await SessionService.isGuest()) {
      return;
    }

    final connectivity = context.read<ConnectivityProvider>();

    if (!connectivity.isOnline) {
      debugPrint('Preferences sync skipped: device is offline.');
      return;
    }

    try {
      await SettingsRepository().syncPreferencesFromBackend();
    } catch (e) {
      debugPrint('Preferences sync unavailable: $e');
    }

    if (!mounted) return;

    try {
      await Provider.of<ThemeProvider>(
        context,
        listen: false,
      ).syncWithBackend();
    } catch (e) {
      debugPrint('Theme sync unavailable: $e');
    }
  }
  // ─────────────────────────────────────────────
  // Budget status
  // ─────────────────────────────────────────────

  Future<void> loadBudgetStatus() async {
    try {
      final insights = await _financialInsightsRepository.getInsights();

      if (!mounted) return;

      setState(() {
        budgetStatus = insights['budget_status'] ?? 'healthy';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        budgetStatus = 'healthy';
      });
    }
  }

  // ─────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────

  Future<void> _onNavigationChanged(int index) async {
    if (index == currentIndex) {
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      currentIndex = index;
    });

    if (index == 2) {
      budgetKey.currentState?.refreshBudget();
    }

    // Optional:
    //
    // if (index == 1) {
    //   expenseKey.currentState?.refreshExpenses();
    // }
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final navHeight = landscape
        ? 62.0
        : compact
        ? 68.0
        : desktop
        ? 78.0
        : tablet
        ? 74.0
        : 72.0;

    final navHorizontalPadding = landscape
        ? 6.0
        : compact
        ? 7.0
        : desktop
        ? 18.0
        : 8.0;

    final navBottomPadding = landscape
        ? 5.0
        : compact
        ? 7.0
        : 10.0;

    final navRadius = landscape
        ? 22.0
        : compact
        ? 24.0
        : 28.0;

    final appBarTitleSize = landscape
        ? 17.0
        : compact
        ? 18.0
        : desktop
        ? 22.0
        : 20.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,

      // ─────────────────────────────────────────
      // App bar
      // ─────────────────────────────────────────
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,

        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,

          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, .12),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },

          child: Row(
            key: ValueKey(currentIndex),
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: landscape
                    ? 32
                    : compact
                    ? 34
                    : 38,
                height: landscape
                    ? 32
                    : compact
                    ? 34
                    : 38,
                decoration: BoxDecoration(
                  color: currentNavigationColor.withOpacity(.11),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icons[currentIndex],
                  color: currentNavigationColor,
                  size: landscape
                      ? 18
                      : compact
                      ? 19
                      : 21,
                ),
              ),

              SizedBox(
                width: landscape
                    ? 7
                    : compact
                    ? 8
                    : 10,
              ),

              Text(
                titles[currentIndex],
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: appBarTitleSize,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),

      // ─────────────────────────────────────────
      // Screen content
      // ─────────────────────────────────────────
      body: IndexedStack(index: currentIndex, children: screens),

      // ─────────────────────────────────────────
      // Bottom navigation
      // ─────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            navHorizontalPadding,
            0,
            navHorizontalPadding,
            navBottomPadding,
          ),
          child: Material(
            elevation: 8,
            shadowColor: Colors.black.withOpacity(.18),
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(navRadius),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(navRadius),

              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  height: navHeight,

                  backgroundColor: colorScheme.surface,

                  indicatorColor: currentNavigationColor.withOpacity(.12),

                  elevation: 0,

                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    final selected = states.contains(WidgetState.selected);

                    return TextStyle(
                      fontSize: compact
                          ? 10
                          : landscape
                          ? 10
                          : 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? currentNavigationColor
                          : colorScheme.onSurface.withOpacity(.58),
                    );
                  }),
                ),

                child: NavigationBar(
                  animationDuration: const Duration(milliseconds: 300),

                  selectedIndex: currentIndex,

                  onDestinationSelected: _onNavigationChanged,

                  labelBehavior: landscape || compact
                      ? NavigationDestinationLabelBehavior.alwaysHide
                      : NavigationDestinationLabelBehavior.onlyShowSelected,

                  destinations: _navigationDestinations(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
