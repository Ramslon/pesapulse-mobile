import 'package:flutter/material.dart';

class BudgetStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;
  final bool isLandscape;

  const BudgetStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
    required this.isLandscape,
  });

  @override
  Widget build(BuildContext context) {
    final padding = isLandscape ? 10.0 : 16.0;
    final iconRadius = isLandscape ? 14.0 : 18.0;
    final iconSize = isLandscape ? 16.0 : 22.0;
    final titleSize = isLandscape ? 10.5 : 12.5;
    final valueSize = isLandscape ? 15.0 : 20.0;
    final spacing = isLandscape ? 4.0 : 10.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Card(
        elevation: isLandscape ? 1 : 2,
        shadowColor: color.withOpacity(.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isLandscape ? 16 : 20),
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: iconRadius,
                backgroundColor: color.withOpacity(.12),
                child: Icon(icon, color: color, size: iconSize),
              ),

              SizedBox(height: spacing),

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: titleSize,
                ),
              ),

              Expanded(
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: valueSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
