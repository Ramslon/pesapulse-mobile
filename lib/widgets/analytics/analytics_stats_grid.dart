import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class AnalyticsStatsGrid extends StatelessWidget {
  final int totalGoals;
  final int completedGoals;
  final int activeGoals;
  final double completionRate;

  const AnalyticsStatsGrid({
    super.key,
    required this.totalGoals,
    required this.completedGoals,
    required this.activeGoals,
    required this.completionRate,
  });

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double cardPadding,
    required double iconSize,
    required double iconBoxSize,
    required double valueSize,
    required double titleSize,
    required double spacing,
    required double radius,
    required bool compact,
    required bool landscape,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: compact ? 1 : 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ─────────────────────────────────────
            // Icon
            // ─────────────────────────────────────
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: iconSize),
            ),

            SizedBox(height: spacing),

            // ─────────────────────────────────────
            // Value
            // ─────────────────────────────────────
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontSize: valueSize,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            SizedBox(height: landscape ? 3 : 5),

            // ─────────────────────────────────────
            // Title
            // ─────────────────────────────────────
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: titleSize,
                color: colorScheme.onSurface.withOpacity(.60),
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final spacing = ResponsiveHelper.spacing(context);

    // ─────────────────────────────────────────────
    // Responsive card height
    // ─────────────────────────────────────────────
    final cardHeight = desktop
        ? 155.0
        : tablet
        ? (landscape ? 118.0 : 145.0)
        : landscape
        ? 104.0
        : compact
        ? 105.0
        : 125.0;

    // ─────────────────────────────────────────────
    // Responsive padding
    // ─────────────────────────────────────────────
    final cardPadding = desktop
        ? 22.0
        : tablet
        ? (landscape ? 10.0 : 18.0)
        : landscape
        ? 8.0
        : compact
        ? 10.0
        : 16.0;

    // ─────────────────────────────────────────────
    // Responsive icon
    // ─────────────────────────────────────────────
    final iconBoxSize = desktop
        ? 50.0
        : tablet
        ? (landscape ? 38.0 : 46.0)
        : landscape
        ? 30.0
        : compact
        ? 32.0
        : 44.0;

    final iconSize = desktop
        ? 27.0
        : tablet
        ? (landscape ? 21.0 : 25.0)
        : landscape
        ? 17.0
        : compact
        ? 17.0
        : 23.0;

    // ─────────────────────────────────────────────
    // Responsive value text
    // ─────────────────────────────────────────────
    final valueSize = desktop
        ? 28.0
        : tablet
        ? (landscape ? 21.0 : 25.0)
        : landscape
        ? 17.0
        : compact
        ? 18.0
        : 22.0;

    // ─────────────────────────────────────────────
    // Responsive title
    // ─────────────────────────────────────────────
    final titleSize = desktop
        ? 14.0
        : tablet
        ? (landscape ? 11.0 : 13.0)
        : landscape
        ? 9.5
        : compact
        ? 10.0
        : 12.0;

    final cardRadius = compact ? 15.0 : 22.0;

    // Keep vertical spacing small in landscape
    // to prevent card content from overflowing.
    final iconSpacing = desktop
        ? 12.0
        : tablet
        ? (landscape ? 5.0 : 12.0)
        : landscape
        ? 5.0
        : compact
        ? 7.0
        : 12.0;

    return Column(
      children: [
        // ─────────────────────────────────────────
        // Row 1
        // ─────────────────────────────────────────
        SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Goals',
                  value: totalGoals.toString(),
                  icon: Icons.flag_rounded,
                  color: Colors.indigo,
                  cardPadding: cardPadding,
                  iconSize: iconSize,
                  iconBoxSize: iconBoxSize,
                  valueSize: valueSize,
                  titleSize: titleSize,
                  spacing: iconSpacing,
                  radius: cardRadius,
                  compact: compact,
                  landscape: landscape,
                ),
              ),

              SizedBox(width: spacing),

              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Completed',
                  value: completedGoals.toString(),
                  icon: Icons.emoji_events_rounded,
                  color: Colors.green,
                  cardPadding: cardPadding,
                  iconSize: iconSize,
                  iconBoxSize: iconBoxSize,
                  valueSize: valueSize,
                  titleSize: titleSize,
                  spacing: iconSpacing,
                  radius: cardRadius,
                  compact: compact,
                  landscape: landscape,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: spacing),

        // ─────────────────────────────────────────
        // Row 2
        // ─────────────────────────────────────────
        SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Active',
                  value: activeGoals.toString(),
                  icon: Icons.track_changes_rounded,
                  color: Colors.orange,
                  cardPadding: cardPadding,
                  iconSize: iconSize,
                  iconBoxSize: iconBoxSize,
                  valueSize: valueSize,
                  titleSize: titleSize,
                  spacing: iconSpacing,
                  radius: cardRadius,
                  compact: compact,
                  landscape: landscape,
                ),
              ),

              SizedBox(width: spacing),

              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Completion Rate',
                  value: '${completionRate.toStringAsFixed(0)}%',
                  icon: Icons.trending_up_rounded,
                  color: Colors.blue,
                  cardPadding: cardPadding,
                  iconSize: iconSize,
                  iconBoxSize: iconBoxSize,
                  valueSize: valueSize,
                  titleSize: titleSize,
                  spacing: iconSpacing,
                  radius: cardRadius,
                  compact: compact,
                  landscape: landscape,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
