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

  @override
  void didUpdateWidget(covariant GoalStatusChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.completedGoals != widget.completedGoals ||
        oldWidget.activeGoals != widget.activeGoals ||
        oldWidget.totalGoals != widget.totalGoals) {
      touchedIndex = null;
    }
  }

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

    final completed = widget.completedGoals;
    final active = widget.activeGoals;

    if (completed <= 0 && active <= 0) {
      return [];
    }

    final sections = <PieChartSectionData>[];

    if (completed > 0) {
      final isSelected = touchedIndex == 0;

      sections.add(
        PieChartSectionData(
          color: Colors.green.shade600,
          value: completed.toDouble(),
          title: 'Completed\n$completed',
          radius: isSelected ? baseRadius + 8 : baseRadius,
          titleStyle: TextStyle(
            fontSize: isSelected ? titleFontSize + 1 : titleFontSize,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            color: Colors.white,
          ),
          borderSide: isSelected
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
      );
    }

    if (active > 0) {
      final activeIndex = completed > 0 ? 1 : 0;
      final isSelected = touchedIndex == activeIndex;

      sections.add(
        PieChartSectionData(
          color: Colors.orange.shade600,
          value: active.toDouble(),
          title: 'Active\n$active',
          radius: isSelected ? baseRadius + 8 : baseRadius,
          titleStyle: TextStyle(
            fontSize: isSelected ? titleFontSize + 1 : titleFontSize,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
            color: Colors.white,
          ),
          borderSide: isSelected
              ? const BorderSide(color: Colors.white, width: 2)
              : BorderSide.none,
        ),
      );
    }

    return sections;
  }

  Map<String, dynamic>? _getSelectedStatus() {
    if (touchedIndex == null) {
      return null;
    }

    final completed = widget.completedGoals;
    final active = widget.activeGoals;

    final statuses = <Map<String, dynamic>>[];

    if (completed > 0) {
      statuses.add({
        'name': 'Completed Goals',
        'value': completed,
        'icon': Icons.check_circle_rounded,
        'color': Colors.green.shade600,
      });
    }

    if (active > 0) {
      statuses.add({
        'name': 'Active Goals',
        'value': active,
        'icon': Icons.flag_rounded,
        'color': Colors.orange.shade600,
      });
    }

    if (touchedIndex! < 0 || touchedIndex! >= statuses.length) {
      return null;
    }

    final status = statuses[touchedIndex!];
    final value = status['value'] as int;

    final percentage = widget.totalGoals <= 0
        ? 0.0
        : (value / widget.totalGoals) * 100;

    return {
      'name': status['name'],
      'value': value,
      'percentage': percentage,
      'icon': status['icon'],
      'color': status['color'],
    };
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
                Icons.flag_outlined,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No goals yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              'Create a goal to start tracking your progress.',
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

  Widget _buildSelectedStatusCard(
    BuildContext context,
    Map<String, dynamic> selectedStatus,
  ) {
    final color = selectedStatus['color'] as Color;
    final icon = selectedStatus['icon'] as IconData;

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
                color: color.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedStatus['name'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${selectedStatus['value']} goals',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Text(
              '${(selectedStatus['percentage'] as double).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final selectedStatus = _getSelectedStatus();
    final sections = _getSections(context);

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
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: SizedBox(
                    height: widget.chartHeight,
                    width: double.infinity,
                    child: sections.isEmpty
                        ? _buildEmptyState(context)
                        : PieChart(
                            PieChartData(
                              sections: sections,
                              centerSpaceRadius: centerSpaceRadius,
                              sectionsSpace: 3,
                              centerSpaceColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              pieTouchData: PieTouchData(
                                touchCallback:
                                    (
                                      FlTouchEvent event,
                                      PieTouchResponse? response,
                                    ) {
                                      if (!event.isInterestedForInteractions ||
                                          response?.touchedSection == null) {
                                        if (touchedIndex != null) {
                                          setState(() {
                                            touchedIndex = null;
                                          });
                                        }
                                        return;
                                      }

                                      final newIndex = response!
                                          .touchedSection!
                                          .touchedSectionIndex;

                                      if (newIndex != touchedIndex) {
                                        setState(() {
                                          touchedIndex = newIndex;
                                        });
                                      }
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
            _buildSelectedStatusCard(context, selectedStatus),
          ],

          const SizedBox(height: 12),

          Text(
            widget.totalGoals == 0
                ? 'No goals created yet'
                : '${widget.completedGoals} of ${widget.totalGoals} goals completed',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: screenWidth >= 900 ? 17 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
