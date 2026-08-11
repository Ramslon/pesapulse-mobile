import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class SettingsStatisticsSection extends StatelessWidget {
  final int totalGoals;
  final int completedGoals;
  final int totalBudgets;
  final int totalExpenses;

  const SettingsStatisticsSection({
    super.key,
    required this.totalGoals,
    required this.completedGoals,
    required this.totalBudgets,
    required this.totalExpenses,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final spacing = ResponsiveHelper.spacing(context);

    final stats = [
      _StatisticData(
        value: totalGoals,
        label: 'Goals Created',
        icon: Icons.flag_outlined,
        color: colorScheme.primary,
      ),
      _StatisticData(
        value: completedGoals,
        label: 'Completed Goals',
        icon: Icons.emoji_events_outlined,
        color: Colors.orange,
      ),
      _StatisticData(
        value: totalBudgets,
        label: 'Budgets Created',
        icon: Icons.account_balance_wallet_outlined,
        color: Colors.blue,
      ),
      _StatisticData(
        value: totalExpenses,
        label: 'Expenses Recorded',
        icon: Icons.receipt_long_outlined,
        color: Colors.red,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Statistics', icon: Icons.bar_chart_rounded),

        const SizedBox(height: 10),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            final int crossAxisCount = isWide ? 4 : 2;

            final double childAspectRatio;

            if (isLandscape && !isCompact) {
              // Give landscape cards additional vertical space.
              childAspectRatio = 1.45;
            } else if (isCompact) {
              // Phones need taller cards to avoid content compression.
              childAspectRatio = 1.05;
            } else {
              childAspectRatio = isWide ? 1.35 : 1.15;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemBuilder: (context, index) {
                final stat = stats[index];

                return _StatisticCard(
                  value: stat.value,
                  label: stat.label,
                  icon: stat.icon,
                  color: stat.color,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _StatisticCard extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatisticCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    final double padding = isCompact
        ? 12
        : isLandscape
        ? 14
        : 15;

    final double iconSize = isCompact ? 38 : 42;
    final double iconGlyphSize = isCompact ? 19 : 21;

    final double valueFontSize = isCompact ? 19 : 22;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
        side: BorderSide(color: colorScheme.outline.withOpacity(.10)),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          children: [
            Container(
              width: iconSize,
              height: iconSize,
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(isCompact ? 11 : 13),
              ),
              child: Icon(icon, color: color, size: iconGlyphSize),
            ),

            SizedBox(width: isCompact ? 9 : 12),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.4,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: isCompact ? 11 : null,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);

    final double iconContainerSize = isCompact ? 38 : 40;
    final double iconSize = isCompact ? 20 : 21;

    return Padding(
      padding: EdgeInsets.only(top: isCompact ? 16 : 20, bottom: 4),
      child: Row(
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(.10),
              borderRadius: BorderRadius.circular(isCompact ? 11 : 12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: iconSize),
          ),

          SizedBox(width: isCompact ? 10 : 11),

          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: isCompact ? 16 : null,
              fontWeight: FontWeight.w800,
              letterSpacing: -.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticData {
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatisticData({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}
