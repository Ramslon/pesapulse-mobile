import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/responsive_helper.dart';
import '../core/utils/currency_formatter.dart';

class SpendingPieChart extends StatelessWidget {
  final Map<String, double> categoryTotals;

  const SpendingPieChart({super.key, required this.categoryTotals});

  static const List<Color> colors = [
    Colors.orange,
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
      return const SizedBox.shrink();
    }

    final compact = ResponsiveHelper.useCompactLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final total = categoryTotals.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    if (total <= 0) {
      return const SizedBox.shrink();
    }

    final chartSize = _chartSize(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
      landscape: landscape,
    );

    final centerSpaceRadius = _centerSpaceRadius(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
      landscape: landscape,
    );

    final sectionRadius = _sectionRadius(
      compact: compact,
      tablet: tablet,
      desktop: desktop,
      landscape: landscape,
    );

    final percentageFontSize = compact
        ? 9.0
        : tablet
        ? 11.0
        : desktop
        ? 12.0
        : landscape
        ? 9.0
        : 11.0;

    return Center(
      child: SizedBox(
        width: chartSize,
        height: chartSize,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeOutCubic,
          builder: (context, animation, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    centerSpaceRadius: centerSpaceRadius,
                    sectionsSpace: compact ? 2 : 3,
                    startDegreeOffset: -90,
                    sections: _buildSections(
                      total: total,
                      radius: sectionRadius,
                      percentageFontSize: percentageFontSize,
                      animation: animation,
                    ),
                  ),
                ),

                // Center financial summary.
                IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_rounded,
                        size: compact
                            ? 18
                            : landscape
                            ? 19
                            : 22,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(.8),
                      ),

                      SizedBox(
                        height: compact
                            ? 4
                            : landscape
                            ? 5
                            : 7,
                      ),

                      Text(
                        "Total Spent",
                        style: TextStyle(
                          fontSize: compact
                              ? 9
                              : landscape
                              ? 10
                              : 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(.65),
                        ),
                      ),

                      const SizedBox(height: 3),

                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyFormatter.format(total),
                          style: TextStyle(
                            fontSize: compact
                                ? 15
                                : tablet
                                ? 18
                                : desktop
                                ? 20
                                : 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections({
    required double total,
    required double radius,
    required double percentageFontSize,
    required double animation,
  }) {
    final entries = categoryTotals.entries.toList();

    return entries.asMap().entries.map((item) {
      final index = item.key;
      final entry = item.value;

      final percentage = (entry.value / total) * 100;

      final showPercentage = percentage >= 5;

      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value,
        radius: radius * animation,

        title: showPercentage ? "${percentage.toStringAsFixed(0)}%" : "",

        titleStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: percentageFontSize,
          shadows: const [Shadow(blurRadius: 3, color: Colors.black26)],
        ),

        badgeWidget: percentage < 5 ? null : null,

        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      );
    }).toList();
  }

  double _chartSize({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    if (desktop) {
      return 250;
    }

    if (tablet) {
      return landscape ? 190 : 230;
    }

    if (landscape) {
      return 155;
    }

    if (compact) {
      return 190;
    }

    return 215;
  }

  double _centerSpaceRadius({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    if (desktop) {
      return 72;
    }

    if (tablet) {
      return landscape ? 52 : 65;
    }

    if (landscape) {
      return 45;
    }

    if (compact) {
      return 55;
    }

    return 62;
  }

  double _sectionRadius({
    required bool compact,
    required bool tablet,
    required bool desktop,
    required bool landscape,
  }) {
    if (desktop) {
      return 78;
    }

    if (tablet) {
      return landscape ? 58 : 70;
    }

    if (landscape) {
      return 48;
    }

    if (compact) {
      return 60;
    }

    return 68;
  }
}
