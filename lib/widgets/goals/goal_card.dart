import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesapulse_mobile/widgets/goals/goal_insights.dart';
import 'package:pesapulse_mobile/widgets/goals/goal_savings_forecast.dart';
import 'package:pesapulse_mobile/widgets/goals/goal_milestone.dart';
import 'package:pesapulse_mobile/widgets/goals/goal_progress.dart';
import 'package:pesapulse_mobile/models/goal.dart';

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

  final Future<void> Function() onArchive;

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
    return isCompleted ? Icons.emoji_events : Icons.flag;
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

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────────
            // Goal header
            // ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withOpacity(.12),
                  child: Icon(
                    statusIcon,
                    color: isCompleted ? Colors.amber : statusColor,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.title.toString(),
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            tooltip: 'Delete Goal',
                            visualDensity: VisualDensity.compact,
                            onPressed: onDelete,
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                Text(
                  targetDate,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ─────────────────────────────────────────────
            // Saved amount
            // ─────────────────────────────────────────────
            Text(
              currency.format(saved),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              'Saved of ${currency.format(target)} target',
              style: TextStyle(color: Colors.grey.shade600),
            ),

            const SizedBox(height: 18),

            // Progress
            GoalProgress(percentage: percentage),

            const SizedBox(height: 18),

            GoalInsights(insight: insight, currency: currency),

            const SizedBox(height: 4),

            GoalMilestone(percentage: percentage, onArchive: onArchive),

            const SizedBox(height: 18),

            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween(begin: 0, end: percentage * 100),
                  builder: (_, value, __) {
                    return Text(
                      '${value.toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 22),
            GoalSavingsForecast(
              forecast: forecast,
              currency: currency,
              isCompleted: percentage >= 1.0,
              onAddSavings: onAddSavings,
            ),
          ],
        ),
      ),
    );
  }
}
