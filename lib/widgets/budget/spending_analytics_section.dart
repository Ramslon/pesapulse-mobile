import 'package:flutter/material.dart';

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
          title: 'Spending Analytics',
          subtitle: 'Insights from your recent spending activity',
        ),

        SizedBox(height: sectionSpacing),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 24, end: 0),
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) {
            return Transform.translate(offset: Offset(0, offset), child: child);
          },
          child: _buildChartCard(
            context,
            theme: theme,
            colorScheme: colorScheme,
            cardPadding: cardPadding,
            chartHeight: chartHeight,
            compact: compact,
            desktop: desktop,
          ),
        ),

        SizedBox(height: sectionSpacing),

        TweenAnimationBuilder<double>(
          tween: Tween(begin: 16, end: 0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) {
            return Transform.translate(offset: Offset(0, offset), child: child);
          },
          child: _buildAnalyticsCards(
            context,
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

  Widget _buildChartCard(
    BuildContext context, {
    required ThemeData theme,
    required ColorScheme colorScheme,
    required double cardPadding,
    required double chartHeight,
    required bool compact,
    required bool desktop,
  }) {
    final radius = desktop
        ? 22.0
        : compact
        ? 17.0
        : 20.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(
              theme.brightness == Brightness.dark ? 0.06 : 0.04,
            ),
            blurRadius: desktop ? 20 : 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: dailySpending.isEmpty
            ? _buildEmptyState(context, compact: compact, desktop: desktop)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildChartHeader(
                    context,
                    colorScheme,
                    compact: compact,
                    desktop: desktop,
                  ),

                  SizedBox(height: compact ? 10 : 14),

                  Container(
                    width: double.infinity,
                    height: chartHeight,
                    padding: EdgeInsets.only(top: compact ? 4 : 6),
                    child: SpendingTrendChart(
                      dailySpending: dailySpending,
                      height: chartHeight,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildChartHeader(
    BuildContext context,
    ColorScheme colorScheme, {
    required bool compact,
    required bool desktop,
  }) {
    final total = dailySpending.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    final iconBox = desktop
        ? 42.0
        : compact
        ? 34.0
        : 39.0;

    final iconSize = desktop
        ? 21.0
        : compact
        ? 17.0
        : 19.0;

    final titleSize = desktop
        ? 15.5
        : compact
        ? 12.5
        : 14.0;

    final subtitleSize = desktop
        ? 11.5
        : compact
        ? 9.5
        : 10.5;

    final totalSize = desktop
        ? 16.0
        : compact
        ? 12.0
        : 14.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconBox,
          height: iconBox,
          decoration: BoxDecoration(
            color: const Color(0xFF0F9D8A).withOpacity(0.09),
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            border: Border.all(
              color: const Color(0xFF0F9D8A).withOpacity(0.10),
            ),
          ),
          child: Icon(
            Icons.show_chart_rounded,
            color: const Color(0xFF0F9D8A),
            size: iconSize,
          ),
        ),

        SizedBox(width: compact ? 9 : 11),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Daily Spending Trend',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),

                  const SizedBox(width: 7),

                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 6 : 7,
                      vertical: compact ? 3 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(
                        0.65,
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      '7 DAYS',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withOpacity(0.68),
                        fontSize: compact ? 7 : 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 3),

              Text(
                'Recent daily spending activity',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.62),
                  fontSize: subtitleSize,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(total),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: totalSize,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              'TOTAL',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.58),
                fontSize: compact ? 7.5 : 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required bool compact,
    required bool desktop,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconBoxSize = desktop
        ? 62.0
        : compact
        ? 52.0
        : 58.0;

    final iconSize = desktop
        ? 29.0
        : compact
        ? 23.0
        : 26.0;

    final titleSize = desktop
        ? 15.0
        : compact
        ? 12.5
        : 14.0;

    final messageSize = desktop
        ? 12.5
        : compact
        ? 10.5
        : 11.5;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: desktop
              ? 28
              : compact
              ? 18
              : 22,
        ),
        child: Column(
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(compact ? 15 : 18),
              ),
              child: Icon(
                Icons.insights_outlined,
                color: colorScheme.primary,
                size: iconSize,
              ),
            ),

            SizedBox(height: compact ? 10 : 12),

            Text(
              'No Spending History',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 5),

            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                'Your daily spending trend will appear here after you record expenses.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.68),
                  fontSize: messageSize,
                  height: 1.4,
                ),
              ),
            ),

            SizedBox(height: compact ? 13 : 16),

            SizedBox(
              height: desktop
                  ? 42
                  : compact
                  ? 36
                  : 40,
              child: ElevatedButton.icon(
                icon: Icon(Icons.add_rounded, size: compact ? 16 : 18),
                label: Text(
                  'Add Expense',
                  style: TextStyle(
                    fontSize: compact ? 11 : 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCards(
    BuildContext context, {
    required double spacing,
    required double cardHeight,
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    final highestDayCard = AnalyticsCard(
      icon: Icons.calendar_month_rounded,
      title: 'Highest Day',
      value: '${CurrencyFormatter.format(highestDayAmount)} • $highestDay',
      color: const Color(0xFFF59E0B),
    );

    final averageCard = AnalyticsCard(
      icon: Icons.speed_rounded,
      title: 'Avg Daily Spending',
      value: CurrencyFormatter.format(averageDaily),
      color: colorScheme.primary,
    );

    final projectionCard = AnalyticsCard(
      icon: Icons.auto_graph_rounded,
      title: 'Projected Month-End',
      value: CurrencyFormatter.format(estimatedMonthEnd),
      color: const Color(0xFF7C3AED),
    );

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

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: highestDayCard),

              SizedBox(width: spacing),

              Expanded(child: averageCard),
            ],
          ),
        ),

        SizedBox(height: spacing),

        SizedBox(
          height: cardHeight,
          width: double.infinity,
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
