import 'package:flutter/material.dart';
import 'package:pesapulse_mobile/utils/responsive_helper.dart';

class GoalProgress extends StatelessWidget {
  final double percentage;

  const GoalProgress({super.key, required this.percentage});

  double get progressValue {
    return percentage.clamp(0.0, 1.0);
  }

  Color get progressColor {
    if (progressValue >= 1.0) {
      return Colors.green;
    }

    if (progressValue >= 0.75) {
      return Colors.orange;
    }

    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isCompact = ResponsiveHelper.useCompactLayout(context);
    final isLandscape = ResponsiveHelper.isLandscape(context);

    // Keep the progress bar visually slim while giving it
    // enough height for comfortable rendering on larger screens.
    final barHeight = isCompact
        ? 8.0
        : isLandscape
        ? 9.0
        : 10.0;

    final radius = barHeight / 2;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: progressValue),
      builder: (_, value, __) {
        return Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
        );
      },
    );
  }
}
