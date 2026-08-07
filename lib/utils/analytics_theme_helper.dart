import 'package:flutter/material.dart';

class AnalyticsThemeHelper {
  const AnalyticsThemeHelper._();

  // ---------------------------------------------------------------------------
  // Recommendation
  // ---------------------------------------------------------------------------

  static Color recommendationColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green;

      case 'warning':
        return Colors.orange;

      case 'overspent':
        return Colors.deepOrange;

      case 'critical':
        return Colors.red;

      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  static IconData recommendationIcon(String status) {
    switch (status.toLowerCase()) {
      case 'critical':
        return Icons.warning_rounded;

      case 'overspent':
        return Icons.error_outline;

      case 'warning':
        return Icons.info_outline;

      default:
        return Icons.check_circle;
    }
  }

  // ---------------------------------------------------------------------------
  // Financial Health
  // ---------------------------------------------------------------------------

  static Color financialHealthColor(BuildContext context, String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Colors.green;

      case 'good':
        return Colors.lightGreen;

      case 'fair':
        return Colors.orange;

      case 'poor':
        return Colors.deepOrange;

      case 'critical':
        return Colors.red;

      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  static IconData financialHealthIcon(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Icons.sentiment_very_satisfied;

      case 'good':
        return Icons.sentiment_satisfied;

      case 'fair':
        return Icons.sentiment_neutral;

      case 'poor':
        return Icons.sentiment_dissatisfied;

      case 'critical':
        return Icons.warning_rounded;

      default:
        return Icons.favorite;
    }
  }
}
