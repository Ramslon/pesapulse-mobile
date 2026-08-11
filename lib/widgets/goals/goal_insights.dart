import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../fade_slide_animation.dart';
import '../../utils/responsive_helper.dart';

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

    // ─────────────────────────────────────────────
    // Responsive configuration
    // ─────────────────────────────────────────────
    final isCompact = ResponsiveHelper.useCompactLayout(context);

    final isLandscape = ResponsiveHelper.isLandscape(context);

    final spacing = ResponsiveHelper.spacing(context);

    final horizontalPadding = isCompact ? 13.0 : 16.0;

    final verticalPadding = isLandscape
        ? 13.0
        : isCompact
        ? 14.0
        : 16.0;

    final iconSize = isCompact ? 38.0 : 40.0;

    final metricIconSize = isCompact ? 30.0 : 32.0;

    return FadeSlideAnimation(
      delay: 300,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: insightColor.withOpacity(.055),
          borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
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
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    color: insightColor.withOpacity(.10),
                    borderRadius: BorderRadius.circular(isCompact ? 11 : 12),
                  ),
                  child: Icon(
                    insightIcon,
                    color: insightColor,
                    size: isCompact ? 20 : 21,
                  ),
                ),

                SizedBox(width: spacing * 0.75),

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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

            SizedBox(height: isLandscape ? 12 : 16),

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
                    iconSize: metricIconSize,
                    compact: isCompact,
                  ),
                ),

                SizedBox(width: spacing * 0.7),

                Expanded(
                  child: _InsightMetric(
                    title: 'Days left',
                    value: '$daysRemaining',
                    icon: Icons.calendar_today_outlined,
                    color: insightColor,
                    iconSize: metricIconSize,
                    compact: isCompact,
                  ),
                ),
              ],
            ),

            SizedBox(height: isLandscape ? 8 : 10),

            // ─────────────────────────────────────────
            // Monthly needed
            // ─────────────────────────────────────────
            _InsightMetric(
              title: 'Monthly needed',
              value: currency.format(monthlyNeeded),
              icon: Icons.savings_outlined,
              color: insightColor,
              iconSize: metricIconSize,
              compact: isCompact,
            ),

            // ─────────────────────────────────────────
            // Message
            // ─────────────────────────────────────────
            if (message.isNotEmpty) ...[
              SizedBox(height: isLandscape ? 11 : 14),

              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 11 : 13,
                  vertical: isCompact ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withOpacity(.55),
                  borderRadius: BorderRadius.circular(isCompact ? 12 : 13),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: isCompact ? 16 : 17,
                      color: insightColor,
                    ),

                    SizedBox(width: spacing * 0.6),

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
  final double iconSize;
  final bool compact;

  const _InsightMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.iconSize,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 9 : 11,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(.65),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: color.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: color.withOpacity(.09),
              borderRadius: BorderRadius.circular(compact ? 9 : 10),
            ),
            child: Icon(icon, color: color, size: compact ? 16 : 17),
          ),

          SizedBox(width: compact ? 7 : 9),

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
