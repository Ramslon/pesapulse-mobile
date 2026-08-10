import 'package:flutter/material.dart';

import '../goal_stat_card.dart';

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
        final isWide = constraints.maxWidth >= 600;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,

            // Give the cards enough vertical space.
            childAspectRatio: isWide ? 1.55 : 1.05,
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
