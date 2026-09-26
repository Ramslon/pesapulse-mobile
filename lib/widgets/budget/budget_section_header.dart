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
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final titleSize = desktop
        ? 21.0
        : tablet
        ? 19.0
        : compact
        ? 16.0
        : landscape
        ? 17.0
        : 19.0;

    final subtitleSize = desktop
        ? 12.5
        : tablet
        ? 12.0
        : compact
        ? 10.5
        : landscape
        ? 10.5
        : 11.5;

    final overlineSize = desktop
        ? 9.0
        : compact
        ? 7.5
        : 8.0;

    final accentWidth = desktop
        ? 4.0
        : compact
        ? 3.0
        : 3.5;

    final accentHeight = desktop
        ? 48.0
        : compact
        ? 39.0
        : landscape
        ? 42.0
        : 45.0;

    final titleSubtitleSpacing = compact
        ? 4.0
        : landscape
        ? 4.0
        : 5.0;

    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: accentWidth,
            height: accentHeight,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          SizedBox(width: compact ? 9 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BUDGET',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.primary.withOpacity(0.78),
                    fontSize: overlineSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    height: 1.0,
                  ),
                ),

                SizedBox(height: compact ? 4 : 5),

                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                    fontSize: titleSize,
                    height: 1.12,
                    letterSpacing: -0.25,
                  ),
                ),

                SizedBox(height: titleSubtitleSpacing),

                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.70),
                    fontSize: subtitleSize,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            width: compact ? 7 : 8,
            height: compact ? 7 : 8,
            margin: EdgeInsets.only(top: compact ? 3 : 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.65),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
