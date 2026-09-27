import 'package:flutter/material.dart';

import '../../screens/expense_details_screen.dart';
import '../../utils/responsive_helper.dart';
import '../../core/utils/currency_formatter.dart';

class ExpenseItemCard extends StatelessWidget {
  final Map<String, dynamic> expense;
  final String searchQuery;

  final String Function(num) currencyFormatter;

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

  String formatDate(String? date) {
    if (date == null || date.trim().isEmpty) {
      return 'Date unavailable';
    }

    final expenseDate = DateTime.tryParse(date);

    if (expenseDate == null) {
      return date;
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final targetDate = DateTime(
      expenseDate.year,
      expenseDate.month,
      expenseDate.day,
    );

    final difference = today.difference(targetDate).inDays;

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

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String query,
    bool compact,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final textStyle = TextStyle(
      fontSize: compact ? 13.5 : 14.5,
      fontWeight: FontWeight.w700,
      height: 1.15,
      color: colorScheme.onSurface,
    );

    if (query.trim().isEmpty) {
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
        style: textStyle,
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: textStyle.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w900,
              backgroundColor: colorScheme.primary.withOpacity(0.10),
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

    final category = (expense['category'] ?? 'Other').toString();

    final title = (expense['title'] ?? 'Untitled expense').toString();

    final amount = double.tryParse(expense['amount']?.toString() ?? '') ?? 0.0;

    final color = categoryColor(category);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 260),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Dismissible(
        key: ValueKey('${expense["id"]}_${expense["client_id"] ?? ""}'),
        direction: DismissDirection.horizontal,
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
          context: context,
          compact: compact,
          horizontalPadding: horizontalPadding,
          category: category,
          title: title,
          color: color,
          amount: amount,
        ),
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required bool compact,
    required double horizontalPadding,
    required String category,
    required String title,
    required Color color,
    required double amount,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final radius = compact ? 16.0 : 18.0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outline.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Row(
          children: [
            // Category accent
            Container(
              width: compact ? 4 : 5,
              height: compact ? 78 : 88,
              color: color.withOpacity(0.85),
            ),

            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExpenseDetailsScreen(expense: expense),
                      ),
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 11 : 14,
                      compact ? 10 : 12,
                      compact ? 8 : 11,
                      compact ? 10 : 12,
                    ),
                    child: Row(
                      children: [
                        // Category icon
                        Container(
                          width: compact ? 40 : 46,
                          height: compact ? 40 : 46,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(
                              compact ? 12 : 14,
                            ),
                          ),
                          child: Icon(
                            categoryIcon(category),
                            color: color,
                            size: compact ? 19 : 21,
                          ),
                        ),

                        SizedBox(width: compact ? 10 : 12),

                        // Main information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHighlightedText(
                                context,
                                title,
                                searchQuery,
                                compact,
                              ),

                              const SizedBox(height: 5),

                              Row(
                                children: [
                                  Flexible(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compact ? 6 : 7,
                                        vertical: compact ? 2.5 : 3,
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
                                          fontSize: compact ? 10.5 : 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),

                                  SizedBox(width: compact ? 6 : 8),

                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: colorScheme.onSurface.withOpacity(
                                        0.28,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                  ),

                                  SizedBox(width: compact ? 6 : 8),

                                  Flexible(
                                    child: Text(
                                      formatDate(
                                        expense['expense_date']?.toString(),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withOpacity(0.52),
                                        fontSize: compact ? 10.5 : 11.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: compact ? 6 : 10),

                        _buildAmountAndMenu(context, compact, amount),
                      ],
                    ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 105 : 145),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              currencyFormatter(amount),
              maxLines: 1,
              style: TextStyle(
                fontSize: compact ? 12.5 : 15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.15,
                color: Colors.red.shade600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 2),

        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 185),
          iconSize: compact ? 18 : 19,
          icon: Icon(
            Icons.more_horiz_rounded,
            color: colorScheme.onSurface.withOpacity(0.42),
          ),
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await onEdit?.call();
                break;

              case 'delete':
                await onDelete?.call();
                break;

              case 'duplicate':
                await onDuplicate?.call();
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 10),
                  Text('Edit'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  const SizedBox(width: 10),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy_outlined),
                  SizedBox(width: 10),
                  Text('Duplicate'),
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
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
      ),
      child: Row(
        children: [
          Icon(
            Icons.edit_outlined,
            color: Colors.white,
            size: compact ? 20 : 23,
          ),
          SizedBox(width: compact ? 6 : 8),
          Text(
            'Edit',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteBackground(BuildContext context, bool compact) {
    return Container(
      alignment: Alignment.centerRight,
      padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 22),
      decoration: BoxDecoration(
        color: Colors.red.shade600,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 13,
            ),
          ),
          SizedBox(width: compact ? 6 : 8),
          Icon(
            Icons.delete_outline,
            color: Colors.white,
            size: compact ? 20 : 23,
          ),
        ],
      ),
    );
  }
}
