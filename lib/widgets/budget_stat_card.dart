import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';

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
    final padding = isLandscape ? 12.0 : 18.0;
    final iconRadius = isLandscape ? 16.0 : 20.0;
    final iconSize = isLandscape ? 18.0 : 24.0;
    final titleSize = isLandscape ? 11.0 : 13.0;
    final valueSize = isLandscape ? 16.0 : 22.0;
    final spacing = isLandscape ? 6.0 : 12.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Card(
        elevation: 2,
        shadowColor: color.withOpacity(.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

              const Spacer(),

              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: valueSize,
                    fontWeight: FontWeight.bold,
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
