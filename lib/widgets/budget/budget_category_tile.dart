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
    final formatter = NumberFormat("#,##0.00");

    final percentage = totalSpent == 0 ? 0 : (amount / totalSpent) * 100;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 7, backgroundColor: color),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

            Text(
              "${percentage.toStringAsFixed(0)}%",
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(width: 12),

            Text(
              "KES ${formatter.format(amount)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
