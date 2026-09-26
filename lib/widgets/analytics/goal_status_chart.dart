import 'dart:math' as math;

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

  static const Color _completedColor = Color(0xFF16A34A);
  static const Color _activeColor = Color(0xFFF59E0B);
  static const Color _neutralColor = Color(0xFF94A3B8);

  @override
  void didUpdateWidget(covariant GoalStatusChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.completedGoals != widget.completedGoals ||
        oldWidget.activeGoals != widget.activeGoals ||
        oldWidget.totalGoals != widget.totalGoals) {
      touchedIndex = null;
    }
  }

  int get _safeTotal {
    return math.max(widget.totalGoals, 0);
  }

  int get _completed {
    if (_safeTotal == 0) return 0;
    return widget.completedGoals.clamp(0, _safeTotal);
  }

  int get _active {
    if (_safeTotal == 0) return 0;

    final maxActive = math.max(_safeTotal - _completed, 0);

    return widget.activeGoals.clamp(0, maxActive);
  }

  int get _unclassified {
    final remaining = _safeTotal - _completed - _active;

    return math.max(remaining, 0);
  }

  double get _completionRate {
    if (_safeTotal == 0) {
      return 0;
    }

    return (_completed / _safeTotal) * 100;
  }

  double _percentage(int value) {
    if (_safeTotal == 0) {
      return 0;
    }

    return (value / _safeTotal) * 100;
  }

  Color _statusColor(int index) {
    switch (index) {
      case 0:
        return _completedColor;
      case 1:
        return _activeColor;
      default:
        return _neutralColor;
    }
  }

  String _statusName(int index) {
    switch (index) {
      case 0:
        return 'Completed';
      case 1:
        return 'Active';
      default:
        return 'Unclassified';
    }
  }

  int _statusValue(int index) {
    switch (index) {
      case 0:
        return _completed;
      case 1:
        return _active;
      default:
        return _unclassified;
    }
  }

  IconData _statusIcon(int index) {
    switch (index) {
      case 0:
        return Icons.check_circle_rounded;
      case 1:
        return Icons.flag_rounded;
      default:
        return Icons.more_horiz_rounded;
    }
  }

  List<PieChartSectionData> _buildSections(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    if (_safeTotal == 0) {
      return [];
    }

    final baseRadius = desktop
        ? 92.0
        : tablet
        ? 80.0
        : landscape
        ? 58.0
        : compact
        ? 54.0
        : 68.0;

    final selectedRadius = baseRadius + (compact ? 5 : 8);

    final values = <int>[_completed, _active];

    if (_unclassified > 0) {
      values.add(_unclassified);
    }

    return values.asMap().entries.map((item) {
      final index = item.key;
      final value = item.value;

      if (value <= 0) {
        return PieChartSectionData(
          value: 0,
          color: Colors.transparent,
          title: '',
          radius: 0,
          showTitle: false,
        );
      }

      final selected = touchedIndex == index;
      final color = _statusColor(index);

      return PieChartSectionData(
        value: value.toDouble(),
        color: color,
        title: '',
        showTitle: false,
        radius: selected ? selectedRadius : baseRadius,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.surface,
          width: selected ? 3 : 2,
        ),
      );
    }).toList();
  }

  Map<String, dynamic>? _selectedStatusData() {
    if (touchedIndex == null) {
      return null;
    }

    final index = touchedIndex!;

    if (index < 0 || index > 2) {
      return null;
    }

    final value = _statusValue(index);

    if (value <= 0) {
      return null;
    }

    return {
      'name': _statusName(index),
      'value': value,
      'percentage': _percentage(value),
      'icon': _statusIcon(index),
      'color': _statusColor(index),
    };
  }

  Widget _buildCenterContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final selected = _selectedStatusData();

    final selectedColor = (selected?['color'] as Color?) ?? _completedColor;

    final selectedName = selected?['name']?.toString() ?? 'Goal Progress';

    final selectedValue = selected?['value'] as int? ?? _completed;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Column(
        key: ValueKey(
          '${selected?.toString() ?? 'overall'}-$_completed-$_active',
        ),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: selectedColor.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              selected != null
                  ? selected['icon'] as IconData
                  : Icons.flag_rounded,
              size: 19,
              color: selectedColor,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            selected != null ? selectedName : 'Goal Progress',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            selected != null
                ? '$selectedValue'
                : '${_completionRate.toStringAsFixed(0)}%',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: selectedColor.withOpacity(.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              selected != null
                  ? '${(selected['percentage'] as double).toStringAsFixed(0)}% of goals'
                  : '$_completed of $_safeTotal completed',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: selectedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionRing(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    final sections = _buildSections(
      context,
      compact: compact,
      tablet: tablet,
      desktop: desktop,
      landscape: landscape,
    );

    if (sections.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.sizeOf(context).width;

    final maxSquare = desktop
        ? 300.0
        : tablet
        ? 270.0
        : compact
        ? 210.0
        : landscape
        ? 220.0
        : 245.0;

    final availableHeight = math.max(widget.chartHeight - 16, 150);

    final size = math.min(
      maxSquare,
      math.min(availableHeight, screenWidth * .72),
    );

    final centerSpaceRadius = desktop
        ? 66.0
        : tablet
        ? 56.0
        : compact
        ? 40.0
        : landscape
        ? 42.0
        : 50.0;

    return SizedBox(
      width: size.toDouble(),
      height: size.toDouble(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: centerSpaceRadius,
              sectionsSpace: compact ? 2 : 3,
              centerSpaceColor: Theme.of(context).colorScheme.surface,
              startDegreeOffset: -90,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                touchCallback:
                    (FlTouchEvent event, PieTouchResponse? response) {
                      if (!event.isInterestedForInteractions ||
                          response?.touchedSection == null) {
                        if (touchedIndex != null) {
                          setState(() {
                            touchedIndex = null;
                          });
                        }

                        return;
                      }

                      final index =
                          response!.touchedSection!.touchedSectionIndex;

                      if (index == touchedIndex) {
                        setState(() {
                          touchedIndex = null;
                        });
                      } else {
                        setState(() {
                          touchedIndex = index;
                        });
                      }
                    },
              ),
            ),
            swapAnimationDuration: const Duration(milliseconds: 380),
            swapAnimationCurve: Curves.easeOutCubic,
          ),

          IgnorePointer(child: _buildCenterContent(context)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final progressColor = _completionRate >= 100
        ? _completedColor
        : _completionRate >= 50
        ? _completedColor
        : _activeColor;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Goal progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Track completed and active financial goals',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: compact ? 9.5 : 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 6 : 7,
          ),
          decoration: BoxDecoration(
            color: progressColor.withOpacity(.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: progressColor.withOpacity(.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.track_changes_rounded,
                size: compact ? 13 : 15,
                color: progressColor,
              ),
              const SizedBox(width: 5),
              Text(
                '${_completionRate.toStringAsFixed(0)}% complete',
                style: TextStyle(
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w800,
                  color: progressColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMetric(
    BuildContext context, {
    required int value,
    required String label,
    required double percentage,
    required Color color,
    required IconData icon,
    required bool compact,
    VoidCallback? onTap,
    bool selected = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 9 : 12,
            vertical: compact ? 9 : 11,
          ),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(.075) : colorScheme.surface,
            borderRadius: BorderRadius.circular(compact ? 13 : 15),
            border: Border.all(
              color: selected
                  ? color.withOpacity(.20)
                  : colorScheme.outline.withOpacity(.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 30 : 34,
                height: compact ? 30 : 34,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: compact ? 15 : 17, color: color),
              ),

              SizedBox(width: compact ? 7 : 9),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 9.5 : 10.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: compact ? 14 : 16,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedStatusCard(
    BuildContext context,
    Map<String, dynamic> selectedStatus,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final color = selectedStatus['color'] as Color;
    final icon = selectedStatus['icon'] as IconData;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 9 : 12,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(.055),
        borderRadius: BorderRadius.circular(compact ? 13 : 16),
        border: Border.all(color: color.withOpacity(.14)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 36,
            height: compact ? 30 : 36,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: compact ? 15 : 18),
          ),

          SizedBox(width: compact ? 8 : 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${selectedStatus['name']} goals',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${selectedStatus['value']} goals • '
                  '${(selectedStatus['percentage'] as double).toStringAsFixed(1)}% of total',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 9 : 10.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            '${selectedStatus['value']}',
            style: TextStyle(
              fontSize: compact ? 14 : 16,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 56 : 64,
              height: compact ? 56 : 64,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(.10),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.flag_outlined,
                size: compact ? 28 : 32,
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
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
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
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final chartWidth = AnalyticsLayoutHelper.maxChartWidth(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final entries = <int>[
      if (_completed > 0) _completed,
      if (_active > 0) _active,
      if (_unclassified > 0) _unclassified,
    ];

    if (entries.isEmpty) {
      return FadeSlideAnimation(
        delay: 200,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: chartWidth),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(compact ? 18 : 22),
                side: BorderSide(color: colorScheme.outline.withOpacity(.07)),
              ),
              child: SizedBox(
                height: widget.chartHeight,
                child: _buildEmptyState(context),
              ),
            ),
          ),
        ),
      );
    }

    final selectedStatus = _selectedStatusData();

    return FadeSlideAnimation(
      delay: 200,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: chartWidth),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                desktop
                    ? 26
                    : tablet
                    ? 24
                    : compact
                    ? 18
                    : 22,
              ),
              side: BorderSide(color: colorScheme.outline.withOpacity(.07)),
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, compact: compact),

                  SizedBox(height: compact ? 12 : 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 700;

                      if (wide) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Center(
                                child: _buildCompletionRing(
                                  context,
                                  compact: compact,
                                  tablet: tablet,
                                  desktop: desktop,
                                  landscape: landscape,
                                ),
                              ),
                            ),

                            const SizedBox(width: 18),

                            Expanded(
                              flex: 6,
                              child: Row(
                                children: [
                                  _buildStatusMetric(
                                    context,
                                    value: _completed,
                                    label: 'Completed',
                                    percentage: _percentage(_completed),
                                    color: _completedColor,
                                    icon: Icons.check_circle_rounded,
                                    compact: compact,
                                    selected: touchedIndex == 0,
                                    onTap: () {
                                      setState(() {
                                        touchedIndex = touchedIndex == 0
                                            ? null
                                            : 0;
                                      });
                                    },
                                  ),

                                  const SizedBox(width: 10),

                                  _buildStatusMetric(
                                    context,
                                    value: _active,
                                    label: 'Active',
                                    percentage: _percentage(_active),
                                    color: _activeColor,
                                    icon: Icons.flag_rounded,
                                    compact: compact,
                                    selected: touchedIndex == 1,
                                    onTap: () {
                                      if (_active == 0) {
                                        return;
                                      }

                                      setState(() {
                                        touchedIndex = touchedIndex == 1
                                            ? null
                                            : 1;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          Center(
                            child: _buildCompletionRing(
                              context,
                              compact: compact,
                              tablet: tablet,
                              desktop: desktop,
                              landscape: landscape,
                            ),
                          ),

                          SizedBox(height: compact ? 6 : 10),

                          Row(
                            children: [
                              _buildStatusMetric(
                                context,
                                value: _completed,
                                label: 'Completed',
                                percentage: _percentage(_completed),
                                color: _completedColor,
                                icon: Icons.check_circle_rounded,
                                compact: compact,
                                selected: touchedIndex == 0,
                                onTap: () {
                                  setState(() {
                                    touchedIndex = touchedIndex == 0 ? null : 0;
                                  });
                                },
                              ),

                              SizedBox(width: compact ? 7 : 10),

                              _buildStatusMetric(
                                context,
                                value: _active,
                                label: 'Active',
                                percentage: _percentage(_active),
                                color: _activeColor,
                                icon: Icons.flag_rounded,
                                compact: compact,
                                selected: touchedIndex == 1,
                                onTap: () {
                                  if (_active == 0) {
                                    return;
                                  }

                                  setState(() {
                                    touchedIndex = touchedIndex == 1 ? null : 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  if (selectedStatus != null) ...[
                    SizedBox(height: compact ? 8 : 12),
                    _buildSelectedStatusCard(context, selectedStatus),
                  ],

                  SizedBox(height: compact ? 8 : 12),

                  Center(
                    child: Text(
                      _safeTotal == 0
                          ? 'No goals created yet'
                          : '$_completed of $_safeTotal goals completed',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: compact ? 11 : 13,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
