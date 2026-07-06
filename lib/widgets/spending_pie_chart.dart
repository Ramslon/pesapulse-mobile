import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SpendingPieChart extends StatelessWidget {
  final Map<String, double> categoryTotals;

  const SpendingPieChart({super.key, required this.categoryTotals});

  static const List<Color> colors = [
    Colors.orange,
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return const SizedBox();
    }

    final total = categoryTotals.values.fold(0.0, (a, b) => a + b);

    int index = 0;

    return AspectRatio(
      aspectRatio: 1.2,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 45,
          sectionsSpace: 3,
          sections: categoryTotals.entries.map((entry) {
            final percentage = (entry.value / total) * 100;

            final section = PieChartSectionData(
              color: colors[index % colors.length],
              value: entry.value,
              radius: 55,
              title: "${percentage.toStringAsFixed(0)}%",
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            );

            index++;

            return section;
          }).toList(),
        ),
      ),
    );
  }
}
