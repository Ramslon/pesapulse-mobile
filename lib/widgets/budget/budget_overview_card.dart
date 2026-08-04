import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;

    final cardPadding = screenWidth * 0.05;

    const smallSpacing = 8.0;
    const sectionSpacing = 18.0;

    final currencyFormatter = NumberFormat("#,##0.00");

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: budget),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return Text(
                  "KES ${currencyFormatter.format(value)}",
                  style: TextStyle(
                    fontSize: screenWidth * .075,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),

            SizedBox(height: smallSpacing),

            BudgetProgressGauge(
              budget: budget,
              spent: spent,
              percentageUsed: percentageUsed,
              statusColor: statusColor,
            ),
            SizedBox(height: sectionSpacing),

            Divider(),

            SizedBox(height: sectionSpacing),

            Row(
              children: [
                Expanded(
                  child: BudgetStatItem(
                    icon: Icons.arrow_upward,
                    iconColor: Colors.red,
                    backgroundColor: Colors.red.shade200,
                    title: "Spent",
                    amount: spent,
                  ),
                ),
                Expanded(
                  child: BudgetStatItem(
                    icon: Icons.savings,
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
