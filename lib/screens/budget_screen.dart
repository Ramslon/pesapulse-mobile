import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../widgets/budget_stat_card.dart';
import '../widgets/spending_pie_chart.dart';
import '../widgets/spending_trend_chart.dart';
import '../widgets/analytics_card.dart';
import '../widgets/financial_health_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/budget_loading_skeleton.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool isLoading = true;

  double budget = 0;
  double spent = 0;
  double remaining = 0;

  Map<String, double> categoryTotals = {};

  Map<String, double> dailySpending = {};

  String highestDay = '';

  double highestDayAmount = 0;

  double averageDaily = 0;

  double estimatedMonthEnd = 0;

  int financialScore = 100;

  String financialLabel = "";

  String recommendation = '';
  String categoryAdvice = '';
  String budgetStatus = '';

  double get percentageUsed {
    if (budget <= 0) return 0;

    return (spent / budget) * 100;
  }

  int get daysRemaining {
    final now = DateTime.now();

    final lastDay = DateTime(now.year, now.month + 1, 0);

    return lastDay.day - now.day;
  }

  Color get statusColor {
    switch (budgetStatus) {
      case 'healthy':
        return Colors.green;

      case 'warning':
        return Colors.orange;

      case 'critical':
        return Colors.red;

      case 'overspent':
        return Colors.deepOrange;

      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String get statusText {
    switch (budgetStatus) {
      case 'healthy':
        return 'Healthy';

      case 'warning':
        return 'Warning';

      case 'critical':
        return 'Critical';

      case 'overspent':
        return 'Exceeded';

      default:
        return 'Unknown';
    }
  }

  String formatCurrency(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  final TextEditingController budgetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadBudget();
  }

  Future<void> loadBudget() async {
    try {
      final data = await ApiService.getBudgetSummary();
      final insights = await ApiService.getFinancialInsights();

      setState(() {
        budget = double.tryParse(data['budget'].toString()) ?? 0;

        budgetController.text = budget.toStringAsFixed(0);

        spent = double.tryParse(data['spent'].toString()) ?? 0;

        remaining = double.tryParse(data['remaining'].toString()) ?? 0;

        budgetStatus = insights['status'] ?? '';
        recommendation = insights['recommendation'] ?? '';
        categoryAdvice = insights['category_advice'] ?? '';

        categoryTotals.clear();

        dailySpending.clear();

        if (insights['daily_spending'] != null) {
          insights['daily_spending'].forEach((day, value) {
            dailySpending[day] = (value as num).toDouble();
          });
        }

        highestDay = insights['highest_spending_day']['day'] ?? '';

        highestDayAmount = (insights['highest_spending_day']['amount'] as num)
            .toDouble();

        averageDaily = (insights['average_daily_spending'] as num).toDouble();

        estimatedMonthEnd = (insights['estimated_month_end_spending'] as num)
            .toDouble();

        financialScore = insights['financial_health_score'];

        financialLabel = insights['financial_health_label'];

        if (insights['category_breakdown'] != null) {
          for (final item in insights['category_breakdown']) {
            categoryTotals[item['category']] = (item['total'] as num)
                .toDouble();
          }
        }

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Unable to load your budget. Please check your internet connection and try again.",
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: "Retry",
            textColor: Colors.white,
            onPressed: loadBudget,
          ),
        ),
      );
    }
  }

  Future<void> saveBudget() async {
    try {
      if (budgetController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a budget amount')),
        );
        return;
      }

      final amount = double.parse(budgetController.text.trim());

      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget must be greater than zero')),
        );
        return;
      }

      final bool isUpdate = budget > 0;

      await ApiService.setBudget(amount);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpdate
                ? "Budget updated successfully"
                : "Budget created successfully",
          ),
        ),
      );
      await loadBudget();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to save budget. Please try again."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> deleteBudget() async {
    try {
      await ApiService.deleteBudget();

      setState(() {
        budgetController.clear();
      });

      await loadBudget();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Budget deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> confirmDeleteBudget() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Delete Budget?"),
          content: const Text(
            "Deleting your monthly budget will remove your spending target for this month.\n\nThis action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline),
              label: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      deleteBudget();
    }
  }

  Future<void> showCreateBudgetDialog() async {
    budgetController.text = budget > 0 ? budget.toStringAsFixed(0) : '';

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Create Monthly Budget"),

          content: TextField(
            controller: budgetController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixText: "KES ",
              labelText: "Budget Amount",
            ),
          ),

          actions: [
            if (budget > 0)
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);

                  await confirmDeleteBudget();
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text("Delete"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await saveBudget();
              },
              icon: Icon(budget > 0 ? Icons.edit : Icons.save),
              label: Text(budget > 0 ? "Update" : "Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  Widget buildBudgetAlert() {
    IconData icon;
    Color color;
    String title;

    switch (budgetStatus) {
      case 'healthy':
        icon = Icons.check_circle;
        color = Colors.green;
        title = 'Budget Healthy';
        break;

      case 'warning':
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        title = 'Budget Warning';
        break;

      case 'overspent':
        icon = Icons.error_outline;
        color = Colors.deepOrange;
        title = 'Budget Exceeded';
        break;

      case 'critical':
        icon = Icons.dangerous;
        color = Colors.red;
        title = 'Critical Budget Alert';
        break;

      default:
        return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 32, color: color),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusChip(text: title, color: color, icon: icon),

                  const SizedBox(height: 12),

                  Text(
                    budget > 0
                        ? '${percentageUsed.toStringAsFixed(1)}% of your budget has been used.'
                        : 'No monthly budget has been set.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    recommendation,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final sectionSpacing = screenHeight * 0.035;
    final smallSpacing = screenHeight * 0.015;
    final cardPadding = screenWidth * 0.05;
    final gaugeSize = (screenWidth * .34).clamp(120.0, 170.0);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    if (isLoading) {
      return const BudgetLoadingSkeleton();
    }
    if (budget <= 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: "No Budget Yet",
            message:
                "Create your monthly budget to start tracking your spending.",
          ),

          const SizedBox(height: 30),

          FloatingActionButton.extended(
            heroTag: "create_budget",
            onPressed: () {
              showCreateBudgetDialog();
            },
            icon: const Icon(Icons.add),
            label: const Text("Create Budget"),
          ),
        ],
      );
    }
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "budgetFab",
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: showCreateBudgetDialog,
        icon: Icon(budget > 0 ? Icons.edit_rounded : Icons.add_rounded),
        label: Text(budget > 0 ? "Edit Budget" : "Create Budget"),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * .05,
          vertical: screenHeight * .025,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Budget Overview",
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: .3,
                  ),
                ),

                SizedBox(height: smallSpacing),

                Text(
                  "Track your spending and stay within budget",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontSize: 15,
                  ),
                ),
              ],
            ),

            SizedBox(height: sectionSpacing),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: screenWidth < 360
                  ? 0.72
                  : screenWidth < 430
                  ? 0.82
                  : 0.92,

              children: [
                BudgetStatCard(
                  icon: Icons.trending_up,
                  title: "Spent",
                  value: "KES ${formatCurrency(spent)}",
                  color: colorScheme.primary,
                ),
                BudgetStatCard(
                  icon: Icons.savings,
                  title: "Remaining",
                  value: "KES ${formatCurrency(remaining)}",
                  color: colorScheme.primary,
                ),

                BudgetStatCard(
                  icon: Icons.pie_chart,
                  title: "Usage",
                  value: "${percentageUsed.toStringAsFixed(0)}%",
                  color: statusColor,
                ),

                BudgetStatCard(
                  icon: Icons.calendar_today,
                  title: "Days Left",
                  value: "$daysRemaining",
                  color: colorScheme.primary,
                ),
              ],
            ),
            SizedBox(height: sectionSpacing),

            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 10,
              spacing: 12,
              children: [
                Text(
                  "Monthly Budget",
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),

              child: Padding(
                padding: EdgeInsets.all(cardPadding + 4),
                child: Column(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: budget),
                      duration: const Duration(milliseconds: 1000),
                      builder: (context, value, child) {
                        return Text(
                          "KES ${value.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: screenWidth * .09,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),

                    SizedBox(height: smallSpacing),

                    SizedBox(
                      width: gaugeSize,
                      height: gaugeSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: budget > 0 ? spent / budget : 0,
                            ),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return CircularProgressIndicator(
                                value: value,
                                strokeWidth: 14,
                                strokeCap: StrokeCap.round,
                                backgroundColor: Colors.grey.shade200,
                                color: statusColor,
                              );
                            },
                          ),

                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: percentageUsed),
                            duration: const Duration(milliseconds: 1200),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "${value.toStringAsFixed(0)}%",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: screenWidth * .09,
                                    ),
                                  ),

                                  Text(
                                    "used",
                                    style: TextStyle(
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: sectionSpacing),

                    Divider(),

                    SizedBox(height: sectionSpacing),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.red.shade200,
                                child: const Icon(
                                  Icons.arrow_upward,
                                  color: Colors.red,
                                ),
                              ),

                              const SizedBox(height: 10),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: spent),
                                duration: const Duration(milliseconds: 1000),
                                builder: (context, value, child) {
                                  return Text(
                                    "KES ${value.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: smallSpacing),

                              const Text("Spent"),
                            ],
                          ),
                        ),

                        Expanded(
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.green.shade200,
                                child: const Icon(
                                  Icons.savings,
                                  color: Colors.green,
                                ),
                              ),

                              const SizedBox(height: 10),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: remaining),
                                duration: const Duration(milliseconds: 1000),
                                builder: (context, value, child) {
                                  return Text(
                                    "KES ${value.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  );
                                },
                              ),

                              SizedBox(height: smallSpacing),

                              const Text("Remaining"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: sectionSpacing),

            Text(
              "Budget Breakdown",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: smallSpacing),

            Text(
              "See where your money goes",
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  children: [
                    categoryTotals.isEmpty
                        ? const EmptyState(
                            icon: Icons.pie_chart_outline,
                            title: "No Spending Data",
                            message:
                                "Add some expenses to view category analysis.",
                          )
                        : SizedBox(
                            height: 280,
                            child: SpendingPieChart(
                              categoryTotals: categoryTotals,
                            ),
                          ),
                    if (categoryTotals.isNotEmpty) ...[
                      const SizedBox(height: 20),

                      Divider(color: Colors.grey.shade300),

                      const SizedBox(height: 18),

                      ...categoryTotals.entries.map((entry) {
                        final color =
                            SpendingPieChart.colors[categoryTotals.keys
                                    .toList()
                                    .indexOf(entry.key) %
                                SpendingPieChart.colors.length];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(radius: 7, backgroundColor: color),

                                const SizedBox(width: 14),

                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                Text(
                                  "${((entry.value / spent) * 100).toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Text(
                                  "KES ${entry.value.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: sectionSpacing),

            Text(
              "Spending Analytics",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: smallSpacing),

            Text(
              "Insights from your spending habits",
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),

            SizedBox(height: sectionSpacing),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 30, end: 0),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOut,
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: child,
                );
              },
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: dailySpending.isEmpty
                      ? const EmptyState(
                          icon: Icons.show_chart,
                          title: "No Spending History",
                          message:
                              "Your daily spending trend will appear after recording expenses.",
                        )
                      : SpendingTrendChart(dailySpending: dailySpending),
                ),
              ),
            ),

            SizedBox(height: sectionSpacing),

            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                runSpacing: 8,
                spacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Flexible(
                    child: Text(
                      "Daily Spending",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: smallSpacing),

            TweenAnimationBuilder<double>(
              tween: Tween(begin: 20, end: 0),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOut,
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: Offset(0, offset),
                  child: child,
                );
              },
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: screenHeight * .21,
                          child: AnalyticsCard(
                            icon: Icons.calendar_today_rounded,
                            title: "Highest Day",
                            value:
                                "$highestDay\nKES ${highestDayAmount.toStringAsFixed(0)}",
                            color: colorScheme.primary,
                          ),
                        ),
                      ),

                      SizedBox(width: 12),

                      Expanded(
                        child: SizedBox(
                          height: screenHeight * .21,
                          child: AnalyticsCard(
                            icon: Icons.analytics_rounded,
                            title: "Avg Daily Spending",
                            value: "KES ${averageDaily.toStringAsFixed(0)}",
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: sectionSpacing),

                  SizedBox(
                    height: screenHeight * .21,
                    child: AnalyticsCard(
                      icon: Icons.trending_up_rounded,
                      title: "Projected Month-End Spending",
                      value: "KES ${estimatedMonthEnd.toStringAsFixed(0)}",
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sectionSpacing),

            Text(
              "Financial Health",
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: smallSpacing),

            Text(
              "Your overall money management score",
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
            ),

            SizedBox(height: sectionSpacing),

            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.9, end: 1),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: FinancialHealthCard(
                score: financialScore,
                label: financialLabel,
              ),
            ),

            SizedBox(height: smallSpacing),

            Text(
              "This score is calculated using your budget usage, spending consistency, and savings potential.",
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),

            SizedBox(height: sectionSpacing),

            Text(
              "${percentageUsed.toStringAsFixed(1)}% Used",
              textAlign: TextAlign.center,
            ),

            SizedBox(height: smallSpacing),

            LinearProgressIndicator(
              value: budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0,

              color: percentageUsed >= 100
                  ? colorScheme.primary
                  : percentageUsed >= 80
                  ? colorScheme.primary
                  : colorScheme.primary,
              minHeight: 10,
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              builder: (context, opacity, child) {
                return Opacity(opacity: opacity, child: child);
              },
              child: buildBudgetAlert(),
            ),

            if (categoryAdvice.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb),
                      const SizedBox(width: 10),
                      Expanded(child: Text(categoryAdvice)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
