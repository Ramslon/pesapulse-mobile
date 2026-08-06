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

    final compact = MediaQuery.of(context).orientation == Orientation.landscape;

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.15)),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: compact ? 22 : 30,
              backgroundColor: color.withOpacity(.15),
              child: Icon(icon, size: compact ? 22 : 32, color: color),
            ),

            SizedBox(width: compact ? 10 : 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusChip(text: title, color: color, icon: icon),

                  SizedBox(height: compact ? 8 : 12),

                  Text(
                    budget > 0
                        ? '${percentageUsed.toStringAsFixed(1)}% of your budget has been used.'
                        : 'No monthly budget has been set.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: compact ? 12 : 14,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    recommendation,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 12 : 14,
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
