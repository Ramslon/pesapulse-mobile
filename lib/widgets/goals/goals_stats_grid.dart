import 'package:flutter/material.dart';

import '../goal_stat_card.dart';
import '../../utils/responsive_helper.dart';

class GoalsStatsGrid extends StatelessWidget {
  final int totalGoals;
  final int completedGoals;
  final int activeGoals;
  final double completionRate;

  const GoalsStatsGrid({
    super.key,
    required this.totalGoals,
    required this.completedGoals,
    required this.activeGoals,
    required this.completionRate,
  });

  @override
  Widget build(BuildContext context) {
    final stats = [
      _GoalStatData(
        title: 'Goals',
        value: '$totalGoals',
        icon: Icons.flag_outlined,
      ),
      _GoalStatData(
        title: 'Completed',
        value: '$completedGoals',
        icon: Icons.emoji_events_outlined,
      ),
      _GoalStatData(
        title: 'Active',
        value: '$activeGoals',
        icon: Icons.track_changes,
      ),
      _GoalStatData(
        title: 'Success Rate',
        value: '${completionRate.toStringAsFixed(1)}%',
        icon: Icons.trending_up,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = ResponsiveHelper.isLandscape(context);
        final isCompact = ResponsiveHelper.useCompactLayout(context);
        final spacing = ResponsiveHelper.spacing(context);

        final isWide = constraints.maxWidth >= 600;

        final int crossAxisCount = isWide ? 4 : 2;

        // childAspectRatio = width / height.
        // Lower values give the cards more vertical height.
        final double childAspectRatio;

        if (isLandscape) {
          if (isCompact) {
            childAspectRatio = 1.15;
          } else {
            childAspectRatio = 1.25;
          }
        } else if (isCompact) {
          childAspectRatio = 0.95;
        } else if (isWide) {
          childAspectRatio = 1.45;
        } else {
          childAspectRatio = 1.05;
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

            return GoalStatCard(
              title: stat.title,
              value: stat.value,
              icon: stat.icon,
              color: _statColor(context, index),
            );
          },
        );
      },
    );
  }

  Color _statColor(BuildContext context, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (index) {
      case 0:
        return colorScheme.primary;

      case 1:
        return Colors.amber;

      case 2:
        return Colors.orange;

      case 3:
        return Colors.purple;

      default:
        return colorScheme.primary;
    }
  }
}

class _GoalStatData {
  final String title;
  final String value;
  final IconData icon;

  const _GoalStatData({
    required this.title,
    required this.value,
    required this.icon,
  });
}
