import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class SpendingTrendChart extends StatelessWidget {
  final Map<String, double> dailySpending;
  final double height;

  const SpendingTrendChart({
    super.key,
    required this.dailySpending,
    required this.height,
  });

  static const List<String> _days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.useDenseVerticalLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final primaryColor = colorScheme.primary;

    final spots = List.generate(
      _days.length,
      (index) => FlSpot(index.toDouble(), dailySpending[_days[index]] ?? 0),
    );

    final maxSpending = spots.fold<double>(
      0,
      (max, spot) => math.max(max, spot.y),
    );

    final highestIndex = _highestSpendingIndex(spots);

    final horizontalPadding = desktop
        ? 16.0
        : tablet
        ? 14.0
        : compact
        ? 8.0
        : 10.0;

    final lineWidth = compact ? 3.0 : 3.5;
    final dotRadius = compact ? 3.5 : 4.5;

    final chartMaxY = _calculateMaxY(maxSpending);
    final interval = _calculateInterval(chartMaxY);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animation, child) {
        return Opacity(opacity: animation, child: child);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: landscape ? 4 : 8,
        ),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: 6,
              minY: 0,
              maxY: chartMaxY,

              clipData: const FlClipData.all(),

              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: interval,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.dividerColor.withOpacity(.16),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  );
                },
              ),

              borderData: FlBorderData(show: false),

              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: compact ? 24 : 30,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < 0 || index >= _days.length) {
                        return const SizedBox.shrink();
                      }

                      final isHighest = index == highestIndex;

                      return Padding(
                        padding: EdgeInsets.only(top: compact ? 6 : 9),
                        child: Text(
                          _days[index],
                          style: TextStyle(
                            fontSize: compact ? 10 : 11.5,
                            fontWeight: isHighest
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isHighest
                                ? primaryColor
                                : colorScheme.onSurface.withOpacity(.58),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: compact ? 36 : 48,
                    interval: interval,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _formatAxisAmount(value),
                        style: TextStyle(
                          fontSize: compact ? 9 : 10.5,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface.withOpacity(.5),
                        ),
                      );
                    },
                  ),
                ),
              ),

              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: true,
                touchSpotThreshold: 24,

                getTouchedSpotIndicator:
                    (LineChartBarData barData, List<int> spotIndexes) {
                      return spotIndexes.map((index) {
                        return TouchedSpotIndicatorData(
                          FlLine(
                            color: primaryColor.withOpacity(.35),
                            strokeWidth: 1.5,
                            dashArray: [4, 4],
                          ),
                          FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) {
                              return FlDotCirclePainter(
                                radius: dotRadius + 2,
                                color: primaryColor,
                                strokeWidth: 3,
                                strokeColor: colorScheme.surface,
                              );
                            },
                          ),
                        );
                      }).toList();
                    },

                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,

                  getTooltipColor: (_) {
                    return colorScheme.inverseSurface;
                  },

                  tooltipRoundedRadius: 12,

                  tooltipPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),

                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final index = spot.x.toInt();

                      final day = index >= 0 && index < _days.length
                          ? _days[index]
                          : '';

                      return LineTooltipItem(
                        '$day\n',
                        TextStyle(
                          color: colorScheme.onInverseSurface.withOpacity(.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        children: [
                          TextSpan(
                            text: 'KES ${_formatCurrency(spot.y)}',
                            style: TextStyle(
                              color: colorScheme.onInverseSurface,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),

              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: .28,
                  barWidth: lineWidth,
                  color: primaryColor,
                  preventCurveOverShooting: true,
                  isStrokeCapRound: true,
                  isStrokeJoinRound: true,

                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) {
                      final isHighest = index == highestIndex;

                      return FlDotCirclePainter(
                        radius: isHighest ? dotRadius + 1.5 : dotRadius,
                        color: isHighest ? colorScheme.surface : primaryColor,
                        strokeWidth: isHighest ? 3 : 2,
                        strokeColor: primaryColor,
                      );
                    },
                  ),

                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primaryColor.withOpacity(.20),
                        primaryColor.withOpacity(.06),
                        primaryColor.withOpacity(.01),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static double _calculateMaxY(double maxSpending) {
    if (maxSpending <= 0) {
      return 1000;
    }

    final padded = maxSpending * 1.25;

    if (padded <= 1000) {
      return 1000;
    }

    final magnitude = math
        .pow(10, (math.log(padded) / math.ln10).floor())
        .toDouble();

    final normalized = padded / magnitude;

    final niceMultiplier = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;

    return niceMultiplier * magnitude;
  }

  static double _calculateInterval(double maxY) {
    final rawInterval = maxY / 4;

    final magnitude = math
        .pow(10, (math.log(rawInterval) / math.ln10).floor())
        .toDouble();

    final normalized = rawInterval / magnitude;

    final niceMultiplier = normalized <= 1
        ? 1
        : normalized <= 2
        ? 2
        : normalized <= 5
        ? 5
        : 10;

    return niceMultiplier * magnitude;
  }

  static int _highestSpendingIndex(List<FlSpot> spots) {
    if (spots.isEmpty) {
      return -1;
    }

    var highestIndex = 0;

    for (var i = 1; i < spots.length; i++) {
      if (spots[i].y > spots[highestIndex].y) {
        highestIndex = i;
      }
    }

    return spots[highestIndex].y > 0 ? highestIndex : -1;
  }

  static String _formatAxisAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}M';
    }

    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(amount % 1000 == 0 ? 0 : 1)}K';
    }

    return amount.toStringAsFixed(0);
  }

  static String _formatCurrency(double amount) {
    return amount.round().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}
