import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryBreakdownChart extends StatelessWidget {
  final Map<String, double> categoryTotals;
  final double chartHeight;

  const CategoryBreakdownChart({
    super.key,
    required this.categoryTotals,
    required this.chartHeight,
  });

  List<PieChartSectionData> _getSections(BuildContext context) {
    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive pie radius.
    final radius = screenWidth >= 1200
        ? 90.0
        : screenWidth >= 900
        ? 82.0
        : screenWidth >= 600
        ? 75.0
        : 65.0;

    final titleFontSize = screenWidth >= 900
        ? 12.0
        : screenWidth >= 600
        ? 11.5
        : 11.0;

    int index = 0;

    return categoryTotals.entries.map((entry) {
      final section = PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,
        title: '${entry.key}\nKES ${entry.value.toStringAsFixed(0)}',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );

      index++;

      return section;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final cardPadding = screenWidth >= 900
        ? 16.0
        : screenWidth >= 600
        ? 14.0
        : 12.0;

    final centerSpaceRadius = (chartHeight * 0.12).clamp(30.0, 55.0);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: SizedBox(
          height: chartHeight,
          width: double.infinity,
          child: PieChart(
            PieChartData(
              sections: _getSections(context),
              centerSpaceRadius: centerSpaceRadius,
              sectionsSpace: 3,
            ),
          ),
        ),
      ),
    );
  }
}
