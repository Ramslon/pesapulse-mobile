import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

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

    final isCompact = ResponsiveHelper.useCompactLayout(context);

    final isLandscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = isCompact ? 10.0 : 12.0;

    final verticalPadding = isLandscape
        ? 7.0
        : isCompact
        ? 8.0
        : 9.0;

    final iconSize = isCompact ? 28.0 : 30.0;

    final iconContainerRadius = isCompact ? 8.0 : 9.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.07),
        borderRadius: BorderRadius.circular(isCompact ? 13 : 14),
        border: Border.all(color: color.withOpacity(.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(iconContainerRadius),
            ),
            child: Icon(icon, color: color, size: isCompact ? 16 : 17),
          ),

          SizedBox(width: isCompact ? 7 : 9),

          Flexible(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
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

    final isCompact = ResponsiveHelper.useCompactLayout(context);

    final isLandscape = ResponsiveHelper.isLandscape(context);

    final cardPadding = isCompact ? 12.0 : 14.0;

    final iconContainerSize = isCompact ? 36.0 : 38.0;

    final iconSize = isCompact ? 20.0 : 21.0;

    final buttonHeight = isLandscape
        ? 44.0
        : isCompact
        ? 46.0
        : 48.0;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(.07),
        borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
        border: Border.all(color: Colors.amber.withOpacity(.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────
          // Completion header
          // ─────────────────────────────────────────
          Row(
            children: [
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(.12),
                  borderRadius: BorderRadius.circular(isCompact ? 10 : 11),
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.amber,
                  size: iconSize,
                ),
              ),

              SizedBox(width: isCompact ? 9 : 11),

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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: isLandscape ? 10 : 13),

          // ─────────────────────────────────────────
          // Archive action
          // ─────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: FilledButton.icon(
              onPressed: onArchive,
              icon: Icon(Icons.archive_outlined, size: isCompact ? 17 : 18),
              label: const Text('Archive Goal'),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 11 : 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
