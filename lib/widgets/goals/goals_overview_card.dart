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
        elevation: 1,
        shadowColor: colorScheme.shadow.withOpacity(.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─────────────────────────────────────────────
              // Header
              // ─────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.flag_outlined,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),

                  const SizedBox(width: 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Goals',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -.2,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          'Track your savings goals and progress',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  IconButton(
                    tooltip: 'Archived Goals',
                    onPressed: onArchivedGoals,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary.withOpacity(.08),
                      foregroundColor: colorScheme.primary,
                    ),
                    icon: const Icon(Icons.archive_outlined, size: 21),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ─────────────────────────────────────────────
              // Total goals
              // ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 800),
                      tween: Tween(begin: 0, end: totalGoals.toDouble()),
                      builder: (_, value, __) {
                        return Text(
                          value.toStringAsFixed(0),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1,
                            letterSpacing: -1,
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 10),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        totalGoals == 1 ? 'goal' : 'goals',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
