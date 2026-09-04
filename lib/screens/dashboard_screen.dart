import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/repositories/budget_repository.dart';
import 'package:pesapulse_mobile/exceptions/rate_limit_exception.dart';

import 'package:pesapulse_mobile/screens/expense_screen.dart';
import '../services/session_service.dart';
import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_loading_skeleton.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_expense_tile.dart';
import '../widgets/app/adaptive_app_bar.dart';
import '../widgets/app/app_scaffold.dart';
import '../screens/add_expense_screen.dart';
import '../screens/add_goals_screen.dart';
import '../screens/budget_page.dart';
import '../widgets/empty_state_helper.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/financial_insights_repository.dart';
import 'package:flutter/foundation.dart';
import '../utils/responsive_helper.dart';
import '../utils/snackbar_helper.dart';
import '../core/utils/currency_formatter.dart';

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

    _initializeDashboard();
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
    // ------------------------------------------------------------
    // Load each cache independently.
    //
    // Missing budget / insights / dashboard cache is NOT the same
    // thing as the entire dashboard being unavailable.
    // ------------------------------------------------------------

    Map<String, dynamic>? dashboard;
    Map<String, dynamic>? budget;
    Map<String, dynamic>? insights;

    // ------------------------------------------------------------
    // Dashboard cache
    // ------------------------------------------------------------
    try {
      dashboard = await dashboardRepository.getCachedDashboard();
    } catch (e) {
      debugPrint('No cached dashboard available: $e');
    }

    // ------------------------------------------------------------
    // Budget cache
    // ------------------------------------------------------------
    try {
      budget = await budgetRepository.getBudgetSummary(useCache: true);
    } catch (e) {
      debugPrint('No cached budget available: $e');

      // No budget is a valid state.
      budget = {'budget': 0, 'spent': 0, 'remaining': 0, 'budget_count': 0};
    }

    // ------------------------------------------------------------
    // Financial insights cache
    // ------------------------------------------------------------
    try {
      insights = await insightsRepository.getInsights(useCache: true);
    } catch (e) {
      debugPrint('No cached insights available: $e');

      // Safe defaults for a dashboard with no cached insights.
      insights = {
        'budget_status': 'healthy',
        'financial_health_score': 0,
        'financial_health_label': '',
        'recommendation': '',
        'category_advice': '',
      };
    }

    // ------------------------------------------------------------
    // Parse dashboard cache if available.
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
              int.tryParse(summary['total_expenses']?.toString() ?? '0') ?? 0;

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
    // Apply budget + insights independently.
    // ------------------------------------------------------------
    setState(() {
      // Budget
      currentBudget =
          double.tryParse(budget?['budget']?.toString() ?? '0') ?? 0;

      spentThisMonth =
          double.tryParse(budget?['spent']?.toString() ?? '0') ?? 0;

      remainingBudget =
          double.tryParse(budget?['remaining']?.toString() ?? '0') ?? 0;

      budgetCount =
          int.tryParse(budget?['budget_count']?.toString() ?? '0') ?? 0;

      // Insights
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

      // ----------------------------------------------------------
      // The first rendering attempt is now complete.
      // Even if there is no budget or no cached dashboard,
      // we should not remain stuck on the skeleton.
      // ----------------------------------------------------------
      isLoading = false;
      _initialLoadComplete = true;
    });

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
      final results = await Future.wait([
        dashboardRepository.refreshDashboard(),
        budgetRepository.getBudgetSummary(),
        insightsRepository.getInsights(),
      ]);

      if (!mounted) return;

      // ------------------------------------------------------------
      // Dashboard
      // ------------------------------------------------------------
      final dashboard = results[0];
      final summary = dashboard['summary'];
      final recent = dashboard['recent_expenses'] as List? ?? [];

      final parsedExpenses = await _parseExpenses(recent);

      // ------------------------------------------------------------
      // Budget
      // ------------------------------------------------------------
      final budget = results[1];

      // ------------------------------------------------------------
      // Financial insights
      // ------------------------------------------------------------
      final insights = results[2];

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

  Widget _buildTodayOverviewBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insights, size: 16, color: Colors.green),
          SizedBox(width: 6),
          Text(
            "Today's Overview",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  Widget _buildOverviewHeader() {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$greeting 👋",
          style: TextStyle(
            fontSize: ResponsiveHelper.useCompactLayout(context) ? 14 : 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          "Welcome Back",
          style: TextStyle(
            fontSize: ResponsiveHelper.useCompactLayout(context) ? 26 : 30,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        if (compact)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTodayOverviewBadge(),
              const SizedBox(height: 8),
              Text(formattedDate, style: const TextStyle(color: Colors.grey)),
            ],
          )
        else
          Row(
            children: [
              _buildTodayOverviewBadge(),
              const Spacer(),
              Text(formattedDate, style: const TextStyle(color: Colors.grey)),
            ],
          ),
      ],
    );
  }

  Widget _buildStatisticsCards(double cardHeight) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final cardSpacing = compact ? 10.0 : 15.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: DashboardCard(
                  title: "Expenses",
                  subtitle: hasExpenses ? "Total Recorded" : "No expenses yet",
                  value: totalCount.toString(),
                  icon: Icons.account_balance_wallet,
                  iconColor: Colors.green,
                ),
              ),
            ),

            SizedBox(width: cardSpacing),

            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: DashboardCard(
                  title: "Budget",
                  subtitle: hasBudget ? getBudgetSubtitle() : "No Budget Set",
                  value: CurrencyFormatter.format(currentBudget),
                  icon: Icons.savings,
                  iconColor: hasBudget ? getBudgetColor() : Colors.grey,
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: compact ? 12 : 18),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: DashboardCard(
                  title: "Categories",
                  subtitle: hasExpenses ? "Expense Types" : "No categories yet",
                  value: totalCategories.toString(),
                  icon: Icons.category,
                  iconColor: hasExpenses ? Colors.orange : Colors.grey,
                ),
              ),
            ),

            SizedBox(width: cardSpacing),

            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: DashboardCard(
                  title: "Remaining",
                  subtitle: hasBudget ? "Budget Left" : "No Budget",
                  value: hasBudget
                      ? CurrencyFormatter.format(remainingBudget)
                      : "—",
                  icon: Icons.account_balance,
                  iconColor: hasBudget
                      ? (remainingBudget >= 0 ? Colors.green : Colors.red)
                      : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialHealthCard() {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Financial Health",
              style: TextStyle(
                fontSize: compact ? 17 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            if (!hasEnoughDataForHealth)
              _buildDashboardEmptyContent(
                icon: Icons.health_and_safety_outlined,
                title: !hasExpenses && !hasBudget
                    ? "Your financial health is waiting"
                    : !hasBudget
                    ? "Set a budget to assess your health"
                    : "Add expenses to assess your health",
                message: !hasExpenses && !hasBudget
                    ? "Add some expenses and create a budget to start analyzing your financial health."
                    : !hasBudget
                    ? "Create a monthly budget so PesaPulse can compare your spending with your planned limits."
                    : "Record your expenses so PesaPulse can measure your spending against your budget.",
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
            else ...[
              LinearProgressIndicator(
                value: (financialHealthScore / 100).clamp(0.0, 1.0),
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),

              const SizedBox(height: 10),

              Text(
                financialHealthLabel.isNotEmpty
                    ? "$financialHealthLabel (${financialHealthScore.toInt()}/100)"
                    : "${financialHealthScore.toInt()}/100",
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 15),

              if (recommendation.isNotEmpty) Text(recommendation),

              if (categoryAdvice.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  categoryAdvice,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverviewCard() {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Budget Overview",
              style: TextStyle(
                fontSize: compact ? 17 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            if (!hasBudget)
              _buildDashboardEmptyContent(
                icon: Icons.account_balance_wallet_outlined,
                title: "No budget set yet",
                message:
                    "Create a monthly budget to track your spending and see how much you have left.",
                buttonText: "Set Budget",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BudgetPage()),
                  );
                },
              )
            else ...[
              if (compact)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _budgetItem(
                          "Budget",
                          CurrencyFormatter.format(currentBudget),
                          Colors.blue,
                        ),
                        _budgetItem(
                          "Spent",
                          CurrencyFormatter.format(spentThisMonth),
                          Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _budgetItem(
                          "Remaining",
                          CurrencyFormatter.format(remainingBudget),
                          remainingBudget >= 0 ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _budgetItem(
                      "Budget",
                      CurrencyFormatter.format(currentBudget),
                      Colors.blue,
                    ),
                    _budgetItem(
                      "Spent",
                      CurrencyFormatter.format(spentThisMonth),
                      Colors.orange,
                    ),
                    _budgetItem(
                      "Remaining",
                      CurrencyFormatter.format(remainingBudget),
                      remainingBudget >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: budgetProgress,
                  color: budgetProgressColor,
                  backgroundColor: Colors.grey.shade300,
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  budgetProgressText,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: budgetProgressColor,
                  ),
                ),
              ),
            ],
          ],
        ),
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

  Widget _budgetItem(String title, String value, Color color) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey, fontSize: compact ? 12 : 13),
        ),

        const SizedBox(height: 6),

        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 14 : 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartInsightsCard() {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(compact ? 14 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  "Smart Insights",
                  style: TextStyle(
                    fontSize: compact ? 17 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (!hasEnoughDataForInsights)
              _buildDashboardEmptyContent(
                icon: Icons.auto_awesome_outlined,
                title: "Insights will appear here",
                message:
                    "Record some expenses or create a budget to let PesaPulse identify patterns and provide personalized recommendations.",
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
                    "Keep using PesaPulse and we'll provide personalized recommendations as more financial data becomes available.",
                buttonText: "Add Expense",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                  );
                },
              )
            else ...[
              if (recommendation.isNotEmpty)
                _buildInsightTile(
                  Icons.account_balance_wallet,
                  "Budget Recommendation",
                  recommendation,
                ),

              if (categoryAdvice.isNotEmpty) ...[
                if (recommendation.isNotEmpty) const Divider(height: 28),

                _buildInsightTile(
                  Icons.category,
                  "Category Advice",
                  categoryAdvice,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInsightTile(IconData icon, String title, String message) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.green.withOpacity(.12),
          child: Icon(icon, color: Colors.green, size: 18),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: ResponsiveHelper.useCompactLayout(context)
                      ? 13
                      : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                message,
                style: TextStyle(
                  fontSize: ResponsiveHelper.useCompactLayout(context)
                      ? 12
                      : 13,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final actions = [
      QuickActionCard(
        icon: Icons.receipt_long,
        title: "Expense",
        color: Colors.green,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
          );
        },
      ),

      QuickActionCard(
        icon: Icons.account_balance_wallet,
        title: "Budget",
        color: Colors.blue,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BudgetPage()),
          );
        },
      ),

      QuickActionCard(
        icon: Icons.flag,
        title: "Goal",
        color: Colors.orange,
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
          "Quick Actions",
          style: TextStyle(
            fontSize: compact ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 15),

        if (compact)
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: actions[0]),
                  const SizedBox(width: 10),
                  Expanded(child: actions[1]),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(child: actions[2]),
                  const Spacer(),
                ],
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(child: actions[0]),
              const SizedBox(width: 12),
              Expanded(child: actions[1]),
              const SizedBox(width: 12),
              Expanded(child: actions[2]),
            ],
          ),
      ],
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildRecentExpenses(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final spacing = ResponsiveHelper.spacing(context);

    final horizontalPadding = compact
        ? 14.0
        : landscape
        ? 24.0
        : 20.0;

    final sectionSpacing = compact ? 20.0 : 30.0;

    final cardHeight = compact
        ? 160.0
        : landscape
        ? 155.0
        : 165.0;

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
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: spacing,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: opacity,
                    child: _buildOverviewHeader(),
                  ),

                  SizedBox(height: sectionSpacing),

                  _buildStatisticsCards(cardHeight),
                  const SizedBox(height: 20),
                  _buildBudgetOverviewCard(),
                  const SizedBox(height: 20),
                  _buildFinancialHealthCard(),
                  const SizedBox(height: 20),

                  _buildSmartInsightsCard(),
                  SizedBox(height: sectionSpacing),

                  _buildQuickActions(),
                  SizedBox(height: sectionSpacing),

                  // Recent expenses section
                  Row(
                    children: [
                      Text(
                        "Recent Expenses",
                        style: TextStyle(
                          fontSize: ResponsiveHelper.useCompactLayout(context)
                              ? 18
                              : 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ExpenseScreen(),
                            ),
                          );
                        },
                        child: const Text("View All"),
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
