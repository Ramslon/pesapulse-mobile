import 'package:flutter/material.dart';

class BudgetSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const BudgetSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: .3,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(.7),
          ),
        ),
      ],
    );
  }
}
