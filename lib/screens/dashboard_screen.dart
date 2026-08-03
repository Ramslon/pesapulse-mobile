import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/repositories/budget_repository.dart';

import 'package:pesapulse_mobile/screens/expense_screen.dart';
import 'package:pesapulse_mobile/widgets/sync_status_icon.dart';

import '../widgets/dashboard_card.dart';
import '../widgets/dashboard_loading_skeleton.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/recent_expense_tile.dart';

import '../screens/add_expense_screen.dart';
import '../screens/add_goals_screen.dart';
import '../screens/budget_page.dart';
import '../widgets/offline_banner.dart';
import '../widgets/empty_state_helper.dart';
import '../repositories/dashboard_repository.dart';
import '../repositories/financial_insights_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;

  bool isGuest = false;

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

    loadDashboardData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        opacity = 1;
      });
    });
  }

  String budgetStatus = "healthy";

  String get budgetProgressText {
    if (currentBudget <= 0) return "No Budget";

    final percent = ((spentThisMonth / currentBudget) * 100).clamp(0, 999);

    return "${percent.toStringAsFixed(0)}% Used";
  }

  Future<void> loadDashboardData() async {
    try {
      final results = await Future.wait([
        dashboardRepository.getDashboard(),
        budgetRepository.getBudgetSummary(),
        insightsRepository.getInsights(),
      ]);

      final data = results[0];

      final budget = results[1];
      final insights = results[2];

      final summary = data['summary'];

      final healthScore =
          double.tryParse(insights["financial_health_score"].toString()) ?? 0;

      final healthLabel = insights["financial_health_label"] ?? "";

      final recommendationText = insights["recommendation"] ?? "";

      final categoryAdviceText = insights["category_advice"] ?? "";

      final currentBudgetValue =
          double.tryParse(budget["budget"].toString()) ?? 0;

      final spentValue = double.tryParse(budget["spent"].toString()) ?? 0;

      final remainingValue =
          double.tryParse(budget["remaining"].toString()) ?? 0;

      final budgetCountValue =
          int.tryParse(budget["budget_count"].toString()) ?? 0;

      final totalExpensesValue =
          double.tryParse(summary['total_expenses'].toString())?.toInt() ?? 0;

      final totalCountValue =
          int.tryParse(summary['total_count'].toString()) ?? 0;

      final totalCategoriesValue =
          int.tryParse(summary['categories'].toString()) ?? 0;

      final recent = List<Map<String, dynamic>>.from(data['recent_expenses']);

      final status = insights["budget_status"] ?? "healthy";

      if (!mounted) return;

      setState(() {
        financialHealthScore = healthScore;
        financialHealthLabel = healthLabel;
        recommendation = recommendationText;
        categoryAdvice = categoryAdviceText;

        currentBudget = currentBudgetValue;
        spentThisMonth = spentValue;
        remainingBudget = remainingValue;
        budgetCount = budgetCountValue;

        totalExpenses = totalExpensesValue;
        totalCount = totalCountValue;
        totalCategories = totalCategoriesValue;

        recentExpenses = recent;
        budgetStatus = status;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      // First launch with no cache
      if (e.toString().contains("No cached dashboard")) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to refresh dashboard. Showing available data."),
        ),
      );
    }
  }

  Future<void> refreshDashboard() async {
    await loadDashboardData();
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
  bool get wantKeepAlive => true;

  Widget _buildOverviewHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$greeting 👋",
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          "Welcome Back",
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Container(
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
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Text(formattedDate, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticsCards(double cardHeight) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: DashboardCard(
                  title: "Expenses",
                  subtitle: "Total Recorded",
                  value: totalCount.toString(),
                  icon: Icons.account_balance_wallet,
                  iconColor: Colors.green,
                ),
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: DashboardCard(
                  title: "Budget",
                  subtitle: getBudgetSubtitle(),
                  value: "KES ${currentBudget.toStringAsFixed(0)}",
                  icon: Icons.savings,
                  iconColor: getBudgetColor(),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: DashboardCard(
                  title: "Categories",
                  subtitle: "Expense Types",
                  value: totalCategories.toString(),
                  icon: Icons.category,
                  iconColor: Colors.orange,
                ),
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: SizedBox(
                height: cardHeight,
                child: DashboardCard(
                  title: "Remaining",
                  subtitle: "Budget Left",
                  value: "KES ${remainingBudget.toStringAsFixed(0)}",
                  icon: Icons.account_balance,
                  iconColor: remainingBudget >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialHealthCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Financial Health",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            LinearProgressIndicator(
              value: financialHealthScore / 100,
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),

            const SizedBox(height: 10),

            Text(
              "$financialHealthLabel (${financialHealthScore.toInt()}/100)",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 15),

            Text(recommendation),

            if (categoryAdvice.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(categoryAdvice, style: const TextStyle(color: Colors.grey)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetOverviewCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Budget Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _budgetItem(
                  "Budget",
                  "KES ${currentBudget.toStringAsFixed(0)}",
                  Colors.blue,
                ),
                _budgetItem(
                  "Spent",
                  "KES ${spentThisMonth.toStringAsFixed(0)}",
                  Colors.orange,
                ),
                _budgetItem(
                  "Remaining",
                  "KES ${remainingBudget.toStringAsFixed(0)}",
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
        ),
      ),
    );
  }

  Widget _budgetItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildSmartInsightsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  "Smart Insights",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            const SizedBox(height: 18),

            _buildInsightTile(
              Icons.account_balance_wallet,
              "Budget Recommendation",
              recommendation,
            ),

            if (categoryAdvice.isNotEmpty) ...[
              const Divider(height: 28),

              _buildInsightTile(
                Icons.category,
                "Category Advice",
                categoryAdvice,
              ),
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),

              const SizedBox(height: 4),

              Text(
                message,
                style: const TextStyle(color: Colors.grey, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 15),

        Row(
          children: [
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

            const SizedBox(width: 12),

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

            const SizedBox(width: 12),

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
          ],
        ),
      ],
    );
  }

  Widget _buildRecentExpenses() {
    if (recentExpenses.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 35),
        child: buildEmptyState(
          context,
          EmptyStateType.expenses,
          isGuest: isGuest,
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
    final cardHeight = MediaQuery.of(context).size.height * 0.22;
    if (isLoading) {
      return const DashboardLoadingSkeleton();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SyncStatusIcon(), // quick glance sync state
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: const OfflineBanner(), //  pinned under AppBar
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refreshDashboard,
        child: SingleChildScrollView(
          key: const PageStorageKey("dashboard"),
          padding: const EdgeInsets.all(20),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            opacity: opacity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                _buildOverviewHeader(),
                const SizedBox(height: 30),

                _buildStatisticsCards(cardHeight),

                const SizedBox(height: 20),

                _buildBudgetOverviewCard(),

                const SizedBox(height: 20),

                _buildFinancialHealthCard(),

                const SizedBox(height: 20),

                _buildSmartInsightsCard(),

                const SizedBox(height: 30),

                _buildQuickActions(),

                const SizedBox(height: 30),

                Row(
                  children: [
                    const Text(
                      "Recent Expenses",
                      style: TextStyle(
                        fontSize: 20,
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
    );
  }
}
