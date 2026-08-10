import 'package:flutter/material.dart';

import '../fade_slide_animation.dart';

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

    final deadlineColor = Colors.orange.shade700;

    return FadeSlideAnimation(
      delay: 150,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: deadlineColor.withOpacity(.16)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: deadlineColor.withOpacity(.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.notifications_active_outlined,
                      color: deadlineColor,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upcoming Deadlines',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Goals that need your attention',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withOpacity(.58),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: deadlineColor.withOpacity(.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${upcomingDeadlines.length}',
                      style: TextStyle(
                        color: deadlineColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Deadline items
              ...upcomingDeadlines.asMap().entries.map((entry) {
                final index = entry.key;
                final goal = entry.value;

                final title = goal['title']?.toString() ?? 'Untitled Goal';

                final daysRemaining =
                    (goal['days_remaining'] as num?)?.toDouble() ?? 0;

                final isLast = index == upcomingDeadlines.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
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

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: urgencyColor.withOpacity(.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.flag_outlined, color: urgencyColor, size: 20),
          ),

          const SizedBox(width: 12),

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
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  remainingText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: urgencyColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Icon(
            Icons.schedule_outlined,
            size: 18,
            color: colorScheme.onSurface.withOpacity(.40),
          ),
        ],
      ),
    );
  }
}
