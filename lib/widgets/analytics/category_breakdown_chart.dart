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

    // Remove zero and negative values.
    final validEntries = widget.categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (validEntries.isEmpty) {
      return [];
    }

    // Special handling for a single category.
    if (validEntries.length == 1) {
      final entry = validEntries.first;

      return [
        PieChartSectionData(
          color: colors.first,
          value: entry.value,
          title: '${entry.key}\nKES ${entry.value.toStringAsFixed(0)}',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ];
    }

    return validEntries.asMap().entries.map((item) {
      final index = item.key;
      final entry = item.value;

      return PieChartSectionData(
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
    }).toList();
  }

  Map<String, dynamic>? _getSelectedCategory() {
    if (touchedIndex == null) {
      return null;
    }

    final validEntries = widget.categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList();

    if (touchedIndex! < 0 || touchedIndex! >= validEntries.length) {
      return null;
    }

    final entry = validEntries[touchedIndex!];

    final total = validEntries.fold<double>(
      0,
      (sum, value) => sum + value.value,
    );

    final percentage = total == 0 ? 0.0 : (entry.value / total) * 100;

    return {'name': entry.key, 'amount': entry.value, 'percentage': percentage};
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final selectedCategory = _getSelectedCategory();

    final cardPadding = screenWidth >= 900
        ? 16.0
        : screenWidth >= 600
        ? 14.0
        : 12.0;

    final chartWidth = AnalyticsLayoutHelper.maxChartWidth(context);

    final centerSpaceRadius = (widget.chartHeight * 0.12).clamp(30.0, 55.0);

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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
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
                        : PieChart(
                            PieChartData(
                              sections: sections,
                              centerSpaceRadius: centerSpaceRadius,
                              sectionsSpace: 3,
                              pieTouchData: PieTouchData(
                                touchCallback:
                                    (
                                      FlTouchEvent event,
                                      PieTouchResponse? response,
                                    ) {
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

          if (selectedCategory != null) ...[
            const SizedBox(height: 12),

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
                            selectedCategory['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'KES ${selectedCategory['amount'].toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      '${selectedCategory['percentage'].toStringAsFixed(1)}%',
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
        ],
      ),
    );
  }
}
