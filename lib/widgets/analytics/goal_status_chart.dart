import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../fade_slide_animation.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/analytics_layout_helper.dart';

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

  List<PieChartSectionData> _getSections(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
  }) {
    final completed = widget.completedGoals;
    final active = widget.activeGoals;

    if (completed <= 0 && active <= 0) {
      return [];
    }

    final baseRadius = desktop
        ? 85.0
        : tablet
        ? 72.0
        : compact
        ? 55.0
        : 64.0;

    final titleFontSize = desktop
        ? 12.0
        : tablet
        ? 11.5
        : compact
        ? 9.5
        : 11.0;

    final sections = <PieChartSectionData>[];

    if (completed > 0) {
      final isSelected = touchedIndex == 0;

      sections.add(
        PieChartSectionData(
          color: Colors.green.shade600,
          value: completed.toDouble(),
          title: 'Completed\n$completed',
          radius: isSelected ? baseRadius + 7 : baseRadius,
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
          radius: isSelected ? baseRadius + 7 : baseRadius,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final iconSize = compact ? 28.0 : 32.0;
    final containerSize = compact ? 56.0 : 64.0;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.cardPadding(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: containerSize,
              height: containerSize,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flag_outlined,
                size: iconSize,
                color: colorScheme.primary,
              ),
            ),

            SizedBox(height: ResponsiveHelper.spacing(context)),

            Text(
              'No goals yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Create a goal to start tracking your progress.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(.60),
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
    final theme = Theme.of(context);
    final color = selectedStatus['color'] as Color;
    final icon = selectedStatus['icon'] as IconData;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final padding = ResponsiveHelper.cardPadding(context);

    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Row(
          children: [
            Container(
              width: compact ? 36 : 42,
              height: compact ? 36 : 42,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: compact ? 19 : 22),
            ),

            SizedBox(width: ResponsiveHelper.spacing(context)),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedStatus['name'] as String,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${selectedStatus['value']} goals',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(.60),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${(selectedStatus['percentage'] as double).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: compact ? 16 : 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final compact = ResponsiveHelper.useCompactLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final chartWidth = AnalyticsLayoutHelper.maxChartWidth(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final centerSpaceRadius =
        (widget.chartHeight *
                (compact
                    ? 0.10
                    : tablet
                    ? 0.12
                    : 0.12))
            .clamp(compact ? 26.0 : 30.0, desktop ? 55.0 : 50.0);

    final selectedStatus = _getSelectedStatus();

    final sections = _getSections(
      context,
      compact: compact,
      tablet: tablet,
      desktop: desktop,
    );

    final summarySpacing = ResponsiveHelper.spacing(context);

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
                  borderRadius: BorderRadius.circular(compact ? 16 : 20),
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
                              sectionsSpace: compact ? 2 : 3,
                              centerSpaceColor: theme.colorScheme.surface,
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
            SizedBox(height: summarySpacing),
            _buildSelectedStatusCard(context, selectedStatus),
          ],

          SizedBox(height: summarySpacing),

          Text(
            widget.totalGoals == 0
                ? 'No goals created yet'
                : '${widget.completedGoals} of ${widget.totalGoals} goals completed',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: compact
                  ? 14
                  : tablet
                  ? 16
                  : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
