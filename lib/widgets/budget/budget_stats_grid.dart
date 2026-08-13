import 'package:flutter/material.dart';

import '../budget_stat_card.dart';
import '../../features/budget/utils/budget_calculator.dart';
import '../../utils/responsive_helper.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    final spacing = ResponsiveHelper.spacing(context);

    final columns = ResponsiveHelper.gridColumns(
      context,
      mobilePortrait: 2,
      mobileLandscape: 4,
      tabletPortrait: 4,
      tabletLandscape: 4,
      desktop: 4,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: itemWidth,
              child: BudgetStatCard(
                icon: Icons.trending_up,
                title: "Spent",
                value: BudgetCalculator.formatCurrency(spent),
                color: colorScheme.primary,
              ),
            ),

            SizedBox(
              width: itemWidth,
              child: BudgetStatCard(
                icon: Icons.savings,
                title: "Remaining",
                value: BudgetCalculator.formatCurrency(remaining),
                color: colorScheme.primary,
              ),
            ),

            SizedBox(
              width: itemWidth,
              child: BudgetStatCard(
                icon: Icons.pie_chart,
                title: "Usage",
                value: "${percentageUsed.toStringAsFixed(0)}%",
                color: statusColor,
              ),
            ),

            SizedBox(
              width: itemWidth,
              child: BudgetStatCard(
                icon: Icons.calendar_today,
                title: "Days Left",
                value: "$daysRemaining",
                color: colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }

  double _childAspectRatio(
    BuildContext context, {
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return 2.2;
    }

    if (tablet) {
      return landscape ? 2.4 : 1.8;
    }

    if (landscape) {
      return 2.0;
    }

    if (compact) {
      final width = ResponsiveHelper.width(context);

      if (width < 360) {
        return 1.20;
      }

      if (width < 430) {
        return 1.30;
      }

      return 1.40;
    }

    return 1.45;
  }
}
