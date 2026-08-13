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

    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final spacing = ResponsiveHelper.spacing(context);

    final columns = ResponsiveHelper.gridColumns(
      context,
      mobilePortrait: 2,
      mobileLandscape: 4,
      tabletPortrait: 4,
      tabletLandscape: 4,
      desktop: 4,
    );

    final childAspectRatio = _childAspectRatio(
      context,
      columns: columns,
      compact: compact,
      landscape: landscape,
      tablet: tablet,
      desktop: desktop,
    );

    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
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

  double _childAspectRatio(
    BuildContext context, {
    required int columns,
    required bool compact,
    required bool landscape,
    required bool tablet,
    required bool desktop,
  }) {
    if (desktop) {
      return 2.0;
    }

    if (tablet) {
      return landscape ? 2.1 : 1.6;
    }

    if (landscape) {
      return 1.8;
    }

    if (compact) {
      final width = ResponsiveHelper.width(context);

      if (width < 360) {
        return 1.12;
      }

      if (width < 430) {
        return 1.22;
      }

      return 1.32;
    }

    return 1.35;
  }
}
