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
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Card(
      elevation: 2,
      shadowColor: color.withOpacity(.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: EdgeInsets.all(isLandscape ? 12 : 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: isLandscape ? 34 : 42,
              height: isLandscape ? 34 : 42,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(21),
              ),
              child: Icon(icon, color: color, size: isLandscape ? 20 : 24),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: isLandscape ? 11 : 13,
                    letterSpacing: .3,
                  ),
                ),

                Divider(color: Colors.grey.shade200, thickness: 1),

                SizedBox(height: isLandscape ? 3 : 6),

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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isLandscape ? 15 : 18,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
