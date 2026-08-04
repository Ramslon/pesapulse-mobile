import 'package:flutter/material.dart';

import '../widgets/budget_stat_card.dart';
import '../widgets/budget/budget_overview_card.dart';
import '../widgets/budget/budget_breakdown_card.dart';
import '../widgets/budget/spending_analytics_section.dart';
import '../widgets/budget/financial_health_section.dart';
import '../widgets/budget/budget_header.dart';
import '../widgets/budget/budget_status_bar.dart';
import '../widgets/status_chip.dart';
import '../widgets/empty_state_helper.dart';
import '../widgets/budget_loading_skeleton.dart';
import '../widgets/sync_status_icon.dart';
import '../widgets/offline_banner.dart';
import '../repositories/budget_repository.dart';
import '../repositories/financial_insights_repository.dart';
import '../providers/connectivity_provider.dart';
import 'package:provider/provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  BudgetScreenState createState() => BudgetScreenState();
}

class BudgetScreenState extends State<BudgetScreen>
    with AutomaticKeepAliveClientMixin {
  bool isLoading = true;

  bool isGuest = false;
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

  final BudgetRepository budgetRepository = BudgetRepository();
  final FinancialInsightsRepository insightsRepository =
      FinancialInsightsRepository();

  bool hasCachedBudget = true;

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

  Future<void> refreshBudget() async {
    await loadBudget();
  }

  Future<void> loadBudget() async {
    try {
      final data = await budgetRepository.getBudgetSummary();

      if (!mounted) return;

      setState(() {
        hasCachedBudget = true;

        budget = double.tryParse(data['budget'].toString()) ?? 0;
        budgetController.text = budget.toStringAsFixed(0);

        spent = double.tryParse(data['spent'].toString()) ?? 0;
        remaining = double.tryParse(data['remaining'].toString()) ?? 0;

        isLoading = false;
      });

      // Load the expensive data AFTER the screen is visible
      _loadInsights();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasCachedBudget = false;
      });
    }
  }

  Future<void> _loadInsights() async {
    try {
      final insights = await insightsRepository.getInsights();

      if (!mounted) return;

      setState(() {
        budgetStatus = insights['budget_status'] ?? 'healthy';

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
      });
    } catch (_) {
      // Keep budget visible even if insights fail
    }
  }

  Future<void> saveBudget() async {
    final network = context.read<ConnectivityProvider>();

    network.setSyncing(true);

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

      await budgetRepository.saveBudget(amount);

      // Immediately update the UI
      setState(() {
        budget = amount;

        budgetController.text = amount.toStringAsFixed(0);

        remaining = amount - spent;
      });

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

      // Refresh in the background to ensure everything stays consistent
      await loadBudget();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to save budget. Please try again."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      network.setSyncing(false);
    }
  }

  Future<void> refreshBudgetData() async {
    final network = context.read<ConnectivityProvider>();

    if (!network.isOnline) {
      await loadBudget();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Offline mode • Showing cached budget data."),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }
  }

  Future<void> deleteBudget() async {
    try {
      await budgetRepository.deleteBudget();

      setState(() {
        budget = 0;

        spent = 0;

        remaining = 0;

        budgetController.clear();

        budgetStatus = "healthy";

        recommendation = "";

        categoryAdvice = "";

        categoryTotals.clear();

        dailySpending.clear();

        highestDay = "";

        highestDayAmount = 0;

        averageDaily = 0;

        estimatedMonthEnd = 0;

        financialScore = 0;

        financialLabel = "";
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
                  await confirmDeleteBudget();
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text("Delete"),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            Consumer<ConnectivityProvider>(
              builder: (context, network, child) {
                return ElevatedButton.icon(
                  onPressed: network.isSyncing
                      ? null
                      : () async {
                          await saveBudget();

                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },

                  icon: network.isSyncing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(budget > 0 ? Icons.edit : Icons.save),

                  label: Text(
                    network.isSyncing
                        ? "Saving..."
                        : (budget > 0 ? "Update" : "Save"),
                  ),
                );
              },
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
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final sectionSpacing = screenHeight * 0.035;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final network = context.watch<ConnectivityProvider>();
    if (isLoading) {
      return const BudgetLoadingSkeleton();
    }
    if (budget <= 0) {
      return Center(
        child: buildEmptyState(
          context,
          EmptyStateType.budget,
          isOnline: network.isOnline,
          isGuest: isGuest,
          refreshBudgetData: refreshBudgetData,
          showCreateBudgetDialog: showCreateBudgetDialog,
        ),
      );
    }

    // replace with your chart widget

    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SyncStatusIcon(), //  quick glance sync state
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: OfflineBanner(), //  pinned under AppBar
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "budgetFab",
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: showCreateBudgetDialog,
        icon: Icon(budget > 0 ? Icons.edit_rounded : Icons.add_rounded),
        label: Text(budget > 0 ? "Edit Budget" : "Create Budget"),
      ),
      body: RefreshIndicator(
        onRefresh: refreshBudgetData,

        child: SingleChildScrollView(
          key: const PageStorageKey("budget"),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * .05,
            vertical: screenHeight * .025,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: sectionSpacing),

              const BudgetHeader(),

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

              BudgetStatusBar(statusText: statusText, statusColor: statusColor),

              BudgetOverviewCard(
                budget: budget,
                spent: spent,
                remaining: remaining,
                percentageUsed: percentageUsed,
                statusColor: statusColor,
              ),

              SizedBox(height: sectionSpacing),

              BudgetBreakdownCard(
                categoryTotals: categoryTotals,
                totalSpent: spent,
              ),

              SizedBox(height: sectionSpacing),

              SpendingAnalyticsSection(
                dailySpending: dailySpending,
                highestDay: highestDay,
                highestDayAmount: highestDayAmount,
                averageDaily: averageDaily,
                estimatedMonthEnd: estimatedMonthEnd,
              ),

              SizedBox(height: sectionSpacing),

              FinancialHealthSection(
                financialScore: financialScore,
                financialLabel: financialLabel,
                percentageUsed: percentageUsed,
                budget: budget,
                spent: spent,
                budgetAlert: buildBudgetAlert(),
                categoryAdvice: categoryAdvice,
              ),
            ],
          ),
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
