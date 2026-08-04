import 'package:flutter/material.dart';

class BudgetHeader extends StatelessWidget {
  const BudgetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Budget Overview",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: .3,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          "Track your spending and stay within budget",
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withOpacity(.7),
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
