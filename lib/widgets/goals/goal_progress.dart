import 'package:flutter/material.dart';

class GoalProgress extends StatelessWidget {
  final double percentage;

  const GoalProgress({super.key, required this.percentage});

  Color get progressColor {
    if (percentage >= 1.0) {
      return Colors.green;
    }

    if (percentage >= 0.75) {
      return Colors.orange;
    }

    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 900),
          tween: Tween(begin: 0, end: percentage),
          builder: (_, value, __) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                color: progressColor,
              ),
            );
          },
        ),

        const SizedBox(height: 14),

        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: progressColor.withOpacity(.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 800),
              tween: Tween(begin: 0, end: percentage * 100),
              builder: (_, value, __) {
                return Text(
                  '${value.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
