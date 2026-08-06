import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/widgets/budget_alert_card.dart';
import '../widgets/budget/budget_overview_card.dart';
import '../widgets/budget/budget_breakdown_card.dart';
import '../widgets/budget/spending_analytics_section.dart';
import '../widgets/budget/financial_health_section.dart';
import '../widgets/budget/budget_header.dart';
import '../widgets/budget/budget_status_bar.dart';
import '../widgets/empty_state_helper.dart';
import '../widgets/budget_loading_skeleton.dart';
import '../widgets/budget/budget_section_header.dart';
import '../widgets/budget/budget_fab.dart';
import '../widgets/budget_dialog.dart';
import '../widgets/delete_budget_dialog.dart';
import '../repositories/budget_repository.dart';
import '../repositories/financial_insights_repository.dart';
import '../features/budget/controllers/budget_controller.dart';
import '../widgets/budget/budget_app_bar.dart';
import '../widgets/budget/budget_stats_grid.dart';
import '../providers/connectivity_provider.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_spacing.dart';
import '../features/budget/utils/budget_calculator.dart';
import '../features/budget/models/budget_state.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  BudgetScreenState createState() => BudgetScreenState();
}

class BudgetScreenState extends State<BudgetScreen>
    with AutomaticKeepAliveClientMixin {
  final BudgetController controller = BudgetController(
    budgetRepository: BudgetRepository(),
    insightsRepository: FinancialInsightsRepository(),
  );

  BudgetState state = const BudgetState();

  double get percentageUsed =>
      BudgetCalculator.percentageUsed(budget: state.budget, spent: state.spent);

  double get remainingAmount =>
      BudgetCalculator.remaining(budget: state.budget, spent: state.spent);

  int get daysRemaining => BudgetCalculator.daysRemaining();

  Color get statusColor =>
      BudgetCalculator.statusColor(context, state.budgetStatus);

  String get statusText => BudgetCalculator.statusText(state.budgetStatus);

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
      final newState = await controller.loadAll();

      if (!mounted) return;

      setState(() {
        state = newState;
        budgetController.text = state.budget.toStringAsFixed(0);
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        state = state.copyWith(isLoading: false, hasCachedBudget: false);
      });
    }
  }

  Future<void> saveBudget() async {
    final network = context.read<ConnectivityProvider>();

    network.setSyncing(true);

    try {
      if (budgetController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a budget amount")),
        );
        return;
      }

      final amount = double.parse(budgetController.text.trim());

      if (amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Budget must be greater than zero")),
        );
        return;
      }

      final bool isUpdate = state.budget > 0;

      final newState = await controller.saveBudget(amount: amount);

      if (!mounted) return;

      setState(() {
        state = newState;
        budgetController.text = state.budget.toStringAsFixed(0);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUpdate
                ? "Budget updated successfully"
                : "Budget created successfully",
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to save budget.")));
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
      final newState = await controller.deleteBudget();

      if (!mounted) return;

      setState(() {
        state = newState;
        budgetController.clear();
      });

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
      builder: (_) => const DeleteBudgetDialog(),
    );

    if (shouldDelete == true) {
      await deleteBudget();
    }
  }

  Future<void> showCreateBudgetDialog() async {
    budgetController.text = state.budget > 0
        ? state.budget.toStringAsFixed(0)
        : '';

    await showDialog(
      context: context,
      builder: (_) => BudgetDialog(
        controller: budgetController,
        hasBudget: state.budget > 0,
        isSyncing: context.read<ConnectivityProvider>().isSyncing,
        onSave: saveBudget,
        onDelete: confirmDeleteBudget,
      ),
    );
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    final sectionSpacing = isLandscape ? 18.0 : screenHeight * 0.035;

    final horizontalSpacing = isLandscape ? 20.0 : 16.0;

    final network = context.watch<ConnectivityProvider>();
    if (state.isLoading) {
      return const BudgetLoadingSkeleton();
    }
    if (state.budget <= 0) {
      return Center(
        child: buildEmptyState(
          context,
          EmptyStateType.budget,
          isOnline: network.isOnline,
          isGuest: state.isGuest,
          refreshBudgetData: refreshBudgetData,
          showCreateBudgetDialog: showCreateBudgetDialog,
        ),
      );
    }

    // replace with your chart widget

    return Scaffold(
      appBar: const BudgetAppBar(),
      floatingActionButton: BudgetFAB(
        hasBudget: state.budget > 0,
        onPressed: showCreateBudgetDialog,
      ),
      body: RefreshIndicator(
        onRefresh: refreshBudgetData,

        child: SingleChildScrollView(
          key: const PageStorageKey("budget"),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isLandscape ? 32 : screenWidth * .05,
            vertical: isLandscape ? 16 : screenHeight * .025,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: sectionSpacing),

              const BudgetHeader(),

              SizedBox(height: sectionSpacing),

              BudgetStatsGrid(
                spent: state.spent,
                remaining: remainingAmount,
                percentageUsed: percentageUsed,
                daysRemaining: daysRemaining,
                statusColor: statusColor,
                isLandscape: isLandscape,
              ),
              SizedBox(height: sectionSpacing),

              BudgetStatusBar(statusText: statusText, statusColor: statusColor),

              SizedBox(height: sectionSpacing),

              const BudgetSectionHeader(
                title: "Monthly Budget Overview",
                subtitle: "Track your monthly spending and stay within budget",
              ),

              AppSpacing.hSm,

              if (isLandscape)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: BudgetOverviewCard(
                        budget: state.budget,
                        spent: state.spent,
                        remaining: remainingAmount,
                        percentageUsed: percentageUsed,
                        statusColor: statusColor,
                        isLandscape: isLandscape,
                      ),
                    ),

                    const SizedBox(width: 20),

                    Expanded(
                      flex: 6,
                      child: BudgetBreakdownCard(
                        categoryTotals: state.categoryTotals,
                        totalSpent: state.spent,
                        isLandscape: isLandscape,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    BudgetOverviewCard(
                      budget: state.budget,
                      spent: state.spent,
                      remaining: remainingAmount,
                      percentageUsed: percentageUsed,
                      statusColor: statusColor,
                      isLandscape: isLandscape,
                    ),

                    SizedBox(height: sectionSpacing),

                    BudgetBreakdownCard(
                      categoryTotals: state.categoryTotals,
                      totalSpent: state.spent,
                      isLandscape: isLandscape,
                    ),
                  ],
                ),

              SizedBox(height: sectionSpacing),

              if (isLandscape)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: SpendingAnalyticsSection(
                        dailySpending: state.dailySpending,
                        highestDay: state.highestDay,
                        highestDayAmount: state.highestDayAmount,
                        averageDaily: state.averageDaily,
                        estimatedMonthEnd: state.estimatedMonthEnd,
                      ),
                    ),

                    const SizedBox(width: 20),

                    Expanded(
                      flex: 5,
                      child: FinancialHealthSection(
                        financialScore: state.financialScore,
                        financialLabel: state.financialLabel,
                        percentageUsed: percentageUsed,
                        budget: state.budget,
                        spent: state.spent,
                        budgetAlert: BudgetAlertCard(
                          budgetStatus: state.budgetStatus,
                          budget: state.budget,
                          percentageUsed: percentageUsed,
                          recommendation: state.recommendation,
                        ),
                        categoryAdvice: state.categoryAdvice,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    SpendingAnalyticsSection(
                      dailySpending: state.dailySpending,
                      highestDay: state.highestDay,
                      highestDayAmount: state.highestDayAmount,
                      averageDaily: state.averageDaily,
                      estimatedMonthEnd: state.estimatedMonthEnd,
                    ),

                    SizedBox(height: sectionSpacing),

                    FinancialHealthSection(
                      financialScore: state.financialScore,
                      financialLabel: state.financialLabel,
                      percentageUsed: percentageUsed,
                      budget: state.budget,
                      spent: state.spent,
                      budgetAlert: BudgetAlertCard(
                        budgetStatus: state.budgetStatus,
                        budget: state.budget,
                        percentageUsed: percentageUsed,
                        recommendation: state.recommendation,
                      ),
                      categoryAdvice: state.categoryAdvice,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
