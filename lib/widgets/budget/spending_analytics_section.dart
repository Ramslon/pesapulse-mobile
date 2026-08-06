import 'package:flutter/material.dart';
import '../empty_state.dart';
import '../spending_trend_chart.dart';
import '../analytics_card.dart';
import 'package:pesapulse_mobile/screens/add_expense_screen.dart';
import 'package:pesapulse_mobile/core/utils/currency_formatter.dart';
import '../../core/constants/app_spacing.dart';
import 'budget_section_header.dart';

class SpendingAnalyticsSection extends StatelessWidget {
  final Map<String, double> dailySpending;
  final String highestDay;
  final double highestDayAmount;
  final double averageDaily;
  final double estimatedMonthEnd;

  const SpendingAnalyticsSection({
    super.key,
    required this.dailySpending,
    required this.highestDay,
    required this.highestDayAmount,
    required this.averageDaily,
    required this.estimatedMonthEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final screenHeight = MediaQuery.of(context).size.height;
    final cardPadding = MediaQuery.of(context).size.width * .05;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final smallSpacing = isLandscape ? 4.0 : 8.0;
    final sectionSpacing = isLandscape ? 12.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BudgetSectionHeader(
          title: "Spending Analytics",
          subtitle: "Insights from your spending habits",
        ),
        SizedBox(height: sectionSpacing),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 30, end: 0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (context, offset, child) {
            return Transform.translate(offset: Offset(0, offset), child: child);
          },
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: EdgeInsets.all(isLandscape ? 14 : cardPadding),
              child: dailySpending.isEmpty
                  ? EmptyState(
                      icon: Icons.show_chart,
                      title: "No Spending History",
                      message:
                          "Your daily spending trend will appear after recording expenses.",
                      action: ElevatedButton.icon(
                        icon: const Icon(Icons.receipt_long),
                        label: const Text("Add Expense"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AddExpenseScreen(),
                            ),
                          );
                        },
                      ),
                    )
                  // replace with your chart widget
                  : SpendingTrendChart(dailySpending: dailySpending),
            ),
          ),
        ),

        SizedBox(height: sectionSpacing),

        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            runSpacing: 8,
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                width: isLandscape ? 10 : 14,
                height: isLandscape ? 10 : 14,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),

              SizedBox(width: isLandscape ? 6 : 10),

              Flexible(
                child: Text(
                  "Daily Spending",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: smallSpacing),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 20, end: 0),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOut,
          builder: (context, offset, child) {
            return Transform.translate(offset: Offset(0, offset), child: child);
          },
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: isLandscape ? 120 : screenHeight * .21,
                      child: AnalyticsCard(
                        icon: Icons.calendar_today_rounded,
                        title: "Highest Day",
                        value: CurrencyFormatter.format(highestDayAmount),
                        color: colorScheme.primary,
                      ),
                    ),
                  ),

                  AppSpacing.hSm,

                  Expanded(
                    child: SizedBox(
                      height: isLandscape ? 120 : screenHeight * .21,
                      child: AnalyticsCard(
                        icon: Icons.analytics_rounded,
                        title: "Avg Daily Spending",
                        value: CurrencyFormatter.format(averageDaily),
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: sectionSpacing),

              SizedBox(
                height: isLandscape ? 120 : screenHeight * .21,
                child: AnalyticsCard(
                  icon: Icons.trending_up_rounded,
                  title: "Projected Month-End Spending",
                  value: CurrencyFormatter.format(estimatedMonthEnd),
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
