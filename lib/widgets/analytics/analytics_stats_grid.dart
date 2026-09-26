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
    required double radius,
    required bool compact,
    required bool desktop,
    required bool highlight,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.96, end: 1.0),
      builder: (_, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: highlight
                ? color.withOpacity(0.16)
                : colorScheme.outline.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(
                highlight
                    ? 0.10
                    : theme.brightness == Brightness.dark
                    ? 0.055
                    : 0.035,
              ),
              blurRadius: desktop ? 18 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: iconBoxSize,
                    height: iconBoxSize,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(compact ? 10 : 12),
                      border: Border.all(color: color.withOpacity(0.10)),
                    ),
                    child: Icon(icon, color: color, size: iconSize),
                  ),

                  const Spacer(),

                  Container(
                    width: compact ? 5 : 6,
                    height: compact ? 5 : 6,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.70),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),

              SizedBox(
                height: compact
                    ? 8
                    : desktop
                    ? 12
                    : 10,
              ),

              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.70),
                  fontSize: titleSize,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  letterSpacing: 0.05,
                ),
              ),

              SizedBox(
                height: compact
                    ? 5
                    : desktop
                    ? 8
                    : 6,
              ),

              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        color: highlight ? color : colorScheme.onSurface,
                        fontSize: valueSize,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(
                height: compact
                    ? 7
                    : desktop
                    ? 11
                    : 9,
              ),

              Container(
                width: highlight
                    ? desktop
                          ? 42
                          : 34
                    : desktop
                    ? 32
                    : 27,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
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

    final cardHeight = desktop
        ? 152.0
        : tablet
        ? (landscape ? 118.0 : 142.0)
        : landscape
        ? 104.0
        : compact
        ? 104.0
        : 124.0;

    final cardPadding = desktop
        ? 18.0
        : tablet
        ? (landscape ? 11.0 : 16.0)
        : landscape
        ? 8.0
        : compact
        ? 10.0
        : 14.0;

    final iconBoxSize = desktop
        ? 46.0
        : tablet
        ? (landscape ? 38.0 : 43.0)
        : landscape
        ? 30.0
        : compact
        ? 32.0
        : 40.0;

    final iconSize = desktop
        ? 24.0
        : tablet
        ? (landscape ? 20.0 : 23.0)
        : landscape
        ? 17.0
        : compact
        ? 17.0
        : 21.0;

    final valueSize = desktop
        ? 29.0
        : tablet
        ? (landscape ? 21.0 : 26.0)
        : landscape
        ? 18.0
        : compact
        ? 19.0
        : 23.0;

    final titleSize = desktop
        ? 12.5
        : tablet
        ? (landscape ? 10.5 : 12.0)
        : landscape
        ? 9.5
        : compact
        ? 10.0
        : 11.5;

    final radius = desktop
        ? 21.0
        : tablet
        ? 19.0
        : compact
        ? 15.0
        : 18.0;

    return Column(
      children: [
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
                  color: const Color(0xFF6366F1),
                  cardPadding: cardPadding,
                  iconSize: iconSize,
                  iconBoxSize: iconBoxSize,
                  valueSize: valueSize,
                  titleSize: titleSize,
                  radius: radius,
                  compact: compact,
                  desktop: desktop,
                  highlight: false,
                ),
              ),

              SizedBox(width: spacing),

              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Completed',
                  value: completedGoals.toString(),
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFF16A34A),
                  cardPadding: cardPadding,
                  iconSize: iconSize,
                  iconBoxSize: iconBoxSize,
                  valueSize: valueSize,
                  titleSize: titleSize,
                  radius: radius,
                  compact: compact,
                  desktop: desktop,
                  highlight: false,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: spacing),

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
                  color: const Color(0xFFF59E0B),
                  cardPadding: cardPadding,
                  iconSize: iconSize,
                  iconBoxSize: iconBoxSize,
                  valueSize: valueSize,
                  titleSize: titleSize,
                  radius: radius,
                  compact: compact,
                  desktop: desktop,
                  highlight: false,
                ),
              ),

              SizedBox(width: spacing),

              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'Completion Rate',
                  value:
                      '${completionRate.clamp(0.0, 100.0).toStringAsFixed(0)}%',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF0F9D8A),
                  cardPadding: cardPadding,
                  iconSize: iconSize,
                  iconBoxSize: iconBoxSize,
                  valueSize: valueSize,
                  titleSize: titleSize,
                  radius: radius,
                  compact: compact,
                  desktop: desktop,
                  highlight: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
