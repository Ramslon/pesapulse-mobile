import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/responsive_helper.dart';

class BudgetCategoryTile extends StatelessWidget {
  final String category;
  final double amount;
  final double totalSpent;
  final Color color;

  const BudgetCategoryTile({
    super.key,
    required this.category,
    required this.amount,
    required this.totalSpent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0");

    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final percentage = totalSpent <= 0 ? 0.0 : (amount / totalSpent) * 100;

    final horizontalPadding = compact
        ? 10.0
        : tablet
        ? 14.0
        : desktop
        ? 16.0
        : 14.0;

    final verticalPadding = compact
        ? 9.0
        : landscape
        ? 9.0
        : tablet
        ? 11.0
        : 12.0;

    final fontSize = compact
        ? 13.0
        : tablet
        ? 14.0
        : desktop
        ? 15.0
        : 15.0;

    final categorySpacing = compact ? 8.0 : 12.0;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(compact ? 12 : 14),
          border: Border.all(color: color.withOpacity(.08)),
        ),
        child: Row(
          children: [
            // Category indicator
            Container(
              width: compact ? 10 : 12,
              height: compact ? 10 : 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),

            SizedBox(width: categorySpacing),

            // Category name
            Expanded(
              child: Text(
                category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: fontSize,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Percentage
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 7 : 9,
                vertical: compact ? 4 : 5,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "${percentage.toStringAsFixed(0)}%",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 12 : 13,
                ),
              ),
            ),

            SizedBox(width: compact ? 7 : 10),

            // Amount
            Flexible(
              child: Text(
                "KES ${formatter.format(amount)}",
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
