import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SpendingTrendChart extends StatelessWidget {
  final Map<String, double> dailySpending;

  const SpendingTrendChart({super.key, required this.dailySpending});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final spots = List.generate(days.length, (index) {
      return FlSpot(index.toDouble(), dailySpending[days[index]] ?? 0);
    });

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final chartHeight = isLandscape ? 150.0 : 240.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.92 + (value * 0.08),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: SizedBox(
        height: chartHeight,

        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 6,

            minY: 0,

            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1000,
              getDrawingHorizontalLine: (_) {
                return FlLine(
                  color: Colors.grey.withOpacity(.15),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),

            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),

              rightTitles: const AxisTitles(),

              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        days[value.toInt()],
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),

              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 42),
              ),
            ),

            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => Colors.black87,
                getTooltipItems: (spots) {
                  return spots.map((spot) {
                    return LineTooltipItem(
                      "KES ${spot.y.toStringAsFixed(0)}",
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),

            lineBarsData: [
              LineChartBarData(
                spots: spots,

                isCurved: true,

                curveSmoothness: 0.35,

                barWidth: 5,

                color: Theme.of(context).colorScheme.primary,

                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) {
                    return FlDotCirclePainter(
                      radius: 5,
                      color: Theme.of(context).colorScheme.primary,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),

                belowBarData: BarAreaData(
                  show: true,
                  color: Theme.of(context).colorScheme.primary.withOpacity(.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
