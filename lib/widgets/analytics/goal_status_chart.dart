import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../fade_slide_animation.dart';
import '/utils/analytics_layout_helper.dart';

class GoalStatusChart extends StatefulWidget {
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

  @override
  State<GoalStatusChart> createState() => _GoalStatusChartState();
}

class _GoalStatusChartState extends State<GoalStatusChart> {
  int? touchedIndex;

  List<PieChartSectionData> _getSections(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final baseRadius = screenWidth >= 1200
        ? 85.0
        : screenWidth >= 900
        ? 78.0
        : screenWidth >= 600
        ? 70.0
        : 62.0;

    final titleFontSize = screenWidth >= 900
        ? 12.0
        : screenWidth >= 600
        ? 11.5
        : 11.0;

    final sections = [
      (
        color: Colors.green,
        value: widget.completedGoals.toDouble(),
        title: 'Completed\n${widget.completedGoals}',
      ),
      (
        color: Colors.orange,
        value: widget.activeGoals.toDouble(),
        title: 'Active\n${widget.activeGoals}',
      ),
    ];

    return sections.asMap().entries.map((item) {
      final index = item.key;
      final section = item.value;

      final isSelected = touchedIndex == index;

      return PieChartSectionData(
        color: section.color,
        value: section.value,
        title: section.title,
        radius: isSelected ? baseRadius + 8 : baseRadius,
        titleStyle: TextStyle(
          fontSize: isSelected ? titleFontSize + 1 : titleFontSize,
          fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Map<String, dynamic>? _getSelectedStatus() {
    if (touchedIndex == null) {
      return null;
    }

    final value = touchedIndex == 0
        ? widget.completedGoals
        : widget.activeGoals;

    final name = touchedIndex == 0 ? 'Completed Goals' : 'Active Goals';

    final percentage = widget.totalGoals == 0
        ? 0.0
        : (value / widget.totalGoals) * 100;

    return {'name': name, 'value': value, 'percentage': percentage};
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final selectedStatus = _getSelectedStatus();

    final cardPadding = screenWidth >= 900
        ? 16.0
        : screenWidth >= 600
        ? 14.0
        : 12.0;

    final chartWidth = AnalyticsLayoutHelper.maxChartWidth(context);

    final centerSpaceRadius = (widget.chartHeight * 0.12).clamp(30.0, 55.0);

    return FadeSlideAnimation(
      delay: 200,
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
                    child: PieChart(
                      PieChartData(
                        sections: _getSections(context),
                        centerSpaceRadius: centerSpaceRadius,
                        sectionsSpace: 3,
                        pieTouchData: PieTouchData(
                          touchCallback:
                              (FlTouchEvent event, PieTouchResponse? response) {
                                if (!event.isInterestedForInteractions ||
                                    response?.touchedSection == null) {
                                  setState(() {
                                    touchedIndex = null;
                                  });
                                  return;
                                }

                                setState(() {
                                  touchedIndex = response!
                                      .touchedSection!
                                      .touchedSectionIndex;
                                });
                              },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          if (selectedStatus != null) ...[
            const SizedBox(height: 10),

            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedStatus['name'],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${selectedStatus['value']} goals',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      '${selectedStatus['percentage'].toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          Text(
            '${widget.completedGoals} of ${widget.totalGoals} goals completed',
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
