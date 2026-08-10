import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../fade_slide_animation.dart';

class GoalInsights extends StatelessWidget {
  final Map<String, dynamic>? insight;
  final NumberFormat currency;

  const GoalInsights({
    super.key,
    required this.insight,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    // No insight available yet.
    if (insight == null) {
      return const SizedBox.shrink();
    }

    final data = insight!;

    Color insightColor;

    switch (data['status']) {
      case 'urgent':
        insightColor = Colors.red;
        break;

      case 'completed':
        insightColor = Colors.green;
        break;

      default:
        insightColor = Colors.blue;
    }

    IconData insightIcon;

    switch (data['status']) {
      case 'completed':
        insightIcon = Icons.emoji_events;
        break;

      case 'urgent':
        insightIcon = Icons.warning_amber_rounded;
        break;

      default:
        insightIcon = Icons.track_changes;
    }

    final statusLabel = data['status']
        .toString()
        .replaceAll('_', ' ')
        .toUpperCase();

    final daysRemaining = (data['days_remaining'] as num?)?.ceil() ?? 0;

    final remainingAmount = (data['remaining_amount'] as num?)?.toDouble() ?? 0;

    final monthlyNeeded = (data['monthly_needed'] as num?)?.toDouble() ?? 0;

    final message = data['message']?.toString() ?? '';

    return FadeSlideAnimation(
      delay: 300,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 18),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: insightColor.withOpacity(.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: insightColor.withOpacity(.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────
            // Insight header
            // ─────────────────────────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: insightColor.withOpacity(.15),
                  child: Icon(insightIcon, color: insightColor),
                ),

                const SizedBox(width: 12),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Goal Insight',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: insightColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: .4,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ─────────────────────────────────────────
            // Remaining + Days Left
            // ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _InsightMetric(
                    title: 'Remaining',
                    value: currency.format(remainingAmount),
                    icon: Icons.account_balance_wallet_outlined,
                    color: insightColor,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _InsightMetric(
                    title: 'Days Left',
                    value: '$daysRemaining',
                    icon: Icons.calendar_today_outlined,
                    color: insightColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ─────────────────────────────────────────
            // Monthly needed
            // ─────────────────────────────────────────
            _InsightMetric(
              title: 'Monthly Needed',
              value: currency.format(monthlyNeeded),
              icon: Icons.savings_outlined,
              color: insightColor,
            ),

            const SizedBox(height: 16),

            // ─────────────────────────────────────────
            // Insight message
            // ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.05),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InsightMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: color.withOpacity(.12),
            child: Icon(icon, color: color, size: 18),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
