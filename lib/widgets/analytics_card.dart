import 'package:flutter/material.dart';

class AnalyticsCard extends StatelessWidget {
  final IconData icon;

  final String title;

  final String value;

  final Color color;

  const AnalyticsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(21),
              ),
              child: Icon(icon, color: color, size: 24),
            ),

            const Spacer(),

            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                letterSpacing: .3,
              ),
            ),

            Divider(color: Colors.grey.shade200, thickness: 1),

            const SizedBox(height: 8),

            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              builder: (context, animation, child) {
                return Opacity(
                  opacity: animation,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - animation)),
                    child: child,
                  ),
                );
              },

              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
