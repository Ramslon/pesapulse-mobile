import 'package:flutter/material.dart';

class RecommendationCard extends StatelessWidget {
  final String budgetStatus;
  final String recommendation;
  final String categoryAdvice;
  final String topCategory;
  final double budgetUsage;

  const RecommendationCard({
    super.key,
    required this.budgetStatus,
    required this.recommendation,
    required this.categoryAdvice,
    required this.topCategory,
    required this.budgetUsage,
  });

  Color getRecommendationColor() {
    switch (budgetStatus.toLowerCase()) {
      case "healthy":
        return Colors.green;

      case "warning":
        return Colors.orange;

      case "overspent":
        return Colors.deepOrange;

      case "critical":
        return Colors.red;

      default:
        return Colors.blue;
    }
  }

  IconData getRecommendationIcon() {
    switch (budgetStatus.toLowerCase()) {
      case "critical":
        return Icons.warning_rounded;

      case "overspent":
        return Icons.error_outline;

      case "warning":
        return Icons.info_outline;

      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = getRecommendationColor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(getRecommendationIcon(), color: Colors.white),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Text(
                  "Smart Recommendation",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              budgetStatus.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            recommendation,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),

          const SizedBox(height: 15),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.pie_chart, color: Colors.white),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Top Spending Category",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        topCategory,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.white),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    categoryAdvice,
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            tween: Tween(begin: 0, end: (budgetUsage / 100).clamp(0.0, 1.0)),
            builder: (_, value, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 10,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 900),
            tween: Tween(begin: 0, end: budgetUsage),
            builder: (_, value, __) {
              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "${value.toStringAsFixed(1)}%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: " of budget used",
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
