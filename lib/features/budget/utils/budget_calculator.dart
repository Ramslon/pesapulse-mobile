import 'package:flutter/material.dart';

class BudgetCalculator {
  static double percentageUsed({
    required double budget,
    required double spent,
  }) {
    if (budget <= 0) return 0;
    return (spent / budget) * 100;
  }

  static double remaining({required double budget, required double spent}) {
    return budget - spent;
  }

  static int daysRemaining() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0);

    return lastDay.day - now.day;
  }

  static Color statusColor(BuildContext context, String budgetStatus) {
    switch (budgetStatus) {
      case 'healthy':
        return Colors.green;

      case 'warning':
        return Colors.orange;

      case 'critical':
        return Colors.red;

      case 'overspent':
        return Colors.deepOrange;

      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  static String statusText(String budgetStatus) {
    switch (budgetStatus) {
      case 'healthy':
        return 'Healthy';

      case 'warning':
        return 'Warning';

      case 'critical':
        return 'Critical';

      case 'overspent':
        return 'Exceeded';

      default:
        return 'Unknown';
    }
  }

  static String formatCurrency(double value) {
    return value
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
