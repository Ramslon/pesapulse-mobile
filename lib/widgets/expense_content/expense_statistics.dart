import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';
import '../../core/utils/currency_formatter.dart';

class ExpenseStatistics extends StatelessWidget {
  final int categoryCount;
  final double highestExpense;
  final double averageExpense;

  const ExpenseStatistics({
    super.key,
    required this.categoryCount,
    required this.highestExpense,
    required this.averageExpense,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    return Row(
      children: [
        Expanded(
          child: _buildMiniStat(
            context,
            title: "Categories",
            value: categoryCount.toString(),
            valueFontSize: compact ? 12 : 15,
            titleFontSize: compact ? 10 : 12,
          ),
        ),

        Expanded(
          child: _buildMiniStat(
            context,
            title: "Highest",
            value: CurrencyFormatter.format(highestExpense),
            valueFontSize: compact ? 12 : 15,
            titleFontSize: compact ? 10 : 12,
          ),
        ),

        Expanded(
          child: _buildMiniStat(
            context,
            title: "Average",
            value: CurrencyFormatter.format(averageExpense),
            valueFontSize: compact ? 12 : 15,
            titleFontSize: compact ? 10 : 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required String title,
    required String value,
    required double valueFontSize,
    required double titleFontSize,
  }) {
    final spacing = ResponsiveHelper.spacing(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: spacing * 0.25),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: valueFontSize,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: titleFontSize),
          ),
        ],
      ),
    );
  }
}
