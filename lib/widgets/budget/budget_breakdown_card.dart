import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';
import '../../widgets/spending_pie_chart.dart';
import '../../screens/add_expense_screen.dart';
import '../../utils/responsive_helper.dart';

import 'budget_category_tile.dart';
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

    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BudgetSectionHeader(
          title: "Budget Breakdown",
          subtitle: "See where your money goes",
        ),

        SizedBox(
          height: compact
              ? 14
              : tablet
              ? 18
              : 20,
        ),

        Card(
          elevation: 0,
          color: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              compact
                  ? 16
                  : tablet
                  ? 18
                  : 20,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: _buildContent(
              context,
              compact: compact,
              tablet: tablet,
              desktop: desktop,
              landscape: landscape,
              sectionSpacing: sectionSpacing,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
    required double sectionSpacing,
  }) {
    if (categoryTotals.isEmpty) {
      return _buildEmptyState(context, compact: compact, tablet: tablet);
    }

    return Column(
      children: [
        SizedBox(
          height: _chartHeight(
            compact: compact,
            tablet: tablet,
            desktop: desktop,
            landscape: landscape,
          ),
          width: double.infinity,
          child: SpendingPieChart(categoryTotals: categoryTotals),
        ),

        SizedBox(height: compact ? 14 : 20),

        Divider(height: 1, color: Colors.grey.shade300),

        SizedBox(height: compact ? 14 : 18),

        ..._buildCategoryTiles(context),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required bool compact,
    required bool tablet,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: compact
            ? 10
            : tablet
            ? 16
            : 20,
      ),
      child: EmptyState(
        icon: Icons.pie_chart_outline,
        title: "No Spending Data",
        message: "Add some expenses to view category analysis.",
        action: ElevatedButton.icon(
          icon: Icon(Icons.receipt_long, size: compact ? 18 : 20),
          label: Text(
            "Add Expense",
            style: TextStyle(fontSize: compact ? 13 : 14),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            );
          },
        ),
      ),
    );
  }

  double _chartHeight({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    if (desktop) {
      return landscape ? 230 : 270;
    }

    if (tablet) {
      return landscape ? 190 : 250;
    }

    if (compact) {
      return landscape ? 160 : 210;
    }

    return landscape ? 170 : 240;
  }

  List<Widget> _buildCategoryTiles(BuildContext context) {
    final categories = categoryTotals.entries.toList();

    return [
      for (int index = 0; index < categories.length; index++)
        BudgetCategoryTile(
          category: categories[index].key,
          amount: categories[index].value,
          totalSpent: totalSpent,
          color:
              SpendingPieChart.colors[index % SpendingPieChart.colors.length],
        ),
    ];
  }
}
