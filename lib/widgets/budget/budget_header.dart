import 'package:flutter/material.dart';

class BudgetHeader extends StatelessWidget {
  const BudgetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final compact = MediaQuery.of(context).orientation == Orientation.landscape;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Budget Overview",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: .3,
            fontSize: compact ? 22 : 30,
          ),
        ),

        SizedBox(height: compact ? 2 : 8),

        Text(
          "Track your spending and stay within budget",
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(.7),
            fontSize: compact ? 12 : 15,
            height: compact ? 1.15 : 1.35,
          ),
        ),
      ],
    );
  }
}
