import 'package:flutter/material.dart';

class BudgetProgressGauge extends StatelessWidget {
  final double budget;
  final double spent;
  final double percentageUsed;
  final Color statusColor;
  final bool isLandscape;

  const BudgetProgressGauge({
    super.key,
    required this.budget,
    required this.spent,
    required this.percentageUsed,
    required this.statusColor,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final gaugeSize = isLandscape
        ? 130.0
        : (screenWidth * .34).clamp(120.0, 170.0);

    final theme = Theme.of(context);

    return SizedBox(
      width: gaugeSize,
      height: gaugeSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: budget > 0 ? spent / budget : 0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return CircularProgressIndicator(
                value: value,
                strokeWidth: 16,
                strokeCap: StrokeCap.round,
                backgroundColor: Colors.grey.shade200,
                color: statusColor,
              );
            },
          ),

          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percentageUsed),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${value.toStringAsFixed(0)}%",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isLandscape
                          ? screenWidth * .035
                          : screenWidth * .07,
                    ),
                  ),

                  Text(
                    "used",
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(.7),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
