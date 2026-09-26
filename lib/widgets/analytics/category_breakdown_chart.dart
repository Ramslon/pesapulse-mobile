import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/core/utils/currency_formatter.dart';

import '../fade_slide_animation.dart';
import '../../utils/responsive_helper.dart';
import '/utils/analytics_layout_helper.dart';

class CategoryBreakdownChart extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final double chartHeight;

  const CategoryBreakdownChart({
    super.key,
    required this.categoryTotals,
    required this.chartHeight,
  });

  @override
  State<CategoryBreakdownChart> createState() => _CategoryBreakdownChartState();
}

class _CategoryBreakdownChartState extends State<CategoryBreakdownChart> {
  int? touchedIndex;

  List<MapEntry<String, double>> get _validEntries {
    final entries = widget.categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList();

    entries.sort((a, b) => b.value.compareTo(a.value));

    return entries;
  }

  double get _totalSpending {
    return _validEntries.fold<double>(0, (sum, entry) => sum + entry.value);
  }

  MapEntry<String, double>? get _topCategory {
    final entries = _validEntries;

    if (entries.isEmpty) {
      return null;
    }

    return entries.first;
  }

  double _percentage(double value) {
    if (_totalSpending <= 0) {
      return 0;
    }

    return (value / _totalSpending) * 100;
  }

  Color _categoryColor(String category, int index) {
    switch (category.trim().toLowerCase()) {
      case 'food':
        return const Color(0xFFF59E0B);

      case 'transport':
        return const Color(0xFF3B82F6);

      case 'shopping':
        return const Color(0xFF8B5CF6);

      case 'bills':
        return const Color(0xFFEF4444);

      case 'entertainment':
        return const Color(0xFFEC4899);

      case 'health':
        return const Color(0xFF10B981);

      case 'education':
        return const Color(0xFF06B6D4);

      case 'other':
        return const Color(0xFF64748B);

      default:
        const fallbackColors = [
          Color(0xFF14B8A6),
          Color(0xFF6366F1),
          Color(0xFF0EA5E9),
          Color(0xFFA855F7),
          Color(0xFFF97316),
          Color(0xFF22C55E),
        ];

        return fallbackColors[index % fallbackColors.length];
    }
  }

  Color _surfaceTint(
    BuildContext context,
    Color accent, {
    double opacity = .06,
  }) {
    final surface = Theme.of(context).colorScheme.surface;

    return Color.alphaBlend(accent.withOpacity(opacity), surface);
  }

  Map<String, dynamic>? _selectedCategoryData() {
    if (touchedIndex == null) {
      return null;
    }

    final entries = _validEntries;

    if (touchedIndex! < 0 || touchedIndex! >= entries.length) {
      return null;
    }

    final entry = entries[touchedIndex!];

    return {
      'name': entry.key,
      'amount': entry.value,
      'percentage': _percentage(entry.value),
      'color': _categoryColor(entry.key, touchedIndex!),
    };
  }

  @override
  void didUpdateWidget(covariant CategoryBreakdownChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.categoryTotals != widget.categoryTotals ||
        oldWidget.chartHeight != widget.chartHeight) {
      touchedIndex = null;
    }
  }

  List<PieChartSectionData> _buildSections(
    BuildContext context, {
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    final entries = _validEntries;

    if (entries.isEmpty) {
      return [];
    }

    final baseRadius = desktop
        ? 94.0
        : tablet
        ? 84.0
        : landscape
        ? 60.0
        : compact
        ? 56.0
        : 72.0;

    final selectedRadius = baseRadius + (compact ? 5 : 8);

    return entries.asMap().entries.map((item) {
      final index = item.key;
      final entry = item.value;

      final selected = touchedIndex == index;
      final color = _categoryColor(entry.key, index);

      return PieChartSectionData(
        value: entry.value,
        color: color,
        title: '',
        radius: selected ? selectedRadius : baseRadius,
        showTitle: false,
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.surface,
          width: selected ? 3.0 : 2.0,
        ),
      );
    }).toList();
  }

  Widget _buildCenterContent(BuildContext context) {
    final selected = _selectedCategoryData();
    final top = _topCategory;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final activeName = selected?['name']?.toString() ?? top?.key ?? 'Spending';

    final activeAmount = (selected?['amount'] as double?) ?? top?.value ?? 0;

    final activePercentage =
        (selected?['percentage'] as double?) ??
        (top == null ? 0 : _percentage(top.value));

    final activeColor =
        (selected?['color'] as Color?) ??
        (top == null ? colorScheme.primary : _categoryColor(top.key, 0));

    final isSelected = selected != null;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: Column(
        key: ValueKey('${isSelected ? 'selected' : 'top'}-$activeName'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: activeColor.withOpacity(.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSelected
                  ? Icons.touch_app_rounded
                  : Icons.account_balance_wallet_rounded,
              size: 18,
              color: activeColor,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            isSelected ? activeName : 'Total Spending',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isSelected
                  ? CurrencyFormatter.format(activeAmount)
                  : CurrencyFormatter.format(_totalSpending),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSelected ? 19 : 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -.3,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: activeColor.withOpacity(.09),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isSelected
                  ? '${activePercentage.toStringAsFixed(1)}% of spending'
                  : top == null
                  ? 'No category data'
                  : 'Top: ${top.key} • ${activePercentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: activeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
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

    final chartHeight = widget.chartHeight;

    final availableHeight = math.max(150.0, chartHeight - (compact ? 8 : 12));

    final chartWidth = MediaQuery.sizeOf(context).width;

    final maxSquare = desktop
        ? 300.0
        : tablet
        ? 270.0
        : compact
        ? 205.0
        : landscape
        ? 210.0
        : 240.0;

    final chartDimension = math.min(
      maxSquare,
      math.min(availableHeight, chartWidth * .72),
    );

    final centerSpaceRadius = desktop
        ? 60.0
        : tablet
        ? 54.0
        : compact
        ? 36.0
        : landscape
        ? 39.0
        : 48.0;

    return SizedBox(
      height: chartDimension,
      width: chartDimension,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: centerSpaceRadius,
              centerSpaceColor: Theme.of(context).colorScheme.surface,
              sectionsSpace: compact ? 2 : 3,
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
            swapAnimationDuration: const Duration(milliseconds: 350),
            swapAnimationCurve: Curves.easeOutCubic,
          ),
          IgnorePointer(child: _buildCenterContent(context)),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    int index,
    MapEntry<String, double> entry, {
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final color = _categoryColor(entry.key, index);
    final percentage = _percentage(entry.value);
    final selected = touchedIndex == index;

    final indicatorSize = compact ? 9.0 : 10.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          touchedIndex = selected ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.only(bottom: compact ? 6 : 8),
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 11,
          vertical: compact ? 8 : 9,
        ),
        decoration: BoxDecoration(
          color: selected
              ? _surfaceTint(context, color, opacity: .075)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(compact ? 12 : 14),
          border: Border.all(
            color: selected
                ? color.withOpacity(.22)
                : colorScheme.outline.withOpacity(.055),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: indicatorSize,
              height: indicatorSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(.20),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),

            SizedBox(width: compact ? 8 : 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 11 : 12.5,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
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

                  SizedBox(height: compact ? 5 : 6),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: (percentage / 100).clamp(0.0, 1.0),
                      minHeight: compact ? 4 : 5,
                      backgroundColor: color.withOpacity(.08),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(width: compact ? 8 : 12),

            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                CurrencyFormatter.format(entry.value),
                style: TextStyle(
                  fontSize: compact ? 10 : 11.5,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final top = _topCategory;

    if (top == null) {
      return const SizedBox.shrink();
    }

    final topColor = _categoryColor(top.key, 0);
    final topPercentage = _percentage(top.value);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where your money goes',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: compact ? 14 : 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${_validEntries.length} spending categories',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: compact ? 10 : 11,
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
            color: topColor.withOpacity(.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: topColor.withOpacity(.10)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.trending_up_rounded,
                size: compact ? 13 : 15,
                color: topColor,
              ),
              const SizedBox(width: 5),
              Text(
                '${top.key} ${topPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: compact ? 9 : 10,
                  fontWeight: FontWeight.w800,
                  color: topColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = ResponsiveHelper.useCompactLayout(context);
    final landscape = ResponsiveHelper.isLandscape(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);

    final entries = _validEntries;

    final chartWidth = AnalyticsLayoutHelper.maxChartWidth(context);

    final cardRadius = desktop
        ? 26.0
        : tablet
        ? 24.0
        : compact
        ? 18.0
        : 22.0;

    final cardPadding = desktop
        ? 20.0
        : tablet
        ? 18.0
        : landscape
        ? 12.0
        : compact
        ? 12.0
        : 16.0;

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
                borderRadius: BorderRadius.circular(cardRadius),
              ),
              child: SizedBox(
                height: widget.chartHeight,
                child: Center(
                  child: Text(
                    'No category spending data',
                    style: TextStyle(
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final selectedCategory = _selectedCategoryData();

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
              borderRadius: BorderRadius.circular(cardRadius),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(.07),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, compact: compact),

                  SizedBox(height: compact ? 12 : 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wideLayout = constraints.maxWidth >= 720;

                      if (wideLayout) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Center(
                                child: _buildChart(
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
                              child: Column(
                                children: [
                                  for (final item in entries.asMap().entries)
                                    _buildCategoryRow(
                                      context,
                                      item.key,
                                      item.value,
                                      compact: compact,
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
                            child: _buildChart(
                              context,
                              compact: compact,
                              tablet: tablet,
                              desktop: desktop,
                              landscape: landscape,
                            ),
                          ),

                          SizedBox(height: compact ? 8 : 12),

                          for (final item in entries.asMap().entries)
                            _buildCategoryRow(
                              context,
                              item.key,
                              item.value,
                              compact: compact,
                            ),
                        ],
                      );
                    },
                  ),

                  if (selectedCategory != null) ...[
                    SizedBox(height: compact ? 5 : 8),
                    _SelectedCategoryCard(
                      name: selectedCategory['name'] as String,
                      amount: selectedCategory['amount'] as double,
                      percentage: selectedCategory['percentage'] as double,
                      color: selectedCategory['color'] as Color,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedCategoryCard extends StatelessWidget {
  final String name;
  final double amount;
  final double percentage;
  final Color color;

  const _SelectedCategoryCard({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

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
            child: Icon(
              Icons.analytics_rounded,
              size: compact ? 15 : 18,
              color: color,
            ),
          ),

          SizedBox(width: compact ? 8 : 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name spending',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${percentage.toStringAsFixed(1)}% of total spending',
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
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: compact ? 11 : 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
