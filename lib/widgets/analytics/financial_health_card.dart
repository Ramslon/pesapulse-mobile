import 'package:flutter/material.dart';
import '../fade_slide_animation.dart';

class FinancialHealthCard extends StatelessWidget {
  final double healthScore;
  final String healthStatus;
  final String recommendation;
  final Color color;
  final IconData icon;

  const FinancialHealthCard({
    super.key,
    required this.healthScore,
    required this.healthStatus,
    required this.recommendation,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideAnimation(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color,
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white.withOpacity(.2),
                  child: Icon(icon, color: Colors.white, size: 40),
                ),

                const SizedBox(width: 12),

                const Expanded(
                  child: Text(
                    "Financial Health",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 900),
              tween: Tween(begin: 0, end: healthScore),
              builder: (_, value, __) {
                return Text(
                  '${value.toStringAsFixed(0)}/100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),

            const SizedBox(height: 5),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                healthStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 24),

            Text(
              recommendation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
