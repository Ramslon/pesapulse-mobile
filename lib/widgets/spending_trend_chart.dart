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

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 6,

          minY: 0,

          gridData: FlGridData(show: true),

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

          lineBarsData: [
            LineChartBarData(
              spots: spots,

              isCurved: true,

              barWidth: 4,

              color: Theme.of(context).colorScheme.primary,

              dotData: const FlDotData(show: true),

              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
