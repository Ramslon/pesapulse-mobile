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
  int? touchedIndex;

  List<BarChartGroupData> _getMonthlyBars() {
    final screenWidth = MediaQuery.of(context).size.width;

    final barWidth = screenWidth >= 1200
        ? 22.0
        : screenWidth >= 900
        ? 20.0
        : screenWidth >= 600
        ? 18.0
        : 16.0;

    return widget.monthlyTotals.entries.map((entry) {
      final isSelected = touchedIndex == entry.key;

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

  @override
  Widget build(BuildContext context) {
    final chartWidth = AnalyticsLayoutHelper.maxChartWidth(context);

    final cardPadding = MediaQuery.of(context).size.width >= 900 ? 16.0 : 12.0;

    return FadeSlideAnimation(
      delay: 300,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: chartWidth),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: SizedBox(
                height: widget.chartHeight,
                child: BarChart(
                  BarChartData(
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
                          const months = [
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

                          final monthIndex = group.x.toInt();

                          final month = monthIndex >= 1 && monthIndex <= 12
                              ? months[monthIndex]
                              : 'Unknown';

                          return BarTooltipItem(
                            '$month\n',
                            const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 13,
                            ),
                            children: [
                              TextSpan(
                                text: 'KES ${rod.toY.toStringAsFixed(2)}',
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
                            if (!event.isInterestedForInteractions ||
                                response?.spot == null) {
                              setState(() {
                                touchedIndex = null;
                              });
                              return;
                            }

                            setState(() {
                              touchedIndex =
                                  response!.spot!.touchedBarGroupIndex;
                            });
                          },
                    ),
                    borderData: FlBorderData(show: false),

                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),

                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            const months = [
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

                            final index = value.toInt();

                            if (index < 1 || index > 12) {
                              return const SizedBox.shrink();
                            }

                            final screenWidth = MediaQuery.of(
                              context,
                            ).size.width;

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

                    barGroups: _getMonthlyBars(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
