import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/core/utils/currency_formatter.dart';

import '../fade_slide_animation.dart';
import '../../utils/responsive_helper.dart';
import '/utils/analytics_layout_helper.dart';

class CategoryBreakdownChart extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final double chartHeight;

  const CategoryBreakdownChart({
    super.key,
    required this.categoryTotals,
    required this.chartHeight,
  });

  @override
  State<CategoryBreakdownChart> createState() => _CategoryBreakdownChartState();
}

class _CategoryBreakdownChartState extends State<CategoryBreakdownChart> {
  int? touchedIndex;

  static const List<Color> _colors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  List<MapEntry<String, double>> get _validEntries {
    return widget.categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList();
  }

  double get _totalSpending {
    return _validEntries.fold<double>(0, (sum, entry) => sum + entry.value);
  }

  List<PieChartSectionData> _getSections(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    final entries = _validEntries;

    if (entries.isEmpty) {
      return [];
    }

    final baseRadius = desktop
        ? 92.0
        : tablet
        ? 80.0
        : compact
        ? 54.0
        : landscape
        ? 58.0
        : 66.0;

    return entries.asMap().entries.map((item) {
      final index = item.key;
      final entry = item.value;

      final isTouched = touchedIndex == index;

      return PieChartSectionData(
        color: _colors[index % _colors.length],
        value: entry.value,

        // Keep the chart clean.
        title: '',

        radius: isTouched ? baseRadius + (compact ? 5 : 8) : baseRadius,

        badgeWidget: isTouched
            ? _CategoryBadge(name: entry.key, amount: entry.value)
            : null,

        badgePositionPercentageOffset: compact ? 1.15 : 1.25,
      );
    }).toList();
  }

  Map<String, dynamic>? _getSelectedCategory() {
    if (touchedIndex == null) {
      return null;
    }

    final entries = _validEntries;

    if (touchedIndex! < 0 || touchedIndex! >= entries.length) {
      return null;
    }

    final entry = entries[touchedIndex!];

    final percentage = _totalSpending == 0
        ? 0.0
        : (entry.value / _totalSpending) * 100;

    return {
      'name': entry.key,
      'amount': entry.value,
      'percentage': percentage,
      'color': _colors[touchedIndex! % _colors.length],
    };
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final selectedCategory = _getSelectedCategory();

    final chartWidth = AnalyticsLayoutHelper.maxChartWidth(context);

    final cardPadding = desktop
        ? 20.0
        : tablet
        ? 18.0
        : compact
        ? 10.0
        : landscape
        ? 12.0
        : 14.0;

    final centerSpaceRadius = desktop
        ? 58.0
        : tablet
        ? 52.0
        : compact
        ? 34.0
        : landscape
        ? 38.0
        : 46.0;

    final centerIconSize = desktop
        ? 28.0
        : tablet
        ? 26.0
        : compact
        ? 18.0
        : landscape
        ? 20.0
        : 24.0;

    final centerTitleSize = desktop
        ? 13.0
        : tablet
        ? 12.0
        : compact
        ? 9.0
        : 11.0;

    final centerAmountSize = desktop
        ? 20.0
        : tablet
        ? 19.0
        : compact
        ? 14.0
        : landscape
        ? 15.0
        : 18.0;

    final sections = _getSections(
      context,
      compact: compact,
      tablet: tablet,
      desktop: desktop,
      landscape: landscape,
    );

    return FadeSlideAnimation(
      delay: 200,
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: chartWidth),
              child: Card(
                elevation: compact ? 1 : 2,
                shadowColor: Colors.black.withOpacity(.08),
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(compact ? 15 : 20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: SizedBox(
                    height: widget.chartHeight,
                    width: double.infinity,
                    child: sections.isEmpty
                        ? Center(
                            child: Text(
                              'No category spending data',
                              style: TextStyle(
                                fontSize: compact ? 11 : 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sections: sections,
                                  centerSpaceRadius: centerSpaceRadius,
                                  sectionsSpace: compact ? 2 : 4,
                                  startDegreeOffset: -90,
                                  pieTouchData: PieTouchData(
                                    touchCallback:
                                        (
                                          FlTouchEvent event,
                                          PieTouchResponse? response,
                                        ) {
                                          if (!event
                                                  .isInterestedForInteractions ||
                                              response?.touchedSection ==
                                                  null) {
                                            if (touchedIndex != null) {
                                              setState(() {
                                                touchedIndex = null;
                                              });
                                            }

                                            return;
                                          }

                                          final newIndex = response!
                                              .touchedSection!
                                              .touchedSectionIndex;

                                          if (newIndex != touchedIndex) {
                                            setState(() {
                                              touchedIndex = newIndex;
                                            });
                                          }
                                        },
                                  ),
                                ),
                                swapAnimationDuration: const Duration(
                                  milliseconds: 350,
                                ),
                                swapAnimationCurve: Curves.easeOutCubic,
                              ),

                              // ─────────────────────────────────
                              // Center information
                              // ─────────────────────────────────
                              IgnorePointer(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pie_chart_rounded,
                                      size: centerIconSize,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),

                                    SizedBox(height: compact ? 3 : 6),

                                    Text(
                                      'Total Spending',
                                      style: TextStyle(
                                        fontSize: centerTitleSize,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    SizedBox(height: compact ? 2 : 3),

                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        CurrencyFormatter.format(
                                          _totalSpending,
                                        ),
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: centerAmountSize,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          if (selectedCategory != null) ...[
            SizedBox(height: ResponsiveHelper.spacing(context)),

            _SelectedCategoryCard(
              name: selectedCategory['name'] as String,
              amount: selectedCategory['amount'] as double,
              percentage: selectedCategory['percentage'] as double,
              color: selectedCategory['color'] as Color,
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Category badge
// ─────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final String name;
  final double amount;

  const _CategoryBadge({required this.name, required this.amount});

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);

    final maxWidth = compact ? 90.0 : 130.0;
    final horizontalPadding = compact ? 6.0 : 8.0;
    final verticalPadding = compact ? 4.0 : 6.0;

    return Material(
      elevation: compact ? 2 : 3,
      borderRadius: BorderRadius.circular(compact ? 7 : 10),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(compact ? 7 : 10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 9 : 11,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: compact ? 1 : 2),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                CurrencyFormatter.format(amount),
                style: TextStyle(
                  fontSize: compact ? 8 : 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────
// Selected category card
// ─────────────────────────────────────────────────────

class _SelectedCategoryCard extends StatelessWidget {
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  const _SelectedCategoryCard({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final padding = desktop
        ? 18.0
        : tablet
        ? 16.0
        : compact
        ? 9.0
        : landscape
        ? 11.0
        : 14.0;

    final indicatorWidth = compact ? 8.0 : 12.0;

    final indicatorHeight = compact ? 34.0 : 42.0;

    final titleSize = desktop
        ? 16.0
        : tablet
        ? 15.0
        : compact
        ? 11.0
        : landscape
        ? 12.0
        : 16.0;

    final amountSize = desktop
        ? 13.0
        : tablet
        ? 12.5
        : compact
        ? 9.0
        : 13.0;

    final percentageSize = desktop
        ? 14.0
        : tablet
        ? 13.0
        : compact
        ? 10.0
        : landscape
        ? 11.0
        : 14.0;

    return Card(
      elevation: compact ? 1 : 1,
      shadowColor: Colors.black.withOpacity(.06),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 12 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: indicatorWidth,
              height: indicatorHeight,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            SizedBox(width: compact ? 8 : 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: compact ? 2 : 4),

                  Text(
                    CurrencyFormatter.format(amount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: amountSize,
                      color: colorScheme.onSurface.withOpacity(.60),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: compact ? 6 : 10),

            // Percentage badge
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 7 : 12,
                  vertical: compact ? 5 : 7,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: percentageSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
