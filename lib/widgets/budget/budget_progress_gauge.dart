import 'package:flutter/material.dart';

import '../../utils/responsive_helper.dart';

class BudgetProgressGauge extends StatelessWidget {
  final double budget;
  final double spent;
  final double percentageUsed;
  final Color statusColor;

  const BudgetProgressGauge({
    super.key,
    required this.budget,
    required this.spent,
    required this.percentageUsed,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final compact = ResponsiveHelper.useCompactLayout(context);

    final tablet = ResponsiveHelper.isTablet(context);

    final desktop = ResponsiveHelper.isDesktop(context);

    final landscape = ResponsiveHelper.isLandscape(context);

    final strokeWidth = desktop
        ? 13.0
        : tablet
        ? 12.0
        : compact
        ? 9.0
        : landscape
        ? 10.0
        : 12.0;

    final percentageFontSize = desktop
        ? 28.0
        : tablet
        ? 25.0
        : compact
        ? 19.0
        : landscape
        ? 21.0
        : 24.0;

    final labelFontSize = desktop
        ? 11.0
        : compact
        ? 9.0
        : 10.0;

    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

    // The visual arc caps at 100%, but the displayed
    // number remains the real budget usage.
    final actualPercentage = percentageUsed.isFinite
        ? percentageUsed.clamp(0.0, double.infinity)
        : 0.0;

    final isOverBudget = actualPercentage > 100.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final shortestSide = constraints.biggest.shortestSide;

        if (shortestSide <= 0 || !shortestSide.isFinite) {
          return const SizedBox.shrink();
        }

        final size = shortestSide;

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Soft outer glow.
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(
                        theme.brightness == Brightness.dark ? 0.08 : 0.045,
                      ),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),

              // Background track.
              SizedBox.square(
                dimension: size,
                child: CircularProgressIndicator(
                  value: 1.0,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.78),
                ),
              ),

              // Animated progress.
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return SizedBox.square(
                    dimension: size,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: strokeWidth,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.transparent,
                      color: statusColor,
                    ),
                  );
                },
              ),

              // Center metric.
              Container(
                width: size * 0.66,
                height: size * 0.66,
                decoration: BoxDecoration(
                  color: theme.cardColor.withOpacity(
                    theme.brightness == Brightness.dark ? 0.72 : 0.92,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withOpacity(0.08)),
                ),
                child: Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: actualPercentage),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${value.toStringAsFixed(0)}%',
                              maxLines: 1,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: percentageFontSize,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 6 : 8,
                              vertical: compact ? 2.5 : 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isOverBudget ? 'over budget' : 'used',
                              maxLines: 1,
                              style: TextStyle(
                                color: statusColor.withOpacity(0.80),
                                fontSize: labelFontSize,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
