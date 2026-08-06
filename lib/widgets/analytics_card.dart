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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 120;

        final padding = compact ? 10.0 : 18.0;
        final iconBox = compact ? 30.0 : 42.0;
        final iconSize = compact ? 18.0 : 24.0;
        final titleSize = compact ? 11.0 : 13.0;
        final valueSize = compact ? 15.0 : 18.0;

        return Card(
          elevation: 2,
          shadowColor: color.withOpacity(.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: iconBox,
                  height: iconBox,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(iconBox / 2),
                  ),
                  child: Icon(icon, color: color, size: iconSize),
                ),

                SizedBox(height: compact ? 6 : 10),

                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: titleSize,
                    letterSpacing: .3,
                  ),
                ),

                Divider(
                  color: Colors.grey.shade200,
                  thickness: .8,
                  height: compact ? 10 : 16,
                ),

                Expanded(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: TweenAnimationBuilder<double>(
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
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          maxLines: 1,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: valueSize,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
