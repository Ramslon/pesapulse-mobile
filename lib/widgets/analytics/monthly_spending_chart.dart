import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/core/utils/currency_formatter.dart';

import '../fade_slide_animation.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/analytics_layout_helper.dart';

class MonthlySpendingChart extends StatefulWidget {
  final Map<String, double> monthlyTotals;
  final List expenses;
  final double chartHeight;

  const MonthlySpendingChart({
    super.key,
    required this.monthlyTotals,
    required this.expenses,
    required this.chartHeight,
  });

  @override
  State<MonthlySpendingChart> createState() => _MonthlySpendingChartState();
}

class _MonthlySpendingChartState extends State<MonthlySpendingChart> {
  String? touchedMonth;

  static const List<String> months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> fullMonths = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void didUpdateWidget(covariant MonthlySpendingChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.monthlyTotals != widget.monthlyTotals) {
      touchedMonth = null;
    }
  }

  List<MapEntry<String, double>> get _validEntries {
    return widget.monthlyTotals.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  double get _maxSpending {
    final entries = _validEntries;

    if (entries.isEmpty) {
      return 0;
    }

    return entries.map((entry) => entry.value).reduce((a, b) => a > b ? a : b);
  }

  double get _totalSpending {
    return _validEntries.fold(0, (sum, entry) => sum + entry.value);
  }

  String _monthLabel(String key) {
    final parts = key.split('-');

    if (parts.length != 2) {
      return key;
    }

    final month = int.tryParse(parts[1]);

    if (month == null || month < 1 || month > 12) {
      return key;
    }

    return months[month];
  }

  String _monthFullLabel(String key) {
    final parts = key.split('-');

    if (parts.length != 2) {
      return key;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);

    if (year == null || month == null || month < 1 || month > 12) {
      return key;
    }

    return '${fullMonths[month]} $year';
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toStringAsFixed(0);
  }

  List<BarChartGroupData> _getMonthlyBars(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    final entries = _validEntries;
    final colorScheme = Theme.of(context).colorScheme;

    final barWidth = desktop
        ? 22.0
        : tablet
        ? 19.0
        : compact
        ? 13.0
        : 16.0;

    final barsSpace = compact ? 2.0 : 4.0;

    return entries.asMap().entries.map((item) {
      final index = item.key;
      final entry = item.value;

      final isSelected = touchedMonth == entry.key;

      return BarChartGroupData(
        x: index,
        barsSpace: barsSpace,
        showingTooltipIndicators: const [],
        barRods: [
          BarChartRodData(
            toY: entry.value,
            width: isSelected ? barWidth + 4 : barWidth,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.primary.withOpacity(.72),
            borderRadius: BorderRadius.circular(compact ? 4 : 6),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: _maxSpending * 1.05,
              color: colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      );
    }).toList();
  }

  MapEntry<String, double>? get _selectedEntry {
    if (touchedMonth == null) {
      return null;
    }

    for (final entry in _validEntries) {
      if (entry.key == touchedMonth) {
        return entry;
      }
    }

    return null;
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);
    final spacing = ResponsiveHelper.spacing(context);

    final iconContainerSize = compact ? 56.0 : 64.0;
    final iconSize = compact ? 28.0 : 32.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: iconContainerSize,
              height: iconContainerSize,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.show_chart_rounded,
                size: iconSize,
                color: colorScheme.primary,
              ),
            ),

            SizedBox(height: spacing),

            Text(
              'No monthly spending data',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Add expenses to start seeing your spending trend.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(.60),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMonthCard(
    BuildContext context,
    MapEntry<String, double> selected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final cardPadding = ResponsiveHelper.cardPadding(context);
    final spacing = ResponsiveHelper.spacing(context);

    final percentage = _totalSpending == 0
        ? 0.0
        : (selected.value / _totalSpending) * 100;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Row(
          children: [
            Container(
              width: compact ? 36 : 42,
              height: compact ? 36 : 42,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: colorScheme.primary,
                size: compact ? 19 : 21,
              ),
            ),

            SizedBox(width: spacing),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _monthFullLabel(selected.key),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${percentage.toStringAsFixed(1)}% of displayed spending',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(.60),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  CurrencyFormatter.format(selected.value),
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: compact ? 14 : 16,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validEntries = _validEntries;
    final selected = _selectedEntry;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final chartWidth = AnalyticsLayoutHelper.maxChartWidth(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);
    final spacing = ResponsiveHelper.spacing(context);

    final colorScheme = Theme.of(context).colorScheme;

    final axisFontSize = desktop
        ? 11.0
        : tablet
        ? 10.5
        : compact
        ? 9.0
        : 10.0;

    final leftReservedSize = desktop
        ? 52.0
        : tablet
        ? 50.0
        : compact
        ? 42.0
        : 46.0;

    final bottomReservedSize = compact ? 26.0 : 30.0;

    if (validEntries.isEmpty) {
      return FadeSlideAnimation(
        delay: 300,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: chartWidth),
            child: Card(
              elevation: 2,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(compact ? 16 : 20),
              ),
              child: SizedBox(
                height: widget.chartHeight,
                width: double.infinity,
                child: _buildEmptyState(context),
              ),
            ),
          ),
        ),
      );
    }

    final maxY = _maxSpending == 0 ? 10.0 : _maxSpending * 1.18;

    return FadeSlideAnimation(
      delay: 300,
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: chartWidth),
              child: Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(compact ? 16 : 20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: SizedBox(
                    height: widget.chartHeight,
                    width: double.infinity,
                    child: BarChart(
                      BarChartData(
                        minY: 0,
                        maxY: maxY,
                        alignment: BarChartAlignment.spaceAround,
                        groupsSpace: compact ? 5 : 10,

                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: maxY / 4,
                          getDrawingHorizontalLine: (_) {
                            return FlLine(
                              color: colorScheme.outline.withOpacity(.10),
                              strokeWidth: 1,
                            );
                          },
                        ),

                        borderData: FlBorderData(show: false),

                        barGroups: _getMonthlyBars(
                          context,
                          compact: compact,
                          tablet: tablet,
                          desktop: desktop,
                        ),

                        barTouchData: BarTouchData(
                          enabled: true,

                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => colorScheme.inverseSurface,

                            tooltipPadding: EdgeInsets.symmetric(
                              horizontal: compact ? 9 : 12,
                              vertical: compact ? 6 : 8,
                            ),

                            tooltipMargin: 8,

                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final entries = _validEntries;

                              if (groupIndex < 0 ||
                                  groupIndex >= entries.length) {
                                return null;
                              }

                              final monthKey = entries[groupIndex].key;

                              final actualValue = entries[groupIndex].value;

                              return BarTooltipItem(
                                '${_monthFullLabel(monthKey)}\n',
                                TextStyle(
                                  color: colorScheme.onInverseSurface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: compact ? 11 : 13,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        'KES ${actualValue.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: colorScheme.onInverseSurface,
                                      fontSize: compact ? 10 : 12,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          touchCallback:
                              (FlTouchEvent event, BarTouchResponse? response) {
                                final spot = response?.spot;

                                if (!event.isInterestedForInteractions ||
                                    spot == null) {
                                  if (touchedMonth != null) {
                                    setState(() {
                                      touchedMonth = null;
                                    });
                                  }
                                  return;
                                }

                                final entries = _validEntries;

                                final groupIndex = spot.touchedBarGroupIndex;

                                if (groupIndex < 0 ||
                                    groupIndex >= entries.length) {
                                  return;
                                }

                                final monthKey = entries[groupIndex].key;

                                if (touchedMonth != monthKey) {
                                  setState(() {
                                    touchedMonth = monthKey;
                                  });
                                }
                              },
                        ),

                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),

                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),

                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: leftReservedSize,
                              interval: maxY / 4,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  _formatAxisValue(value),
                                  style: TextStyle(
                                    fontSize: axisFontSize,
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              },
                            ),
                          ),

                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              reservedSize: bottomReservedSize,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();

                                if (index < 0 || index >= validEntries.length) {
                                  return const SizedBox.shrink();
                                }

                                final monthKey = validEntries[index].key;

                                return SideTitleWidget(
                                  axisSide: AxisSide.bottom,
                                  child: Text(
                                    _monthLabel(monthKey),
                                    style: TextStyle(
                                      fontSize: axisFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (selected != null) ...[
            SizedBox(height: spacing),
            _buildSelectedMonthCard(context, selected),
          ],

          SizedBox(height: spacing),

          Text(
            'Total displayed spending: '
            'KES ${_totalSpending.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: compact
                  ? 13
                  : tablet
                  ? 16
                  : 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
