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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GoalStatCard(
                title: 'Goals',
                value: '$totalGoals',
                icon: Icons.flag_outlined,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GoalStatCard(
                title: 'Completed',
                value: '$completedGoals',
                icon: Icons.emoji_events_outlined,
                color: Colors.amber,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: GoalStatCard(
                title: 'Active',
                value: '$activeGoals',
                icon: Icons.track_changes,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GoalStatCard(
                title: 'Success Rate',
                value: '${completionRate.toStringAsFixed(1)}%',
                icon: Icons.trending_up,
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
