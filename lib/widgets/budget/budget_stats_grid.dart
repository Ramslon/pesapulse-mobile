import 'package:flutter/material.dart';

import '../budget_stat_card.dart';
import '../../features/budget/utils/budget_calculator.dart';

class BudgetStatsGrid extends StatelessWidget {
  final double spent;
  final double remaining;
  final double percentageUsed;
  final int daysRemaining;
  final Color statusColor;

  const BudgetStatsGrid({
    super.key,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.daysRemaining,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final colorScheme = Theme.of(context).colorScheme;

    return GridView.count(
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
          value: BudgetCalculator.formatCurrency(spent),
          color: colorScheme.primary,
        ),
        BudgetStatCard(
          icon: Icons.savings,
          title: "Remaining",
          value: BudgetCalculator.formatCurrency(remaining),
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
    );
  }
}
