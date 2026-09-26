import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/core/utils/currency_formatter.dart';

import '../../utils/responsive_helper.dart';

class BudgetStatsGrid extends StatelessWidget {
  final double spent;
  final double remaining;
  final double percentageUsed;
  final int daysRemaining;
  final Color statusColor;

  const BudgetStatsGrid({
    super.key,
    required this.spent,
    required this.remaining,
    required this.percentageUsed,
    required this.daysRemaining,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final spacing = ResponsiveHelper.spacing(context);

    final columns = ResponsiveHelper.gridColumns(
      context,
      mobilePortrait: 2,
      mobileLandscape: 4,
      tabletPortrait: 4,
      tabletLandscape: 4,
      desktop: 4,
    );

    final normalizedUsage = percentageUsed.clamp(0.0, 100.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        final stats = [
          _BudgetMetric(
            icon: Icons.arrow_upward_rounded,
            title: 'Spent',
            value: CurrencyFormatter.format(spent),
            color: const Color(0xFFE53935),
          ),
          _BudgetMetric(
            icon: Icons.savings_rounded,
            title: 'Remaining',
            value: CurrencyFormatter.format(remaining),
            color: const Color(0xFF16A34A),
          ),
          _BudgetMetric(
            icon: Icons.pie_chart_rounded,
            title: 'Usage',
            value: '${normalizedUsage.toStringAsFixed(0)}%',
            color: statusColor,
          ),
          _BudgetMetric(
            icon: Icons.calendar_today_rounded,
            title: 'Days Left',
            value: daysRemaining.toString(),
            color: colorScheme.primary,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final stat in stats)
              SizedBox(
                width: itemWidth,
                child: _buildMetric(context, stat: stat),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMetric(BuildContext context, {required _BudgetMetric stat}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final cardRadius = desktop
        ? 18.0
        : compact
        ? 14.0
        : 17.0;

    final iconBoxSize = desktop
        ? 40.0
        : compact
        ? 30.0
        : 36.0;

    final iconSize = desktop
        ? 20.0
        : compact
        ? 15.0
        : 18.0;

    final titleSize = desktop
        ? 10.5
        : compact
        ? 8.5
        : 9.5;

    final valueSize = desktop
        ? 17.0
        : compact
        ? 12.0
        : 14.0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0.96, end: 1.0),
      builder: (_, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(
          desktop
              ? 13
              : compact
              ? 9
              : 11,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: stat.color.withOpacity(
                theme.brightness == Brightness.dark ? 0.07 : 0.045,
              ),
              blurRadius: desktop ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: iconBoxSize,
                  height: iconBoxSize,
                  decoration: BoxDecoration(
                    color: stat.color.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(compact ? 9 : 11),
                    border: Border.all(color: stat.color.withOpacity(0.10)),
                  ),
                  child: Icon(stat.icon, color: stat.color, size: iconSize),
                ),

                const Spacer(),

                Container(
                  width: compact ? 5 : 6,
                  height: compact ? 5 : 6,
                  decoration: BoxDecoration(
                    color: stat.color.withOpacity(0.70),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),

            SizedBox(
              height: compact
                  ? 8
                  : desktop
                  ? 11
                  : 9,
            ),

            Text(
              stat.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.68),
                fontSize: titleSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.15,
              ),
            ),

            SizedBox(height: compact ? 4 : 6),

            SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  stat.value,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: valueSize,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -0.35,
                  ),
                ),
              ),
            ),

            SizedBox(height: compact ? 7 : 9),

            Container(
              width: desktop
                  ? 32
                  : compact
                  ? 23
                  : 28,
              height: 3,
              decoration: BoxDecoration(
                color: stat.color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetMetric {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _BudgetMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
}
