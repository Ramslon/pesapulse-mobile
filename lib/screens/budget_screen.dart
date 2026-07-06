import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../widgets/budget_stat_card.dart';
import '../widgets/spending_pie_chart.dart';
import '../widgets/spending_trend_chart.dart';
import '../widgets/analytics_card.dart';

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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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

      await ApiService.setBudget(amount);

      await loadBudget();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Budget Overview",
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            "Manage your monthly spending",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),

          const SizedBox(height: 24),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,

            children: [
              BudgetStatCard(
                icon: Icons.trending_up,
                title: "Spent",
                value: "KES ${spent.toStringAsFixed(0)}",
                color: Colors.red,
              ),

              BudgetStatCard(
                icon: Icons.savings,
                title: "Remaining",
                value: "KES ${remaining.toStringAsFixed(0)}",
                color: Colors.green,
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
                color: Colors.blue,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                children: [
                  TextField(
                    controller: budgetController,

                    keyboardType: TextInputType.number,

                    decoration: const InputDecoration(
                      labelText: 'Monthly Budget Amount',
                      prefixText: 'KES ',
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton.icon(
                      onPressed: saveBudget,

                      icon: const Icon(Icons.save),

                      label: const Text('Save Budget'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: budget),
                    duration: const Duration(milliseconds: 1000),
                    builder: (context, value, child) {
                      return Text(
                        "KES ${value.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Monthly Budget",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: 130,
                    height: 130,
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
                              strokeWidth: 10,
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
                            return Text(
                              "${value.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
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

                            const SizedBox(height: 4),

                            const Text("Spent"),
                          ],
                        ),
                      ),

                      Expanded(
                        child: Column(
                          children: [
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

                            const SizedBox(height: 4),

                            const Text("Remaining"),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        backgroundColor: statusColor.withOpacity(.12),

                        side: BorderSide.none,

                        avatar: Icon(
                          Icons.circle,
                          size: 10,
                          color: statusColor,
                        ),

                        label: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      Text(
                        "$daysRemaining days left",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Spending by Category",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 18),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    height: 250,
                    child: SpendingPieChart(categoryTotals: categoryTotals),
                  ),

                  const SizedBox(height: 20),

                  ...categoryTotals.entries.map((entry) {
                    final color =
                        SpendingPieChart.colors[categoryTotals.keys
                                .toList()
                                .indexOf(entry.key) %
                            SpendingPieChart.colors.length];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 6, backgroundColor: color),

                          const SizedBox(width: 12),

                          Expanded(child: Text(entry.key)),

                          Text(
                            "KES ${entry.value.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            "Daily Spending Trend",
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SpendingTrendChart(dailySpending: dailySpending),
            ),
          ),

          const SizedBox(height: 24),

          AnalyticsCard(
            icon: Icons.calendar_today,
            title: "Highest Spending Day",
            value: "$highestDay • KES ${highestDayAmount.toStringAsFixed(0)}",
            color: Colors.red,
          ),

          const SizedBox(height: 12),

          AnalyticsCard(
            icon: Icons.analytics,
            title: "Average Daily Spending",
            value: "KES ${averageDaily.toStringAsFixed(0)}/day",
            color: Colors.blue,
          ),

          const SizedBox(height: 12),

          AnalyticsCard(
            icon: Icons.trending_up,
            title: "Estimated Month-End Spending",
            value: "KES ${estimatedMonthEnd.toStringAsFixed(0)}",
            color: Colors.green,
          ),

          const SizedBox(height: 24),

          Text(
            '${percentageUsed.toStringAsFixed(1)}% Used',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          LinearProgressIndicator(
            value: budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0,

            color: percentageUsed >= 100
                ? Colors.red
                : percentageUsed >= 80
                ? Colors.orange
                : Colors.green,
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
          ),

          if (percentageUsed >= 80)
            Container(
              margin: const EdgeInsets.only(top: 20),

              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          if (budgetStatus == 'critical')
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.dangerous),
                      SizedBox(width: 10),
                      Text(
                        'Critical Budget Alert',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${percentageUsed.toStringAsFixed(1)}% of your budget has been used.',
                  ),
                  const SizedBox(height: 8),
                  Text(recommendation),
                ],
              ),
            ),

          if (budgetStatus == 'warning')
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber),
                      SizedBox(width: 10),
                      Text(
                        'Budget Warning',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${percentageUsed.toStringAsFixed(1)}% of your budget has been used.',
                  ),
                  const SizedBox(height: 8),
                  Text(recommendation),
                ],
              ),
            ),

          if (budgetStatus == 'overspent')
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.error),
                      SizedBox(width: 10),
                      Text(
                        'Budget Exceeded',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'You have spent ${percentageUsed.toStringAsFixed(1)}% of your budget.',
                  ),
                  const SizedBox(height: 8),
                  Text(recommendation),
                ],
              ),
            ),

          if (budgetStatus == 'healthy')
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Budget Healthy',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    '${percentageUsed.toStringAsFixed(1)}% of your budget has been used.',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 8),
                  Text(recommendation, style: TextStyle(color: Colors.white)),
                ],
              ),
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
    );
  }
}
