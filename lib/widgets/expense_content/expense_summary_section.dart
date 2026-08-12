import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../utils/responsive_helper.dart';

import '../../widgets/expense_content/expense_statistics.dart';

class ExpenseSummarySection extends StatelessWidget {
  final double totalAmount;
  final int expenseCount;
  final int categoryCount;
  final double highestExpense;
  final double averageExpense;

  const ExpenseSummarySection({
    super.key,
    required this.totalAmount,
    required this.expenseCount,
    required this.categoryCount,
    required this.highestExpense,
    required this.averageExpense,
  });

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);
    final spacing = ResponsiveHelper.spacing(context);

    final currencyFormatter = NumberFormat("#,##0.00");

    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = Theme.of(context).colorScheme.surface;

    final avatarRadius = compact ? 22.0 : 26.0;
    final iconSize = compact ? 21.0 : 24.0;

    final amountFontSize = compact ? 19.0 : 24.0;
    final transactionFontSize = compact ? 12.0 : 14.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.horizontalPadding(context),
        vertical: compact ? 8 : 12,
      ),
      child: Card(
        elevation: 2,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 14 : 18),
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: primaryColor.withOpacity(.12),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: primaryColor,
                  size: iconSize,
                ),
              ),

              SizedBox(width: spacing),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "KES ${currencyFormatter.format(totalAmount)}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: amountFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "$expenseCount "
                      "${expenseCount == 1 ? "Transaction" : "Transactions"}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: transactionFontSize,
                      ),
                    ),

                    SizedBox(
                      height: compact
                          ? ResponsiveHelper.spacing(context)
                          : ResponsiveHelper.sectionSpacing(context) * 0.55,
                    ),

                    ExpenseStatistics(
                      categoryCount: categoryCount,
                      highestExpense: highestExpense,
                      averageExpense: averageExpense,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
