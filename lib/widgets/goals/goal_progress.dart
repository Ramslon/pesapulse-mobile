import 'package:flutter/material.dart';

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

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: progressValue),
      builder: (_, value, __) {
        return Container(
          height: 10,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value,
            child: Container(
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }
}
