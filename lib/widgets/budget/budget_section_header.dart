import 'package:flutter/material.dart';

class BudgetSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool compact;

  const BudgetSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.compact = false,
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
            fontSize: compact ? 18 : 22,
          ),
        ),

        SizedBox(height: compact ? 2 : 6),

        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: compact ? 11 : 14,
            color: theme.colorScheme.onSurface.withOpacity(.7),
          ),
        ),
      ],
    );
  }
}
