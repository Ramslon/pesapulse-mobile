import 'package:flutter/material.dart';

import 'package:pesapulse_mobile/screens/expense_details_screen.dart';

import '../utils/responsive_helper.dart';
import '../core/utils/currency_formatter.dart';

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
        return Colors.blueGrey;
    }
  }

  IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'transport':
        return Icons.directions_car_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'health':
        return Icons.favorite_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final category = (expense['category'] ?? 'Other').toString().trim().isEmpty
        ? 'Other'
        : expense['category'].toString();

    final title = (expense['title'] ?? 'Untitled expense').toString();

    final amount = double.tryParse(expense['amount']?.toString() ?? '') ?? 0.0;

    final color = categoryColor(category);

    final avatarSize = compact
        ? 42.0
        : landscape
        ? 46.0
        : 48.0;

    final iconSize = compact
        ? 20.0
        : landscape
        ? 21.0
        : 22.0;

    final titleSize = compact
        ? 13.5
        : landscape
        ? 14.0
        : 14.5;

    final categorySize = compact
        ? 11.0
        : landscape
        ? 11.5
        : 12.0;

    final amountSize = compact
        ? 13.0
        : landscape
        ? 14.0
        : 15.0;

    final horizontalPadding = compact ? 2.0 : 3.0;
    final verticalPadding = compact
        ? 8.0
        : landscape
        ? 9.0
        : 10.0;

    final contentGap = compact
        ? 10.0
        : landscape
        ? 11.0
        : 12.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
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
              // Category icon
              Hero(
                tag: 'expense_${expense["id"]}',
                child: Container(
                  width: avatarSize,
                  height: avatarSize,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(compact ? 13 : 15),
                    border: Border.all(color: color.withOpacity(0.08)),
                  ),
                  child: Icon(
                    categoryIcon(category),
                    color: color,
                    size: iconSize,
                  ),
                ),
              ),

              SizedBox(width: contentGap),

              // Main information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        color: colorScheme.onSurface,
                      ),
                    ),

                    SizedBox(height: compact ? 4 : 5),

                    Row(
                      children: [
                        // Category badge
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 6 : 7,
                              vertical: compact ? 3 : 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: categorySize,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: compact ? 7 : 8),

                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withOpacity(0.30),
                            shape: BoxShape.circle,
                          ),
                        ),

                        SizedBox(width: compact ? 7 : 8),

                        Flexible(
                          child: Text(
                            formatDate(expense['expense_date']?.toString()),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colorScheme.onSurface.withOpacity(0.52),
                              fontSize: categorySize,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(width: compact ? 7 : 10),

              // Amount + navigation cue
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      CurrencyFormatter.format(amount),
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: amountSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Icon(
                    Icons.chevron_right_rounded,
                    size: compact ? 17 : 18,
                    color: colorScheme.onSurface.withOpacity(0.30),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatDate(String? date) {
    if (date == null || date.trim().isEmpty) {
      return 'Date unavailable';
    }

    final expenseDate = DateTime.tryParse(date);

    if (expenseDate == null) {
      return date;
    }

    final today = DateTime.now();

    final todayDate = DateTime(today.year, today.month, today.day);

    final targetDate = DateTime(
      expenseDate.year,
      expenseDate.month,
      expenseDate.day,
    );

    final difference = todayDate.difference(targetDate).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    if (difference > 1 && difference < 7) {
      return '$difference days ago';
    }

    return '${expenseDate.day}/${expenseDate.month}/${expenseDate.year}';
  }
}
