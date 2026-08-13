import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../fade_slide_animation.dart';
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

  static const List<Color> _colors = [
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  List<MapEntry<String, double>> get _validEntries {
    return widget.categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList();
  }

  double get _totalSpending {
    return _validEntries.fold<double>(0, (sum, entry) => sum + entry.value);
  }

  List<PieChartSectionData> _getSections(BuildContext context) {
    final entries = _validEntries;

    if (entries.isEmpty) {
      return [];
    }

    final screenWidth = MediaQuery.of(context).size.width;

    final baseRadius = screenWidth >= 1200
        ? 92.0
        : screenWidth >= 900
        ? 84.0
        : screenWidth >= 600
        ? 76.0
        : 66.0;

    final titleFontSize = screenWidth >= 900
        ? 11.5
        : screenWidth >= 600
        ? 11.0
        : 10.0;

    return entries.asMap().entries.map((item) {
      final index = item.key;
      final entry = item.value;

      final isTouched = touchedIndex == index;

      return PieChartSectionData(
        color: _colors[index % _colors.length],
        value: entry.value,

        // Keep the chart clean. Details appear in the center/selected card.
        title: '',

        radius: isTouched ? baseRadius + 8 : baseRadius,

        titleStyle: TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),

        badgeWidget: isTouched
            ? _CategoryBadge(name: entry.key, amount: entry.value)
            : null,

        badgePositionPercentageOffset: 1.25,
      );
    }).toList();
  }

  Map<String, dynamic>? _getSelectedCategory() {
    if (touchedIndex == null) {
      return null;
    }

    final entries = _validEntries;

    if (touchedIndex! < 0 || touchedIndex! >= entries.length) {
      return null;
    }

    final entry = entries[touchedIndex!];

    final percentage = _totalSpending == 0
        ? 0.0
        : (entry.value / _totalSpending) * 100;

    return {
      'name': entry.key,
      'amount': entry.value,
      'percentage': percentage,
      'color': _colors[touchedIndex! % _colors.length],
    };
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final selectedCategory = _getSelectedCategory();

    final cardPadding = screenWidth >= 900
        ? 18.0
        : screenWidth >= 600
        ? 16.0
        : 14.0;

    final chartWidth = AnalyticsLayoutHelper.maxChartWidth(context);

    final centerSpaceRadius = (widget.chartHeight * 0.15).clamp(34.0, 58.0);

    final sections = _getSections(context);

    return FadeSlideAnimation(
      delay: 200,
      child: Column(
        children: [
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: chartWidth),
              child: Card(
                elevation: 2,
                shadowColor: Colors.black.withOpacity(.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: EdgeInsets.all(cardPadding),
                  child: SizedBox(
                    height: widget.chartHeight,
                    width: double.infinity,
                    child: sections.isEmpty
                        ? const Center(
                            child: Text(
                              'No category spending data',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          )
                        : Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sections: sections,
                                  centerSpaceRadius: centerSpaceRadius,
                                  sectionsSpace: 4,
                                  startDegreeOffset: -90,

                                  pieTouchData: PieTouchData(
                                    touchCallback:
                                        (
                                          FlTouchEvent event,
                                          PieTouchResponse? response,
                                        ) {
                                          if (!event
                                                  .isInterestedForInteractions ||
                                              response?.touchedSection ==
                                                  null) {
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
                                swapAnimationDuration: const Duration(
                                  milliseconds: 350,
                                ),
                                swapAnimationCurve: Curves.easeOutCubic,
                              ),

                              IgnorePointer(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.pie_chart_rounded,
                                      size: 24,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      'Total Spending',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade300,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    const SizedBox(height: 3),

                                    Text(
                                      'KES ${_totalSpending.toStringAsFixed(0)}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),

          if (selectedCategory != null) ...[
            const SizedBox(height: 12),

            _SelectedCategoryCard(
              name: selectedCategory['name'] as String,
              amount: selectedCategory['amount'] as double,
              percentage: selectedCategory['percentage'] as double,
              color: selectedCategory['color'] as Color,
            ),
          ],
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String name;
  final double amount;

  const _CategoryBadge({required this.name, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 130),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'KES ${amount.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
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
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withOpacity(.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 42,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            const SizedBox(width: 12),

            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'KES ${amount.toStringAsFixed(0)} spent',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: color.withOpacity(.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
