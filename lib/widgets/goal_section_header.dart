import 'package:flutter/material.dart';

class GoalSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const GoalSectionHeader({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 21),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -.2,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
