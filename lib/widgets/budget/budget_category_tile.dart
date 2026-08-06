import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BudgetCategoryTile extends StatelessWidget {
  final String category;
  final double amount;
  final double totalSpent;
  final Color color;

  const BudgetCategoryTile({
    super.key,
    required this.category,
    required this.amount,
    required this.totalSpent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0");

    final percentage = totalSpent == 0 ? 0 : (amount / totalSpent) * 100;
    final compact = MediaQuery.of(context).orientation == Orientation.landscape;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: compact ? 5 : 7, backgroundColor: color),

            SizedBox(width: compact ? 8 : 14),

            Expanded(
              child: Text(
                category,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 13 : 15,
                ),
              ),
            ),

            Text(
              "${percentage.toStringAsFixed(0)}%",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: compact ? 13 : 15,
              ),
            ),

            SizedBox(width: compact ? 6 : 10),

            Text(
              "KES ${formatter.format(amount)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: compact ? 13 : 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
