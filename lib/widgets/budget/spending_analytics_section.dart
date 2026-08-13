import 'package:flutter/material.dart';

import '../empty_state.dart';
import '../spending_trend_chart.dart';
import '../analytics_card.dart';
import 'package:pesapulse_mobile/screens/add_expense_screen.dart';
import 'package:pesapulse_mobile/core/utils/currency_formatter.dart';
import 'budget_section_header.dart';

import '../../utils/responsive_helper.dart';

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

    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final sectionSpacing = ResponsiveHelper.sectionSpacing(context);

    final spacing = ResponsiveHelper.spacing(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final chartHeight = _chartHeight(
      context,
      compact: compact,
      tablet: tablet,
      desktop: desktop,
      landscape: landscape,
    );

    final analyticsCardHeight = _analyticsCardHeight(
      context,
      compact: compact,
      tablet: tablet,
      desktop: desktop,
      landscape: landscape,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BudgetSectionHeader(
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
            elevation: 1,
            shadowColor: colorScheme.primary.withOpacity(.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(compact ? 18 : 22),
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: dailySpending.isEmpty
                  ? EmptyState(
                      icon: Icons.show_chart_rounded,
                      title: "No Spending History",
                      message:
                          "Your daily spending trend will appear after recording expenses.",
                      action: ElevatedButton.icon(
                        icon: const Icon(Icons.receipt_long_rounded),
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
                  : SizedBox(
                      height: chartHeight,
                      child: SpendingTrendChart(dailySpending: dailySpending),
                    ),
            ),
          ),
        ),

        SizedBox(height: spacing),

        _buildChartLegend(context, colorScheme, compact: compact),

        SizedBox(height: sectionSpacing),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 20, end: 0),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOut,
          builder: (context, offset, child) {
            return Transform.translate(offset: Offset(0, offset), child: child);
          },
          child: _buildAnalyticsCards(
            context,
            colorScheme,
            spacing: spacing,
            cardHeight: analyticsCardHeight,
            compact: compact,
            tablet: tablet,
            desktop: desktop,
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend(
    BuildContext context,
    ColorScheme colorScheme, {
    required bool compact,
  }) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(.07),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 9 : 11,
              height: compact ? 9 : 11,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),

            SizedBox(width: compact ? 7 : 9),

            Text(
              "Daily Spending",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: compact ? 12 : 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCards(
    BuildContext context,
    ColorScheme colorScheme, {
    required double spacing,
    required double cardHeight,
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    final cards = [
      AnalyticsCard(
        icon: Icons.calendar_today_rounded,
        title: "Highest Day",
        value: "${CurrencyFormatter.format(highestDayAmount)} • $highestDay",
        color: colorScheme.primary,
      ),
      AnalyticsCard(
        icon: Icons.analytics_rounded,
        title: "Avg Daily Spending",
        value: CurrencyFormatter.format(averageDaily),
        color: colorScheme.primary,
      ),
    ];

    // On larger screens, keep the three analytics cards
    // in one row where there is enough horizontal space.
    if (desktop || tablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SizedBox(height: cardHeight, child: cards[0]),
          ),

          SizedBox(width: spacing),

          Expanded(
            child: SizedBox(height: cardHeight, child: cards[1]),
          ),

          SizedBox(width: spacing),

          Expanded(
            child: SizedBox(
              height: cardHeight,
              child: AnalyticsCard(
                icon: Icons.trending_up_rounded,
                title: "Projected Month-End",
                value: CurrencyFormatter.format(estimatedMonthEnd),
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SizedBox(height: cardHeight, child: cards[0]),
            ),

            SizedBox(width: spacing),

            Expanded(
              child: SizedBox(height: cardHeight, child: cards[1]),
            ),
          ],
        ),

        SizedBox(height: spacing),

        SizedBox(
          width: double.infinity,
          height: cardHeight,
          child: AnalyticsCard(
            icon: Icons.trending_up_rounded,
            title: "Projected Month-End Spending",
            value: CurrencyFormatter.format(estimatedMonthEnd),
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  double _chartHeight(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    if (desktop) {
      return 280;
    }

    if (tablet) {
      return landscape ? 220 : 260;
    }

    if (landscape) {
      return 150;
    }

    if (compact) {
      return 210;
    }

    return 240;
  }

  double _analyticsCardHeight(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    if (desktop) {
      return 145;
    }

    if (tablet) {
      return landscape ? 135 : 150;
    }

    if (landscape) {
      return 120;
    }

    if (compact) {
      return 125;
    }

    return 145;
  }
}
