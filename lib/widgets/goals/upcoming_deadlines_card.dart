import 'package:flutter/material.dart';

import '../fade_slide_animation.dart';
import '../../utils/responsive_helper.dart';

class UpcomingDeadlinesCard extends StatelessWidget {
  final List upcomingDeadlines;

  const UpcomingDeadlinesCard({super.key, required this.upcomingDeadlines});

  @override
  Widget build(BuildContext context) {
    if (upcomingDeadlines.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    final deadlineColor = Colors.orange.shade700;

    final cardRadius = isCompact ? 18.0 : 20.0;
    final cardPadding = isCompact
        ? 15.0
        : isLandscape
        ? 18.0
        : 20.0;

    final headerIconSize = isCompact ? 40.0 : 44.0;
    final headerIcon = isCompact ? 21.0 : 23.0;

    return FadeSlideAnimation(
      delay: 150,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(color: deadlineColor.withOpacity(.16)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─────────────────────────────────────────────
              // Header
              // ─────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: headerIconSize,
                    height: headerIconSize,
                    decoration: BoxDecoration(
                      color: deadlineColor.withOpacity(.10),
                      borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: deadlineColor,
                      size: headerIcon,
                    ),
                  ),

                  SizedBox(width: isCompact ? 10 : 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming Deadlines',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Goals that need your attention',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(.58),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: isCompact ? 6 : 8),

                  Container(
                    constraints: const BoxConstraints(minWidth: 30),
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 10,
                      vertical: isCompact ? 5 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: deadlineColor.withOpacity(.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${upcomingDeadlines.length}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: deadlineColor,
                        fontWeight: FontWeight.w800,
                        fontSize: isCompact ? 12 : 13,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isCompact ? 14 : 16),

              // ─────────────────────────────────────────────
              // Deadline items
              // ─────────────────────────────────────────────
              ...upcomingDeadlines.asMap().entries.map((entry) {
                final index = entry.key;
                final goal = entry.value;

                final title = goal['title']?.toString() ?? 'Untitled Goal';

                final daysRemaining =
                    (goal['days_remaining'] as num?)?.toDouble() ?? 0;

                final isLast = index == upcomingDeadlines.length - 1;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: isLast
                        ? 0
                        : isCompact
                        ? 8
                        : 10,
                  ),
                  child: _DeadlineItem(
                    title: title,
                    daysRemaining: daysRemaining,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeadlineItem extends StatelessWidget {
  final String title;
  final double daysRemaining;

  const _DeadlineItem({required this.title, required this.daysRemaining});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);

    final days = daysRemaining.ceil();

    final Color urgencyColor;

    if (days <= 1) {
      urgencyColor = Colors.red;
    } else if (days <= 3) {
      urgencyColor = Colors.orange;
    } else {
      urgencyColor = colorScheme.primary;
    }

    final String remainingText;

    if (days <= 0) {
      remainingText = 'Due today';
    } else if (days == 1) {
      remainingText = '1 day remaining';
    } else {
      remainingText = '$days days remaining';
    }

    final itemPadding = isCompact ? 11.0 : 13.0;
    final iconBoxSize = isCompact ? 34.0 : 38.0;

    return Container(
      padding: EdgeInsets.all(itemPadding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
        border: Border.all(color: colorScheme.outline.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
            ),
            child: Icon(
              Icons.flag_outlined,
              color: urgencyColor,
              size: isCompact ? 18 : 20,
            ),
          ),

          SizedBox(width: isCompact ? 9 : 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: isCompact ? 13 : null,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  remainingText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: urgencyColor,
                    fontWeight: FontWeight.w600,
                    fontSize: isCompact ? 11 : null,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: isCompact ? 6 : 10),

          Icon(
            Icons.schedule_outlined,
            size: isCompact ? 17 : 18,
            color: colorScheme.onSurface.withOpacity(.40),
          ),
        ],
      ),
    );
  }
}
