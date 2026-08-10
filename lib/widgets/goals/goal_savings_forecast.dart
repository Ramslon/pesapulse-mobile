import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../fade_slide_animation.dart';
import 'forecast_metric.dart';

class GoalSavingsForecast extends StatelessWidget {
  final Map<String, dynamic>? forecast;
  final NumberFormat currency;
  final bool isCompleted;
  final VoidCallback onAddSavings;

  const GoalSavingsForecast({
    super.key,
    required this.forecast,
    required this.currency,
    required this.isCompleted,
    required this.onAddSavings,
  });

  Color _forecastColor(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    switch (forecast?['forecast']) {
      case 'ahead':
        return Colors.green;

      case 'behind':
        return Colors.red;

      case 'completed':
        return Colors.teal;

      case 'on_track':
        return primary;

      default:
        return primary;
    }
  }

  IconData _forecastIcon() {
    switch (forecast?['forecast']) {
      case 'ahead':
        return Icons.trending_up_rounded;

      case 'behind':
        return Icons.trending_down_rounded;

      case 'completed':
        return Icons.emoji_events_rounded;

      case 'on_track':
        return Icons.track_changes_rounded;

      default:
        return Icons.insights_outlined;
    }
  }

  String _forecastLabel() {
    final value = forecast?['forecast'];

    if (value == null) {
      return 'Forecast unavailable';
    }

    return value
        .toString()
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  String _completionDate() {
    final value = forecast?['estimated_completion_date'];

    if (value == null || value.toString().isEmpty) {
      return 'Unknown';
    }

    return value.toString();
  }

  double _amount(String key) {
    return (forecast?[key] as num?)?.toDouble() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final forecastColor = _forecastColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─────────────────────────────────────────────
        // Section heading
        // ─────────────────────────────────────────────
        Row(
          children: [
            Icon(
              Icons.auto_graph_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Savings Forecast',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ─────────────────────────────────────────────
        // Forecast card
        // ─────────────────────────────────────────────
        if (forecast != null)
          FadeSlideAnimation(
            delay: 450,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: forecastColor.withOpacity(.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: forecastColor.withOpacity(.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Forecast status
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: forecastColor.withOpacity(.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _forecastIcon(),
                          color: forecastColor,
                          size: 21,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _forecastLabel(),
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: forecastColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 3),

                            Text(
                              'Based on your current savings pace',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Forecast message
                  if ((forecast?['message']?.toString() ?? '').isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(.55),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        forecast!['message'].toString(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Completion + daily saving
                  Row(
                    children: [
                      Expanded(
                        child: ForecastMetric(
                          title: 'Expected completion',
                          value: _completionDate(),
                          icon: Icons.calendar_today_outlined,
                          color: forecastColor,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: ForecastMetric(
                          title: 'Daily saving',
                          value: currency.format(
                            _amount('recommended_daily_saving'),
                          ),
                          icon: Icons.savings_outlined,
                          color: forecastColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Monthly saving
                  ForecastMetric(
                    title: 'Recommended monthly saving',
                    value: currency.format(
                      _amount('recommended_monthly_saving'),
                    ),
                    icon: Icons.account_balance_wallet_outlined,
                    color: forecastColor,
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 14),

        // ─────────────────────────────────────────────
        // Add savings action
        // ─────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: isCompleted ? null : onAddSavings,
            icon: Icon(
              isCompleted
                  ? Icons.check_circle_outline
                  : Icons.add_circle_outline,
            ),
            label: Text(isCompleted ? 'Goal Completed' : 'Add Savings'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
