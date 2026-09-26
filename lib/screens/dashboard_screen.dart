import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/repositories/budget_repository.dart';
import 'package:pesapulse_mobile/exceptions/rate_limit_exception.dart';

import 'package:pesapulse_mobile/screens/expense_screen.dart';
import '../services/session_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_loading_skeleton.dart';
import '../widgets/recent_expense_tile.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../screens/add_expense_screen.dart';
import '../screens/add_goals_screen.dart';
import '../screens/budget_page.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/financial_insights_repository.dart';
import 'package:flutter/foundation.dart';
import '../utils/responsive_helper.dart';
import '../utils/snackbar_helper.dart';
import '../core/utils/currency_formatter.dart';
import '../services/startup_refresh_coordinator.dart';
import '../services/sync_events.dart';

List<Map<String, dynamic>> _decodeExpenses(dynamic raw) {
  return List<Map<String, dynamic>>.from(raw);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;
  bool _initialLoadComplete = false;

  bool _cachedDashboardLoadInProgress = false;
  bool _cachedDashboardReloadPending = false;

  bool isGuest = false;

  bool _dashboardRefreshInProgress = false;

  bool get hasBudget => budgetCount > 0 && currentBudget > 0;

  bool get hasExpenses => totalCount > 0;

  bool get hasFinancialData => hasExpenses || hasBudget;

  bool get hasEnoughDataForHealth => hasExpenses && hasBudget;

  bool get hasEnoughDataForInsights => hasExpenses || hasBudget;

  bool get hasInsights =>
      recommendation.trim().isNotEmpty || categoryAdvice.trim().isNotEmpty;

  int totalExpenses = 0;
  int totalCount = 0;
  int totalCategories = 0;

  double currentBudget = 0;
  double spentThisMonth = 0;
  double remainingBudget = 0;
  int budgetCount = 0;

  double financialHealthScore = 0;
  String financialHealthLabel = "";
  String recommendation = "";
  String categoryAdvice = "";

  double get budgetProgress {
    if (currentBudget <= 0) return 0;

    return (spentThisMonth / currentBudget).clamp(0.0, 1.0);
  }

  List recentExpenses = [];
  double opacity = 0;

  late final String greeting;
  late final String formattedDate;

  final DashboardRepository dashboardRepository = DashboardRepository();
  final BudgetRepository budgetRepository = BudgetRepository();
  final FinancialInsightsRepository insightsRepository =
      FinancialInsightsRepository();

  @override
  void initState() {
    super.initState();

    greeting = getGreeting();
    formattedDate = getFormattedDate();

    SyncEvents.instance.dashboardRefresh.addListener(_onDashboardDataChanged);

    _initializeDashboard();
  }

  void _onDashboardDataChanged() {
    if (!mounted) return;

    debugPrint(
      'Dashboard: synchronized data changed. '
      'Reloading cached dashboard.',
    );

    if (_cachedDashboardLoadInProgress) {
      debugPrint(
        'Dashboard: cached reload already in progress. '
        'Scheduling another reload.',
      );

      _cachedDashboardReloadPending = true;
      return;
    }

    _loadCachedDashboard();
  }

  String budgetStatus = "healthy";

  String get budgetProgressText {
    if (currentBudget <= 0) return "No Budget";

    final percent = ((spentThisMonth / currentBudget) * 100).clamp(0, 999);

    return "${percent.toStringAsFixed(0)}% Used";
  }

  Future<void> _initializeDashboard() async {
    final guest = await SessionService.isGuest();

    if (!mounted) return;

    setState(() {
      isGuest = guest;
    });

    // ------------------------------------------------------------
    // STEP 1: Load everything available locally.
    // This must never wait for the network.
    // ------------------------------------------------------------
    await _loadCachedDashboard();

    if (!mounted) return;

    // ------------------------------------------------------------
    // STEP 2: Render the first frame.
    // ------------------------------------------------------------
    setState(() {
      opacity = 1;
    });

    // ------------------------------------------------------------
    // STEP 3: Refresh from the API after the UI is visible.
    // ------------------------------------------------------------
    if (!isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        _refreshDashboardInBackground();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _parseExpenses(dynamic raw) async {
    return compute(_decodeExpenses, raw);
  }

  Future<void> _loadCachedDashboard() async {
    if (_cachedDashboardLoadInProgress) {
      _cachedDashboardReloadPending = true;

      debugPrint(
        'Dashboard: cache load already running. '
        'Marking reload as pending.',
      );

      return;
    }

    _cachedDashboardLoadInProgress = true;

    try {
      do {
        _cachedDashboardReloadPending = false;

        // ------------------------------------------------------------
        // Load each cache independently.
        // ------------------------------------------------------------

        Map<String, dynamic>? dashboard;
        Map<String, dynamic>? budget;
        Map<String, dynamic>? insights;

        // ------------------------------------------------------------
        // Dashboard cache
        // ------------------------------------------------------------
        try {
          dashboard = await dashboardRepository.getCachedDashboard();

          debugPrint('Dashboard cache loaded successfully.');
        } catch (e) {
          debugPrint('No cached dashboard available: $e');
        }

        // ------------------------------------------------------------
        // Budget cache
        // ------------------------------------------------------------
        try {
          budget = await budgetRepository.getBudgetSummary(useCache: true);

          debugPrint(
            'Dashboard budget cache loaded: '
            'budget=${budget['budget']} '
            'spent=${budget['spent']} '
            'remaining=${budget['remaining']} '
            'count=${budget['budget_count']}',
          );
        } catch (e) {
          debugPrint('No cached budget available: $e');

          budget = {'budget': 0, 'spent': 0, 'remaining': 0, 'budget_count': 0};
        }

        // ------------------------------------------------------------
        // Financial insights cache
        // ------------------------------------------------------------
        try {
          insights = await insightsRepository.getInsights(useCache: true);

          debugPrint('Dashboard insights cache loaded.');
        } catch (e) {
          debugPrint('No cached insights available: $e');

          insights = {
            'budget_status': 'healthy',
            'financial_health_score': 0,
            'financial_health_label': '',
            'recommendation': '',
            'category_advice': '',
          };
        }

        // ------------------------------------------------------------
        // Parse dashboard cache
        // ------------------------------------------------------------
        List<Map<String, dynamic>> parsedExpenses = [];

        if (dashboard != null) {
          try {
            final summary = dashboard['summary'] as Map<String, dynamic>? ?? {};

            final recent = dashboard['recent_expenses'] as List? ?? [];

            parsedExpenses = await _parseExpenses(recent);

            if (!mounted) return;

            setState(() {
              totalExpenses =
                  int.tryParse(summary['total_expenses']?.toString() ?? '0') ??
                  0;

              totalCount =
                  int.tryParse(summary['total_count']?.toString() ?? '0') ?? 0;

              totalCategories =
                  int.tryParse(summary['categories']?.toString() ?? '0') ?? 0;

              recentExpenses = parsedExpenses;
            });
          } catch (e) {
            debugPrint('Failed to parse cached dashboard: $e');
          }
        }

        if (!mounted) return;

        // ------------------------------------------------------------
        // Apply budget + insights together.
        // ------------------------------------------------------------
        setState(() {
          currentBudget =
              double.tryParse(budget?['budget']?.toString() ?? '0') ?? 0;

          spentThisMonth =
              double.tryParse(budget?['spent']?.toString() ?? '0') ?? 0;

          remainingBudget =
              double.tryParse(budget?['remaining']?.toString() ?? '0') ?? 0;

          budgetCount =
              int.tryParse(budget?['budget_count']?.toString() ?? '0') ?? 0;

          budgetStatus = insights?['budget_status']?.toString() ?? 'healthy';

          financialHealthScore =
              double.tryParse(
                insights?['financial_health_score']?.toString() ?? '0',
              ) ??
              0;

          financialHealthLabel =
              insights?['financial_health_label']?.toString() ?? '';

          recommendation = insights?['recommendation']?.toString() ?? '';

          categoryAdvice = insights?['category_advice']?.toString() ?? '';

          isLoading = false;
          _initialLoadComplete = true;
        });

        debugPrint(
          'Dashboard: applied cached budget values: '
          'budget=$currentBudget '
          'spent=$spentThisMonth '
          'remaining=$remainingBudget '
          'count=$budgetCount',
        );

        // ------------------------------------------------------------
        // If another synchronization event arrived while we were
        // loading, immediately perform one more cache read.
        // ------------------------------------------------------------
      } while (_cachedDashboardReloadPending);
    } finally {
      _cachedDashboardLoadInProgress = false;
    }

    debugPrint('Finished loading available cached dashboard data.');
  }

  Future<void> _refreshDashboardInBackground() async {
    if (isGuest) {
      debugPrint('Dashboard API refresh skipped: guest user.');
      return;
    }
    if (_dashboardRefreshInProgress) return;

    _dashboardRefreshInProgress = true;

    try {
      // ------------------------------------------------------------
      // Refresh all dashboard data concurrently.
      // ------------------------------------------------------------
      final dashboard = await StartupRefreshCoordinator.instance.run(
        'dashboard',
        () async {
          return await dashboardRepository.refreshDashboard();
        },
      );

      debugPrint('Dashboard: loading cached budget-summary...');

      final budget = await budgetRepository.getBudgetSummary(useCache: true);

      debugPrint('Dashboard: cached budget-summary loaded.');

      final insights = await insightsRepository.getInsights(useCache: true);

      if (!mounted) return;

      // ------------------------------------------------------------
      // Dashboard
      // ------------------------------------------------------------

      final summary = dashboard['summary'];
      final recent = dashboard['recent_expenses'] as List? ?? [];

      final parsedExpenses = await _parseExpenses(recent);

      // ------------------------------------------------------------
      // Budget
      // ------------------------------------------------------------

      // ------------------------------------------------------------
      // Financial insights
      // ------------------------------------------------------------

      if (!mounted) return;

      setState(() {
        // Dashboard
        totalExpenses = int.tryParse(summary['total_expenses'].toString()) ?? 0;

        totalCount = int.tryParse(summary['total_count'].toString()) ?? 0;

        totalCategories = int.tryParse(summary['categories'].toString()) ?? 0;

        recentExpenses = parsedExpenses;

        // Budget
        currentBudget = double.tryParse(budget['budget'].toString()) ?? 0;

        spentThisMonth = double.tryParse(budget['spent'].toString()) ?? 0;

        remainingBudget = double.tryParse(budget['remaining'].toString()) ?? 0;

        budgetCount = int.tryParse(budget['budget_count'].toString()) ?? 0;

        // Insights
        budgetStatus = insights['budget_status']?.toString() ?? 'healthy';

        financialHealthScore =
            double.tryParse(insights['financial_health_score'].toString()) ?? 0;

        financialHealthLabel =
            insights['financial_health_label']?.toString() ?? '';

        recommendation = insights['recommendation']?.toString() ?? '';

        categoryAdvice = insights['category_advice']?.toString() ?? '';

        isLoading = false;
      });

      debugPrint('Dashboard background refresh completed.');
    } on RateLimitException catch (e) {
      debugPrint('Dashboard refresh rate limited: ${e.message}');

      // Don't replace already visible cached data with an error.
    } catch (e) {
      debugPrint('Dashboard background refresh failed: $e');

      // The cached dashboard remains visible.
    } finally {
      _dashboardRefreshInProgress = false;

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> refreshDashboard() async {
    if (_dashboardRefreshInProgress) return;

    try {
      await _refreshDashboardInBackground();
    } on RateLimitException catch (e) {
      if (!mounted) return;

      SnackbarHelper.showRateLimited(
        context,
        message: e.message,
        remaining: e.remaining,
        retryAfter: e.retryAfter,
      );
    } catch (e) {
      if (!mounted) return;

      SnackbarHelper.showInfo(
        context,
        "Unable to refresh dashboard. Showing available data.",
      );
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return "Good Morning";
    } else if (hour < 17) {
      return "Good Afternoon";
    } else {
      return "Good Evening";
    }
  }

  String getFormattedDate() {
    final now = DateTime.now();

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return "${now.day} ${months[now.month - 1]}, ${now.year}";
  }

  Color getBudgetColor() {
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

  Color get budgetProgressColor {
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

  String getBudgetSubtitle() {
    switch (budgetStatus) {
      case "warning":
        return "Budget Warning";

      case "overspent":
        return "Budget Exceeded";

      case "critical":
        return "Critical Budget";

      default:
        return "Current Budget";
    }
  }

  @override
  void dispose() {
    SyncEvents.instance.dashboardRefresh.removeListener(
      _onDashboardDataChanged,
    );

    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildOverviewHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final titleSize = desktop
        ? 32.0
        : compact
        ? 24.0
        : 29.0;

    final greetingSize = desktop
        ? 14.0
        : compact
        ? 11.0
        : 12.5;

    final dateSize = desktop
        ? 11.5
        : compact
        ? 9.0
        : 10.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$greeting 👋",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.68),
                      fontSize: greetingSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    'Welcome Back',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                      height: 1.0,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Here is your financial snapshot for today.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.68),
                      fontSize: compact ? 10.5 : 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Container(
              width: desktop
                  ? 46
                  : compact
                  ? 36
                  : 42,
              height: desktop
                  ? 46
                  : compact
                  ? 36
                  : 42,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(compact ? 11 : 13),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.10),
                ),
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: colorScheme.primary,
                size: desktop
                    ? 23
                    : compact
                    ? 18
                    : 21,
              ),
            ),
          ],
        ),

        SizedBox(height: compact ? 12 : 15),

        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 5 : 6,
              ),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withOpacity(0.10)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.insights_rounded,
                    size: compact ? 13 : 15,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "Today's Overview",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: compact ? 8.5 : 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Text(
              formattedDate,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.58),
                fontSize: dateSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsCards(double cardHeight) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final spacing = ResponsiveHelper.spacing(context);

    final cards = [
      DashboardCard(
        title: "Expenses",
        subtitle: hasExpenses ? "Total Recorded" : "No expenses yet",
        value: totalCount.toString(),
        icon: Icons.receipt_long_rounded,
        iconColor: colorScheme.primary,
      ),

      DashboardCard(
        title: "Budget",
        subtitle: hasBudget ? getBudgetSubtitle() : "No Budget Set",
        value: CurrencyFormatter.format(currentBudget),
        icon: Icons.account_balance_wallet_rounded,
        iconColor: hasBudget ? getBudgetColor() : colorScheme.onSurfaceVariant,
      ),

      DashboardCard(
        title: "Categories",
        subtitle: hasExpenses ? "Expense Types" : "No categories yet",
        value: totalCategories.toString(),
        icon: Icons.category_rounded,
        iconColor: hasExpenses
            ? const Color(0xFFF59E0B)
            : colorScheme.onSurfaceVariant,
      ),

      DashboardCard(
        title: "Remaining",
        subtitle: hasBudget ? "Budget Left" : "No Budget",
        value: hasBudget ? CurrencyFormatter.format(remainingBudget) : "—",
        icon: Icons.savings_rounded,
        iconColor: hasBudget
            ? remainingBudget >= 0
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626)
            : colorScheme.onSurfaceVariant,
      ),
    ];

    if (landscape && !compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int index = 0; index < cards.length; index++) ...[
            if (index > 0) SizedBox(width: spacing),
            Expanded(
              child: SizedBox(height: cardHeight, child: cards[index]),
            ),
          ],
        ],
      );
    }

    final rowSpacing = compact ? 10.0 : 14.0;

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[0]),
              SizedBox(width: rowSpacing),
              Expanded(child: cards[1]),
            ],
          ),
        ),

        SizedBox(height: rowSpacing),

        SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[2]),
              SizedBox(width: rowSpacing),
              Expanded(child: cards[3]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialHealthCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final healthColor = financialHealthScore >= 80
        ? const Color(0xFF16A34A)
        : financialHealthScore >= 60
        ? const Color(0xFF65A30D)
        : financialHealthScore >= 40
        ? const Color(0xFFF59E0B)
        : financialHealthScore >= 20
        ? const Color(0xFFF97316)
        : const Color(0xFFDC2626);

    final safeScore = financialHealthScore.clamp(0.0, 100.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(
          desktop
              ? 22
              : compact
              ? 17
              : 20,
        ),
        border: Border.all(color: healthColor.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 36 : 42,
                height: compact ? 36 : 42,
                decoration: BoxDecoration(
                  color: healthColor.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: healthColor,
                  size: compact ? 18 : 21,
                ),
              ),

              SizedBox(width: compact ? 9 : 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Health',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      hasEnoughDataForHealth
                          ? 'Your current financial position'
                          : 'Build your financial profile',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.65),
                        fontSize: compact ? 10 : 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              if (hasEnoughDataForHealth)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 7 : 9,
                    vertical: compact ? 4 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: healthColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    financialHealthLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: healthColor,
                      fontSize: compact ? 8 : 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: compact ? 16 : 20),

          if (!hasEnoughDataForHealth)
            _buildDashboardEmptyContent(
              icon: Icons.health_and_safety_outlined,
              title: !hasExpenses && !hasBudget
                  ? "Your financial health is waiting"
                  : !hasBudget
                  ? "Set a budget to assess your health"
                  : "Add expenses to assess your health",
              message: !hasExpenses && !hasBudget
                  ? "Add expenses and create a budget to start analyzing your financial health."
                  : !hasBudget
                  ? "Create a monthly budget so PesaPulse can compare spending with your planned limits."
                  : "Record expenses so PesaPulse can measure spending against your budget.",
              buttonText: !hasBudget ? "Set Budget" : "Add Expense",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => !hasBudget
                        ? const BudgetPage()
                        : const AddExpenseScreen(),
                  ),
                );
              },
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: compact ? 78 : 96,
                  height: compact ? 78 : 96,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: safeScore / 100,
                        strokeWidth: compact ? 8 : 10,
                        strokeCap: StrokeCap.round,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: healthColor,
                      ),

                      Text(
                        safeScore.toStringAsFixed(0),
                        style: TextStyle(
                          color: healthColor,
                          fontSize: compact ? 23 : 29,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: compact ? 14 : 18),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${safeScore.toStringAsFixed(0)} / 100',
                        style: TextStyle(
                          color: healthColor,
                          fontSize: compact ? 17 : 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        recommendation.isNotEmpty
                            ? recommendation
                            : 'Keep monitoring your spending, budget, and savings progress.',
                        maxLines: compact ? 4 : 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.72),
                          fontSize: compact ? 10.5 : 11.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildBudgetOverviewCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final padding = ResponsiveHelper.cardPadding(context);
    final radius = desktop
        ? 22.0
        : compact
        ? 17.0
        : 20.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: getBudgetColor().withOpacity(
              theme.brightness == Brightness.dark ? 0.06 : 0.04,
            ),
            blurRadius: desktop ? 18 : 13,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 36 : 42,
                height: compact ? 36 : 42,
                decoration: BoxDecoration(
                  color: getBudgetColor().withOpacity(0.09),
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: getBudgetColor(),
                  size: compact ? 18 : 21,
                ),
              ),

              SizedBox(width: compact ? 9 : 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget Overview',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      hasBudget
                          ? 'Your current monthly budget position'
                          : 'Create a budget to start tracking limits',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.66),
                        fontSize: compact ? 10 : 11.5,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              if (hasBudget)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 7 : 9,
                    vertical: compact ? 4 : 5,
                  ),
                  decoration: BoxDecoration(
                    color: getBudgetColor().withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    budgetProgressText,
                    style: TextStyle(
                      color: getBudgetColor(),
                      fontSize: compact ? 8.5 : 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),

          SizedBox(height: compact ? 16 : 20),

          if (!hasBudget)
            _buildDashboardEmptyContent(
              icon: Icons.account_balance_wallet_outlined,
              title: "No budget set yet",
              message:
                  "Create a monthly budget to track spending and see how much you have left.",
              buttonText: "Set Budget",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BudgetPage()),
                );
              },
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _dashboardBudgetMetric(
                    context,
                    title: 'Budget',
                    value: CurrencyFormatter.format(currentBudget),
                    color: colorScheme.primary,
                  ),
                ),

                SizedBox(width: compact ? 8 : 12),

                Expanded(
                  child: _dashboardBudgetMetric(
                    context,
                    title: 'Spent',
                    value: CurrencyFormatter.format(spentThisMonth),
                    color: const Color(0xFFF59E0B),
                  ),
                ),

                SizedBox(width: compact ? 8 : 12),

                Expanded(
                  child: _dashboardBudgetMetric(
                    context,
                    title: 'Remaining',
                    value: CurrencyFormatter.format(remainingBudget),
                    color: remainingBudget >= 0
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),

            SizedBox(height: compact ? 14 : 18),

            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      tween: Tween(begin: 0, end: budgetProgress),
                      builder: (_, value, __) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: compact ? 7 : 9,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            budgetProgressColor,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(width: compact ? 8 : 10),

                Text(
                  budgetProgressText,
                  style: TextStyle(
                    color: budgetProgressColor,
                    fontSize: compact ? 9 : 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _dashboardBudgetMetric(
    BuildContext context, {
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      padding: EdgeInsets.all(compact ? 9 : 11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.055),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withOpacity(0.62),
              fontSize: compact ? 8.5 : 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: compact ? 11.5 : 13,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardEmptyContent({
    required IconData icon,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: compact ? 10 : 14,
          horizontal: compact ? 4 : 10,
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.green, size: 26),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 14 : 15,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: compact ? 12 : 13,
                height: 1.4,
              ),
            ),

            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 12),

              TextButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.add, size: 18),
                label: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSmartInsightsCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final padding = ResponsiveHelper.cardPadding(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(
          desktop
              ? 22
              : compact
              ? 17
              : 20,
        ),
        border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 36 : 42,
                height: compact ? 36 : 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.09),
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: const Color(0xFF7C3AED),
                  size: compact ? 18 : 21,
                ),
              ),

              SizedBox(width: compact ? 9 : 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Insights',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      'Personalized signals from your finances',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.65),
                        fontSize: compact ? 10 : 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: compact ? 15 : 18),

          if (!hasEnoughDataForInsights)
            _buildDashboardEmptyContent(
              icon: Icons.auto_awesome_outlined,
              title: "Insights will appear here",
              message:
                  "Record expenses or create a budget to let PesaPulse identify patterns and provide recommendations.",
              buttonText: "Add Expense",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
              },
            )
          else if (!hasInsights)
            _buildDashboardEmptyContent(
              icon: Icons.insights_outlined,
              title: "Building your insights",
              message:
                  "Keep using PesaPulse while more financial data becomes available.",
              buttonText: "Add Expense",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
              },
            )
          else ...[
            if (recommendation.trim().isNotEmpty)
              _buildDashboardInsight(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Budget recommendation',
                message: recommendation,
                color: colorScheme.primary,
              ),

            if (categoryAdvice.trim().isNotEmpty) ...[
              if (recommendation.trim().isNotEmpty)
                SizedBox(height: compact ? 9 : 11),

              _buildDashboardInsight(
                icon: Icons.category_rounded,
                title: 'Category insight',
                message: categoryAdvice,
                color: const Color(0xFFF59E0B),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildDashboardInsight({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.055),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: color.withOpacity(0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: compact ? 15 : 17),
          ),

          SizedBox(width: compact ? 9 : 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: compact ? 10.5 : 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  message,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.72),
                    fontSize: compact ? 10 : 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final actions = [
      _DashboardAction(
        icon: Icons.receipt_long_rounded,
        title: 'Expense',
        color: colorScheme.primary,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
      ),
      _DashboardAction(
        icon: Icons.account_balance_wallet_rounded,
        title: 'Budget',
        color: const Color(0xFF2563EB),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BudgetPage()),
          );
        },
      ),
      _DashboardAction(
        icon: Icons.flag_rounded,
        title: 'Goal',
        color: const Color(0xFFF59E0B),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddGoalScreen()),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: compact ? 16 : 18,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            for (int i = 0; i < actions.length; i++) ...[
              if (i > 0) SizedBox(width: compact ? 8 : 10),

              Expanded(child: _buildDashboardAction(actions[i])),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDashboardAction(_DashboardAction action) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        child: Ink(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 12,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: action.color.withOpacity(0.055),
            borderRadius: BorderRadius.circular(compact ? 14 : 16),
            border: Border.all(color: action.color.withOpacity(0.10)),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 32 : 36,
                height: compact ? 32 : 36,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(compact ? 9 : 10),
                ),
                child: Icon(
                  action.icon,
                  color: action.color,
                  size: compact ? 16 : 18,
                ),
              ),

              SizedBox(width: compact ? 7 : 9),

              Expanded(
                child: Text(
                  action.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: compact ? 10.5 : 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              Icon(
                Icons.arrow_forward_rounded,
                size: compact ? 14 : 16,
                color: action.color.withOpacity(0.75),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentExpenses() {
    if (recentExpenses.isEmpty) {
      final compact = ResponsiveHelper.useCompactLayout(context);
      final color = Theme.of(context).colorScheme.primary;

      return Padding(
        padding: EdgeInsets.symmetric(
          vertical: compact ? 20 : 28,
          horizontal: compact ? 8 : 16,
        ),
        child: Column(
          children: [
            Container(
              width: compact ? 56 : 64,
              height: compact ? 56 : 64,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: compact ? 28 : 32,
                color: color,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              "No Expenses Yet",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 16 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              "Add your first expense to start tracking your spending.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: compact ? 12 : 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 14),

            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                "Add Expense",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recentExpenses.length,
      itemBuilder: (context, index) {
        return RecentExpenseTile(expense: recentExpenses[index]);
      },
      separatorBuilder: (_, __) => const Divider(),
    );
  }

  Widget _buildRecentExpensesCard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(
          desktop
              ? 22
              : compact
              ? 17
              : 20,
        ),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: _buildRecentExpenses(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final spacing = ResponsiveHelper.spacing(context);

    final sectionSpacing = desktop
        ? 28.0
        : compact
        ? 20.0
        : 24.0;

    final horizontalPadding = compact
        ? 14.0
        : landscape
        ? 20.0
        : 18.0;

    final cardHeight = desktop
        ? 158.0
        : landscape
        ? 145.0
        : compact
        ? 145.0
        : 158.0;

    if (!_initialLoadComplete) {
      return const DashboardLoadingSkeleton();
    }

    return AppScaffold(
      appBar: const AdaptiveAppBar(title: null),
      body: RefreshIndicator(
        onRefresh: refreshDashboard,
        child: SingleChildScrollView(
          key: const PageStorageKey("dashboard"),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            spacing,
            horizontalPadding,
            spacing + 24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: desktop ? 1100 : 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: opacity,
                    child: _buildOverviewHeader(),
                  ),

                  SizedBox(height: sectionSpacing),

                  _buildStatisticsCards(cardHeight),

                  SizedBox(height: sectionSpacing),

                  _buildBudgetOverviewCard(),

                  SizedBox(height: sectionSpacing),

                  _buildFinancialHealthCard(),

                  SizedBox(height: sectionSpacing),

                  _buildSmartInsightsCard(),

                  SizedBox(height: sectionSpacing),

                  _buildQuickActions(),

                  SizedBox(height: sectionSpacing),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Recent Activity",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: compact ? 16 : 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Your latest recorded expenses",
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withOpacity(0.62),
                                fontSize: compact ? 10 : 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExpenseScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          "View All",
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _buildRecentExpensesCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardAction {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
}
