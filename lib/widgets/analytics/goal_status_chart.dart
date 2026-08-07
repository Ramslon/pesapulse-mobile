import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../fade_slide_animation.dart';

class GoalStatusChart extends StatelessWidget {
  final int completedGoals;
  final int activeGoals;
  final int totalGoals;
  final double chartHeight;

  const GoalStatusChart({
    super.key,
    required this.completedGoals,
    required this.activeGoals,
    required this.totalGoals,
    required this.chartHeight,
  });

  List<PieChartSectionData> _getSections(BuildContext context) {
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
        ? 13.0
        : screenWidth >= 600
        ? 12.0
        : 11.0;

    final titleStyle = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: titleFontSize,
    );

    return [
      PieChartSectionData(
        color: Colors.green,
        value: completedGoals.toDouble(),
        title: 'Completed\n$completedGoals',
        radius: radius,
        titleStyle: titleStyle,
      ),
      PieChartSectionData(
        color: Colors.orange,
        value: activeGoals.toDouble(),
        title: 'Active\n$activeGoals',
        radius: radius,
        titleStyle: titleStyle,
      ),
    ];
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

    return FadeSlideAnimation(
      delay: 200,
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
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
          ),

          const SizedBox(height: 12),

          Text(
            '$completedGoals of $totalGoals goals completed',
            style: TextStyle(
              fontSize: screenWidth >= 900 ? 17 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
