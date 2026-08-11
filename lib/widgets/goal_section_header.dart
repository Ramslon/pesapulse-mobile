import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class GoalSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const GoalSectionHeader({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    final iconBoxSize = isCompact
        ? 38.0
        : isLandscape
        ? 40.0
        : 42.0;

    final iconSize = isCompact
        ? 19.0
        : isLandscape
        ? 20.0
        : 21.0;

    final spacing = isCompact ? 10.0 : 12.0;

    return Row(
      children: [
        // ─────────────────────────────────────────
        // Section icon
        // ─────────────────────────────────────────
        Container(
          width: iconBoxSize,
          height: iconBoxSize,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(isCompact ? 11 : 13),
          ),
          child: Icon(icon, color: colorScheme.primary, size: iconSize),
        ),

        SizedBox(width: spacing),

        // ─────────────────────────────────────────
        // Section title
        // ─────────────────────────────────────────
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -.2,
              color: colorScheme.onSurface,
              fontSize: isCompact ? 15 : null,
            ),
          ),
        ),
      ],
    );
  }
}
