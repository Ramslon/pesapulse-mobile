import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesapulse_mobile/models/goal.dart';
import 'package:pesapulse_mobile/utils/responsive_helper.dart';

import 'package:pesapulse_mobile/widgets/goals/goal_insights.dart';
import 'package:pesapulse_mobile/widgets/goals/goal_savings_forecast.dart';
import 'package:pesapulse_mobile/widgets/goals/goal_milestone.dart';
import 'package:pesapulse_mobile/widgets/goals/goal_progress.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final double target;
  final double saved;
  final double percentage;
  final NumberFormat currency;

  final VoidCallback onDelete;
  final VoidCallback onAddSavings;

  final Map<String, dynamic>? insight;
  final Map<String, dynamic>? forecast;

  final Future Function() onArchive;

  const GoalCard({
    super.key,
    required this.goal,
    required this.target,
    required this.saved,
    required this.percentage,
    required this.currency,
    required this.onDelete,
    required this.onAddSavings,
    required this.insight,
    required this.forecast,
    required this.onArchive,
  });

  bool get isCompleted => percentage >= 1;

  bool get isAlmostThere => percentage >= 0.75;

  Color get statusColor {
    if (isCompleted) {
      return Colors.green;
    }

    if (isAlmostThere) {
      return Colors.orange;
    }

    return Colors.blue;
  }

  String get statusLabel {
    if (isCompleted) {
      return 'Completed';
    }

    if (isAlmostThere) {
      return 'Almost There';
    }

    return 'In Progress';
  }

  IconData get statusIcon {
    if (isCompleted) {
      return Icons.emoji_events_rounded;
    }

    return Icons.flag_rounded;
  }

  String get targetDate {
    final rawDate = goal.targetDate;

    if (rawDate == null) {
      return 'No deadline';
    }

    try {
      return DateFormat(
        'dd MMM yyyy',
      ).format(DateTime.parse(rawDate.toString()));
    } catch (_) {
      return 'No deadline';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final progressPercentage = percentage.clamp(0.0, 1.0);

    // ─────────────────────────────────────────────
    // Responsive values
    // ─────────────────────────────────────────────
    final cardPadding = ResponsiveHelper.cardPadding(context);
    final spacing = ResponsiveHelper.spacing(context);
    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isCompact = ResponsiveHelper.useCompactLayout(context);

    // Landscape screens have less vertical space, so slightly
    // reduce some vertical spacing without changing the design.
    final verticalScale = isLandscape ? 0.85 : 1.0;

    return Card(
      margin: EdgeInsets.only(bottom: 18 * verticalScale),
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.10)),
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
                _buildGoalIcon(colorScheme, isCompact: isCompact),

                SizedBox(width: spacing),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),

                      SizedBox(height: 8 * verticalScale),

                      _buildStatusChip(),
                    ],
                  ),
                ),

                SizedBox(width: spacing * 0.55),

                _buildDeleteButton(colorScheme, isCompact: isCompact),
              ],
            ),

            SizedBox(height: 14 * verticalScale),

            // ─────────────────────────────────────────────
            // Deadline
            // ─────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: isCompact ? 14 : 15,
                  color: colorScheme.onSurfaceVariant,
                ),

                SizedBox(width: spacing * 0.5),

                Expanded(
                  child: Text(
                    targetDate,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 22 * verticalScale),

            // ─────────────────────────────────────────────
            // Financial progress
            // ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isCompact ? 14 : 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(.45),
                borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current savings',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  SizedBox(height: 5 * verticalScale),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          currency.format(saved),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),

                      SizedBox(width: spacing * 0.55),

                      _buildPercentageBadge(),
                    ],
                  ),

                  SizedBox(height: 5 * verticalScale),

                  Text(
                    'of ${currency.format(target)} target',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  SizedBox(height: 16 * verticalScale),

                  GoalProgress(percentage: progressPercentage),
                ],
              ),
            ),

            SizedBox(height: sectionSpacing * verticalScale),

            // ─────────────────────────────────────────────
            // Insights
            // ─────────────────────────────────────────────
            if (insight != null) ...[
              _buildSectionLabel(
                context,
                icon: Icons.auto_awesome_outlined,
                title: 'Insight',
              ),

              SizedBox(height: 8 * verticalScale),

              GoalInsights(insight: insight, currency: currency),

              SizedBox(height: 14 * verticalScale),
            ],

            // ─────────────────────────────────────────────
            // Milestone
            // ─────────────────────────────────────────────
            GoalMilestone(percentage: progressPercentage, onArchive: onArchive),

            SizedBox(height: sectionSpacing * verticalScale),

            // ─────────────────────────────────────────────
            // Savings forecast
            // ─────────────────────────────────────────────
            SizedBox(height: 8 * verticalScale),

            GoalSavingsForecast(
              forecast: forecast,
              currency: currency,
              isCompleted: isCompleted,
              onAddSavings: onAddSavings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalIcon(ColorScheme colorScheme, {required bool isCompact}) {
    final size = isCompact ? 44.0 : 48.0;
    final iconSize = isCompact ? 23.0 : 25.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: statusColor.withOpacity(.10),
        borderRadius: BorderRadius.circular(isCompact ? 13 : 15),
      ),
      child: Icon(
        statusIcon,
        color: isCompleted ? Colors.amber.shade700 : statusColor,
        size: iconSize,
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(width: 6),

          Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(
    ColorScheme colorScheme, {
    required bool isCompact,
  }) {
    final size = isCompact ? 36.0 : 40.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onDelete,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Colors.red,
            size: isCompact ? 19 : 20,
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageBadge() {
    final progressPercentage = percentage.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: progressPercentage * 100),
      builder: (_, value, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${value.toStringAsFixed(0)}%',
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionLabel(
    BuildContext context, {
    required IconData icon,
    required String title,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 17, color: colorScheme.primary),

        const SizedBox(width: 7),

        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
