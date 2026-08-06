import 'package:flutter/material.dart';

class BudgetStatusBar extends StatelessWidget {
  final String statusText;
  final Color statusColor;

  const BudgetStatusBar({
    super.key,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final compact = MediaQuery.of(context).orientation == Orientation.landscape;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: compact ? 4 : 10,
      spacing: compact ? 8 : 12,
      children: [
        Text(
          "Monthly Budget",
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(.7),
            fontWeight: FontWeight.w600,
            fontSize: compact ? 13 : 15,
          ),
        ),

        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(.12),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 12 : 14,
            ),
          ),
        ),
      ],
    );
  }
}
