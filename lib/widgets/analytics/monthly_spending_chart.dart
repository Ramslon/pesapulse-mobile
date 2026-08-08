import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../fade_slide_animation.dart';
import '/utils/analytics_layout_helper.dart';

class MonthlySpendingChart extends StatefulWidget {
  final Map<int, double> monthlyTotals;
  final double chartHeight;

  const MonthlySpendingChart({
    super.key,
    required this.monthlyTotals,
    required this.chartHeight,
  });

  @override
  State<MonthlySpendingChart> createState() => _MonthlySpendingChartState();
}

class _MonthlySpendingChartState extends State<MonthlySpendingChart> {
  int? touchedMonth;

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
  List<MapEntry<int, double>> get _validEntries {
    return widget.monthlyTotals.entries
        .where((entry) => entry.key >= 1 && entry.key <= 12 && entry.value > 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  double get _maxSpending {
    if (_validEntries.isEmpty) {
      return 0;
    }

    return _validEntries
        .map((entry) => entry.value)
        .reduce((a, b) => a > b ? a : b);
  }

  List<BarChartGroupData> _getMonthlyBars() {
    final screenWidth = MediaQuery.of(context).size.width;

    final barWidth = screenWidth >= 1200
        ? 22.0
        : screenWidth >= 900
        ? 20.0
        : screenWidth >= 600
        ? 18.0
        : 16.0;

    return _validEntries.map((entry) {
      final isSelected = touchedMonth == entry.key;

      return BarChartGroupData(
        x: entry.key,
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

  String _monthName(int month) {
    if (month >= 1 && month <= 12) {
      return months[month];
    }

    return 'Unknown';
  }

  MapEntry<int, double>? _findMonthEntry(
    List<MapEntry<int, double>> entries,
    int month,
  ) {
    for (final entry in entries) {
      if (entry.key == month) {
        return entry;
      }
    }

    return null;
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
                              final monthIndex = group.x.toInt();

                              final entry = _findMonthEntry(
                                validEntries,
                                monthIndex,
                              );

                              final actualValue = entry?.value ?? rod.toY;

                              return BarTooltipItem(
                                '${_monthName(monthIndex)}\n',
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

                                final month = spot.touchedBarGroup.x;

                                if (touchedMonth != month) {
                                  setState(() {
                                    touchedMonth = month;
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

                                if (index < 1 || index > 12) {
                                  return const SizedBox.shrink();
                                }

                                return SideTitleWidget(
                                  axisSide: AxisSide.bottom,
                                  child: Text(
                                    months[index],
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
                final selected = _findMonthEntry(validEntries, touchedMonth!);

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
                            _monthName(selected.key),
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
