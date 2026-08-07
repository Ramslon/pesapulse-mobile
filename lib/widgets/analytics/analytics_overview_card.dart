import 'package:flutter/material.dart';

class AnalyticsOverviewCard extends StatelessWidget {
  final double totalSpending;

  const AnalyticsOverviewCard({super.key, required this.totalSpending});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      tween: Tween(begin: .95, end: 1),
      builder: (_, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Analytics Overview",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Track your spending and financial progress",
                style: TextStyle(color: Colors.grey.shade600),
              ),

              const SizedBox(height: 22),

              Text(
                "KES ${totalSpending.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                "Total Spending",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
