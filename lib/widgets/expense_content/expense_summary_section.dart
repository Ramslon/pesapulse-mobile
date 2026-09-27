import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';
import '../../core/utils/currency_formatter.dart';

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

    final landscape = ResponsiveHelper.isLandscape(context);

    final horizontalPadding = ResponsiveHelper.horizontalPadding(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final cardRadius = compact ? 18.0 : 20.0;

    final iconSize = compact ? 42.0 : 48.0;

    final totalFontSize = compact
        ? 23.0
        : landscape
        ? 24.0
        : 27.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: compact ? 8 : 10,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(cardRadius),
          border: Border.all(color: colorScheme.outline.withOpacity(0.07)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wallet icon
                  Container(
                    width: iconSize,
                    height: iconSize,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(compact ? 13 : 15),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: colorScheme.primary,
                      size: compact ? 21 : 24,
                    ),
                  ),

                  SizedBox(width: compact ? 11 : 13),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SPENDING TOTAL',
                          style: TextStyle(
                            fontSize: compact ? 9.5 : 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: colorScheme.primary,
                          ),
                        ),

                        const SizedBox(height: 5),

                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.format(totalAmount),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: totalFontSize,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                              letterSpacing: -0.5,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          '$expenseCount '
                          '${expenseCount == 1 ? 'transaction' : 'transactions'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 11 : 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.52),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Transaction badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 9,
                      vertical: compact ? 5 : 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: compact ? 15 : 16,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              SizedBox(height: compact ? 15 : 18),

              Container(
                height: 1,
                color: colorScheme.outline.withOpacity(0.07),
              ),

              SizedBox(height: compact ? 13 : 15),

              ExpenseStatistics(
                categoryCount: categoryCount,
                highestExpense: highestExpense,
                averageExpense: averageExpense,
              ),

              SizedBox(height: compact ? 3 : 5),
            ],
          ),
        ),
      ),
    );
  }
}
