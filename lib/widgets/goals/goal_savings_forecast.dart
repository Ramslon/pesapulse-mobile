import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/core/utils/currency_formatter.dart';

import '../fade_slide_animation.dart';
import 'forecast_metric.dart';
import '../../utils/responsive_helper.dart';

class GoalSavingsForecast extends StatelessWidget {
  final Map<String, dynamic>? forecast;
  final String Function(num) currency;
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

    final isLandscape = ResponsiveHelper.isLandscape(context);
    final isCompact = ResponsiveHelper.useCompactLayout(context);

    final spacing = ResponsiveHelper.spacing(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);

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
              size: isCompact ? 19 : 20,
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

        SizedBox(height: isLandscape ? 10 : 12),

        // ─────────────────────────────────────────────
        // Forecast card
        // ─────────────────────────────────────────────
        if (forecast != null)
          FadeSlideAnimation(
            delay: 450,
            child: Container(
              padding: EdgeInsets.all(cardPadding),
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
                        width: isCompact ? 40 : 42,
                        height: isCompact ? 40 : 42,
                        decoration: BoxDecoration(
                          color: forecastColor.withOpacity(.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _forecastIcon(),
                          color: forecastColor,
                          size: isCompact ? 20 : 21,
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

                  SizedBox(height: isLandscape ? 12 : 14),

                  // Forecast message
                  if ((forecast?['message']?.toString() ?? '').isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isCompact ? 12 : 13),
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

                  SizedBox(height: isLandscape ? 12 : 14),

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

                      SizedBox(width: spacing),

                      Expanded(
                        child: ForecastMetric(
                          title: 'Daily saving',
                          value: CurrencyFormatter.format(
                            _amount('recommended_daily_saving'),
                          ),
                          icon: Icons.savings_outlined,
                          color: forecastColor,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: isLandscape ? 8 : 10),

                  // Monthly saving
                  ForecastMetric(
                    title: 'Recommended monthly saving',
                    value: CurrencyFormatter.format(
                      _amount('recommended_monthly_saving'),
                    ),
                    icon: Icons.account_balance_wallet_outlined,
                    color: forecastColor,
                  ),
                ],
              ),
            ),
          ),

        SizedBox(height: isLandscape ? 10 : 14),

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
              minimumSize: Size.fromHeight(isCompact ? 48 : 50),
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
