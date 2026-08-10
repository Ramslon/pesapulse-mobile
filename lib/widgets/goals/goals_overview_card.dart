import 'package:flutter/material.dart';
import '../fade_slide_animation.dart';

class GoalsOverviewCard extends StatelessWidget {
  final int totalGoals;
  final VoidCallback onArchivedGoals;

  const GoalsOverviewCard({
    super.key,
    required this.totalGoals,
    required this.onArchivedGoals,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FadeSlideAnimation(
      child: Card(
        elevation: 2,
        shadowColor: colorScheme.shadow.withOpacity(.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.flag_outlined,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Financial Goals',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track your savings goals and progress',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Archived Goals',
                    onPressed: onArchivedGoals,
                    icon: Icon(
                      Icons.archive_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0, end: totalGoals.toDouble()),
                builder: (_, value, __) {
                  return Text(
                    value.toStringAsFixed(0),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),

              const SizedBox(height: 4),

              Text(
                'Total Goals',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
