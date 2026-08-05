import 'package:flutter/material.dart';
import 'status_chip.dart';

class BudgetAlertCard extends StatelessWidget {
  final String budgetStatus;
  final double budget;
  final double percentageUsed;
  final String recommendation;

  const BudgetAlertCard({
    super.key,
    required this.budgetStatus,
    required this.budget,
    required this.percentageUsed,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String title;

    switch (budgetStatus) {
      case 'healthy':
        icon = Icons.check_circle;
        color = Colors.green;
        title = 'Budget Healthy';
        break;

      case 'warning':
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
        title = 'Budget Warning';
        break;

      case 'overspent':
        icon = Icons.error_outline;
        color = Colors.deepOrange;
        title = 'Budget Exceeded';
        break;

      case 'critical':
        icon = Icons.dangerous;
        color = Colors.red;
        title = 'Critical Budget Alert';
        break;

      default:
        return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(.15),
              child: Icon(icon, size: 32, color: color),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusChip(text: title, color: color, icon: icon),

                  const SizedBox(height: 12),

                  Text(
                    budget > 0
                        ? '${percentageUsed.toStringAsFixed(1)}% of your budget has been used.'
                        : 'No monthly budget has been set.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    recommendation,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
