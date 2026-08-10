import 'package:flutter/material.dart';

class GoalMilestone extends StatelessWidget {
  final double percentage;
  final Future Function() onArchive;

  const GoalMilestone({
    super.key,
    required this.percentage,
    required this.onArchive,
  });

  double get progress => percentage.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    if (progress >= 1.0) {
      return _CompletedMilestone(onArchive: onArchive);
    }

    if (progress >= 0.75) {
      return const _MilestoneBadge(
        title: '75% — Almost There',
        icon: Icons.bolt_rounded,
        color: Colors.orange,
      );
    }

    if (progress >= 0.50) {
      return const _MilestoneBadge(
        title: '50% — Halfway There',
        icon: Icons.trending_up_rounded,
        color: Colors.indigo,
      );
    }

    if (progress >= 0.25) {
      return const _MilestoneBadge(
        title: '25% — Good Start',
        icon: Icons.savings_outlined,
        color: Colors.green,
      );
    }

    return const SizedBox.shrink();
  }
}

class _MilestoneBadge extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _MilestoneBadge({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 17),
          ),

          const SizedBox(width: 9),

          Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedMilestone extends StatelessWidget {
  final Future Function() onArchive;

  const _CompletedMilestone({required this.onArchive});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: 21,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goal Completed',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Congratulations! You reached your target.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onArchive,
              icon: const Icon(Icons.archive_outlined, size: 18),
              label: const Text('Archive Goal'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
