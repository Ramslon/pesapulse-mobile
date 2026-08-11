import 'package:flutter/material.dart';

import '../fade_slide_animation.dart';
import '../../utils/responsive_helper.dart';

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

    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isCompact = ResponsiveHelper.useCompactLayout(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    return FadeSlideAnimation(
      child: Card(
        elevation: 1,
        shadowColor: colorScheme.shadow.withOpacity(.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
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
                    width: isCompact ? 42 : 46,
                    height: isCompact ? 42 : 46,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(.10),
                      borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
                    ),
                    child: Icon(
                      Icons.flag_outlined,
                      color: colorScheme.primary,
                      size: isCompact ? 22 : 24,
                    ),
                  ),

                  SizedBox(width: isCompact ? 10 : 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Goals',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -.2,
                            fontSize: isCompact ? 18 : null,
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

                  SizedBox(width: isCompact ? 4 : 8),

                  IconButton(
                    tooltip: 'Archived Goals',
                    onPressed: onArchivedGoals,
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary.withOpacity(.08),
                      foregroundColor: colorScheme.primary,
                      minimumSize: Size(
                        isCompact ? 40 : 44,
                        isCompact ? 40 : 44,
                      ),
                    ),
                    icon: Icon(
                      Icons.archive_outlined,
                      size: isCompact ? 19 : 21,
                    ),
                  ),
                ],
              ),

              SizedBox(height: isLandscape ? 16 : 22),

              // ─────────────────────────────────────────────
              // Total goals
              // ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 14 : 16,
                  vertical: isCompact ? 12 : 15,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(.45),
                  borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
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
                            fontSize: isCompact ? 30 : null,
                          ),
                        );
                      },
                    ),

                    SizedBox(width: isCompact ? 8 : 10),

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
