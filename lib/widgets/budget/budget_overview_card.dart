import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/responsive_helper.dart';
import 'budget_stat_item.dart';
import 'budget_progress_gauge.dart';

class BudgetOverviewCard extends StatelessWidget {
  final double budget;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final Color statusColor;

  const BudgetOverviewCard({
    super.key,
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final currencyFormatter = NumberFormat("#,##0");

    // Responsive card padding.
    final cardPadding = ResponsiveHelper.cardPadding(context);

    // Keep the gauge proportional without allowing it
    // to become excessively large on tablets/desktop.
    final gaugeSize = compact
        ? 108.0
        : tablet
        ? 140.0
        : desktop
        ? 150.0
        : landscape
        ? 120.0
        : 145.0;

    // Responsive budget amount typography.
    final amountFont = compact
        ? 24.0
        : tablet
        ? 30.0
        : desktop
        ? 32.0
        : landscape
        ? 27.0
        : 30.0;

    final verticalSpacing = compact
        ? 8.0
        : landscape
        ? 10.0
        : 14.0;

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            // ─────────────────────────────────────────
            // Budget Amount
            // ─────────────────────────────────────────
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: budget),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "KES ${currencyFormatter.format(value)}",
                    style: TextStyle(
                      fontSize: amountFont,
                      fontWeight: FontWeight.bold,
                      letterSpacing: .2,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: verticalSpacing),

            // ─────────────────────────────────────────
            // Progress Gauge
            // ─────────────────────────────────────────
            SizedBox(
              width: gaugeSize,
              height: gaugeSize,
              child: BudgetProgressGauge(
                budget: budget,
                spent: spent,
                percentageUsed: percentageUsed,
                statusColor: statusColor,
              ),
            ),

            SizedBox(height: verticalSpacing),

            Divider(thickness: .8, color: theme.dividerColor.withOpacity(.3)),

            SizedBox(height: verticalSpacing),

            // ─────────────────────────────────────────
            // Spending Statistics
            // ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: BudgetStatItem(
                    icon: Icons.arrow_upward_rounded,
                    iconColor: Colors.red,
                    backgroundColor: Colors.red.shade200,
                    title: "Spent",
                    amount: spent,
                  ),
                ),

                SizedBox(width: ResponsiveHelper.spacing(context)),

                Expanded(
                  child: BudgetStatItem(
                    icon: Icons.savings_rounded,
                    iconColor: Colors.green,
                    backgroundColor: Colors.green.shade200,
                    title: "Remaining",
                    amount: remaining,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
