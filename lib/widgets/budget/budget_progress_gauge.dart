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

    final compact = ResponsiveHelper.useCompactLayout(context);
    final tablet = ResponsiveHelper.isTablet(context);
    final desktop = ResponsiveHelper.isDesktop(context);
    final landscape = ResponsiveHelper.isLandscape(context);

    final strokeWidth = compact
        ? 10.0
        : tablet
        ? 12.0
        : desktop
        ? 13.0
        : landscape
        ? 11.0
        : 14.0;

    final percentageFontSize = compact
        ? 20.0
        : tablet
        ? 25.0
        : desktop
        ? 27.0
        : landscape
        ? 22.0
        : 25.0;

    final labelFontSize = compact
        ? 11.0
        : desktop
        ? 13.0
        : 12.0;

    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

    final displayedPercentage = percentageUsed.clamp(0.0, 100.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide;

        if (size <= 0 || !size.isFinite) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
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
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: statusColor,
                    ),
                  );
                },
              ),

              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: displayedPercentage),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${value.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: percentageFontSize,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'used',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(
                            .65,
                          ),
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
