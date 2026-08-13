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
      compact: compact,
      tablet: tablet,
      desktop: desktop,
      landscape: landscape,
    );

    final analyticsCardHeight = _analyticsCardHeight(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
      landscape: landscape,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BudgetSectionHeader(
          title: "Spending Analytics",
          subtitle: "Insights from your spending habits",
        ),

        SizedBox(height: sectionSpacing),

        // ─────────────────────────────────────────
        // Spending trend chart
        // ─────────────────────────────────────────
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
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChartHeader(
                          context,
                          colorScheme,
                          compact: compact,
                        ),

                        SizedBox(height: compact ? 8 : 12),

                        SizedBox(
                          height: chartHeight,
                          child: SpendingTrendChart(
                            dailySpending: dailySpending,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),

        SizedBox(height: sectionSpacing),

        // ─────────────────────────────────────────
        // Analytics summary cards
        // ─────────────────────────────────────────
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

  Widget _buildChartHeader(
    BuildContext context,
    ColorScheme colorScheme, {
    required bool compact,
  }) {
    final total = dailySpending.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: compact ? 34 : 40,
          height: compact ? 34 : 40,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(.10),
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
          ),
          child: Icon(
            Icons.trending_up_rounded,
            color: colorScheme.primary,
            size: compact ? 18 : 21,
          ),
        ),

        SizedBox(width: compact ? 10 : 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Daily Spending Trend",
                style: TextStyle(
                  fontSize: compact ? 13 : 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Last 7 days",
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  color: colorScheme.onSurface.withOpacity(.55),
                ),
              ),
            ],
          ),
        ),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(total),
              style: TextStyle(
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Total",
              style: TextStyle(
                fontSize: compact ? 9 : 10,
                color: colorScheme.onSurface.withOpacity(.5),
              ),
            ),
          ],
        ),
      ],
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
    final highestDayCard = AnalyticsCard(
      icon: Icons.calendar_today_rounded,
      title: "Highest Day",
      value: "${CurrencyFormatter.format(highestDayAmount)} • $highestDay",
      color: colorScheme.primary,
    );

    final averageCard = AnalyticsCard(
      icon: Icons.analytics_rounded,
      title: "Avg Daily Spending",
      value: CurrencyFormatter.format(averageDaily),
      color: colorScheme.primary,
    );

    final projectionCard = AnalyticsCard(
      icon: Icons.trending_up_rounded,
      title: "Projected Month-End",
      value: CurrencyFormatter.format(estimatedMonthEnd),
      color: colorScheme.primary,
    );

    // Tablet and desktop:
    // three cards in one row.
    if (desktop || tablet) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SizedBox(height: cardHeight, child: highestDayCard),
          ),

          SizedBox(width: spacing),

          Expanded(
            child: SizedBox(height: cardHeight, child: averageCard),
          ),

          SizedBox(width: spacing),

          Expanded(
            child: SizedBox(height: cardHeight, child: projectionCard),
          ),
        ],
      );
    }

    // Mobile:
    // two cards on the first row,
    // projection card below.
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SizedBox(height: cardHeight, child: highestDayCard),
            ),

            SizedBox(width: spacing),

            Expanded(
              child: SizedBox(height: cardHeight, child: averageCard),
            ),
          ],
        ),

        SizedBox(height: spacing),

        SizedBox(
          width: double.infinity,
          height: cardHeight,
          child: projectionCard,
        ),
      ],
    );
  }

  double _chartHeight({
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

  double _analyticsCardHeight({
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
