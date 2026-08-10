import 'package:flutter/material.dart';

class GoalMilestone extends StatelessWidget {
  final double percentage;
  final Future<void> Function() onArchive;

  const GoalMilestone({
    super.key,
    required this.percentage,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    if (percentage >= 1.0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildMilestoneBadge(
            title: 'Goal Completed',
            icon: Icons.emoji_events,
            color: Colors.amber,
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive Goal'),
              onPressed: onArchive,
            ),
          ),
        ],
      );
    }

    if (percentage >= 0.75) {
      return buildMilestoneBadge(
        title: '75% Almost There',
        icon: Icons.bolt,
        color: Colors.orange,
      );
    }

    if (percentage >= 0.50) {
      return buildMilestoneBadge(
        title: '50% Progress',
        icon: Icons.trending_up,
        color: Colors.indigo,
      );
    }

    if (percentage >= 0.25) {
      return buildMilestoneBadge(
        title: '25% Saved',
        icon: Icons.savings,
        color: Colors.green,
      );
    }

    return const SizedBox(height: 14);
  }

  Widget buildMilestoneBadge({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withOpacity(.18),
            child: Icon(icon, color: color, size: 18),
          ),

          const SizedBox(width: 10),

          Text(
            title,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
