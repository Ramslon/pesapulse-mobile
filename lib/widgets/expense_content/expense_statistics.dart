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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildMiniStat(
            context,
            title: 'Categories',
            value: categoryCount.toString(),
            icon: Icons.category_outlined,
            color: Colors.indigo,
          ),
        ),

        _buildDivider(context),

        Expanded(
          child: _buildMiniStat(
            context,
            title: 'Highest',
            value: CurrencyFormatter.format(highestExpense),
            icon: Icons.arrow_upward_rounded,
            color: Colors.red,
          ),
        ),

        _buildDivider(context),

        Expanded(
          child: _buildMiniStat(
            context,
            title: 'Average',
            value: CurrencyFormatter.format(averageExpense),
            icon: Icons.show_chart_rounded,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final titleSize = compact ? 9.5 : 10.5;
    final valueSize = compact ? 12.0 : 13.5;
    final iconSize = compact ? 14.0 : 15.5;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 27 : 30,
            height: compact ? 27 : 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.09),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: iconSize),
          ),

          const SizedBox(height: 6),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: valueSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
          ),

          const SizedBox(height: 3),

          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 5),
      color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
    );
  }
}
