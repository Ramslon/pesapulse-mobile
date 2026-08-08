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

  /// Removes invalid values and sorts months chronologically.
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

  List<BarChartGroupData> _getMonthlyBars() {
    final entries = _validEntries;

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
        barRods: [
          BarChartRodData(
            toY: entry.value,
            width: isSelected ? barWidth + 4 : barWidth,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
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

    const fullMonths = [
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

    return '${fullMonths[month]} $year';
  }

  @override
  Widget build(BuildContext context) {
    final validEntries = _validEntries;

    final chartWidth = AnalyticsLayoutHelper.maxChartWidth(context);

    final screenWidth = MediaQuery.of(context).size.width;

    final cardPadding = screenWidth >= 900 ? 16.0 : 12.0;

    /*
     * No valid spending data.
     *
     * This covers:
     * - empty map
     * - only zero values
     * - negative/invalid values
     */
    if (validEntries.isEmpty) {
      return FadeSlideAnimation(
        delay: 300,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: chartWidth),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: SizedBox(
                height: widget.chartHeight,
                width: double.infinity,
                child: const Center(
                  child: Text(
                    'No monthly spending data',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FadeSlideAnimation(
      delay: 300,
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: chartWidth),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: SizedBox(
                    height: widget.chartHeight,
                    width: double.infinity,
                    child: BarChart(
                      BarChartData(
                        minY: 0,

                        /*
                         * Add a little headroom above the largest bar.
                         */
                        maxY: _maxSpending == 0 ? 10 : _maxSpending * 1.15,

                        barGroups: _getMonthlyBars(),

                        borderData: FlBorderData(show: false),

                        barTouchData: BarTouchData(
                          enabled: true,

                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => Colors.black87,

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
                                const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                children: [
                                  TextSpan(
                                    text:
                                        'KES ${actualValue.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
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
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                            ),
                          ),

                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),

                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),

                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                final entries = _validEntries;

                                if (index < 0 || index >= entries.length) {
                                  return const SizedBox.shrink();
                                }

                                final monthKey = entries[index].key;

                                return SideTitleWidget(
                                  axisSide: AxisSide.bottom,
                                  child: Text(
                                    _monthLabel(monthKey),
                                    style: TextStyle(
                                      fontSize: screenWidth >= 900 ? 11 : 10,
                                      fontWeight: FontWeight.w500,
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

          /*
           * Show the selected month's actual value below
           * the chart as an additional accessible detail.
           */
          if (touchedMonth != null) ...[
            const SizedBox(height: 10),

            Builder(
              builder: (context) {
                final selected = validEntries
                    .where((entry) => entry.key == touchedMonth)
                    .firstOrNull;
                if (selected == null) {
                  return const SizedBox.shrink();
                }

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _monthFullLabel(selected.key),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          'KES ${selected.value.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
