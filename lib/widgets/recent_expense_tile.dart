import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pesapulse_mobile/screens/expense_details_screen.dart';

import '../utils/responsive_helper.dart';

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
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final category = expense['category'] ?? 'Other';
    final color = categoryColor(category);

    final amount = double.tryParse(expense["amount"].toString()) ?? 0;

    // Responsive dimensions
    final avatarRadius = compact
        ? 21.0
        : landscape
        ? 23.0
        : 24.0;

    final iconSize = compact
        ? 21.0
        : landscape
        ? 23.0
        : 24.0;

    final titleFontSize = compact
        ? 14.0
        : landscape
        ? 15.0
        : 16.0;

    final categoryFontSize = compact
        ? 12.0
        : landscape
        ? 12.5
        : 13.0;

    final dateFontSize = compact
        ? 11.0
        : landscape
        ? 11.5
        : 12.0;

    final amountFontSize = compact
        ? 13.0
        : landscape
        ? 15.0
        : 16.0;

    final horizontalPadding = compact ? 2.0 : 4.0;
    final verticalPadding = compact ? 8.0 : 10.0;

    final contentSpacing = compact ? 10.0 : 14.0;
    final trailingSpacing = compact ? 8.0 : 12.0;

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
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Hero(
              tag: "expense_${expense["id"]}",
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: color.withOpacity(.12),
                child: Icon(
                  categoryIcon(category),
                  color: color,
                  size: iconSize,
                ),
              ),
            ),

            SizedBox(width: contentSpacing),

            // Main information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    expense["title"] ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  SizedBox(height: compact ? 3 : 4),

                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w500,
                            fontSize: categoryFontSize,
                          ),
                        ),
                      ),

                      SizedBox(width: compact ? 6 : 8),

                      Container(
                        width: compact ? 3 : 4,
                        height: compact ? 3 : 4,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),

                      SizedBox(width: compact ? 6 : 8),

                      Flexible(
                        child: Text(
                          formatDate(expense["expense_date"]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: dateFontSize,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: trailingSpacing),

            // Amount
            Flexible(
              flex: 0,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  "KES ${currencyFormatter.format(amount)}",
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: amountFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
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
