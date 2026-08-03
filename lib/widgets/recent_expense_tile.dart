import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesapulse_mobile/screens/expense_details_screen.dart';

class RecentExpenseTile extends StatelessWidget {
  final Map<String, dynamic> expense;

  RecentExpenseTile({super.key, required this.expense});
  final NumberFormat currencyFormatter = NumberFormat("#,##0.00");

  Color categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;

      case 'transport':
        return Colors.blue;

      case 'shopping':
        return Colors.purple;

      case 'bills':
        return Colors.red;

      case 'health':
        return Colors.green;

      case 'education':
        return Colors.indigo;

      case 'entertainment':
        return Colors.pink;

      default:
        return Colors.grey;
    }
  }

  IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;

      case 'transport':
        return Icons.directions_car;

      case 'shopping':
        return Icons.shopping_bag;

      case 'bills':
        return Icons.receipt_long;

      case 'health':
        return Icons.favorite;

      case 'education':
        return Icons.school;

      case 'entertainment':
        return Icons.movie;

      default:
        return Icons.account_balance_wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = expense['category'] ?? 'Other';

    final color = categoryColor(category);

    final amount = double.tryParse(expense["amount"].toString()) ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExpenseDetailsScreen(expense: expense),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Hero(
              tag: "expense_${expense["id"]}",
              child: CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(.12),
                child: Icon(categoryIcon(category), color: color, size: 24),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense["title"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Row(
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),

                      const SizedBox(width: 8),

                      Flexible(
                        child: Text(
                          formatDate(expense["expense_date"]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            Text(
              "KES ${currencyFormatter.format(amount)}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(String date) {
    final expenseDate = DateTime.parse(date);
    final today = DateTime.now();

    final difference = today.difference(expenseDate).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Yesterday";

    return "${expenseDate.day}/${expenseDate.month}/${expenseDate.year}";
  }
}
