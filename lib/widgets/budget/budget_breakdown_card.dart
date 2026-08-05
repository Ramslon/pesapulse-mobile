import 'package:flutter/material.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/spending_pie_chart.dart';

import 'budget_category_tile.dart';
import '../../screens/add_expense_screen.dart';
import '../../core/constants/app_spacing.dart';
import 'budget_section_header.dart';

class BudgetBreakdownCard extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double totalSpent;

  const BudgetBreakdownCard({
    super.key,
    required this.categoryTotals,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BudgetSectionHeader(
          title: "Budget Breakdown",
          subtitle: "See where your money goes",
        ),

        const SizedBox(height: 20),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: AppSpacing.cardPadding,
            child: _buildContent(context, colorScheme),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    const double cardPadding = 20;
    return Padding(
      padding: EdgeInsets.all(cardPadding),
      child: Column(
        children: [
          categoryTotals.isEmpty
              ? EmptyState(
                  icon: Icons.pie_chart_outline,
                  title: "No Spending Data",
                  message: "Add some expenses to view category analysis.",
                  action: ElevatedButton.icon(
                    icon: const Icon(Icons.receipt_long),
                    label: const Text("Add Expense"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddExpenseScreen(),
                        ),
                      );
                    },
                  ),
                )
              // replace with your chart widget
              : SizedBox(
                  height: 280,
                  child: SpendingPieChart(categoryTotals: categoryTotals),
                ),
          if (categoryTotals.isNotEmpty) ...[
            const SizedBox(height: 20),

            Divider(color: Colors.grey.shade300),

            const SizedBox(height: 18),

            ...categoryTotals.entries.map((entry) {
              final color =
                  SpendingPieChart.colors[categoryTotals.keys.toList().indexOf(
                        entry.key,
                      ) %
                      SpendingPieChart.colors.length];

              return BudgetCategoryTile(
                category: entry.key,
                amount: entry.value,
                totalSpent: totalSpent,
                color: color,
              );
            }),
          ],
        ],
      ),
    );
  }
}
