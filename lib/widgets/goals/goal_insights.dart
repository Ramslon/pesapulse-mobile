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

  Color _insightColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'urgent':
        return Colors.red;

      case 'completed':
        return Colors.green;

      default:
        return colorScheme.primary;
    }
  }

  IconData _insightIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.emoji_events_rounded;

      case 'urgent':
        return Icons.warning_amber_rounded;

      default:
        return Icons.auto_awesome_rounded;
    }
  }

  String _statusLabel(String status) {
    if (status.isEmpty) {
      return 'INSIGHT';
    }

    return status.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (insight == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final data = insight!;

    final status = data['status']?.toString() ?? '';

    final insightColor = _insightColor(status, colorScheme);

    final insightIcon = _insightIcon(status);

    final statusLabel = _statusLabel(status);

    final daysRemaining = (data['days_remaining'] as num?)?.ceil() ?? 0;

    final remainingAmount = (data['remaining_amount'] as num?)?.toDouble() ?? 0;

    final monthlyNeeded = (data['monthly_needed'] as num?)?.toDouble() ?? 0;

    final message = data['message']?.toString().trim() ?? '';

    return FadeSlideAnimation(
      delay: 300,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: insightColor.withOpacity(.055),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: insightColor.withOpacity(.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────
            // Header
            // ─────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: insightColor.withOpacity(.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(insightIcon, color: insightColor, size: 21),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Goal Insight',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: insightColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ─────────────────────────────────────────
            // Key metrics
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

                const SizedBox(width: 10),

                Expanded(
                  child: _InsightMetric(
                    title: 'Days left',
                    value: '$daysRemaining',
                    icon: Icons.calendar_today_outlined,
                    color: insightColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            _InsightMetric(
              title: 'Monthly needed',
              value: currency.format(monthlyNeeded),
              icon: Icons.savings_outlined,
              color: insightColor,
            ),

            // ─────────────────────────────────────────
            // Message
            // ─────────────────────────────────────────
            if (message.isNotEmpty) ...[
              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(.55),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 17,
                      color: insightColor,
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Text(
                        message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.45,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
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
