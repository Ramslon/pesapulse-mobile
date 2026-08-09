import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../fade_slide_animation.dart';
import '/utils/analytics_layout_helper.dart';

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

  List<BarChartGroupData> _getMonthlyBars(BuildContext context) {
    final entries = _validEntries;
    final colorScheme = Theme.of(context).colorScheme;

    final screenWidth = MediaQuery.of(context).size.width;

    final barWidth = screenWidth >= 1200
        ? 22.0
        : screenWidth >= 900
        ? 20.0
        : screenWidth >= 600
        ? 18.0
        : 16.0;

    return entries.asMap().entries.map((item) {
      final index = item.key;
      final entry = item.value;

      final isSelected = touchedMonth == entry.key;

      return BarChartGroupData(
        x: index,
        barsSpace: 4,
        showingTooltipIndicators: const [],
        barRods: [
          BarChartRodData(
            toY: entry.value,
            width: isSelected ? barWidth + 5 : barWidth,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.primary.withOpacity(.72),
            borderRadius: BorderRadius.circular(6),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.show_chart_rounded,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No monthly spending data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              'Add expenses to start seeing your spending trend.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
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
    final colorScheme = Theme.of(context).colorScheme;

    final percentage = _totalSpending == 0
        ? 0.0
        : (selected.value / _totalSpending) * 100;

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: colorScheme.primary,
                size: 21,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _monthFullLabel(selected.key),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${percentage.toStringAsFixed(1)}% of displayed spending',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            Text(
              'KES ${selected.value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colorScheme.primary,
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

    final chartWidth = AnalyticsLayoutHelper.maxChartWidth(context);

    final screenWidth = MediaQuery.of(context).size.width;

    final cardPadding = screenWidth >= 900 ? 16.0 : 12.0;

    final colorScheme = Theme.of(context).colorScheme;

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
                borderRadius: BorderRadius.circular(20),
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
                  borderRadius: BorderRadius.circular(20),
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
                        groupsSpace: 10,

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

                        barGroups: _getMonthlyBars(context),

                        barTouchData: BarTouchData(
                          enabled: true,

                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => colorScheme.inverseSurface,

                            tooltipPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
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
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        'KES ${actualValue.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: colorScheme.onInverseSurface,
                                      fontSize: 12,
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
                              reservedSize: 46,
                              interval: maxY / 4,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  _formatAxisValue(value),
                                  style: TextStyle(
                                    fontSize: 10,
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
                              reservedSize: 30,
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
                                      fontSize: screenWidth >= 900 ? 11 : 10,
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
            const SizedBox(height: 10),
            _buildSelectedMonthCard(context, selected),
          ],

          const SizedBox(height: 12),

          Text(
            'Total displayed spending: '
            'KES ${_totalSpending.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth >= 900 ? 16 : 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
