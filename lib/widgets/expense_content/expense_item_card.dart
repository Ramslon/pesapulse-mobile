import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../screens/expense_details_screen.dart';
import '../../utils/responsive_helper.dart';

class ExpenseItemCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final String searchQuery;

  final NumberFormat currencyFormatter;

  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onDuplicate;
  const ExpenseItemCard({
    super.key,
    required this.expense,
    required this.searchQuery,
    required this.currencyFormatter,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
  });

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

  String formatDate(String date) {
    final expenseDate = DateTime.parse(date);
    final today = DateTime.now();

    final difference = today.difference(expenseDate).inDays;

    if (difference == 0) return "Today";
    if (difference == 1) return "Yesterday";

    return "${expenseDate.day}/${expenseDate.month}/${expenseDate.year}";
  }

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String query,
    bool compact,
  ) {
    final textStyle = TextStyle(
      fontSize: compact ? 14 : 16,
      fontWeight: FontWeight.w600,
    );

    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    final start = lowerText.indexOf(lowerQuery);

    if (start == -1) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      );
    }

    final end = start + query.length;

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: textStyle.copyWith(
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: textStyle.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final category = expense["category"] ?? "Other";
    final color = categoryColor(category);

    final amount = double.tryParse(expense["amount"].toString()) ?? 0;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 250),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: ValueKey(expense["id"]),

        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            await onEdit?.call();
            return false;
          }

          await onDelete?.call();
          return false;
        },
        background: _buildEditBackground(context, compact),

        secondaryBackground: _buildDeleteBackground(context, compact),

        child: _buildCard(
          context,
          compact,
          horizontalPadding,
          category,
          color,
          amount,
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    bool compact,
    double horizontalPadding,
    String category,
    Color color,
    double amount,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Row(
          children: [
            Container(width: compact ? 4 : 5, color: color),

            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExpenseDetailsScreen(expense: expense),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 12 : 16,
                    vertical: compact ? 11 : 14,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: compact ? 20 : 24,
                        backgroundColor: color.withOpacity(.12),
                        child: Icon(
                          categoryIcon(category),
                          color: color,
                          size: compact ? 20 : 24,
                        ),
                      ),

                      SizedBox(width: compact ? 10 : 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHighlightedText(
                              context,
                              expense["title"] ?? "",
                              searchQuery,
                              compact,
                            ),

                            const SizedBox(height: 4),

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
                                      fontSize: compact ? 11 : 13,
                                    ),
                                  ),
                                ),

                                SizedBox(width: compact ? 5 : 8),

                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),

                                SizedBox(width: compact ? 5 : 8),

                                Flexible(
                                  child: Text(
                                    formatDate(expense["expense_date"]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: compact ? 10 : 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: compact ? 6 : 12),

                      _buildAmountAndMenu(context, compact, amount),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountAndMenu(
    BuildContext context,
    bool compact,
    double amount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 105 : 150),
          child: Text(
            "KES ${currencyFormatter.format(amount)}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: compact ? 12 : 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),

        SizedBox(height: compact ? 2 : 4),

        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          iconSize: compact ? 18 : 20,
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case "edit":
                await onEdit?.call();
                break;

              case "delete":
                await onDelete?.call();
                break;

              case "duplicate":
                await onDuplicate?.call();
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: "edit",
              child: Row(
                children: [Icon(Icons.edit), SizedBox(width: 10), Text("Edit")],
              ),
            ),
            PopupMenuItem(
              value: "delete",
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 10),
                  Text("Delete"),
                ],
              ),
            ),
            PopupMenuItem(
              value: "duplicate",
              child: Row(
                children: [
                  Icon(Icons.copy),
                  SizedBox(width: 10),
                  Text("Duplicate"),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEditBackground(BuildContext context, bool compact) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(Icons.edit, color: Colors.white, size: compact ? 20 : 24),
          SizedBox(width: compact ? 6 : 8),
          Text(
            "Edit",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 13 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteBackground(BuildContext context, bool compact) {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "Delete",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: compact ? 13 : 14,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Icon(Icons.delete, color: Colors.white, size: compact ? 20 : 24),
        ],
      ),
    );
  }
}
