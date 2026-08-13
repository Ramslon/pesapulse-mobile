import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

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

    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final titleSize = compact
        ? 18.0
        : tablet
        ? 21.0
        : desktop
        ? 22.0
        : landscape
        ? 19.0
        : 22.0;

    final subtitleSize = compact
        ? 12.0
        : tablet
        ? 13.0
        : desktop
        ? 14.0
        : landscape
        ? 12.0
        : 14.0;

    final spacing = compact
        ? 3.0
        : landscape
        ? 4.0
        : 6.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: titleSize,
            height: 1.2,
          ),
        ),

        SizedBox(height: spacing),

        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: subtitleSize,
            color: theme.colorScheme.onSurface.withOpacity(.68),
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
