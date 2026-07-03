import 'package:flutter/material.dart';

class RecentExpenseTile extends StatelessWidget {
  final Map<String, dynamic> expense;

  const RecentExpenseTile({super.key, required this.expense});

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

    return ListTile(
      contentPadding: EdgeInsets.zero,

      leading: CircleAvatar(
        radius: 22,
        backgroundColor: color.withOpacity(.12),
        child: Icon(categoryIcon(category), color: color),
      ),

      title: Text(
        expense['title'] ?? '',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),

      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(category),

          const SizedBox(height: 2),

          Text(
            expense['expense_date'] ?? '',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),

      trailing: Text(
        "KES ${expense['amount']}",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
          fontSize: 15,
        ),
      ),
    );
  }
}
