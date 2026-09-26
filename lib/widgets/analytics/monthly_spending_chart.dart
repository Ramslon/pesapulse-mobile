import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/core/utils/currency_formatter.dart';

import '../fade_slide_animation.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/analytics_layout_helper.dart';

class MonthlySpendingChart extends StatefulWidget {
  final Map<String, double> monthlyTotals;
  final List expenses;
  final double chartHeight;

  const MonthlySpendingChart({
    super.key,
    required this.monthlyTotals,
    required this.expenses,
    required this.chartHeight,
  });

  @override
  State<MonthlySpendingChart> createState() => _MonthlySpendingChartState();
}

class _MonthlySpendingChartState extends State<MonthlySpendingChart> {
  String? touchedMonth;

  static const List<String> months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> fullMonths = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void didUpdateWidget(covariant MonthlySpendingChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.monthlyTotals != widget.monthlyTotals) {
      touchedMonth = null;
    }
  }

  // ─────────────────────────────────────────────
  // DATA
  // ─────────────────────────────────────────────

  List<MapEntry<String, double>> get _validEntries {
    final entries = widget.monthlyTotals.entries
        .where((entry) => entry.value >= 0)
        .toList();

    entries.sort((a, b) => a.key.compareTo(b.key));

    return entries;
  }

  double get _totalSpending {
    return _validEntries.fold<double>(0, (sum, entry) => sum + entry.value);
  }

  double get _averageSpending {
    final entries = _validEntries;

    if (entries.isEmpty) {
      return 0;
    }

    return _totalSpending / entries.length;
  }

  double get _maxSpending {
    final entries = _validEntries;

    if (entries.isEmpty) {
      return 0;
    }

    return entries.map((entry) => entry.value).reduce((a, b) => a > b ? a : b);
  }

  MapEntry<String, double>? get _latestEntry {
    final entries = _validEntries;

    if (entries.isEmpty) {
      return null;
    }

    return entries.last;
  }

  MapEntry<String, double>? get _previousEntry {
    final entries = _validEntries;

    if (entries.length < 2) {
      return null;
    }

    return entries[entries.length - 2];
  }

  MapEntry<String, double>? get _selectedEntry {
    if (touchedMonth == null) {
      return null;
    }

    for (final entry in _validEntries) {
      if (entry.key == touchedMonth) {
        return entry;
      }
    }

    return null;
  }

  double? get _latestChangePercentage {
    final latest = _latestEntry;
    final previous = _previousEntry;

    if (latest == null || previous == null) {
      return null;
    }

    if (previous.value == 0) {
      if (latest.value == 0) {
        return 0;
      }

      return null;
    }

    return ((latest.value - previous.value) / previous.value) * 100;
  }

  // ─────────────────────────────────────────────
  // LABEL HELPERS
  // ─────────────────────────────────────────────

  String _monthLabel(String key) {
    final parts = key.split('-');

    if (parts.length != 2) {
      return key;
    }

    final month = int.tryParse(parts[1]);

    if (month == null || month < 1 || month > 12) {
      return key;
    }

    return months[month];
  }

  String _monthFullLabel(String key) {
    final parts = key.split('-');

    if (parts.length != 2) {
      return key;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);

    if (year == null || month == null || month < 1 || month > 12) {
      return key;
    }

    return '${fullMonths[month]} $year';
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }

    return value.toStringAsFixed(0);
  }

  // ─────────────────────────────────────────────
  // COLORS
  // ─────────────────────────────────────────────

  Color _chartColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return colorScheme.primary;
  }

  Color _trendColor(BuildContext context, double? change) {
    if (change == null) {
      return Theme.of(context).colorScheme.onSurfaceVariant;
    }

    // Higher spending = warning/red.
    // Lower spending = positive/green.
    if (change > 0) {
      return const Color(0xFFEF4444);
    }

    if (change < 0) {
      return const Color(0xFF16A34A);
    }

    return Theme.of(context).colorScheme.onSurfaceVariant;
  }

  IconData _trendIcon(double? change) {
    if (change == null) {
      return Icons.remove_rounded;
    }

    if (change > 0) {
      return Icons.trending_up_rounded;
    }

    if (change < 0) {
      return Icons.trending_down_rounded;
    }

    return Icons.trending_flat_rounded;
  }

  // ─────────────────────────────────────────────
  // CHART
  // ─────────────────────────────────────────────

  List<FlSpot> _buildSpots() {
    final entries = _validEntries;

    return entries.asMap().entries.map((item) {
      return FlSpot(item.key.toDouble(), item.value.value);
    }).toList();
  }

  double _chartMaxY() {
    if (_maxSpending <= 0) {
      return 10;
    }

    final padded = _maxSpending * 1.22;

    return padded <= 10 ? 10 : padded;
  }

  double _horizontalInterval() {
    final maxY = _chartMaxY();

    return maxY / 4;
  }

  List<LineChartBarData> _buildLineBars(
    BuildContext context, {
    required bool compact,
  }) {
    final chartColor = _chartColor(context);
    final spots = _buildSpots();

    if (spots.isEmpty) {
      return [];
    }

    return [
      LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: .32,
        barWidth: compact ? 2.8 : 3.2,
        isStrokeCapRound: true,
        isStrokeJoinRound: true,

        gradient: LinearGradient(
          colors: [chartColor.withOpacity(.95), chartColor.withOpacity(.72)],
        ),

        dotData: FlDotData(
          show: true,
          checkToShowDot: (spot, barData) {
            if (touchedMonth == null) {
              return false;
            }

            final entries = _validEntries;

            if (spot.x.toInt() < 0 || spot.x.toInt() >= entries.length) {
              return false;
            }

            return entries[spot.x.toInt()].key == touchedMonth;
          },
          getDotPainter: (spot, percent, barData, index) {
            return FlDotCirclePainter(
              radius: compact ? 4.5 : 5.5,
              color: Theme.of(context).colorScheme.surface,
              strokeWidth: compact ? 2 : 2.5,
              strokeColor: chartColor,
            );
          },
        ),

        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [chartColor.withOpacity(.20), chartColor.withOpacity(.035)],
          ),
        ),
      ),
    ];
  }

  // ─────────────────────────────────────────────
  // SELECTED MONTH
  // ─────────────────────────────────────────────

  Widget _buildSelectedMonthCard(
    BuildContext context,
    MapEntry<String, double> selected,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final previousIndex =
        _validEntries.indexWhere((entry) => entry.key == selected.key) - 1;

    double? change;

    if (previousIndex >= 0) {
      final previous = _validEntries[previousIndex];

      if (previous.value != 0) {
        change = ((selected.value - previous.value) / previous.value) * 100;
      }
    }

    final trendColor = _trendColor(context, change);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 14,
        vertical: compact ? 9 : 12,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(.42),
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: colorScheme.outline.withOpacity(.08)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 32 : 38,
            height: compact ? 32 : 38,
            decoration: BoxDecoration(
              color: _chartColor(context).withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              color: _chartColor(context),
              size: compact ? 16 : 19,
            ),
          ),

          SizedBox(width: compact ? 8 : 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _monthFullLabel(selected.key),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 10.5 : 12,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_percentageOfDisplayedTotal(selected.value).toStringAsFixed(1)}% of displayed spending',
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

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  CurrencyFormatter.format(selected.value),
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w800,
                    color: _chartColor(context),
                  ),
                ),
              ),

              if (change != null) ...[
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _trendIcon(change),
                      size: compact ? 11 : 13,
                      color: trendColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${change.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: compact ? 9 : 10,
                        fontWeight: FontWeight.w800,
                        color: trendColor,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  double _percentageOfDisplayedTotal(double amount) {
    if (_totalSpending <= 0) {
      return 0;
    }

    return (amount / _totalSpending) * 100;
  }

  // ─────────────────────────────────────────────
  // TOP SUMMARY
  // ─────────────────────────────────────────────

  Widget _buildSummary(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final latest = _latestEntry;
    final change = _latestChangePercentage;
    final trendColor = _trendColor(context, change);

    final latestLabel = latest == null
        ? 'No recent data'
        : _monthLabel(latest.key);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spending pulse',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Monthly movement at a glance',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: compact ? 9.5 : 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        if (latest != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 6 : 7,
            ),
            decoration: BoxDecoration(
              color: trendColor.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: trendColor.withOpacity(.10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _trendIcon(change),
                  size: compact ? 13 : 15,
                  color: trendColor,
                ),
                const SizedBox(width: 4),
                Text(
                  change == null
                      ? latestLabel
                      : '${change.abs().toStringAsFixed(0)}% vs previous',
                  style: TextStyle(
                    fontSize: compact ? 9 : 10,
                    fontWeight: FontWeight.w800,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final spacing = ResponsiveHelper.spacing(context);

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
                Icons.insights_rounded,
                size: compact ? 28 : 32,
                color: colorScheme.primary,
              ),
            ),

            SizedBox(height: spacing),

            Text(
              'No monthly spending data',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Add expenses to start seeing your spending trend.',
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

  // ─────────────────────────────────────────────
  // MAIN BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final validEntries = _validEntries;
    final selected = _selectedEntry;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final chartWidth = AnalyticsLayoutHelper.maxChartWidth(context);

    final colorScheme = Theme.of(context).colorScheme;

    final cardPadding = ResponsiveHelper.cardPadding(context);

    final spacing = ResponsiveHelper.spacing(context);

    final axisFontSize = desktop
        ? 11.0
        : tablet
        ? 10.5
        : compact
        ? 8.5
        : 9.5;

    final leftReservedSize = desktop
        ? 52.0
        : tablet
        ? 48.0
        : compact
        ? 39.0
        : 44.0;

    final bottomReservedSize = compact
        ? 24.0
        : landscape
        ? 26.0
        : 30.0;

    if (validEntries.isEmpty) {
      return FadeSlideAnimation(
        delay: 300,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: chartWidth),
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(compact ? 18 : 22),
                side: BorderSide(color: colorScheme.outline.withOpacity(.07)),
              ),
              child: SizedBox(
                height: widget.chartHeight,
                width: double.infinity,
                child: _buildEmptyState(context),
              ),
            ),
          ),
        ),
      );
    }

    final chartMaxY = _chartMaxY();
    final chartInterval = _horizontalInterval();

    return FadeSlideAnimation(
      delay: 280,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: chartWidth),
          child: Column(
            children: [
              Card(
                elevation: 0,
                margin: EdgeInsets.zero,
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
                  padding: EdgeInsets.fromLTRB(
                    cardPadding,
                    cardPadding,
                    cardPadding,
                    compact ? 10 : 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummary(context, compact: compact),

                      SizedBox(height: compact ? 8 : 12),

                      SizedBox(
                        height: widget.chartHeight,
                        width: double.infinity,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            maxX: math
                                .max(0, validEntries.length - 1)
                                .toDouble(),

                            minY: 0,
                            maxY: chartMaxY,

                            clipData: const FlClipData(
                              top: false,
                              bottom: false,
                              left: false,
                              right: false,
                            ),

                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: chartInterval,
                              getDrawingHorizontalLine: (_) {
                                return FlLine(
                                  color: colorScheme.outline.withOpacity(.075),
                                  strokeWidth: 1,
                                );
                              },
                            ),

                            borderData: FlBorderData(show: false),

                            extraLinesData: ExtraLinesData(
                              horizontalLines: [
                                HorizontalLine(
                                  y: _averageSpending,
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(.35),
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                ),
                              ],
                            ),

                            lineBarsData: _buildLineBars(
                              context,
                              compact: compact,
                            ),

                            lineTouchData: LineTouchData(
                              enabled: true,
                              handleBuiltInTouches: true,

                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (_) =>
                                    colorScheme.inverseSurface,
                                tooltipPadding: EdgeInsets.symmetric(
                                  horizontal: compact ? 9 : 12,
                                  vertical: compact ? 7 : 9,
                                ),
                                tooltipMargin: 10,

                                getTooltipItems: (spots) {
                                  return spots.map((spot) {
                                    final entries = _validEntries;

                                    final index = spot.x.toInt();

                                    if (index < 0 || index >= entries.length) {
                                      return null;
                                    }

                                    final entry = entries[index];

                                    return LineTooltipItem(
                                      '${_monthFullLabel(entry.key)}\n',
                                      TextStyle(
                                        color: colorScheme.onInverseSurface,
                                        fontSize: compact ? 10.5 : 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: CurrencyFormatter.format(
                                            entry.value,
                                          ),
                                          style: TextStyle(
                                            color: colorScheme.onInverseSurface,
                                            fontSize: compact ? 10 : 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList();
                                },
                              ),

                              touchCallback:
                                  (
                                    FlTouchEvent event,
                                    LineTouchResponse? response,
                                  ) {
                                    final spots = response?.lineBarSpots;

                                    if (!event.isInterestedForInteractions ||
                                        spots == null ||
                                        spots.isEmpty) {
                                      if (touchedMonth != null) {
                                        setState(() {
                                          touchedMonth = null;
                                        });
                                      }

                                      return;
                                    }

                                    final index = spots.first.x.toInt();

                                    final entries = _validEntries;

                                    if (index < 0 || index >= entries.length) {
                                      return;
                                    }

                                    final key = entries[index].key;

                                    if (touchedMonth != key) {
                                      setState(() {
                                        touchedMonth = key;
                                      });
                                    }
                                  },
                            ),

                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),

                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),

                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: leftReservedSize,
                                  interval: chartInterval,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) {
                                      return const SizedBox.shrink();
                                    }

                                    return Text(
                                      _formatAxisValue(value),
                                      style: TextStyle(
                                        fontSize: axisFontSize,
                                        color: colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    );
                                  },
                                ),
                              ),

                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  reservedSize: bottomReservedSize,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();

                                    if (index < 0 ||
                                        index >= validEntries.length) {
                                      return const SizedBox.shrink();
                                    }

                                    final key = validEntries[index].key;

                                    final isSelected = touchedMonth == key;

                                    return SideTitleWidget(
                                      axisSide: AxisSide.bottom,
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        style: TextStyle(
                                          fontSize: axisFontSize,
                                          fontWeight: isSelected
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: isSelected
                                              ? _chartColor(context)
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                        child: Text(_monthLabel(key)),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                        ),
                      ),

                      SizedBox(height: compact ? 8 : 10),

                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: _chartColor(context),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Monthly spending',
                                  style: TextStyle(
                                    fontSize: compact ? 9 : 10,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 18,
                                height: 1,
                                decoration: BoxDecoration(
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(.35),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Average '
                                '${CurrencyFormatter.format(_averageSpending)}',
                                style: TextStyle(
                                  fontSize: compact ? 9 : 10,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              if (selected != null) ...[
                SizedBox(height: spacing),
                _buildSelectedMonthCard(context, selected),
              ],

              SizedBox(height: spacing),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Displayed total ',
                    style: TextStyle(
                      fontSize: compact ? 10 : 11,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(_totalSpending),
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${validEntries.length} months',
                    style: TextStyle(
                      fontSize: compact ? 10 : 11,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
