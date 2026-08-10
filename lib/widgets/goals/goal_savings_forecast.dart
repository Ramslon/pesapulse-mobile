import 'package:flutter/material.dart';
import '../fade_slide_animation.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    Color forecastColor = Colors.blue;
    IconData forecastIcon = Icons.trending_flat;

    if (forecast != null) {
      switch (forecast!['forecast']) {
        case 'ahead':
          forecastColor = Colors.green;
          forecastIcon = Icons.trending_up;
          break;

        case 'behind':
          forecastColor = Colors.red;
          forecastIcon = Icons.trending_down;
          break;

        case 'completed':
          forecastColor = Colors.teal;
          forecastIcon = Icons.emoji_events;
          break;

        case 'on_track':
          forecastColor = Colors.blue;
          forecastIcon = Icons.track_changes;
          break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_graph, color: Colors.indigo, size: 20),
            const SizedBox(width: 8),
            Text(
              'Savings Forecast',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (forecast != null)
          FadeSlideAnimation(
            delay: 450,
            child: Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: forecastColor.withOpacity(.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: forecastColor.withOpacity(.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: forecastColor.withOpacity(.15),
                        child: Icon(forecastIcon, color: forecastColor),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Savings Forecast',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            forecast!['forecast']
                                .toString()
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: TextStyle(
                              color: forecastColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.05),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      forecast!['message'] ?? '',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: _ForecastMetric(
                          title: 'Completion',
                          value:
                              (forecast!['estimated_completion_date']
                                  as String?) ??
                              'Unknown',
                          icon: Icons.calendar_today,
                          color: forecastColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ForecastMetric(
                          title: 'Daily',
                          value: currency.format(
                            (forecast!['recommended_daily_saving'] as num?)
                                    ?.toDouble() ??
                                0,
                          ),
                          icon: Icons.savings,
                          color: forecastColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _ForecastMetric(
                    title: 'Monthly Saving',
                    value: currency.format(
                      (forecast!['recommended_monthly_saving'] as num?)
                              ?.toDouble() ??
                          0,
                    ),
                    icon: Icons.account_balance_wallet,
                    color: forecastColor,
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isCompleted ? null : onAddSavings,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: Colors.green.withOpacity(.15),
              disabledForegroundColor: Colors.green,
            ),
            icon: const Icon(Icons.savings),
            label: const Text('Add Savings'),
          ),
        ),
      ],
    );
  }
}

class _ForecastMetric extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ForecastMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(.15),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
