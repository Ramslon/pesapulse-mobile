import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

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
    final spacing = ResponsiveHelper.spacing(context);

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
            value: "KES ${_formatAmount(highestExpense)}",
            valueFontSize: compact ? 12 : 15,
            titleFontSize: compact ? 10 : 12,
          ),
        ),

        Expanded(
          child: _buildMiniStat(
            context,
            title: "Average",
            value: "KES ${_formatAmount(averageExpense)}",
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

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(2)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  }
}
