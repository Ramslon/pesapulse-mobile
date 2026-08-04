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

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 10,
      spacing: 12,
      children: [
        Text(
          "Monthly Budget",
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(.7),
            fontWeight: FontWeight.w600,
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(.12),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            statusText,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
